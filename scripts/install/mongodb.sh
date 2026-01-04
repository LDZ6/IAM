#!/usr/bin/env bash



# The root of the build/dist directory
IAM_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..
[[ -z ${COMMON_SOURCED} ]] && source ${IAM_ROOT}/scripts/install/common.sh

# 安装后打印必要的信息
function iam::mongodb::info() {
cat << EOF
MongoDB Login: mongo mongodb://${MONGO_USERNAME}:'${MONGO_PASSWORD}'@${MONGO_HOST}:${MONGO_PORT}/iam_analytics?authSource=iam_analytics
EOF
}

# 安装
function iam::mongodb::install()
{
  # 1. 配置 MongoDB Yum �?  echo ${LINUX_PASSWORD} | sudo -S bash -c "cat << 'EOF' > /etc/yum.repos.d/mongodb-org-5.0.repo
[mongodb-org-5.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/5.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-5.0.asc
EOF"

  # 2. 安装 MongoDB �?MongoDB 客户�?  iam::common::sudo "yum install -y mongodb-org"

	# 3. 禁用 SELinux
	echo ${LINUX_PASSWORD} | sudo -S setenforce 0 || true
	echo ${LINUX_PASSWORD} | sudo -S sed -i 's/^SELINUX=.*$/SELINUX=disabled/' /etc/selinux/config

	# 4. 开启外网访问权限和登录验证
	echo ${LINUX_PASSWORD} | sudo -S sed -i '/bindIp/{s/127.0.0.1/0.0.0.0/}' /etc/mongod.conf
	echo ${LINUX_PASSWORD} | sudo -S sed -i '/^#security/a\security:\n  authorization: enabled' /etc/mongod.conf

  # 5. 启动 MongoDB，并设置开机启�?  iam::common::sudo "systemctl enable mongod"
  iam::common::sudo "systemctl start mongod"

  # 6. 创建管理员账号，设置管理员密�?	mongosh --quiet "mongodb://${MONGO_HOST}:${MONGO_PORT}" << EOF
use admin
db.createUser({user:"${MONGO_ADMIN_USERNAME}",pwd:"${MONGO_ADMIN_PASSWORD}",roles:["root"]})
db.auth("${MONGO_ADMIN_USERNAME}", "${MONGO_ADMIN_PASSWORD}")
EOF

	# 7. 创建 ${MONGO_USERNAME} 用户
	mongosh --quiet mongodb://${MONGO_ADMIN_USERNAME}:${MONGO_ADMIN_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/iam_analytics?authSource=admin << EOF
use iam_analytics
db.createUser({user:"${MONGO_USERNAME}",pwd:"${MONGO_PASSWORD}",roles:["dbOwner"]})
db.auth("${MONGO_USERNAME}", "${MONGO_PASSWORD}")
EOF

  iam::mongodb::status || return 1
  iam::mongodb::info
  iam::log::info "install MongoDB successfully"
}

# 卸载
function iam::mongodb::uninstall()
{
  set +o errexit
  iam::common::sudo "systemctl stop mongodb"
  iam::common::sudo "systemctl disable mongodb"
  iam::common::sudo "yum -y remove mongodb-org"
  iam::common::sudo "rm -rf /var/lib/mongo"
  iam::common::sudo "rm -f /etc/yum.repos.d/mongodb-10.5.repo"
  iam::common::sudo "rm -f /etc/mongod.conf"
  iam::common::sudo "rm -f /lib/systemd/system/mongod.service"
  iam::common::sudo "rm -f /tmp/mongodb-*.sock"
  set -o errexit
  iam::log::info "uninstall MongoDB successfully"
}

# 状态检�?function iam::mongodb::status()
{
  # 查看 mongodb 运行状态，如果输出中包�?active (running) 字样说明 mongodb 成功启动�?  systemctl status mongod |grep -q 'active' || {
    iam::log::error "mongodb failed to start, maybe not installed properly"
    return 1
  }

	echo "show dbs" | mongosh --quiet "mongodb://${MONGO_HOST}:${MONGO_PORT}" &>/dev/null || {
    iam::log::error "cannot connect to mongodb, mongo maybe not installed properly"
    return 1
  }

	echo "show dbs" | \
		mongosh --quiet mongodb://${MONGO_ADMIN_USERNAME}:${MONGO_ADMIN_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/iam_analytics?authSource=admin &>/dev/null || {
    iam::log::error "can not login with ${MONGO_ADMIN_USERNAME}, mongo maybe not initialized properly"
    return 1
  }

	echo "show dbs" | \
		mongosh --quiet mongodb://${MONGO_USERNAME}:${MONGO_PASSWORD}@${MONGO_HOST}:${MONGO_PORT}/iam_analytics?authSource=iam_analytics &>/dev/null|| {
    iam::log::error "can not login with ${MONGO_USERNAME}, mongo maybe not initialized properly"
    return 1
  }
}

if [[ "$*" =~ iam::mongodb:: ]];then
  eval $*
fi
