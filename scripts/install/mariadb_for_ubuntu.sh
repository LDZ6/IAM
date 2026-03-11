#!/bin/bash



# The root of the build/dist directory
IAM_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..

[[ -z ${COMMON_SOURCED} ]] && source ${IAM_ROOT}/scripts/install/common.sh

# 安装后打印必要的信息
function iam::mariadb::info() {
cat << EOF
MariaDB Login: mysql -h127.0.0.1 -u${MARIADB_ADMIN_USERNAME} -p'${MARIADB_ADMIN_PASSWORD}'
EOF
}

# 安装
function iam::mariadb::install()
{
  # 1. 配置 MariaDB 10.5 apt �?  iam::common::sudo "apt-get install software-properties-common dirmngr apt-transport-https"
  echo ${LINUX_PASSWORD} | sudo -S apt-key adv --fetch-keys 'https://mariadb.org/mariadb_release_signing_key.asc'
  # add /etc/apt/sources.list
  echo ${LINUX_PASSWORD} | sudo -S add-apt-repository 'deb [arch=amd64,arm64,ppc64el,s390x] https://mirrors.aliyun.com/mariadb/repo/10.5/ubuntu focal main'

  # 2. 安装 MariaDB �?MariaDB 客户�?  iam::common::sudo "apt update"
  iam::common::sudo "apt -y install mariadb-server"

  # 3. 启动 MariaDB，并设置开机启�?  iam::common::sudo "systemctl enable mariadb"
  iam::common::sudo "systemctl start mariadb"

  # 4. 设置 root 初始密码
  iam::common::sudo "mysqladmin -u${MARIADB_ADMIN_USERNAME} password ${MARIADB_ADMIN_PASSWORD}"

  iam::mariadb::status || return 1
  iam::mariadb::info
  iam::log::info "install MariaDB successfully"
}

# 卸载
function iam::mariadb::uninstall()
{
  set +o errexit
  iam::common::sudo "systemctl stop mariadb"
  iam::common::sudo "systemctl disable mariadb"
  iam::common::sudo "apt-get -y remove mariadb-server"
  iam::common::sudo "rm -rf /var/lib/mysql"
  set -o errexit
  iam::log::info "uninstall MariaDB successfully"
}

# 状态检�?function iam::mariadb::status()
{
  # 查看 mariadb 运行状态，如果输出中包�?active (running) 字样说明 mariadb 成功启动�?  systemctl status mariadb |grep -q 'active' || {
    iam::log::error "mariadb failed to start, maybe not installed properly"
    return 1
  }

  mysql -u${MARIADB_ADMIN_USERNAME} -p${MARIADB_ADMIN_PASSWORD} -e quit &>/dev/null || {
    iam::log::error "can not login with root, mariadb maybe not initialized properly"
    return 1
  }
  iam::log::info "MariaDB status active"
}

if [[ "$*" =~ iam::mariadb:: ]];then
  eval $*
fi
