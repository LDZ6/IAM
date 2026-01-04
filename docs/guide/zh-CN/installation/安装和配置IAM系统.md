# 安装和配置IAM系统

为了能够给你提供一个随时可以操作的学习环境，同时也加深你对实战项目的理解，这一讲来教你一步步搭建起整个IAM系统，IAM系统具体实现后面会具体介绍。可以通过以下2步搭建起整个IAM系统�?1. 安装和配置数据库：需要安装和配置MariaDB、Redis、MongoDB�?2. 安装和配置IAM服务：需要安装和配置iam-apiserver、iam-authz-server、iam-pump、iamctl、man文件�?
为了方便记忆：IAM 系统所有组件密码均使用 **iam59!z$**，请拿小本本记录下来。建议严格按照本教程来安装。接下来，我会详细的展示如何安装IAM系统�?
## MariaDB安装和配�?
IAM使用关系型数据库来持久化存储系统数据，我选择了MariaDB作为后端数据库。接下来，我会教你如何安装和配置MariaDB数据库�?
### 为什么选择MariaDB

IAM会把REST资源的定义信息存储在关系型数据库种，关系型数据库我选择了MariaDB。这里你可能会问“为啥选择 MariaDB，而不�?MySQL？”。选择MariaDB一方面是因为它是发展最快的 MySQL 分支，相比MySQL，它加入了很多新的特性，并且它能够完全兼�?MySQL，包�?API 和命令行。另一方面是因�?MariaDB 是开源的，而且迭代速度很快�?
### MariaDB安装和配�?
在安装之前，需要确保服务器上安装有MariaDB，执行如下命令来检查是否安装了MariaDB�?
```bash
$ rpm -qa|grep -i mariadb-server
```

如果输出是空的，则说明没有安装MariaDB，需要手动安装。如果出�?`MariaDB-server-xxx.el8xxx.x86_64` 则说明已经安装�?
如果确认Linux服务器没有安装MariaDB，可以通过以下步骤来安装：

1. 配置MariaDB 10.5 Yum�?
执行如下命令，配置MariaDB 10.5 Yum源：

```bash
$ sudo tee /etc/yum.repos.d/mariadb-10.5.repo<<'EOF'
# MariaDB 10.5 CentOS repository list - created 2020-10-23 01:54 UTC
# http://downloads.mariadb.org/mariadb/repositories/
[mariadb]
name = MariaDB
baseurl = https://mirrors.aliyun.com/mariadb/yum/10.5/centos8-amd64/
module_hotfixes=1
gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB
gpgcheck=0
EOF
```

为了避免安装RPM包时，因为校验GPG失败，这里设置`gpgcheck=0`关闭GPG校验。为了避免被墙，选择了国内阿里的yum源�?
2. 安装MariaDB和MariaDB客户�?
```bash
$ sudo yum -y install MariaDB-server MariaDB-client
```

MariaDB-client是MariaDB的客户端安装包，MariaDB-server是MariaDB的服务器安装包�?
3. 启动MariaDB，并设置开机启�?
```bash
$ sudo systemctl enable mariadb
$ sudo systemctl start mariadb
$ sudo systemctl status mariadb # 查看mariadb运行状态，如果输出中包含active (running)字样说明mariadb成功启动�?```

4. 设置初始密码

设置root用户的密码为：iam59!z$，命令如下：

```bash
$ sudo mysqladmin -u root password 'iam59!z$'
```

## Redis安装和配�?
iam-authz-server从iam-apiserver缓存了用户的密钥和策略信息，为了保证数据的一致性，使用了Redis的发布订�?pub/sub)功能来进行消息通知，同时iam-authz-server也会将授权审计日志缓存到Redis中，所以也需要安装Redis key-value数据库。接下来，我会教你如何安装和配置Redis数据库�?
### 安装Redis

CentOS 8.x可直接执行如下命令安装Redis�?
```bash
$ sudo yum -y install redis
```

### 配置Redis

Redis配置分如下几步：

1. 修改`/etc/redis.conf`文件，将daemonize由no改成yes，表示允许redis在后台启动：

```bash
$ sudo sed -i '/^daemonize/{s/no/yes/}' /etc/redis.conf
```
2. 在`bind 127.0.0.1`前面添加 `#` 将其注释掉，默认情况下只允许本地连接，注释掉后外网可以连接Redis

```
$ sudo sed -i '/^bind.*/{s/bind/# bind/}' /etc/redis.conf
```

3. 修改requirepass配置，设置Redis密码

```
$ sudo sed -i 's/^# requirepass.*$/requirepass iam59!z$/' /etc/redis.conf
```

4. 因为我们上面配置了密码登录，需要将protected-mode设置为no，关闭保护模�?
```
$ sudo sed -i '/^protected-mode/{s/yes/no/}' /etc/redis.conf
```

5. 为了能够远程连上Redis，需要执行以下命令关闭防火墙，并禁止防火墙开机启动（如果不需要远程连接，可忽略此步骤�?
```bash
$ sudo systemctl stop firewalld.service
$ sudo systemctl disable firewalld.service
```

### 启动并登录Redis

```bash
$ sudo redis-server /etc/redis.conf
$ redis-cli -h 127.0.0.1 -p 6379 -a 'iam59!z$' # 连接 Redis�?h 指定主机�?p 指定监听端口�?a 指定登录密码
```

## MongoDB安装和配�?
iam-pump会将iam-authz-server产生的数据，处理后存储在MongoDB中，所以需要安装MongoDB数据库�?
### MongoDB安装

可以通过以下几步来安装MongoDB�?
1. 配置MongoDB yum�?
执行如下命令，配置MongoDB yum源：

