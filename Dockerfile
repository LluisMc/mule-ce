FROM openjdk:8-jdk-alpine

# Define arguments to build image
ARG REPOSITORY_OWNER
ARG REPOSITORY_NAME
ARG RELEASE_VERSION
ARG APP_NAME
ARG APP_VERSION

# Define environment variables.
ENV BUILD_DATE=12082019
ENV MULE_HOME=/opt/mule
ENV MULE_VERSION=4.2.1
ENV MULE_MD5=de730172857f8030746c40d28e178446
ENV TINI_SUBREAPER=
ENV TZ=Europe/Madrid
ENV GLIBC_REPO=https://github.com/sgerrand/alpine-pkg-glibc
ENV GLIBC_VERSION=2.29-r0

# SSL Cert for downloading mule zip
RUN apk --no-cache update && \
    apk --no-cache upgrade && \
    apk --no-cache add ca-certificates && \
    update-ca-certificates && \
    apk --no-cache add openssl && \
    apk add --update tzdata && \
    apk add --update bash && \
    rm -rf /var/cache/apk/*

# Install glibc library required by the Java Wrapper.
RUN apk add libstdc++ curl java-cacerts && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL ${GLIBC_REPO}/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

RUN adduser -D -g "" mule mule

RUN mkdir /opt/mule-standalone-${MULE_VERSION} && \
    ln -s /opt/mule-standalone-${MULE_VERSION} ${MULE_HOME} && \
    chown mule:mule -R /opt/mule*

# Set timezone
RUN echo ${TZ} > /etc/timezone

USER mule

# For checksum, alpine linux needs two spaces between checksum and file name
RUN cd ~ && wget https://repository-master.mulesoft.org/nexus/content/repositories/releases/org/mule/distributions/mule-standalone/${MULE_VERSION}/mule-standalone-${MULE_VERSION}.tar.gz && \
    echo "${MULE_MD5}  mule-standalone-${MULE_VERSION}.tar.gz" | md5sum -c && \
    cd /opt && \
    tar xvzf ~/mule-standalone-${MULE_VERSION}.tar.gz && \
    rm ~/mule-standalone-${MULE_VERSION}.tar.gz

#Download Mule application jar
RUN cd ~ && wget https://github.com/${REPOSITORY_OWNER}/${REPOSITORY_NAME}/releases/download/${RELEASE_VERSION}/${APP_NAME}-${APP_VERSION}-mule-application.jar && \
    cd /opt/mule/apps && \
    mv ~/${APP_NAME}-${APP_VERSION}-mule-application.jar .

# Define working directory.
WORKDIR ${MULE_HOME}

CMD [ "/opt/mule/bin/mule"]

# Default http port
EXPOSE 8081
