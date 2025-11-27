#############################
# Base image
#############################
FROM serversideup/php:8.5-fpm-nginx-alpine AS base

LABEL org.opencontainers.image.title="speedtest-tracker-docker" \
    org.opencontainers.image.authors="Alex Justesen (@alexjustesen)"

ARG CLI_VERSION="1.2.0" \
    RELEASE_TAG="latest"

ENV AUTORUN_ENABLED="true" \
    AUTORUN_LARAVEL_MIGRATION="true" \
    AUTORUN_LARAVEL_MIGRATION_ISOLATION="true" \
    PHP_OPCACHE_ENABLE="1" \
    SHOW_WELCOME_MESSAGE="false"

# Switch to root so we can do root things
USER root

# Install Speedtest CLI
RUN curl -o \
        /tmp/speedtest-cli.tgz -L \
        "https://install.speedtest.net/app/cli/ookla-speedtest-${CLI_VERSION}-linux-x86_64.tgz" && \
    tar xzf \
        /tmp/speedtest-cli.tgz -C \
        /usr/bin

# Install the intl extension with root permissions
RUN install-php-extensions gd intl

# Drop back to our unprivileged user
USER www-data

# Set working directory
WORKDIR /var/www/html

# Fetch the appropriate release
RUN set -e; \
    if [ "${RELEASE_TAG}" = "current" ]; then \
        wget https://github.com/alexjustesen/speedtest-tracker/archive/refs/heads/main.tar.gz \
        && tar -xzvf main.tar.gz --strip-components=1 \
        && rm main.tar.gz; \
    elif [ "${RELEASE_TAG}" = "latest" ]; then \
        LATEST_RELEASE=$(wget -q -O - https://api.github.com/repos/alexjustesen/speedtest-tracker/releases/latest | jq -r .tag_name) \
        && wget https://github.com/alexjustesen/speedtest-tracker/archive/refs/tags/${LATEST_RELEASE}.tar.gz \
        && tar -xzvf ${LATEST_RELEASE}.tar.gz --strip-components=1 \
        && rm ${LATEST_RELEASE}.tar.gz; \
    else \
        wget https://github.com/alexjustesen/speedtest-tracker/archive/refs/tags/${RELEASE_TAG}.tar.gz \
        && tar -xzvf ${RELEASE_TAG}.tar.gz --strip-components=1 \
        && rm ${RELEASE_TAG}.tar.gz; \
    fi

RUN composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

#############################
# Node go brrr
#############################
FROM node:24 AS assets

WORKDIR /app

COPY --from=base /var/www/html /app

RUN npm ci && npm run build

#############################
# Production image
#############################
FROM base AS production

COPY --chown=www-data:www-data --from=assets /app/public/build /var/www/html/public/build
