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
docker build -f php-fpm7.1.Dockerfile -t 7061384/php-fpm:7.1 .
```