# Docker Nextcloud
## Features
 - use `$PUID` `$PGID` to change uid gid
 - [notify_push](https://github.com/nextcloud/notify_push) auto install and configured
 - ffmpeg and VA-API driver installed (for [memories](https://github.com/pulsejet/memories))

## Versions
 - nextcloud: 32
 - supercronic: 0.2.41

## How to install
### Copy example files
```shell
cp ./example/.env ./
cp ./example/docker-compose.yml ./
```
### Configure environment variable
 - `TZ` Timezone
 - `PUID` uid to run in container
 - `PGID` gid to run in container
 - `POSTGRES_PASSWORD` postgresql password
 - `NEXTCLOUD_ADMIN_PASSWORD` initial  nextcloud password
 - `OVERWRITEHOST` your host name

For other environment variables, please refer to [nextcloud/docker](https://github.com/nextcloud/docker).

Hint: you can generate password by 
```shell
openssl rand -base64 24
```

### Configure docker-compose.yml
```yml
app:
  restart: unless-stopped
  # Uncomment to enable dri device (VA-API)
  # devices:
  #   - /dev/dri:/dev/dri
  volumes:
    - html:/var/www/html
    # - /somewhere/my/data/store:/var/www/html/data
    
```

### Run
```shell
docker compose up -d
```
