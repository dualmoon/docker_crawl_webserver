FROM debian:buster

# add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
RUN groupadd -r -g 1000 crawl && useradd -r -m -g crawl -u 1000 crawl

# install required packages
RUN apt-get update \
	&& apt-get install --no-install-recommends --no-install-suggests -y \
    ca-certificates locales wget git

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8 \
    LANGUAGE en_US:en \
    LC_ALL en_US.UTF-8

# clone from github latest crawl version
RUN git clone https://github.com/crawl/crawl.git && cd /crawl \
	&& mkdir -p /crawl/crawl-ref/source/rcs \
	&& mkdir -p /crawl/crawl-ref/source/saves

RUN apt install -y \
		build-essential \
		libncursesw5 \
		libncursesw5-dev \
		bison \
		flex \
		liblua5.1-0-dev \
		libsqlite3-dev \
		libz-dev \
		pkg-config \
		python3-yaml \
		binutils-gold \
		libsdl2-image-dev \
		libsdl2-mixer-dev \
		libsdl2-dev \
		libfreetype6-dev \
		libpng-dev \
		ttf-dejavu-core \
		advancecomp \
		pngcrush \
		python3-pip

RUN set -eux; \
	apt install -y gosu; \
	rm -rf /var/lib/apt/lists/*; \
# verify that the binary works
	gosu nobody true

# install dependencies
RUN cd /crawl && git submodule update --init

RUN pip3 install 'tornado<4.0'

# make webtile version
RUN cd /crawl/crawl-ref/source && make WEBTILES=y

COPY docker-entrypoint.sh /entrypoint.sh
RUN chown -R crawl:crawl /entrypoint.sh \
	&& chmod 777 /entrypoint.sh \
	&& chown -R crawl:crawl /crawl

WORKDIR /crawl/crawl-ref/source
VOLUME /crawl
VOLUME /crawl/crawl-ref/source/saves
EXPOSE 8080
ENTRYPOINT ["/entrypoint.sh"]

CMD ["python3", "./webserver/server.py"]