```bash
$ sudo tee /etc/yum.repos.d/mongodb-org-4.4.repo<<'EOF'
[mongodb-org-4.4]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/$releasever/mongodb-org/4.4/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.4.asc
EOF
```
2. 安装最新的MongoDB�?
```bash
$ sudo yum install -y mongodb-org
```

3. 关闭SELinux

SELinux可能会阻止MongoDB访问/sys/fs/cgroup，需要关闭SELinux�?
```bash
$ sudo setenforce 0
$ sudo sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config # 永久关闭SELINUX
```

4. 开启外网访问权限和登录验证

安装完MongoDB之后，默认情况下MongoDB没有开启外网访问权限和登录验证，需要先开启这些功能，修改配置文件/etc/mongod.conf，设置`net.bindIp: 0.0.0.0`, `security.authorization: enabled`，执行如下命令：

```bash
$ sudo sed -i '/bindIp/{s/127.0.0.1/0.0.0.0/}' /etc/mongod.conf
$ sudo sed -i '/^#security/a\security:\n  authorization: enabled' /etc/mongod.conf
```

修改完后，保存�?
5. 启动MongoDB

```bash
$ sudo systemctl start mongod
$ sudo systemctl enable mongod # 设置开机启�?$ sudo systemctl status mongod # 查看mongod运行状态，如果输出中包含active (running)字样说明mongod成功启动�?```

6. 登录MongoDB Shell

```bash
$ mongo --quiet "mongodb://127.0.0.1:27017"
>
```

如果没有报错，则说明MongoDB被成功安装�?
### 配置MongoDB

安装完MongoDB之后，还需要做一些配置，才可以开始使用MongoDB。主要配置以下内容：
- 创建管理员账户�?- 创建iam用户�?
1. 创建管理员账�?
```go
$ mongo --quiet "mongodb://127.0.0.1:27017"
> use admin
switched to db admin
> db.createUser({user:"root",pwd:"iam59!z$",roles:["root"]})
Successfully added user: { "user" : "root", "roles" : [ "root" ] }
> db.auth("root", "iam59!z$")
1
```

通过`use admin`指令切换到admin数据库。通过`db.auth("用户�?�?用户密码")`验证用户登录权限，如果返�?表示验证成功，如果返�?表示验证失败。删除用户可以使用`db.dropUser("用户�?)`�?
创建用户参数说明�?- user: 用户名�?- pwd: 用户密码�?- roles: 用来设置用户的权限，比如读，读写，写等�?
2. 创建iam用户

为了安全，我们需要使用一个普通用户而非管理员用户来连接MongoDB，所以我们需要为IAM创建一个叫iam的普通用户：

```go
$ mongo --quiet mongodb://root:'iam59!z$'@127.0.0.1:27017/tyk_analytics?authSource=admin # 用管理员账户连接MongoDB
> use iam_analytics
switched to db iam_analytics
> db.createUser({user:"iam",pwd:"iam59!z$",roles:["dbOwner"]})
Successfully added user: { "user" : "iam", "roles" : [ "dbOwner" ] }
> db.auth("iam", "iam59!z$")
1
```

创建完iam普通用户后，我们就可以通过iam用户登录MongoDB�?
```bash
$ mongo --quiet mongodb://iam:'iam59!z$'@127.0.0.1:27017/iam_analytics?authSource=iam_analytics
```

官方安装文档请参考：[Install MongoDB Community Edition on Red Hat or CentOS](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-red-hat/)

至此，我们成功安装了IAM系统需要的数据库MariaDB、Redis和MongoDB。接下来，我会教你如何安装IAM应用的所有服务�?
## IAM系统安装和配�?
要完成IAM系统的安装，还需要安装和配置如下组件：iam-apiserver、iam-authz-server、iam-pump、iamctl。这些组件的功能，在 **01 | 项目介绍：本专栏教学项目 IAM 系统介绍** 都有详细介绍，这里不再介绍�?
### 准备工作

在开始安装之前，我们需要先做一些准备工作，包括如下准备�?1. 下载iam项目代码�?2. 初始化MariaDB数据库，创建iam数据库�?3. 配置scripts/install/environment.sh�?4. 创建需要的目录�?5. 创建CA根证书和秘钥�?6. 配置hosts�?
1. 下载iam项目代码

IAM的安装脚本存放在iam代码仓库中，安装需要的二进制文件也需要通过iam代码构建，所以第一步，需要下载iam代码�?
```bash
$ mkdir -p $WORKSPACE/golang/src/github.com/marmotedu
$ cd $WORKSPACE/golang/src/github.com/marmotedu
$ git clone --depth https://github.com/marmotedu/iam
```

marmotedu和marmotedu/iam目录存放了本实战项目的代码，在学习过程中，你需要频繁访问这2个目录，为了访问方便，我们可以追加如�?个环境变量和2个alias到`$HOME/.bashrc`文件中：
```bash
$ tee -a $HOME/.bashrc << 'EOF'
# Alias for quick access
export GOWORK="$WORKSPACE/golang/src"
export IAM_ROOT="$GOWORK/github.com/marmotedu/iam"
alias mm="cd $GOWORK/github.com/marmotedu"
alias i="cd $GOWORK/github.com/marmotedu/iam"
EOF
$ bash
```

后续可以通过执行alias命令`mm`访问`$GOWORK/github.com/marmotedu`目录，通过执行alias命令`i`访问`$GOWORK/github.com/marmotedu/iam`目录�?
2. 初始化MariaDB数据库，创建iam数据�?
安装完MariaDB数据库之后，需要在MariaDB数据库中创建IAM系统需要的数据库、表和存储过程，创建SQL语句保存在IAM代码仓库中的configs/iam.sql文件中，创建步骤如下�?
1) 登录数据库并创建iam用户

