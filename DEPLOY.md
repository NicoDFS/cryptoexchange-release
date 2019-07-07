# Depoly to Ubuntu server by Ansible

准备：

## 1. 安装Ubuntu Server 16.04

更新`apt update & apt upgrade`

## 2. 添加ubuntu用户

如果没有`ubuntu`用户，需要添加`ubuntu`用户并赋予无密码的`sudo`权限；

添加ubuntu用户：

```
# adduser ubuntu
```

添加无密码sudo权限：

```
# more /etc/sudoers
...
root	ALL=(ALL:ALL) ALL
ubuntu  ALL=(ALL) NOPASSWD: ALL
...
```

## 3. 添加key

把`ansible/crypto_rsa.pub`添加到`ubuntu`的`authorizaed_keys`，这个key是ansible部署时使用的；

## 4. 安装Node.js

（可选）安装Node.js

```
$ curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
```

## 5. 添加openresty源

使用以下命令：

```
$ wget -qO - https://openresty.org/package/pubkey.gpg | sudo apt-key add -
$ sudo apt-get install software-properties-common
$ sudo add-apt-repository -y "deb http://openresty.org/package/ubuntu $(lsb_release -sc) main"
$ sudo apt-get update
```

## 6. 安装python,redis,MySQL

手动安装python, redis and MySQL:

```
$ sudo apt-get install python redis-server mysql-server-5.7
```

MySQL口令建议配置root/password（仅测试环境）

## 7. 初始化MySQL

将sql目录上传至服务器，依次执行：

- mysql -u root -p < ex.sql
- mysql -u root -p < ui.sql
- mysql -u root -p < mg.sql
- mysql -u root -p < init-ex.sql
- mysql -u root -p < init-ui.sql
- mysql -u root -p < init-mg.sql

## 8. 创建镜像

（可选）It is highly recommended to make an image after preparement.

# 从本地部署

## 1. 准备host映射

将以下host添加至`/etc/hosts`文件，注意把IP替换为服务器IP：

```
1.2.3.4 api.highdax.com config.highdax.com manage.highdax.com mq.highdax.com notification.highdax.com sequence.highdax.com quotation.highdax.com spot-clearing.highdax.com spot-match.highdax.com static.highdax.com ui.highdax.com wss.highdax.com www.highdax.com
```

Change the IP `1.2.3.4` to your server's.

## 2. 部署RocketMQ

RocketMQ只需部署一次：

```
$ ansible/deploy.py --profile native mq
```

部署后，第一次需要登录服务器，手动启动RocketMQ：`sudo supervisorctl reload`

检查RocketMQ是否在运行：

```
$ sudo supervisorctl status
mq:mq-broker                     RUNNING   pid 10447, uptime 0:04:42
mq:mq-console                    RUNNING   pid 10446, uptime 0:04:42
mq:mq-namesrv                    RUNNING   pid 10445, uptime 0:04:42
```

## 3. 初始化MQ队列

把`script/init-mq.sh`上传至服务器的`/src/rocketmq`目录，登录至服务器，执行`sh /srv/rocketmq/init-mq.sh`

```
$ sh /srv/rocketmq/init-mq.sh
init rocketmq topics...
create topic to 172.16.1.72:10911 success.
set cluster ... create topic to 172.16.1.72:10911 success.
set cluster ... create topic to 172.16.1.72:10911 success.
set cluster ... create topic to 172.16.1.72:10911 success.
set cluster ... create topic to 172.16.1.72:10911 success.
set cluster ... create topic to 172.16.1.72:10911 success.
ok
```

此过程只需部署一次。

## 4. 部署Gateway（OpenResty）

Deploy gateway:

```
$ ansible/deploy.py --profile native www
```

## 5. 部署config-server

Deploy config server:

```
$ ansible/deploy.py --profile native config
```

## 6. 部署其他jar

Deploy all other apps for exchange:

```
$ ansible/deploy.py --profile native api manage notification sequence quotation clearing spot-clearing spot-match ui
```

检查supervisor正在运行的所有服务：

```
$ sudo supervisorctl status
api                              RUNNING   pid 21584, uptime 0:02:28
config                           RUNNING   pid 18021, uptime 0:07:23
manage                           RUNNING   pid 21970, uptime 0:02:04
mq:mq-broker                     RUNNING   pid 10447, uptime 0:22:16
mq:mq-console                    RUNNING   pid 10446, uptime 0:22:16
mq:mq-namesrv                    RUNNING   pid 10445, uptime 0:22:16
notification                     RUNNING   pid 19880, uptime 0:04:29
quotation                        RUNNING   pid 21480, uptime 0:02:40
sequence                         RUNNING   pid 20598, uptime 0:03:35
spot-clearing                    RUNNING   pid 22286, uptime 0:01:50
spot-match                       RUNNING   pid 22866, uptime 0:01:03
ui                               RUNNING   pid 23431, uptime 0:00:13
```

# Access HighDAX

Visit: [https://www.highdax.com](https://www.highdax.com)

Login: bot0@example.com ~ bot99@example.com
Password: password

# Access Management

Visit: [https://manage.highdax.com](https://manage.highdax.com)

Login: root@example.com
Password: password

