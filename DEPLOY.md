# Depoly to Ubuntu server by Ansible

## Preparement

1. Install Ubuntu server 16.04;

2. Make sure user `ubuntu` has sudo privilege without password;

3. add key `ansible/crypto_rsa.pub` to user `ubuntu`;

4. Update and upgrade by:

```
$ sudo apt-get update
$ sudo apt-get upgrade
```

5. Add nodejs source by:

```
$ curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
```

6. Add openresty source by:

```
$ wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
$ sudo apt-get install software-properties-common
$ sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
$ sudo apt-get update
```

7. Install python, redis and MySQL manually:

```
$ sudo apt-get install python redis-server mysql-server-5.7
```

## Make image

It is highly recommended to make an image after preparement.

## Deploy

The default hosts are `*.local.highdax.com` which is point to `127.0.0.1`, so you need add hosts into `/etc/hosts` by:

```
10.0.1.222 api.local.highdax.com config.local.highdax.com hd-cold-wallet.local.highdax.com hd-hot-wallet.local.highdax.com manage.local.highdax.com mq.local.highdax.com notification.local.highdax.com sequence.local.highdax.com quotation.local.highdax.com spot-clearing.local.highdax.com spot-match.local.highdax.com static.local.highdax.com ui.local.highdax.com wss.local.highdax.com www.local.highdax.com
```

Change the IP `10.0.1.222` to your server's.

### Deploy RocketMQ

Deploy RocketMQ only once:

    $ ansible/deploy.py --profile native mq

Start RocketMQ manually by `sudo supervisorctl reload`.

Init RocketMQ by upload `script/init-mq.sh` to `/srv/rocketmq` and run once.

### Deploy gateway

Deploy gateway:

    $ ansible/deploy.py --profile native www

### Deploy config server

Deploy config server:

    $ ansible/deploy.py --profile native config

### Deploy all other apps

Deploy all other apps for exchange:

    $ ansible/deploy.py --profile native api manage notification sequence quotation clearing spot-clearing spot-match ui
