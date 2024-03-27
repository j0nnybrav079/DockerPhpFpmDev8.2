FROM php:8.2-fpm

MAINTAINER j0nnybrav079

# used to setup xdebug remote-ip
ARG remoteIp

# set timezone
RUN echo "UTC" > /etc/timezone
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

#set locale

# install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# Install system dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    bash \
    curl \
    git \
    g++ \
    ghostscript \
    gnupg2 \
    apt-transport-https \
    unixodbc-dev \
    git \
    openssh-client \
    unzip \
    locales \
    libwebp-dev \
    libmemcached-dev \
    libmcrypt-dev \
    libonig-dev \
    libpq-dev \
    libzip-dev \
    libicu-dev \
    libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    imagemagick \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    openssh-client \
    nodejs \
    npm \
    wget \
    zlib1g-dev \
    libzip-dev \
    lsb-release \
    ca-certificates

# symfony cli
RUN curl -sS https://get.symfony.com/cli/installer | bash && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

# yarn
RUN npm install --global yarn

# install Xdebug
RUN apt-get update \
    && pecl install xdebug\
        && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_host=$remoteIp" >> /usr/local/etc/php/conf.d/xdebug.ini

# php misc
RUN docker-php-ext-configure \
        gd \
            --prefix=/usr \
            --with-jpeg \
            --with-freetype \
            --with-webp \
    && docker-php-ext-install \
        bcmath \
        calendar \
        dom \
        iconv \
        intl \
        mbstring \
        opcache \
        pdo \
        pdo_pgsql \
        pdo_mysql \
        mysqli \
        phar \
        pgsql \
        session \
        sockets \
        soap \
        gd \
        sockets \
        soap \
        zip \
    && docker-php-ext-enable  \
      opcache xdebug

# imagick
RUN apt-get update && apt-get install -y \
    libmagickwand-dev --no-install-recommends \
    && pecl install imagick \
	&& docker-php-ext-enable imagick

# mssql: Add Microsoft repository GPG key
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    # Add the Microsoft SQL Server repository
    && curl https://packages.microsoft.com/config/debian/10/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    # Install the Microsoft ODBC driver for SQL Server
    && apt-get update && ACCEPT_EULA=Y apt-get install -y msodbcsql17 \
    # Install the PHP extensions
    && docker-php-ext-install pdo pdo_mysql \
    # Download the Microsoft SQL Server PHP drivers
    && pecl install sqlsrv pdo_sqlsrv
RUN docker-php-ext-enable  \
      sqlsrv pdo_sqlsrv

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
