FROM ubuntu:18.04
ENV ZK_USER=zookeeper \
ZK_DATA_DIR=/var/lib/zookeeper/data \
ZK_DATA_LOG_DIR=/var/lib/zookeeper/log \
ZK_LOG_DIR=/var/log/zookeeper \
JAVA_HOME=/usr/lib/jvm/applejdk-11.0.6.10.2

ARG GPG_KEY=BBE7232D7991050B54C8EA0ADC08637CA615D22C
ARG ZK_DIST_SHORT=zookeeper-3.5.6
ARG ZK_DIST=apache-zookeeper-3.5.6-bin
RUN mkdir ~/.gnupg
RUN echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf
RUN set -x \
    && apt-get update \
    && apt-get install -y wget \
    && apt-get install -y  gpg-agent \
    && apt-get install -y netcat-openbsd \
    && apt-get -y install curl \

    #get apple jdk
    && curl -k https://artifacts.apple.com/api/gpg/key/public | apt-key add - \
    && grep -q "applejdk-apt-local universal release" /etc/apt/sources.list || echo 'deb [trusted=yes] https://artifacts.apple.com/applejdk-apt-local universal release' >> /etc/apt/sources.list \
    #following two echos are here to bypass SSL to make apt-get update pass
    && echo 'Acquire::https::artifacts.apple.com::Verify-Peer "false";' >> /etc/apt/apt.conf.d/80ssl-exceptions \
    && echo 'Acquire::https::artifacts.apple.com::Verify-Host "false";' >> /etc/apt/apt.conf.d/80ssl-exceptions \
    && apt-get update \
    && apt-get -y install applejdk-11 \

	#get zookeeper
	&& wget -q "https://archive.apache.org/dist/zookeeper/$ZK_DIST_SHORT/$ZK_DIST.tar.gz" \
    && wget -q "https://archive.apache.org/dist/zookeeper/$ZK_DIST_SHORT/$ZK_DIST.tar.gz.asc" \
    && export GNUPGHOME="$(mktemp -d)" \
    && gpg --keyserver ipv4.pool.sks-keyservers.net --recv-key "$GPG_KEY" \
    && gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" \
    && gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys "$GPG_KEY" \
    && gpg --batch --verify "$ZK_DIST.tar.gz.asc" "$ZK_DIST.tar.gz" \
    && tar -xzf "$ZK_DIST.tar.gz" -C /opt \
    && rm -r "$ZK_DIST.tar.gz" "$ZK_DIST.tar.gz.asc" \
    && pkill -9 gpg-agent \
    && pkill -9 dirmngr \
    && rm -rf "$GNUPGHOME" \
    && ln -s /opt/$ZK_DIST /opt/zookeeper \
    && rm -rf /opt/zookeeper/CHANGES.txt \
    /opt/zookeeper/README.txt \
    /opt/zookeeper/NOTICE.txt \
    /opt/zookeeper/CHANGES.txt \
    /opt/zookeeper/README_packaging.txt \
    /opt/zookeeper/build.xml \
    /opt/zookeeper/config \
    /opt/zookeeper/contrib \
    /opt/zookeeper/dist-maven \
    /opt/zookeeper/docs \
    /opt/zookeeper/ivy.xml \
    /opt/zookeeper/ivysettings.xml \
    /opt/zookeeper/recipes \
    /opt/zookeeper/src \
    /opt/zookeeper/$ZK_DIST.jar.asc \
    /opt/zookeeper/$ZK_DIST.jar.md5 \
    /opt/zookeeper/$ZK_DIST.jar.sha1 \
	&& apt-get autoremove -y wget \
	&& rm -rf /var/lib/apt/lists/*

#Copy configuration generator script to bin
COPY scripts /opt/zookeeper/bin/

# Create a user for the zookeeper process and configure file system ownership
# for nessecary directories and symlink the distribution as a user executable
RUN set -x \
	&& useradd $ZK_USER \
    && [ `id -u $ZK_USER` -eq 1000 ] \
    && [ `id -g $ZK_USER` -eq 1000 ] \
    && mkdir -p $ZK_DATA_DIR $ZK_DATA_LOG_DIR $ZK_LOG_DIR /usr/share/zookeeper /tmp/zookeeper /usr/etc/ \
	&& chown -R "$ZK_USER:$ZK_USER" /opt/$ZK_DIST $ZK_DATA_DIR $ZK_LOG_DIR $ZK_DATA_LOG_DIR /tmp/zookeeper \
	&& ln -s /opt/zookeeper/conf/ /usr/etc/zookeeper \
	&& ln -s /opt/zookeeper/bin/* /usr/bin \
	&& ln -s /opt/zookeeper/$ZK_DIST.jar /usr/share/zookeeper/ \
	&& ln -s /opt/zookeeper/lib/* /usr/share/zookeeper

ENTRYPOINT ["start-zookeeper"]