# docker-php-fpm

[alibaba mirror](https://opsx.alibaba.com/mirror)

[base on the offical docker image](https://docs.docker.com/samples/library/php/)

## pull image

latest image

```
docker pull 7061384/php-fpm
```

other version image

```
docker pull 7061384/php-fpm:7.1
```

## bulid image

latest php version(default: Dockerfile)

```
docker build -t 7061384/php-fpm .
```

other php version

```
docker build --no-cache -f php-fpm7.1.Dockerfile -t 7061384/php-fpm:7.1 .
```

run image

```
docker run -it --rm 7061384/php-fpm:7.3 bash
``` 

## configuration

https://docs.docker.com/samples/library/php/#configuration

```
FROM php:7.2-fpm-alpine

# Use the default production configuration
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Override with custom opcache settings
COPY config/opcache.ini $PHP_INI_DIR/conf.d/
```

