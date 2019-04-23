FROM php:7.3-fpm

LABEL maintainer="peter <7061384@126.com>"

###########################################################################
# lib
###########################################################################

RUN cp -a /etc/apt/sources.list /etc/apt/sources.list.bak && \
    echo '' > /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian-security stretch/updates main' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian-security stretch/updates main' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib' >> /etc/apt/sources.list && \
    echo 'deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib' >> /etc/apt/sources.list

RUN apt-get clean && apt-get update --fix-missing -y && apt-get upgrade -y
RUN apt-get install --assume-yes apt-utils && \
    mkdir -p /usr/share/man/man1 && \
    mkdir -p /usr/share/man/man7 && \
    apt-get install -y --no-install-recommends --fix-missing\
        cron \
        vim \
        curl \
        libmemcached-dev \
        wget \
        git \
        zip \
        libfreetype6-dev \
        libz-dev \
        libssl-dev \
        libnghttp2-dev \
        libjpeg-dev \
        libpq-dev \
	libzip-dev \
        postgresql-client \
        wkhtmltopdf

###########################################################################
# Mysqli Modifications:
###########################################################################

RUN docker-php-ext-install pdo \
        pdo_mysql \
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

# wrong install memcache

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

WORKDIR /var/www

CMD ["php-fpm"]

EXPOSE 9000
