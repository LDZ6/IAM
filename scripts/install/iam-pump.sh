#!/usr/bin/env bash



# The root of the build/dist directory
IAM_ROOT=$(dirname "${BASH_SOURCE[0]}")/../..
[[ -z ${COMMON_SOURCED} ]] && source ${IAM_ROOT}/scripts/install/common.sh

# 安装后打印必要的信息
function iam::pump::info() {
cat << EOF
iam-pumpn listen on: ${IAM_PUMP_HOST}
EOF
}

# 安装
function iam::pump::install()
{
  pushd ${IAM_ROOT}

  # 1. 构建 iam-pump
  make build BINS=iam-pump
  iam::common::sudo "cp ${LOCAL_OUTPUT_ROOT}/platforms/linux/amd64/iam-pump ${IAM_INSTALL_DIR}/bin"

  # 2.  生成并安�?iam-pump 的配置文件（iam-pump.yaml�?  echo ${LINUX_PASSWORD} | sudo -S bash -c \
    "./scripts/genconfig.sh ${ENV_FILE} configs/iam-pump.yaml > ${IAM_CONFIG_DIR}/iam-pump.yaml"

  # 3. 创建并安�?iam-pump systemd unit 文件
  echo ${LINUX_PASSWORD} | sudo -S bash -c \
    "./scripts/genconfig.sh ${ENV_FILE} init/iam-pump.service > /etc/systemd/system/iam-pump.service"

  # 4. 启动 iam-pump 服务
  iam::common::sudo "systemctl daemon-reload"
  iam::common::sudo "systemctl restart iam-pump"
  iam::common::sudo "systemctl enable iam-pump"
  iam::pump::status || return 1
  iam::pump::info

  iam::log::info "install iam-pump successfully"
  popd
}

# 卸载
function iam::pump::uninstall()
{
  set +o errexit
  iam::common::sudo "systemctl stop iam-pump"
  iam::common::sudo "systemctl disable iam-pump"
  iam::common::sudo "rm -f ${IAM_INSTALL_DIR}/bin/iam-pump"
  iam::common::sudo "rm -f ${IAM_CONFIG_DIR}/iam-pump.yaml"
  iam::common::sudo "rm -f /etc/systemd/system/iam-pump.service"
  set -o errexit
  iam::log::info "uninstall iam-pump successfully"
}

# 状态检�?function iam::pump::status()
{
  # 查看 iam-pump 运行状态，如果输出中包�?active (running) 字样说明 iam-pump 成功启动�?  systemctl status iam-pump|grep -q 'active' || {
    iam::log::error "iam-pump failed to start, maybe not installed properly"
    return 1
  }

  # 监听端口在配置文件中�?hardcode
  if echo | telnet 127.0.0.1 7070 2>&1|grep refused &>/dev/null;then
    iam::log::error "cannot access health check port, iam-pump maybe not startup"
    return 1
  fi
}

if [[ "$*" =~ iam::pump:: ]];then
  eval $*
fi
