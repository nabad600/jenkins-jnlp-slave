# Use latest Jenkins inbound agent with JDK21 (Alpine-based)
# Ref: https://hub.docker.com/r/jenkins/inbound-agent/tags
ARG FROM_TAG=alpine3.22-jdk21

FROM jenkins/inbound-agent:${FROM_TAG}

# Versions
ARG GOSU_VERSION=1.17
ARG DOCKER_CHANNEL=stable
ARG DOCKER_VERSION=27.2.1        # latest stable docker
ARG TINY_VERSION=0.19.0          # latest tini

USER root

# Locale setup (Debian vs Alpine)
RUN set -ex; \
    if [ -f /etc/alpine-release ] ; then \
        echo "Alpine base"; \
    elif [ -f /etc/debian_version ] ; then \
        echo "Debian base, setting locales"; \
        apt-get update \
        && apt-get install -y --no-install-recommends locales \
        && localedef -i en_US -f UTF-8 en_US.UTF-8 \
        && rm -rf /var/lib/apt/lists/*; \
    fi

ENV LANG=en_US.UTF-8

# Install base packages
RUN set -ex; \
    echo "Installing required packages"; \
    if [ -f /etc/alpine-release ] ; then \
        apk add --no-cache curl shadow iptables bash \
        ; \
    elif [ -f /etc/debian_version ] ; then \
        apt-get update \
        && apt-get install -y --no-install-recommends curl iptables bash \
        && rm -rf /var/lib/apt/lists/* \
        ; \
    fi

# Install gosu and tini
RUN set -ex; \
    curl -sSL -o /usr/bin/gosu https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-amd64 \
    && chmod +x /usr/bin/gosu \
    && curl -sSL -o /usr/bin/tini https://github.com/krallin/tini/releases/download/v${TINY_VERSION}/tini-static-amd64 \
    && chmod +x /usr/bin/tini

# Install Docker CLI
RUN set -ex; \
    curl -sSL "https://download.docker.com/linux/static/${DOCKER_CHANNEL}/x86_64/docker-${DOCKER_VERSION}.tgz" \
    | tar -xz --strip-components 1 -C /usr/bin/

# Install Docker Compose plugin (V2 replaces legacy docker-compose)
RUN set -ex; \
    mkdir -p /usr/libexec/docker/cli-plugins \
    && curl -sSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64" \
       -o /usr/libexec/docker/cli-plugins/docker-compose \
    && chmod +x /usr/libexec/docker/cli-plugins/docker-compose

# Copy entrypoint & helper scripts
COPY entrypoint.sh /entrypoint.sh
COPY modprobe.sh /usr/local/bin/modprobe
COPY wrapdocker.sh /usr/local/bin/wrapdocker

RUN chmod +x /usr/local/bin/wrapdocker
RUN chmod +x /usr/local/bin/modprobe
RUN chmod +x /entrypoint.sh

VOLUME /var/lib/docker

ENTRYPOINT [ "tiny", "--", "/entrypoint.sh" ]