```bash
$ cd $IAM_ROOT
$ mysql -h127.0.0.1 -P3306 -uroot -p'iam59!z$' # 连接 MariaDB�?h 指定主机�?P 指定监听端口�?u 指定登录用户�?p 指定登录密码
MariaDB [(none)]> grant all on iam.* TO iam@127.0.0.1 identified by 'iam59!z$';
Query OK, 0 rows affected (0.000 sec)
MariaDB [(none)]> flush privileges;
Query OK, 0 rows affected (0.000 sec)
```
2) 用iam用户登录mysql，执行iam.sql文件，创建iam数据�?```bash
$ mysql -h127.0.0.1 -P3306 -uiam -p'iam59!z$'
MariaDB [(none)]> source configs/iam.sql;
MariaDB [iam]> show databases;
+--------------------+
| Database           |
+--------------------+
| iam                |
| information_schema |
+--------------------+
2 rows in set (0.000 sec)
```

可以看到已经成功创建iam数据库，创建了如下数据库资源�?- 表：
    - user：用户表，存放用户信息�?    - secret：密钥表，存放密钥信息�?    - policy：策略表，存放授权策略信息�?    - policy_audit：策略历史表，被删除的策略会被转存到该表�?- admin用户：在user表中，创建一个管理员用户，用户名：admin，密码：Admin@2021�?- 存储过程：删除用户时，会自动删除该用户所属的秘钥和策略信息�?
至此我们已经成功创建了iam数据库、表和存储过程，并初始化了一条数据�?
3. 配置scripts/install/environment.sh

