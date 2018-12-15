# Linux Runtime Environment

## General

All apps and mq are run as user `www-data`, daemonized by `supervisor`. Please check supervisor configuration `/etc/supervisor/conf.d`.

## How settings are passed to application?

1. Application started by supervisor, and environments are passed which defined in supervisor configuration `/etc/supervisor/conf.d`.

2. Application tries to fetch configuration from config server by URL `http://config-server-ip:8888/<app-name>/<profile>`.

3. Application reads the settings, and replace the value by environment if present.

Example: get a setting `crypto.settings.name: ${EXCHANGE_NAME:HighDAX}` will return:

  - `HighDAX` if no environment variable `EXCHANGE_NAME` found;

  - or environment variable `EXCHANGE_NAME` value like `SuperDAX`.

## Where logs stores?

1. Application started with environment variable `PROFILES=native` (default to `native` if not set);

2. Logs are wrotten by `slf4j`:

   - If profile is `native`, all logs are output to console, which was redirect to `/var/log/supervisor/<app>.log` by supervisor;

   - If profile is not `native`, all logs are output to directory `/var/log/crypto/<app>.log`. Rolling support is built-in.

3. Please make sure the log directory exists and owner is `www-data`.

## Where snapshot data stores?

1. The `spot-match` application will dump snapshot data periodically at `/data/spot-match-snapshot`.

2. If multiple spot-match applications are running, the directory `/data/spot-match-snapshot` MUST be shared between these spot-match applications. e.g. mount `/data` to NFS.

NOTE: DO NOT mount `/data/spot-match-snapshot` to NFS. Instead, mount `/data` to NFS and create directory `spot-match-snapshot`, and spot-match will fail to start if NFS fails.

3. Make sure the user `www-data` can read and write to directory `/data/spot-match-snapshot`.

AWS supports EFS which is highly recommended to use.

## Where RocketMQ data stores?

1. RocketMQ has two processes: `namesrv` and `broker`, which are managed by supervisor.

2. RocketMQ stores data at `/data/rocketmq`. This directory must be writable by user `www-data`.

## How reverse proxy works?

1. The reverse proxy is `openresty`, which is a pre-compiled nginx with Lua support.

2. HighDAX uses openresty for API rate limit by Lua script.

There are 4 domains:

  - www.xxx: access UI;
  - api.xxx: access API;
  - manage.xxx: access management;
  - static.xxx: access static resource.

If there is no ELB:

    UI:     end user -> https -> openresty:ui:443:8000     -> http -> ui:8000
    API:    end user -> https -> openresty:api:443:8001    -> http -> api:8001
    Manage: end user -> https -> openresty:manage:443:8008 -> http -> manage:8008
    Static: end user -> https -> openresty:static:443      -> dir:/srv/cryptoexchange/www

If ELB is configured:

    UI:     end user -> https -> ELB -> http -> openresty:ui:80:8000     -> http -> ui:8000
    API:    end user -> https -> ELB -> http -> openresty:api:80:8001    -> http -> api:8001
    Manage: end user -> https -> ELB -> http -> openresty:manage:80:8008 -> http -> manage:8008
    Static: end user -> https -> ELB -> http -> openresty:static:80      -> dir:/srv/cryptoexchange/www
