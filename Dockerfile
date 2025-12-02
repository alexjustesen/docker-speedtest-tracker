#############################
# Base image
#############################
FROM serversideup/php:8.4-fpm-nginx-alpine-v4.2.1 AS base

LABEL org.opencontainers.image.title="speedtest-tracker-docker" \
    org.opencontainers.image.authors="Alex Justesen (@alexjustesen)"

ARG LIBRESPEED_CLI_VERSION="1.0.12" \
    OOKLA_CLI_VERSION="1.2.0" \
    RELEASE_TAG="latest"

ENV AUTORUN_ENABLED="true" \
    AUTORUN_LARAVEL_MIGRATION="true" \
    AUTORUN_LARAVEL_MIGRATION_ISOLATION="true" \
    PHP_MEMORY_LIMIT="512M" \
    PHP_OPCACHE_ENABLE="1" \
    SHOW_WELCOME_MESSAGE="false"

# Switch to root so we can do root things
USER root

# Install system dependencies and clean up in the same layer
RUN apk add --no-cache jq iperf3 \
    && rm -rf /var/cache/apk/*

# Install CLI tools in a single layer
RUN curl -o /tmp/librespeed-cli.tgz -L \
        "https://github.com/librespeed/speedtest-cli/releases/download/v${LIBRESPEED_CLI_VERSION}/librespeed-cli_${LIBRESPEED_CLI_VERSION}_linux_amd64.tar.gz" \
    && curl -o /tmp/speedtest-cli.tgz -L \
        "https://install.speedtest.net/app/cli/ookla-speedtest-${OOKLA_CLI_VERSION}-linux-x86_64.tgz" \
    && tar xzf /tmp/librespeed-cli.tgz -C /usr/bin \
    && tar xzf /tmp/speedtest-cli.tgz -C /usr/bin \
    && rm /tmp/librespeed-cli.tgz /tmp/speedtest-cli.tgz

# Install the intl extension with root permissions
RUN install-php-extensions intl \
    && rm -rf /tmp/*

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

RUN --mount=type=cache,target=/tmp/cache \
    COMPOSER_CACHE_DIR=/tmp/cache composer install --no-interaction --prefer-dist --optimize-autoloader --no-dev

#############################
# Node go brrr
#############################
FROM node:24-alpine AS assets

WORKDIR /app

COPY --from=base /var/www/html /app

RUN --mount=type=cache,target=/root/.npm \
    npm ci && npm run build

#############################
# Production image
#############################
FROM base AS production

COPY --chown=www-data:www-data --from=assets /app/public/build /var/www/html/public/build
