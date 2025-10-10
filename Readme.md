# docker-nextcloud
## Features
 - use `$PUID` `$PGID` to change uid gid
 - [notify_push](https://github.com/nextcloud/notify_push) bundled and auto-configured
 - ffmpeg and VA-API driver installed (for [memories](https://github.com/pulsejet/memories))
 - pdlib with AVX2 enabled installed (for [facerecognition](https://github.com/matiasdelellis/facerecognition))

## Versions
 - nextcloud: 31
 - dlib: 20.0
 - pdlib: 1.1.0
 - notify_push: 1.2.0

## How to install
### Build image
```shell
git clone https://github.com/william920429/docker-nextcloud
cp compose.yaml.example compose.yaml
docker-compose build app
```
### Configure environment variable
1. `cp .env.example .env`
2. change the following environment variables

 - `TZ` Timezone
 - `PUID` uid to run in container
 - `PGID` gid to run in container
 - `POSTGRES_PASSWORD` postgresql password
 - `NEXTCLOUD_ADMIN_PASSWORD` initial  nextcloud password
 - `OVERWRITEHOST` your host name

For other environment variables, please refer to [nextcloud/docker](https://github.com/nextcloud/docker).

Hint: you can generate password by 
 `tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 32`

### Configure compose.yaml
```yaml
app:
  restart: unless-stopped
  # Uncomment the following to enable dri device (VA-API)
  # devices:
  #   - /dev/dri:/dev/dri
```

### Run
```shell
mkdir -p --mode 777 \
    volumes/nextcloud_data \
    volumes/nextcloud_html \
    volumes/postgres_data \
    volumes/redis_data
docker-compose up -d
```