IAM组件的安装配置都是通过环境变量文件[scripts/install/environment.sh](https://github.com/marmotedu/iam/blob/master/scripts/install/environment.sh)进行配置的，所以这里要先配置好scripts/install/environment.sh文件�?如果你自己设置了MariaDB、Redis和MongoDB的数据库密码就需要配置到environment.sh文件中。如果你是根据本教程安装的数据库或其它组件，那么可以直接使用environment.sh，内容为�?
```bash

#!/usr/bin/bash

IAM_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..

# 设置统一的密码，方便记忆
readonly PASSWORD=${PASSWORD:-'iam59!z$'}

# Linux系统 going 用户
readonly LINUX_USERNAME=${LINUX_USERNAME:-going}
# Linux root & going 用户密码
readonly LINUX_PASSWORD=${LINUX_PASSWORD:-${PASSWORD}}

readonly LOCAL_OUTPUT_ROOT="${IAM_ROOT}/${OUT_DIR:-_output}"

# 设置安装目录
readonly INSTALL_DIR=${INSTALL_DIR:-/tmp/installation}
mkdir -p ${INSTALL_DIR}
readonly ENV_FILE=${IAM_ROOT}/scripts/install/environment.sh

# MariaDB 配置信息
readonly MARIADB_ADMIN_USERNAME=${MARIADB_ADMIN_USERNAME:-root} # MariaDB root 用户
readonly MARIADB_ADMIN_PASSWORD=${MARIADB_ADMIN_PASSWORD:-${PASSWORD}} # MariaDB root 用户密码
readonly MARIADB_HOST=${MARIADB_HOST:-127.0.0.1:3306} # MariaDB 主机地址
readonly MARIADB_DATABASE=${MARIADB_DATABASE:-iam} # MariaDB iam 应用使用的数据库�?readonly MARIADB_USERNAME=${MARIADB_USERNAME:-iam} # iam 数据库用户名
readonly MARIADB_PASSWORD=${MARIADB_PASSWORD:-${PASSWORD}} # iam 数据库密�?
# Redis 配置信息
readonly REDIS_HOST=${REDIS_HOST:-127.0.0.1} # Redis 主机地址
readonly REDIS_PORT=${REDIS_PORT:-6379} # Redis 监听端口
readonly REDIS_USERNAME=${REDIS_USERNAME:-''} # Redis 用户�?readonly REDIS_PASSWORD=${REDIS_PASSWORD:-${PASSWORD}} # Redis 密码

# MongoDB 配置
readonly MONGO_ADMIN_USERNAME=${MONGO_ADMIN_USERNAME:-root} # MongoDB root 用户
readonly MONGO_ADMIN_PASSWORD=${MONGO_ADMIN_PASSWORD:-${PASSWORD}} # MongoDB root用户密码
readonly MONGO_HOST=${MONGO_HOST:-127.0.0.1} # MongoDB 地址
readonly MONGO_PORT=${MONGO_PORT:-27017} # MongoDB 端口
readonly MONGO_USERNAME=${MONGO_USERNAME:-iam} # MongoDB 用户�?readonly MONGO_PASSWORD=${MONGO_PASSWORD:-${PASSWORD}} # MongoDB 密码

# iam 配置
readonly IAM_DATA_DIR=${IAM_DATA_DIR:-/data/iam} # iam 各组件数据目�?readonly IAM_INSTALL_DIR=${IAM_INSTALL_DIR:-/opt/iam} # iam 安装文件存放目录
readonly IAM_CONFIG_DIR=${IAM_CONFIG_DIR:-/etc/iam} # iam 配置文件存放目录
readonly IAM_LOG_DIR=${IAM_LOG_DIR:-/var/log/iam} # iam 日志文件存放目录
readonly CA_FILE=${CA_FILE:-${IAM_CONFIG_DIR}/cert/ca.pem} # CA

# iam-apiserver 配置
readonly IAM_APISERVER_HOST=${IAM_APISERVER_HOST:-127.0.0.1} # iam-apiserver 部署机器 IP 地址
readonly IAM_APISERVER_GRPC_BIND_ADDRESS=${IAM_APISERVER_GRPC_BIND_ADDRESS:-0.0.0.0}
readonly IAM_APISERVER_GRPC_BIND_PORT=${IAM_APISERVER_GRPC_BIND_PORT:-8081}
readonly IAM_APISERVER_INSECURE_BIND_ADDRESS=${IAM_APISERVER_INSECURE_BIND_ADDRESS:-127.0.0.1}
readonly IAM_APISERVER_INSECURE_BIND_PORT=${IAM_APISERVER_INSECURE_BIND_PORT:-8080}
readonly IAM_APISERVER_SECURE_BIND_ADDRESS=${IAM_APISERVER_SECURE_BIND_ADDRESS:-0.0.0.0}
readonly IAM_APISERVER_SECURE_BIND_PORT=${IAM_APISERVER_SECURE_BIND_PORT:-8443}
readonly IAM_APISERVER_SECURE_TLS_CERT_KEY_CERT_FILE=${IAM_APISERVER_SECURE_TLS_CERT_KEY_CERT_FILE:-${IAM_CONFIG_DIR}/cert/iam-apiserver.pem}
readonly IAM_APISERVER_SECURE_TLS_CERT_KEY_PRIVATE_KEY_FILE=${IAM_APISERVER_SECURE_TLS_CERT_KEY_PRIVATE_KEY_FILE:-${IAM_CONFIG_DIR}/cert/iam-apiserver-key.pem}

# iam-authz-server 配置
readonly IAM_AUTHZ_SERVER_HOST=${IAM_AUTHZ_SERVER_HOST:-127.0.0.1} # iam-authz-server 部署机器 IP 地址
readonly IAM_AUTHZ_SERVER_INSECURE_BIND_ADDRESS=${IAM_AUTHZ_SERVER_INSECURE_BIND_ADDRESS:-127.0.0.1}
readonly IAM_AUTHZ_SERVER_INSECURE_BIND_PORT=${IAM_AUTHZ_SERVER_INSECURE_BIND_PORT:-9090}
readonly IAM_AUTHZ_SERVER_SECURE_BIND_ADDRESS=${IAM_AUTHZ_SERVER_SECURE_BIND_ADDRESS:-0.0.0.0}
readonly IAM_AUTHZ_SERVER_SECURE_BIND_PORT=${IAM_AUTHZ_SERVER_SECURE_BIND_PORT:-9443}
readonly IAM_AUTHZ_SERVER_SECURE_TLS_CERT_KEY_CERT_FILE=${IAM_AUTHZ_SERVER_SECURE_TLS_CERT_KEY_CERT_FILE:-${IAM_CONFIG_DIR}/cert/iam-authz-server.pem}
readonly IAM_AUTHZ_SERVER_SECURE_TLS_CERT_KEY_PRIVATE_KEY_FILE=${IAM_AUTHZ_SERVER_SECURE_TLS_CERT_KEY_PRIVATE_KEY_FILE:-${IAM_CONFIG_DIR}/cert/iam-authz-server-key.pem}
readonly IAM_AUTHZ_SERVER_CLIENT_CA_FILE=${IAM_AUTHZ_SERVER_CLIENT_CA_FILE:-${CA_FILE}}
readonly IAM_AUTHZ_SERVER_RPCSERVER=${IAM_AUTHZ_SERVER_RPCSERVER:-${IAM_APISERVER_HOST}:${IAM_APISERVER_GRPC_BIND_PORT}}

# iam-pump 配置
readonly IAM_PUMP_HOST=${IAM_PUMP_HOST:-127.0.0.1} # iam-pump 部署机器 IP 地址
readonly IAM_PUMP_COLLECTION_NAME=${IAM_PUMP_COLLECTION_NAME:-iam_analytics}
readonly IAM_PUMP_MONGO_URL=${IAM_PUMP_MONGO_URL:-mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/${IAM_PUMP_COLLECTION_NAME}?authSource=admin}

# iamctl 配置
readonly CONFIG_USER_USERNAME=${CONFIG_USER_USERNAME:-admin}
readonly CONFIG_USER_PASSWORD=${CONFIG_USER_PASSWORD:-Admin@2020}
readonly CONFIG_USER_CLIENT_CERTIFICATE=${CONFIG_USER_CLIENT_CERTIFICATE:-${HOME}/.iam/cert/admin.pem}
readonly CONFIG_USER_CLIENT_KEY=${CONFIG_USER_CLIENT_KEY:-${HOME}/.iam/cert/admin-key.pem}
readonly CONFIG_SERVER_ADDRESS=${CONFIG_SERVER_ADDRESS:-${IAM_APISERVER_HOST}:${IAM_APISERVER_SECURE_BIND_PORT}}
readonly CONFIG_SERVER_CERTIFICATE_AUTHORITY=${CONFIG_SERVER_CERTIFICATE_AUTHORITY:-${CA_FILE}}
```

4. 创建需要的目录

安装和运行IAM系统，需要将配置、二进制文件和数据文件存放到指定的目录，所以需要先创建好这些目录，创建步骤如下�?
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ sudo mkdir -p ${IAM_DATA_DIR}/{iam-apiserver,iam-authz-server,iam-pump} # 创建 Systemd WorkingDirectory 目录
$ sudo mkdir -p ${IAM_INSTALL_DIR}/bin #创建 IAM 系统安装目录
$ sudo mkdir -p ${IAM_CONFIG_DIR}/cert # 创建 IAM 系统配置文件存放目录
$ sudo mkdir -p ${IAM_LOG_DIR} # 创建 IAM 日志文件存放目录
```

5. 创建CA根证书和秘钥

为确保安全，iam系统各组件需要使用x509证书对通信进行加密和认证。CA (Certificate Authority)是自签名的根证书，用来签名后续创建的其它证书。本专栏使用CloudFlare的PKI工具�?cfssl来创建所有证书。创建步骤如下：

1) 安装cfssl工具�?
```bash
$ cd $IAM_ROOT
$ mkdir -p $HOME/bin/
$ wget https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl_1.4.1_linux_amd64 -O $HOME/bin/cfssl
$ wget https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssljson_1.4.1_linux_amd64 -O $HOME/bin/cfssljson
$ wget https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl-certinfo_1.4.1_linux_amd64 -O $HOME/bin/cfssl-certinfo
$ chmod +x $HOME/bin/{cfssl,cfssljson,cfssl-certinfo}
```

2) 创建配置文件

```bash
$ cd $IAM_ROOT
$ tee ca-config.json << EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "iam": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "876000h"
      }
    }
  }
}
EOF
```

- signing：表示该证书可用于签名其它证书（生成的ca.pem证书中CA=TRUE）�?- server auth：表示client可以用该该证书对server提供的证书进行验证�?- client auth：表示server可以用该该证书对client提供的证书进行验证�?- expiry: 876000h，证书有效期设置�?100 年�?
3) 创建证书签名请求文件

```bash
$ cd $IAM_ROOT
$ tee ca-csr.json << EOF
{
  "CN": "iam-ca",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "iam",
      "OU": "marmotedu"
    }
  ],
  "ca": {
    "expiry": "876000h"
  }
}
EOF
```

- CN：Common Name，iam-apiserver从证书中提取该字段作为请求的用户�?**(User Name)** ，浏览器使用该字段验证网站是否合法�?- O：Organization，iam-apiserver从证书中提取该字段作为请求用户所属的�?**(Group)**�?
注意�?- 不同证书csr文件的CN、C、ST、L、O、OU组合必须不同，否则可能出现`PEER'S CERTIFICATE HAS AN INVALID SIGNATURE`错误�?- 后续创建证书的csr文件时，CN都不相同（C、ST、L、O、OU 相同），以达到区分的目的�?
4) 生成CA证书和私�?
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ cfssl gencert -initca ca-csr.json | cfssljson -bare ca
$ ls ca*
ca-config.json  ca.csr  ca-csr.json  ca-key.pem  ca.pem
```

5) 将生成的证书文件拷贝到配置文件目�?
```bash
$ sudo mv ca* ${IAM_CONFIG_DIR}/cert
```

6. 配置hosts

iam通过域名访问API接口，所以需要配置hosts，操作如下：

```bash
$ sudo tee -a /etc/hosts <<EOF
127.0.0.1 iam.api.marmotedu.com
127.0.0.1 iam.authz.marmotedu.com
EOF
```

### 安装和配置iam-apiserver

通过以下3步完成iam-apiserver的安装和配置�?1. 创建iam-apiserver证书和私钥�?2. 安装并运行iam-apiserver�?3. 测试iam-apiserver是否成功安装�?
安装详细步骤如下�?
1. 创建iam-apiserver证书和私�?
其它服务为了安全都是通过HTTPS协议访问iam-apiserver，所以要先创建iam-apiserver证书和私钥，步骤如下�?
1) 创建证书签名请求

```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ tee iam-apiserver-csr.json <<EOF
{
  "CN": "iam-apiserver",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "iam",
      "OU": "marmotedu"
    }
  ],
  "hosts": [
    "127.0.0.1",
    "localhost",
    "iam.api.marmotedu.com"
  ]
}
EOF
```

hosts字段指定授权使用该证书的IP和域名列表，这里列出了iam-apiserver服务�?IP 和域名�?
2) 生成证书和私�?
```bash
$ cfssl gencert -ca=${IAM_CONFIG_DIR}/cert/ca.pem \
  -ca-key=${IAM_CONFIG_DIR}/cert/ca-key.pem \
  -config=${IAM_CONFIG_DIR}/cert/ca-config.json \
  -profile=iam iam-apiserver-csr.json | cfssljson -bare iam-apiserver
