FROM php:7.3-fpm

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
    && mkdir -p /usr/share/man/man1 \
    && mkdir -p /usr/share/man/man7 \
    && apt-get install -y --no-install-recommends --fix-missing\
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
        libssl-dev \
        libnghttp2-dev \
        libjpeg-dev \
        libpng-dev \
        libpq-dev \
	    libzip-dev \
        postgresql-client \
        wkhtmltopdf

###########################################################################
# php ext
###########################################################################

RUN docker-php-ext-install pdo \
        pdo_mysql \
        mbstring \
        zip \
        pcntl \
        opcache \
        pgsql \
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
