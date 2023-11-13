FROM php:8.2-fpm

MAINTAINER j0nnybrav079

# used to setup xdebug remote-ip
ARG remoteIp

# set timezone
RUN echo "UTC" > /etc/timezone

# install composer
ENV COMPOSER_HOME /composer
ENV PATH ./vendor/bin:/composer/vendor/bin:$PATH
ENV COMPOSER_ALLOW_SUPERUSER 1
RUN curl -s https://getcomposer.org/installer | php --install-dir=/usr/local/bin/ --filename=composer

# Install system dependencies
RUN apt-get update && apt-get install -y \
    bash \
    curl \
    git \
    gnupg2 \
    apt-transport-https \
    unixodbc-dev \
    git \
    openssh-client \
    unzip \
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
    libmagickwand-6.q16-dev \
    libssl-dev \
    libxml2-dev \
    openssh-client

# symfony cli
RUN curl -sS https://get.symfony.com/cli/installer | bash && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

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
        phar \
        pgsql \
        session \
        sockets \
        soap \
        gd \
        sockets \
        soap \
    && docker-php-ext-enable  \
      opcache sqlsrv pdo_sqlsrv

# install Xdebug
RUN apt-get update \
    && pecl install xdebug\
        && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_enable=on" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_autostart=off" >> /usr/local/etc/php/conf.d/xdebug.ini \
        && echo "xdebug.remote_host=$remoteIp" >> /usr/local/etc/php/conf.d/xdebug.ini

# blackfire PHP Probe
RUN version=$(php -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && architecture=$(case $(uname -m) in i386 | i686 | x86) echo "i386" ;; x86_64 | amd64) echo "amd64" ;; aarch64 | arm64 | armv8) echo "arm64" ;; *) echo "amd64" ;; esac) \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/linux/$architecture/$version \
    && mkdir -p /tmp/blackfire \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp/blackfire \
    && mv /tmp/blackfire/blackfire-*.so $(php -r "echo ini_get ('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > $PHP_INI_DIR/conf.d/blackfire.ini \
    && rm -rf /tmp/blackfire /tmp/blackfire-probe.tar.gz

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/*