```

3) 将生成的证书和私钥文件拷贝到配置文件目录

```bash
$ sudo mv iam-apiserver*pem ${IAM_CONFIG_DIR}/cert
```

2. 安装并运行iam-apiserver

iam-apiserver作为iam系统的核心组件，需要第一个安装，安装步骤如下�?
1) 安装iam-apiserver可执行程�?
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ make build BINS=iam-apiserver
$ sudo cp _output/platforms/linux/amd64/iam-apiserver ${IAM_INSTALL_DIR}/bin
```

2) 生成并安装iam-apiserver的配置文件（iam-apiserver.yaml�?```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh configs/iam-apiserver.yaml > iam-apiserver.yaml
$ sudo mv iam-apiserver.yaml ${IAM_CONFIG_DIR}
```

3) 创建并安装iam-apiserver systemd unit文件

```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh init/iam-apiserver.service > iam-apiserver.service
$ sudo mv iam-apiserver.service /etc/systemd/system/
```

4) 启动iam-apiserver服务
```bash
$ sudo systemctl daemon-reload
$ sudo systemctl enable iam-apiserver
$ sudo systemctl restart iam-apiserver
$ systemctl status iam-apiserver # 查看iam-apiserver运行状态，如果输出中包含active (running)字样说明iam-apiserver成功启动�?```

3. 测试iam-apiserver是否成功安装

测试iam-apiserver主要是测试RESTful资源的CURD�?- 用户CURD
- 密钥CURD
- 授权策略CURD

