## Speedtest Tracker Docker

WIP to build my own image again. This image is build off https://serversideup.net/open-source/docker-php/.

### Using

This image is designed to work as a contained service and separates out the task scheduler and queue worker to separate containers.

```yaml
services:
    php:
        image: speedtest-tracker-docker:latest
        ports:
            - 80:8080
        networks:
            - speedtest
        environment:
            - APP_KEY=
            - APP_URL=http://localhost
            - DB_CONNECTION= # use: mariadb, mysql or pgsql
            - DB_HOST=db
            - DB_PORT= # use: 3306 for mariadb and mysql,
            - DB_DATABASE=
            - DB_USERNAME=
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

    # Add your database here

networks:
    speedtest:
        driver: bridge
volumes:
    db:
        driver: local
```

#### Chose a database

```yaml
#mariadb
db:
    image: 'mariadb:11'
    ports:
        - '${FORWARD_DB_PORT:-3306}:3306'
    environment:
        MYSQL_ROOT_PASSWORD: '${DB_PASSWORD}'
        MYSQL_ROOT_HOST: '%'
        MYSQL_DATABASE: '${DB_DATABASE}'
        MYSQL_USER: '${DB_USERNAME}'
        MYSQL_PASSWORD: '${DB_PASSWORD}'
        MYSQL_ALLOW_EMPTY_PASSWORD: 'yes'
    volumes:
        - 'db:/var/lib/mysql'
    networks:
        - sail
    healthcheck:
        test:
            - CMD
            - healthcheck.sh
            - '--connect'
            - '--innodb_initialized'
        retries: 3
        timeout: 5s

# mysql
db:
    image: 'mysql/mysql-server:8.0'
    ports:
        - '${FORWARD_DB_PORT:-3306}:3306'
    environment:
        MYSQL_ROOT_PASSWORD: '${DB_PASSWORD}'
        MYSQL_ROOT_HOST: '%'
        MYSQL_DATABASE: '${DB_DATABASE}'
        MYSQL_USER: '${DB_USERNAME}'
        MYSQL_PASSWORD: '${DB_PASSWORD}'
        MYSQL_ALLOW_EMPTY_PASSWORD: 1
    volumes:
        - 'db:/var/lib/mysql'
    networks:
        - speedtest
    healthcheck:
        test:
            - CMD
            - mysqladmin
            - ping
            - '-p${DB_PASSWORD}'
        retries: 3
        timeout: 5s
# postgres
db:
    image: 'postgres:17'
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
```

### Build

Use the `build` script to build the version you want to use. Use either a tagged version like `v0.24.0` or `latest`, if you don't specify a tag it will pull the main branch.

```bash
# Build with current main branch
./build.sh

# Build latest release
./build.sh latest

# Build a specific release
./build.sh v1.2.3
```
