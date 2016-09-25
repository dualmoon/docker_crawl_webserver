FROM debian:jessie
MAINTAINER IgorSh

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r -g 1000 crawluser && useradd -r -g crawluser -u 1000 crawluser

# install required packages
RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates \
    wget \
    git \
    python-pip

# add gosu for easy step-down from root
ENV GOSU_VERSION 1.7
RUN set -x \
        && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
        && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
        && export GNUPGHOME="$(mktemp -d)" \
        && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
        && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
        && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
        && chmod +x /usr/local/bin/gosu \
        && gosu nobody true

# clone from github latest crawl version
RUN git clone https://github.com/crawl/crawl.git && cd /crawl \
	&& git checkout 0.18.1 \
        && git submodule update --init \
	&& mkdir -p /crawl/crawl-ref/source/rcs

# install required packages for crawl build
RUN apt-get update \ 
	&& apt-get install --no-install-recommends --no-install-suggests -y \
    build-essential \
    libncursesw5-dev \
    bison \
    flex \
    liblua5.1-0-dev \
    libsqlite3-dev \
    libz-dev \
    pkg-config \
    libsdl2-image-dev \
    libsdl2-mixer-dev \
    libsdl2-dev \
    libfreetype6-dev \
    libpng-dev \
    ttf-dejavu-core \
        && rm -rf /var/lib/apt/lists/*

# install pip and tornado for web server
RUN pip install -U pip && pip install 'tornado>=3.0,<4.0' 

# make webtile version
RUN cd /crawl/crawl-ref/source && make WEBTILES=y

COPY docker-entrypoint.sh /entrypoint.sh
RUN chown -R crawluser:crawluser /entrypoint.sh \
	&& chmod 777 /entrypoint.sh \
	&& chown -R crawluser:crawluser /crawl
RUN apt-get update \
        && apt-get install -y \
    locales
 
RUN touch /etc/locale.conf && echo "LANG=en_US.UTF-8\nLC_ALL=en_US.UTF-8" > /etc/locale.conf \
	&& locale-gen en_US.UTF-8 \
	&& echo "146\n3\n" | dpkg-reconfigure locales

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LC_ALL en_US.UTF-8

WORKDIR /crawl/crawl-ref/source
VOLUME /crawl
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]

#USER crawluser
CMD ["python", "./webserver/server.py"]