首先需要获取访问iam-apiserver的token，请求如下API访问�?
```bash
$ curl -s -XPOST -H'Content-Type: application/json' -d'{"username":"admin","password":"Admin@2021"}' http://127.0.0.1:8080/login | jq -r .token
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA
```

**用户CURD**

1) 创建colin用户

```bash
$ curl -s -XPOST -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"password":"User@2021","metadata":{"name":"colin"},"nickname":"colin","email":"colin@foxmail.com","phone":"1812884xxxx"}' http://127.0.0.1:8080/v1/users
```

2) 列出所有用�?
```bash
$ curl -s -XGET -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' 'http://127.0.0.1:8080/v1/users?offset=0&limit=10'
```

3) 获取colin用户的详细信�?
```bash
$ curl -s -XGET -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/users/colin
```

4) 修改colin用户

```bash
$ curl -s -XPUT -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"nickname":"colin","email":"colin_modified@foxmail.com","phone":"1812884xxxx"}' http://127.0.0.1:8080/v1/users/colin
```

5) 删除colin用户

```bash
$ curl -s -XDELETE -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/users/colin
```

6) 批量删除用户

```bash
$ curl -s -XDELETE -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' 'http://127.0.0.1:8080/v1/users?name=colin&name=mark&name=john'
```

**密钥CURD**

1) 创建secret0密钥

```bash
$ curl -s -XPOST -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"metadata":{"name":"secret0"},"expires":0,"description":"admin secret"}' http://127.0.0.1:8080/v1/secrets
```

2) 列出所有密�?
```bash
$ curl -s -XGET -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/secrets
```

3) 获取secret0密钥的详细信�?
```bash
$ curl -s -XGET -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/secrets/secret0
```

4) 修改secret0密钥

```bash
$ curl -s -XPUT -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"metadata":{"name":"secret0"},"expires":0,"description":"admin secret(modified)"}' http://127.0.0.1:8080/v1/secrets/secret0
```

5) 删除secret0密钥

```bash
$ curl -s -XDELETE -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/secrets/secret0
```

**授权策略CURD**

1) 创建policy0策略

```bash
$ curl -s -XPOST -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"metadata":{"name":"policy0"},"policy":{"description":"One policy to rule them all.","subjects":["users:<peter|ken>","users:maria","groups:admins"],"actions":["delete","<create|update>"],"effect":"allow","resources":["resources:articles:<.*>","resources:printer"],"conditions":{"remoteIPAddress":{"type":"CIDRCondition","options":{"cidr":"192.168.0.1/16"}}}}}' http://127.0.0.1:8080/v1/policies
```

2) 列出所有策�?
```bash
$ curl -s -XGET -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/policies
```

3) 获取policy0策略的详细信�?
```bash
$ curl -s -XGET -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/policies/policy0

```
4) 修改policy策略

```bash
$ curl -s -XPUT -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"metadata":{"name":"policy0"},"policy":{"description":"One policy to rule them all(modified).","subjects":["users:<peter|ken>","users:maria","groups:admins"],"actions":["delete","<create|update>"],"effect":"allow","resources":["resources:articles:<.*>","resources:printer"],"conditions":{"remoteIPAddress":{"type":"CIDRCondition","options":{"cidr":"192.168.0.1/16"}}}}}' http://127.0.0.1:8080/v1/policies/policy0
```

5) 删除policy0策略

```bash
$ curl -s -XDELETE -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' http://127.0.0.1:8080/v1/policies/policy0
```

### 安装和配置iam-authz-server

通过以下3步完成iam-authz-server的安装和配置�?1. 创建iam-authz-server证书和私钥�?2. 安装并运行iam-authz-server�?3. 测试iam-authz-server是否成功安装�?
安装详细步骤如下�?
1. 创建iam-authz-server证书和私�?
1) 创建证书签名请求
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ tee iam-authz-server-csr.json <<EOF
{
  "CN": "iam-authz-server",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "iam-authz-server",
      "OU": "marmotedu"
    }
  ],
  "hosts": [
    "127.0.0.1",
    "localhost",
    "iam.authz.marmotedu.com"
  ]
}
EOF
```
hosts字段指定授权使用该证书的IP和域名列表，这里列出了iam-authz-server服务�?IP 和域名�?
2) 生成证书和私�?
```bash
$ cfssl gencert -ca=${IAM_CONFIG_DIR}/cert/ca.pem \
  -ca-key=${IAM_CONFIG_DIR}/cert/ca-key.pem \
  -config=${IAM_CONFIG_DIR}/cert/ca-config.json \
  -profile=iam iam-authz-server-csr.json | cfssljson -bare iam-authz-server
```

3) 将生成的证书和私钥文件拷贝到配置文件目录

```bash
$ sudo mv iam-authz-server*pem ${IAM_CONFIG_DIR}/cert
```

2. 安装并运行iam-authz-server

安装iam-authz-server步骤和安装iam-apiserver步骤基本一样，具体步骤如下�?
1) 安装iam-authz-server可执行程�?
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ make build BINS=iam-authz-server
$ sudo cp _output/platforms/linux/amd64/iam-authz-server ${IAM_INSTALL_DIR}/bin
```

2) 生成并安装iam-authz-server的配置文件（iam-authz-server.yaml�?
```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh configs/iam-authz-server.yaml > iam-authz-server.yaml
$ sudo mv iam-authz-server.yaml ${IAM_CONFIG_DIR}
```

3) 创建并安装iam-authz-server systemd unit文件

```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh init/iam-authz-server.service > iam-authz-server.service
$ sudo mv iam-authz-server.service /etc/systemd/system/
```

4) 启动iam-authz-server服务

