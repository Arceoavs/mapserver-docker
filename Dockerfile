FROM debian:jessie
MAINTAINER Ian Blenke "ian@blenke.com"

# Inspired by
#  - https://hub.docker.com/r/nopz/mapserver/
#  - https://github.com/srounet/docker-mapserver

RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y \
    ca-certificates \
    build-essential cmake curl libcurl4-gnutls-dev libssl-dev openssl wget \
    shapelib libproj-dev libproj0 proj-data libgeos-3.4.2 libgeos-c1 libgeos-dev \
    libxml2-dev libpng-dev zlib1g-dev libtiff5 libjpeg-dev libtiff-dev postgis libpq-dev \
    libfcgi-dev libfribidi-dev libfreetype6-dev libharfbuzz-dev \
    make \
    nginx \
    supervisor \
    -y --no-install-recommends && rm -rf /var/lib/apt/lists/*

ARG GDAL_VERSION=2.3.1
ENV GDAL_VERSION=${GDAL_VERSION}

RUN curl -sL http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz | tar zxv -C /tmp \
 && cd /tmp/gdal-${GDAL_VERSION} \
 && ./configure \
    --prefix=/usr \
    --with-threads \
    --with-hide-internal-symbols=yes \
    --with-rename-internal-libtiff-symbols=yes \
    --with-rename-internal-libgeotiff-symbols=yes \
    --with-libtiff=internal \
    --with-geotiff=internal \
    --with-geos \
    --with-pg \
    --with-curl \
    --with-static-proj4=yes \
    --with-ecw=no \
    --with-grass=no \
    --with-hdf5=no \
    --with-java=no \
    --with-mrsid=no \
    --with-perl=no \
    --with-python=no \
    --with-webp=no \
    --with-xerces=no \
 && make -j $(nproc) \
 && make install \
 && cd .. \
 && rm -fr /tmp/gdal-${GDAL_VERSION}

ARG MAPSERVER_VERSION=7.2.0
ENV MAPSERVER_VERSION=${MAPSERVER_VERSION}

RUN curl -sL http://download.osgeo.org/mapserver/mapserver-${MAPSERVER_VERSION}.tar.gz | tar zxv -C /tmp \
 && mkdir -p /tmp/mapserver-${MAPSERVER_VERSION}/build \
 && cd /tmp/mapserver-${MAPSERVER_VERSION}/build \
 && cmake .. -DWITH_GDAL=1 -DWITH_CURL=1 -DWITH_CAIRO=0 -DWITH_GIF=0 -DWITH_PROTOBUFC=0 \
 && make -j $(nproc) \
 && make install \
 && cd .. \
 && rm -fr /tmp/mapserver-${MAPSERVER_VERSION}/build

RUN rm /etc/nginx/sites-enabled/default
ADD etc /etc

RUN mkdir -p /usr/src
COPY mapfiles /usr/src/mapfiles

EXPOSE 80
CMD /usr/bin/supervisord
