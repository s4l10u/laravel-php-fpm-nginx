FROM php:7.3-fpm-alpine

WORKDIR /var/www/html

# Essentials
RUN echo "UTC" > /etc/timezone

RUN apk add --update --no-cache \
    zip \
    unzip \
    curl  \
    sqlite \
    mariadb-client \
    jpegoptim \
    pngquant \
    optipng \
    supervisor \
    vim \
    icu-dev \
    freetype-dev \
    nodejs \
    npm \
    redis \
    nginx \
    mysql-client



RUN apk add --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing gnu-libiconv
ENV LD_PRELOAD /usr/lib/preloadable_libiconv.so php

# Installing bash
RUN apk add bash
RUN sed -i 's/bin\/ash/bin\/bash/g' /etc/passwd

# Installing PHP  dependencies

RUN apk add --no-cache php \
    php-common \
    php-pdo \
    php-opcache \
    php-zip \
    php-phar \
    php-iconv \
    php-cli \
    php-curl \
    php-openssl \
    php-mbstring \
    php-tokenizer \
    php-fileinfo \
    php-json \
    php-xml \
    php-xmlwriter \
    php-simplexml \
    php-dom \
    php-tokenizer \
    php7-pecl-redis \
    php-bz2 \
    php-exif \
    php-intl \
    php-bcmath \
    php-opcache \
    php-calendar \
    php-zip

RUN docker-php-ext-install pdo_mysql

# Install and configure gd

RUN apk add --no-cache freetype libpng libjpeg-turbo freetype-dev libpng-dev libjpeg-turbo-dev libwebp-dev zlib-dev libxpm-dev && \
docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd 

#docker-php-ext-configure gd --with-freetype-dir=/usr --with-jpeg-dir=/usr --with-png-dir=/usr

# Installing composer
RUN curl -sS https://getcomposer.org/installer -o composer-setup.php
RUN php composer-setup.php --install-dir=/usr/local/bin --filename=composer
RUN rm -rf composer-setup.php

### configuer Nginx
RUN adduser -D -g 'www' www
RUN mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.orig
ADD .nginx/nginx.conf /etc/nginx/
RUN chown -R www:www /var/lib/nginx

# Cron job
RUN echo '*  *  *  *  * /usr/local/bin/php  /var/www/artisan schedule:run >> /dev/null 2>&1' > /etc/crontabs/root && mkdir -p /etc/supervisor.d
#  Add supervisor configuation file
ADD .supervisor/master.ini /etc/supervisor.d/
ADD ./init.sh /var/www/html/
RUN chmod 600 /var/spool/cron/crontabs/root
### install laravel-echo server
RUN npm install  -g pm2  && npm install -g laravel-echo-server

EXPOSE 80 443

CMD ["/usr/bin/supervisord"]