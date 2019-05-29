FROM php:7.1-fpm

LABEL maintainer="peter <7061384@126.com>"

# Change application source from dl-cdn.alpinelinux.org to aliyun source
RUN cp /etc/apt/sources.list /etc/apt/sources.list.bak
COPY debian/9.x.stretch.source.list /etc/apt/sources.list

RUN apt-get clean \
    && apt-get update --fix-missing -y \
    && apt-get upgrade -y

###########################################################################
# lib
###########################################################################

RUN apt-get install --assume-yes apt-utils \
    && mkdir -p /usr/share/man/man1  \
    && mkdir -p /usr/share/man/man7 \
    && apt-get install -y --no-install-recommends --fix-missing \
        cron \
        rsync \
        openssh-client \
        vim \
        curl \
        libmemcached-dev \
        libmcrypt-dev \
        wget \
        git \
        zip \
        libfreetype6-dev \
        libz-dev \
        libssl-dev \
        libnghttp2-dev \
        libjpeg-dev \
        libpq-dev \
        postgresql-client \
        wkhtmltopdf

###########################################################################
# php ext
###########################################################################

RUN docker-php-ext-install pdo \
        pdo_mysql \
        mcrypt \
        mbstring \
        zip \
        gd \
        pcntl \
        opcache \
        pgsql \
        bcmath


###########################################################################
# composer
###########################################################################

RUN curl --silent --show-error https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer &&\
    composer config -g repo.packagist composer https://packagist.laravel-china.org


###########################################################################
# Swoole:
###########################################################################

RUN wget https://github.com/redis/hiredis/archive/v0.13.3.tar.gz -O hiredis.tar.gz \
    && mkdir -p hiredis \
    && tar -xf hiredis.tar.gz -C hiredis --strip-components=1 \
    && rm hiredis.tar.gz \
    && ( \
        cd hiredis \
        && make -j$(nproc) \
        && make install \
        && ldconfig \
    ) \
    && rm -r hiredis

RUN wget https://github.com/swoole/swoole-src/archive/v4.0.3.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
        cd swoole \
        && phpize \
        && ./configure --enable-async-redis --enable-mysqlnd --enable-openssl --enable-http2 \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole


###########################################################################
# PHP Memcached:
###########################################################################

RUN if [ $(php -r "echo PHP_MAJOR_VERSION;") = "5" ]; then \
      curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/2.2.0.tar.gz"; \
    else \
      curl -L -o /tmp/memcached.tar.gz "https://github.com/php-memcached-dev/php-memcached/archive/php7.tar.gz"; \
    fi \
    && mkdir -p memcached \
    && tar -C memcached -zxvf /tmp/memcached.tar.gz --strip 1 \
    && ( \
        cd memcached \
        && phpize \
        && ./configure \
        && make -j$(nproc) \
        && make install \
    ) \
    && rm -r memcached \
    && rm /tmp/memcached.tar.gz \
    && docker-php-ext-enable memcached

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