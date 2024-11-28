## Speedtest Tracker Docker

WIP to build my own image again.

### Using

This image is designed to work as a contained service and separates out the task scheduler and queue worker to separate containers.

```docker-compose
services:
    php:
        image: speedtest-tracker-docker:latest
        ports:
            - 80:8080
            - 443:8443
        environment:
            - APP_KEY=
            - APP_URL=http://localhost
            # - DB_ // todo: add these

    task:
        image: speedtest-tracker-docker:latest
        command: ["php", "/var/www/html/artisan", "schedule:work"]
        stop_signal: SIGTERM # Set this for graceful shutdown if you're using fpm-apache or fpm-nginx
        healthcheck:
            test: ["CMD", "healthcheck-schedule"]
            start_period: 10s

    queue:
        image: speedtest-tracker-docker:latest
        command: ["php", "/var/www/html/artisan", "queue:work", "--tries=3"]
        stop_signal: SIGTERM # Set this for graceful shutdown if you're using fpm-apache or fpm-nginx
        healthcheck:
            test: ["CMD", "healthcheck-queue"]
            start_period: 10s

```

### Build Locally

```bash
# Build with current main branch
./build.sh

# Build latest release
./build.sh latest

# Build a specific release
./build.sh v1.2.3
```
