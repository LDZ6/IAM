#!/usr/bin/env bash



# The root of the build/dist directory
IAM_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..
[[ -z ${COMMON_SOURCED} ]] && source ${IAM_ROOT}/scripts/install/common.sh

# 安装后打印必要的信息
function iam::watcher::info() {
cat << EOF
iam-watcher listen on: ${IAM_WATCHER_HOST}
EOF
}

# 安装
function iam::watcher::install()
{
  pushd ${IAM_ROOT}

  # 1. 构建 iam-watcher
  make build BINS=iam-watcher
  iam::common::sudo "cp ${LOCAL_OUTPUT_ROOT}/platforms/linux/amd64/iam-watcher ${IAM_INSTALL_DIR}/bin"

  # 2.  生成并安�?iam-watcher 的配置文件（iam-watcher.yaml�?  echo ${LINUX_PASSWORD} | sudo -S bash -c \
    "./scripts/genconfig.sh ${ENV_FILE} configs/iam-watcher.yaml > ${IAM_CONFIG_DIR}/iam-watcher.yaml"

  # 3. 创建并安�?iam-watcher systemd unit 文件
  echo ${LINUX_PASSWORD} | sudo -S bash -c \
    "./scripts/genconfig.sh ${ENV_FILE} init/iam-watcher.service > /etc/systemd/system/iam-watcher.service"

  # 4. 启动 iam-watcher 服务
  iam::common::sudo "systemctl daemon-reload"
  iam::common::sudo "systemctl restart iam-watcher"
  iam::common::sudo "systemctl enable iam-watcher"
  iam::watcher::status || return 1
  iam::watcher::info

  iam::log::info "install iam-watcher successfully"
  popd
}

# 卸载
function iam::watcher::uninstall()
{
  set +o errexit
  iam::common::sudo "systemctl stop iam-watcher"
  iam::common::sudo "systemctl disable iam-watcher"
  iam::common::sudo "rm -f ${IAM_INSTALL_DIR}/bin/iam-watcher"
  iam::common::sudo "rm -f ${IAM_CONFIG_DIR}/iam-watcher.yaml"
  iam::common::sudo "rm -f /etc/systemd/system/iam-watcher.service"
  set -o errexit
  iam::log::info "uninstall iam-watcher successfully"
}

# 状态检�?function iam::watcher::status()
{
  # 查看 iam-watcher 运行状态，如果输出中包�?active (running) 字样说明 iam-watcher 成功启动�?  systemctl status iam-watcher|grep -q 'active' || {
    iam::log::error "iam-watcher failed to start, maybe not installed properly"
    return 1
  }

  # 监听端口在配置文件中�?hardcode
  if echo | telnet 127.0.0.1 5050 2>&1|grep refused &>/dev/null;then
    iam::log::error "cannot access health check port, iam-watcher maybe not startup"
    return 1
  fi
}

if [[ "$*" =~ iam::watcher:: ]];then
  eval $*
fi
