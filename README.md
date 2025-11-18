# 🐋 Speedtest Tracker Docker

> [!INFO]
> **Work in Progress** - This is a custom Docker image build based on [ServerSideUp's Docker PHP](https://serversideup.net/open-source/docker-php/).
>
> This image separates the application into multiple services:
> - **Main App** (PHP/Web server)
> - **Task Scheduler** (Cron jobs)
> - **Queue Worker** (Background jobs)

### Using

This image is designed to work as a service and separates the app from the task scheduler and queue worker into separate service containers.

```yaml
# compose.yml
services:
    php:
        image: speedtest-tracker-docker:latest
        ports:
            - 80:8080
            # - 443:8443
        networks:
            - speedtest
        environment:
            - APP_KEY=
            - APP_URL=http://localhost
            - DB_CONNECTION=pgsql
            - DB_HOST=db
            - DB_PORT=5432
            - DB_DATABASE=speedtest
            - DB_USERNAME=speedtest
            - DB_PASSWORD=
        depends_on:
            - db
            - task
            - queue

    task:
        image: speedtest-tracker-docker:latest
        command: ["php", "/var/www/html/artisan", "schedule:work"]
        stop_signal: SIGTERM # Set this for graceful shutdown if you're using fpm-apache or fpm-nginx
        healthcheck:
            test: ["CMD", "healthcheck-schedule"]
            start_period: 10s
        networks:
            - speedtest

    queue:
        image: speedtest-tracker-docker:latest
        command: ["php", "/var/www/html/artisan", "queue:work", "--tries=3"]
        stop_signal: SIGTERM # Set this for graceful shutdown if you're using fpm-apache or fpm-nginx
        healthcheck:
            test: ["CMD", "healthcheck-queue"]
            start_period: 10s
        networks:
            - speedtest

    db:
        image: 'postgres:18-alpine'
        ports:
            - '${FORWARD_DB_PORT:-5432}:5432'
        environment:
            PGPASSWORD: '${DB_PASSWORD:-secret}'
            POSTGRES_DB: '${DB_DATABASE}'
            POSTGRES_USER: '${DB_USERNAME}'
            POSTGRES_PASSWORD: '${DB_PASSWORD:-secret}'
        volumes:
            - 'db:/var/lib/postgresql/data'
        networks:
            - speedtest
        healthcheck:
            test:
                - CMD
                - pg_isready
                - '-q'
                - '-d'
                - '${DB_DATABASE}'
                - '-U'
                - '${DB_USERNAME}'
            retries: 3
            timeout: 5s

networks:
    speedtest:
        driver: bridge
volumes:
    db:
        driver: local
```

### Build

Use the `build` script to build the version you want to use. Use either a tagged version like `v1.0.0` or `latest`, if you don't specify a tag it will pull the main branch.

```bash
# Build with current main branch
./build.sh

# Build latest release
./build.sh latest

# Build a specific release
./build.sh v1.2.3
```
