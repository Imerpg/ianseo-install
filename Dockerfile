FROM php:8.5-apache

ARG IANSEO_VERSION
ENV IANSEO_VERSION=$IANSEO_VERSION

# Dépendances système et client MySQL
RUN apt-get update && apt-get install -y \
    unzip \
    curl \
    dos2unix \
    default-mysql-client \
    libicu-dev \
    libmagickwand-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    libonig-dev \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Extensions PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) intl gd mysqli pdo_mysql zip gettext

RUN pecl install imagick && docker-php-ext-enable imagick

# Configuration Apache & Entrypoint
COPY web/ianseo.conf /etc/apache2/conf-available/
COPY web/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN dos2unix /usr/local/bin/entrypoint.sh && chmod +x /usr/local/bin/entrypoint.sh
RUN a2enconf -q ianseo

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]