```bash
$ sudo systemctl daemon-reload
$ sudo systemctl enable iam-authz-server
$ sudo systemctl restart iam-authz-server
$ systemctl status iam-authz-server # 查看iam-authz-server运行状态，如果输出中包含active (running)字样说明iam-authz-server成功启动�?```

3. 测试iam-authz-server是否成功安装

1) 创建密钥

```bash
$ curl -s -XPOST -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXBpLm1hcm1vdGVkdS5jb20iLCJleHAiOjE2MTc5MjI4OTQsImlkZW50aXR5IjoiYWRtaW4iLCJpc3MiOiJpYW0tYXBpc2VydmVyIiwib3JpZ19pYXQiOjE2MTc4MzY0OTQsInN1YiI6ImFkbWluIn0.9qztVJseQ9XwqOFVUHNOtG96-KUovndz0SSr_QBsxAA' -d'{"metadata":{"name":"authztest"},"expires":0,"description":"admin secret"}' http://127.0.0.1:8080/v1/secrets
{"metadata":{"id":23,"name":"authztest","createdAt":"2021-04-08T07:24:50.071671422+08:00","updatedAt":"2021-04-08T07:24:50.071671422+08:00"},"username":"admin","secretID":"ZuxvXNfG08BdEMqkTaP41L2DLArlE6Jpqoox","secretKey":"7Sfa5EfAPIwcTLGCfSvqLf0zZGCjF3l8","expires":0,"description":"admin secret"}
```

从上面的输出中提取：secretID和secretKey�?
2) 生成访问iam-authz-server的token

```bash
$ iamctl jwt sign ZuxvXNfG08BdEMqkTaP41L2DLArlE6Jpqoox 7Sfa5EfAPIwcTLGCfSvqLf0zZGCjF3l8 # iamctl jwt sign $secretID $secretKey
eyJhbGciOiJIUzI1NiIsImtpZCI6Ilp1eHZYTmZHMDhCZEVNcWtUYVA0MUwyRExBcmxFNkpwcW9veCIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXV0aHoubWFybW90ZWR1LmNvbSIsImV4cCI6MTYxNzg0NTE5NSwiaWF0IjoxNjE3ODM3OTk1LCJpc3MiOiJpYW1jdGwiLCJuYmYiOjE2MTc4Mzc5OTV9.za9yLM7lHVabPAlVQLCqXEaf8sTU6sodAsMXnmpXjMQ
```

2) 测试资源授权是否通过

```bash
$ curl -s -XPOST -H'Content-Type: application/json' -H'Authorization: Bearer eyJhbGciOiJIUzI1NiIsImtpZCI6Ilp1eHZYTmZHMDhCZEVNcWtUYVA0MUwyRExBcmxFNkpwcW9veCIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJpYW0uYXV0aHoubWFybW90ZWR1LmNvbSIsImV4cCI6MTYxNzg0NTE5NSwiaWF0IjoxNjE3ODM3OTk1LCJpc3MiOiJpYW1jdGwiLCJuYmYiOjE2MTc4Mzc5OTV9.za9yLM7lHVabPAlVQLCqXEaf8sTU6sodAsMXnmpXjMQ' -d'{"subject":"users:peter","action":"delete","resource":"resources:articles:ladon-introduction","context":{"remoteIPAddress":"193.168.0.5"}}' http://127.0.0.1:9090/v1/authz
{"allowed":true}
```

预期通过，返回：**{"allowed":true}**

### 安装和配置iam-pump

安装iam-pump步骤和安装iam-apiserver、iam-authz-server步骤基本一样，具体步骤如下�?
1. 安装iam-pump可执行程�?
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ make build BINS=iam-pump
$ sudo cp _output/platforms/linux/amd64/iam-pump ${IAM_INSTALL_DIR}/bin
```

2. 生成并安装iam-pump的配置文件（iam-pump.yaml�?
```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh configs/iam-pump.yaml > iam-pump.yaml
$ sudo mv iam-pump.yaml ${IAM_CONFIG_DIR}
```

3. 创建并安装iam-pump systemd unit文件

```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh init/iam-pump.service > iam-pump.service
$ sudo mv iam-pump.service /etc/systemd/system/
```

4. 启动iam-pump服务
```bash
$ sudo systemctl daemon-reload
$ sudo systemctl enable iam-pump
$ sudo systemctl restart iam-pump
$ systemctl status iam-pump # 查看iam-pump运行状态，如果输出中包含active (running)字样说明iam-pump成功启动�?```

5. 测试iam-pump是否成功安装

```bash
$ curl http://127.0.0.1:7070/healthz
{"status": "ok"}
```

返回 **{"status": "ok"}** 说明iam-pump服务健康�?
### 安装iamctl

上面，我们安装了iam系统的服务，为了访问iam服务，还需要安装客户端工具iamctl。通过以下3步完成iamctl的安装和配置�?1. 创建iamctl证书和私钥�?2. 安装iamctl�?3. 测试iamctl是否成功安装�?
安装详细步骤如下�?
1. 创建iamctl证书和私�?
iamctl使用https协议与iam-apiserver进行安全通信，iam-apiserver对iamctl请求包含的证书进行认证和授权。iamctl后续用于iam系统访问和管理，所以这里创建具有最高权限的admin证书�?1) 创建证书签名请求

```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "iamctl",
      "OU": "marmotedu"
    }
  ],
  "hosts": []
}
EOF
```

