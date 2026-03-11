#!/usr/bin/env bash



# The root of the build/dist directory
IAM_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..
[[ -z ${COMMON_SOURCED} ]] && source ${IAM_ROOT}/scripts/install/common.sh

# 安装后打印必要的信息
function iam::authzserver::info() {
cat << EOF
iam-authz-server insecure listen on: ${IAM_AUTHZ_SERVER_HOST}:${IAM_AUTHZ_SERVER_INSECURE_BIND_PORT}
iam-authz-server secure listen on: ${IAM_AUTHZ_SERVER_HOST}:${IAM_AUTHZ_SERVER_SECURE_BIND_PORT}
EOF
}

# 安装
function iam::authzserver::install()
{
  pushd ${IAM_ROOT}

  # 1. 生成 CA 证书和私�?  ./scripts/gencerts.sh generate-iam-cert ${LOCAL_OUTPUT_ROOT}/cert
  iam::common::sudo "cp ${LOCAL_OUTPUT_ROOT}/cert/ca* ${IAM_CONFIG_DIR}/cert"

  ./scripts/gencerts.sh generate-iam-cert ${LOCAL_OUTPUT_ROOT}/cert iam-authz-server
  iam::common::sudo "cp ${LOCAL_OUTPUT_ROOT}/cert/iam-authz-server*pem ${IAM_CONFIG_DIR}/cert"

  # 2. 构建 iam-authz-server
  make build BINS=iam-authz-server
  iam::common::sudo "cp ${LOCAL_OUTPUT_ROOT}/platforms/linux/amd64/iam-authz-server ${IAM_INSTALL_DIR}/bin"

  # 3.  生成并安�?iam-authz-server 的配置文件（iam-authz-server.yaml�?  echo ${LINUX_PASSWORD} | sudo -S bash -c \
    "./scripts/genconfig.sh ${ENV_FILE} configs/iam-authz-server.yaml > ${IAM_CONFIG_DIR}/iam-authz-server.yaml"

  # 4. 创建并安�?iam-authz-server systemd unit 文件
  echo ${LINUX_PASSWORD} | sudo -S bash -c \
    "./scripts/genconfig.sh ${ENV_FILE} init/iam-authz-server.service > /etc/systemd/system/iam-authz-server.service"

  # 5. 启动 iam-authz-server 服务
  iam::common::sudo "systemctl daemon-reload"
  iam::common::sudo "systemctl restart iam-authz-server"
  iam::common::sudo "systemctl enable iam-authz-server"
  iam::authzserver::status || return 1
  iam::authzserver::info

  iam::log::info "install iam-authz-server successfully"
  popd
}

# 卸载
function iam::authzserver::uninstall()
{
  set +o errexit
  iam::common::sudo "systemctl stop iam-authz-server"
  iam::common::sudo "systemctl disable iam-authz-server"
  iam::common::sudo "rm -f ${IAM_INSTALL_DIR}/bin/iam-authz-server"
  iam::common::sudo "rm -f ${IAM_CONFIG_DIR}/iam-authz-server.yaml"
  iam::common::sudo "rm -f /etc/systemd/system/iam-authz-server.service"
  iam::common::sudo "rm -f ${IAM_CONFIG_DIR}/cert/iam-authz-server*pem"
  set -o errexit
  iam::log::info "uninstall iam-authz-server successfully"
}

# 状态检�?function iam::authzserver::status()
{
  # 查看 iam-authz-server 运行状态，如果输出中包�?active (running) 字样说明 iam-authz-server 成功启动�?  systemctl status iam-authz-server|grep -q 'active' || {
    iam::log::error "iam-authz-server failed to start, maybe not installed properly"
    return 1
  }

 if echo | telnet ${IAM_AUTHZSERVER_HOST} ${IAM_AUTHZSERVER_INSECURE_BIND_PORT} 2>&1|grep refused &>/dev/null;then
   iam::log::error "cannot access insecure port, iam-authz-server maybe not startup"
   return 1
 fi
}

if [[ "$*" =~ iam::authzserver:: ]];then
  eval $*
fi
