FROM php:8.2.11-apache

ARG DOWNLOAD_URL
ARG FOLDER

ENV DIR_OPENCART='/var/www/html/'
ENV DIR_STORAGE=${DIR_OPENCART}'system/storage/'
ENV DIR_CACHE=${DIR_STORAGE}'cache/'
ENV DIR_DOWNLOAD=${DIR_STORAGE}'download/'
ENV DIR_LOGS=${DIR_STORAGE}'logs/'
ENV DIR_SESSION=${DIR_STORAGE}'session/'
ENV DIR_UPLOAD=${DIR_STORAGE}'upload/'
ENV DIR_IMAGE=${DIR_OPENCART}'image/'
ENV DB_PASSWORD=demo
ENV DB_USERNAME=demo

RUN apt-get clean && apt-get update && apt-get upgrade -y \
    && apt-get install -y \
                       wait-for-it \
                       unzip \
                       libfreetype6-dev \
                       libjpeg62-turbo-dev \
                       libpng-dev \
                       libzip-dev \
                       libcurl3-dev \
                       libwebp-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) gd zip mysqli curl \
    && docker-php-ext-enable gd zip mysqli curl

RUN mkdir /storage && mkdir /opencart

RUN if [ -z "$DOWNLOAD_URL" ]; then \
  curl -Lo /tmp/opencart.zip $(sh -c 'curl -s https://api.github.com/repos/opencart/opencart/releases/latest | grep "browser_download_url" | cut -d : -f 2,3 | tr -d \"'); \
  else \
  curl -Lo /tmp/opencart.zip ${DOWNLOAD_URL}; \
  fi

RUN unzip /tmp/opencart.zip -d  /tmp/opencart;

RUN mv /tmp/opencart/$(if [ -n "$FOLDER" ]; then echo $FOLDER; else  unzip -l /tmp/opencart.zip | awk '{print $4}' | grep -E 'opencart-[a-z0-9.]+/upload/$'; fi)* ${DIR_OPENCART};

RUN rm -rf /tmp/opencart.zip && rm -rf /tmp/opencart;

RUN cp ${DIR_OPENCART}config-dist.php ${DIR_OPENCART}config.php \
    && cp ${DIR_OPENCART}admin/config-dist.php ${DIR_OPENCART}admin/config.php

RUN a2enmod rewrite
RUN chown -R www-data:www-data ${DIR_OPENCART}
RUN chmod -R 755 ${DIR_OPENCART}

CMD ["apache2-foreground"]