该证书只会被iamctl当做client证书使用，所以hosts字段为空�?
2) 生成证书和私�?
```bash
cfssl gencert -ca=${IAM_CONFIG_DIR}/cert/ca.pem \
  -ca-key=${IAM_CONFIG_DIR}/cert/ca-key.pem \
  -config=${IAM_CONFIG_DIR}/cert/ca-config.json \
  -profile=iam admin-csr.json | cfssljson -bare admin
```
3) 将生成的证书和私钥文件拷贝到配置文件目录

```bash
$ sudo mv admin* ${IAM_CONFIG_DIR}/cert
```

2. 安装iamctl

iamctl是IAM系统的客户端工具，其安装位置和iam-apiserver、iam-authz-server、iam-pump位置不同，为了能够在shell下直接运行iamctl命令，我们需要将iamctl安装到`$HOME/bin`下，同时将iamctl的配置存放在默认加载的目录下：`$HOME/.iam`�?
具体步骤如下�?
1) 安装iamctl可执行程�?
```bash
$ cd $IAM_ROOT
$ source scripts/install/environment.sh
$ make build BINS=iamctl
$ cp _output/platforms/linux/amd64/iamctl $HOME/bin
```

2) 生成并安装iamctl的配置文件（iamctl.yaml�?
```bash
$ ./scripts/genconfig.sh scripts/install/environment.sh configs/iamctl.yaml > iamctl.yaml 
$ mkdir -p $HOME/.iam
$ mv iamctl.yaml $HOME/.iam
```

因为iamctl是一个客户端工具，我们可能会在多台机器上运行，为了简化部署iamctl工具的复杂度，我们可以把config配置文件中跟CA认证相关的CA文件内容，用base64加密后，放置在config配置文件中，config文件中的配置项client-certificate、client-key、certificate-authority分别可用如下配置项替换client-certificate-data、client-key-data、certificate-authority-data，这些配置项的值，可以通过将CA文件使用base64加密获得�?假如，certificate-authority值为`/etc/iam/cert/ca.pem`，则certificate-authority-data的值为`cat "/etc/iam/cert/ca.pem" | base64 | tr -d '\r\n'`，其它`-data`变量的值类似。这样当我们再在部署iamctl工具时，只需要拷贝iamctl和配置文件，而不用再拷贝CA文件�?
3. 测试iamctl是否成功安装

执行 `iamctl user list` 可以列出预创建的admin用户，如下图所示：

![iamctl_user_list](https://images-public-1254073058.cos.ap-guangzhou.myqcloud.com/iamctl_user_list.png)

### 安装man文件

本书通过组合调用包：`github.com/cpuguy83/go-md2man/v2/md2man`和`github.com/spf13/cobra`的相关函数生成了各个组件的man1文件。生成和安装步骤如下�?
1. 生成各个组件的man1文件

```bash
$ cd $IAM_ROOT
$ ./scripts/update-generated-docs.sh
```

2. 安装生成的man1文件

```bash
$ sudo cp docs/man/man1/* /usr/share/man/man1/
```

3. 检查是否成功安装man1文件

```bash
$ man iam-apiserver
```

执行man iam-apiserver命令后，可以成功弹出man文档界面，如图x-x所示�?
![iam-apiserver-man1](https://images-public-1254073058.cos.ap-guangzhou.myqcloud.com/iam-apiserver-man1.png)

至此，IAM系统所有组件均安装成功，可以通过`iamctl version`查看客户端和服务端版本：

```bash
$ iamctl version -o yaml
clientVersion:
  buildDate: "2021-04-08T01:56:20Z"
  compiler: gc
  gitCommit: 1d682b0317396347b568a3ef366c1c54b3b0186b
  gitTreeState: dirty
  gitVersion: v0.6.1-5-g1d682b0
  goVersion: go1.17
  platform: linux/amd64
serverVersion:
  buildDate: "2021-04-07T22:30:53Z"
  compiler: gc
  gitCommit: bde163964b8c004ebb20ca4abd8a2ac0cd1f71ad
  gitTreeState: dirty
  gitVersion: bde1639
  goVersion: go1.17
  platform: linux/amd64
```

## 彩蛋：一键安�?
如果你完成了 **03 | 项目部署：快速部�?IAM 系统，准备实验环�?* 的学习，那么可以直接执行如下脚本，来完成IAM系统的安装：

```bash
$ git clone --depth=1 https://github.com/marmotedu/iam.git /tmp/iam
$ cd /tmp/iam/ && ./scripts/install/install.sh iam::install::install_iam
```

你也可以参考[IAM 部署指南](https://github.com/marmotedu/iam/tree/master/docs/guide/zh-CN/installation/README.md)教程进行安装。该安装手册可以使你创建完普通用户后，一键部署整个IAM系统，包括开发环境和IAM服务�?
## 总结

这一讲，通过一步步教你安装IAM应用来协助你加深对IAM应用的理解，并为后面的实战准备好环境。整个安装过程分为以�?大类�?
- 安装和配置数据库：MariaDB、Redis、MongoDB�?- 安装和配置IAM服务：iam-apiserver、iam-authz-server、iam-pump、iamctl�?
因为服务之间通过HTTPS进行访问，所以需要生成CA证书，通过cfssl来制作CA证书�?为了方便你安装IAM应用，结尾也留了一个彩蛋：一键安装IAM应用。如果你是第一次安装IAM应用，我建议你一步步安装IAM，而不要使用一键安装脚本�?
## 课后练习

1. 登录MariaDB，查看iam.user、iam.policy、iam.secret（格式：数据�?表）表结构，理解每个字段的意思�?2. 调用iam-apiserver提供的API接口创建一个用户：`xuezhang`，并在该用户下创建policy和secret资源。最后调用iam-authz-server提供的`/v1/authz`接口进行资源鉴权�?3. 使用iamctl工具创建用户、策略、密钥�?