FROM odavid/jenkins-jnlp-slave:3071.v7e9b_0dc08466-1-39-jdk17

USER root
RUN apt-get update && \
    apt-get install -y wget gnupg && \
    wget -O- https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb > /tmp/jdk21.deb && \
    apt install -y /tmp/jdk21.deb && \
    rm -rf /var/lib/apt/lists/* /tmp/jdk21.deb

# Ensure JAVA_HOME points to JDK 21
ENV JAVA_HOME=/usr/lib/jvm/jdk-21
ENV PATH="${JAVA_HOME}/bin:${PATH}"
RUN apt upgrade -y
