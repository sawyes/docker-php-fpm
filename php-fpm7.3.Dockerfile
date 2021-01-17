FROM php:7.3-fpm

LABEL maintainer="peter <7061384@126.com>"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get -y install \
        gnupg2 && \
    apt-key update && \
    apt-get update

###########################################################################
# lib
###########################################################################
# apt-get install --assume-yes apt-utils
RUN apt-get install -y --no-install-recommends --fix-missing\
        g++ \
        imagemagick \
        libcurl3-dev \
        libicu-dev \
        cron \
        rsync \
        openssh-client \
        vim \
        curl \
        libmemcached-dev \
        wget \
        git \
        zip \
        libz-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        libnghttp2-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
	    libzip-dev \
        default-mysql-client \
        nano \
        unzip \
        postgresql-client \
        wkhtmltopdf \
        libxml2 \
        zlib1g-dev

###########################################################################
# php ext
###########################################################################

RUN docker-php-ext-install pdo \
        pdo_mysql \
        mbstring \
        exif \
        zip \
        pcntl \
        opcache \
        pdo_pgsql \
        curl \
        intl \
        bcmath

# gd extension
# https://docs.docker.com/samples/library/php/#php-core-extensions
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
    && docker-php-ext-install -j$(nproc) iconv \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

###########################################################################
# composer
###########################################################################

RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer &&\
    composer config -g repo.packagist composer https://packagist.laravel-china.org


###########################################################################
# Swoole:
###########################################################################

# RUN wget https://github.com/redis/hiredis/archive/v0.13.3.tar.gz -O hiredis.tar.gz \
#     && mkdir -p hiredis \
#     && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
#     && rm hiredis.tar.gz \
#     && ( \
#         cd hiredis \
#         && make -j$(nproc) \
#         && make install \
#         && ldconfig \
#     ) \
#     && rm -r hiredis

# RUN wget https://github.com/swoole/swoole-src/archive/v4.0.3.tar.gz -O swoole.tar.gz \
#     && mkdir -p swoole \
#     && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
#     && rm swoole.tar.gz \
#     && ( \
#         cd swoole \
#         && phpize \
#         && ./configure --enable-async-redis --enable-mysqlnd --enable-openssl --enable-http2 \
#         && make -j$(nproc) \
#         && make install \
#     ) \
#     && rm -r swoole \
#     && docker-php-ext-enable swoole

###########################################################################
# Xdebug
# Need a PHP version >= 7.0.0
###########################################################################
RUN wget https://github.com/xdebug/xdebug/archive/2.7.2.tar.gz -O xdebug.tar.gz \
    && mkdir -p xdebug \
    && tar -xf xdebug.tar.gz -C xdebug --strip-components=1 \
    && rm xdebug.tar.gz \
    && ( \
        cd xdebug \
        && phpize \
        && ./configure --enable-xdebug \
        && make \
        && make install \
    ) \
    && rm -r xdebug \
    && docker-php-ext-enable xdebug

###########################################################################
# xlswriter
# Need a PHP version >= 7.0.0
###########################################################################
RUN pecl install xlswriter mongo \
    && docker-php-ext-enable \
            xlswrite \
            mongodb

# Clean up
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    rm /var/log/lastlog /var/log/faillog && \
    apt-get autoremove

###########################################################################
# User Aliases
###########################################################################

USER root
COPY ./aliases.sh /root/aliases.sh
RUN sed -i 's/\r//' /root/aliases.sh && \
    echo "" >> ~/.bashrc && \
    echo "# Load Custom Aliases" >> ~/.bashrc && \
    echo "source ~/aliases.sh" >> ~/.bashrc && \
	echo "" >> ~/.bashrc

RUN rm -fr /var/www/html

WORKDIR /var/www

CMD ["php-fpm"]

EXPOSE 9000
