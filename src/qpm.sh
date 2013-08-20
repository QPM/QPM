#!/bin/sh
##############################################################################
#
# $Id: qbuild $
#
# This script is used to build QPKGs.
#
##############################################################################

#! uninstall need SYS_QPKG_DIR
#! 了解 md5sum 的用途

#===
# Default Configs
#===
QPM_QPKG_VER=""

QPM_DIR_ICONS="icon"
QPM_DIR_ARM="arm"
QPM_DIR_X86="x86"
QPM_DIR_SHARE="share"
QPM_DIR_WEB="web"
QPM_DIR_BIN="bin"
QPM_DIR_BUILD="build"

QPM_QPKG_CONFIGS="qpkg.cfg"
QPM_QPKG_SERVICE="service.sh"
QPM_QPKG_SERVICE_ID=101
QPM_QPKG_DATA="data.tar.gz"
QPM_QPKG_SCRIPT="script.sh"
QPM_QPKG_INSTALL="install.sh"
QPM_QPKG_UNINSTALL="uninstall.sh"
QPM_QPKG_WEB_CONFIG="apache-qpkg-${QPKG_NAME}.conf"
QPM_QPKG_BIN_LOG=".bin_log"

#===
# Message
#===

# Error messages
err_msg(){
  echo "[ERROR] $1" 1>&1
  echo "[x] 任務失敗"
  rm -rf build.$$
  rm -rf tmp.$$
  exit 0
}

warn_msg(){
  echo "[WARN] $1" 1>&1
}

msg(){
  echo "$1" 1>&1
}

debug_msg(){
  #msg "$1" $DEBUG
  return 0
}

#===
# Library
#===

edit_config(){
  local field="$1"
  local value="$2"
  local qpkg_cfg="${3:-$QPM_QPKG_CONFIGS}"
  if [ -n "$field" ] && [ -n "$value" ] && [ -f "$qpkg_cfg" ]; then
    local space=$(perl -E 'say " " x '$(expr 48 - ${#field} - ${#value} - 1))
    value=$(echo ${value} | sed 's/\//\\\//g')
    sed "s/${field}=[^#]*/${field}=${value}${space}/" $qpkg_cfg > $qpkg_cfg.$$
    rm -f $qpkg_cfg
    mv -f $qpkg_cfg.$$ $qpkg_cfg
  else
    return 1
  fi
}

fetch_shell(){
  local start=$(grep -n "^###${1} START" ${0} |  awk -F "[/:]" '{print $1}')
  start=$(expr ${start} + 1)

  local end=$(grep -n "^###${1} END" ${0} |  awk -F "[/:]" '{print $1}')
  end=$(expr ${end} - 1)

  sed -n "${start},${end}p" ${0}

  return 0
}

#===
# Main
#===

# Help messages
help(){
  cat <<EOF
Usage: $(/usr/bin/basename $0) [options] [--create NAME]
Options:
  --create, -c NAME       建立一個package目錄
  -?, -h, --help          顯示操作訊息
  -V, -ver, --version     列出qbuild的版本資訊.
EOF
  exit 0
}

# Create directory with template build environment
create_qpkg(){
  [ -n "$1" ] || err_msg "internal error: create called with no argument"
  local qpkg_name="$1"

  [ -d "$qpkg_name" ] && err_msg "$(pwd)/${qpkg_name} 已經存在"

  echo "建立 $qpkg_name 目錄..."
  /bin/mkdir -m 755 -p "${qpkg_name}" || err_msg "${qpkg_name}: 主目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_ICONS}" || err_msg "${qpkg_name}: Icon目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_ARM}" || err_msg "${qpkg_name}: ARM目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_X86}" || err_msg "${qpkg_name}: X86目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_SHARE}" || err_msg "${qpkg_name}: Share目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_SHARE}/${QPM_DIR_WEB}" || err_msg "${qpkg_name}: Web目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_SHARE}/${QPM_DIR_BIN}" || err_msg "${qpkg_name}: Bin目錄建立失敗"
  /bin/mkdir -m 755 -p "${qpkg_name}/${QPM_DIR_BUILD}" || err_msg "${qpkg_name}: Build目錄建立失敗"

  fetch_shell "QPM_ICONS_64" > "${qpkg_name}/${QPM_DIR_ICONS}/qpkg_icon.png"
  fetch_shell "QPM_ICONS_64_GRAY" > "${qpkg_name}/${QPM_DIR_ICONS}/qpkg_icon_gray.png"
  fetch_shell "QPM_ICONS_80" > "${qpkg_name}/${QPM_DIR_ICONS}/qpkg_icon_80.png"

  echo "初始化 QPKG設定檔..."

  local configs_path="${qpkg_name}/${QPM_QPKG_CONFIGS}"
  fetch_shell "QPM_QPKG_CONFIGS" > $configs_path

  edit_config "QPKG_NAME" \"${qpkg_name}\" ${configs_path}
  edit_config "QPKG_DISPLAY_NAME" \"${qpkg_name}\" ${configs_path}
  edit_config "QPKG_AUTHOR" \"$(/usr/bin/whoami)\" ${configs_path}
  edit_config "#QPKG_DIR_ICONS" \"${QPM_DIR_ICONS}\" ${configs_path}
  edit_config "#QPKG_DIR_ARM" \"${QPM_DIR_ARM}\" ${configs_path}
  edit_config "#QPKG_DIR_X86" \"${QPM_DIR_X86}\" ${configs_path}
  edit_config "#QPKG_DIR_WEB" \"${QPM_DIR_WEB}\" ${configs_path}
  edit_config "#QPKG_DIR_BIN" \"${QPM_DIR_BIN}\" ${configs_path}
  edit_config "#QPKG_DIR_SHARE" \"${QPM_DIR_SHARE}\" ${configs_path}

  fetch_shell "QPM_QPKG_SERVICE" > "${qpkg_name}/${QPM_QPKG_SERVICE}"

  edit_config "QPKG_NAME" ${qpkg_name} "${qpkg_name}/${QPM_QPKG_SERVICE}"

  echo "[v] package初始化完成"
}

build_qpkg(){
  # Fetch configs
  msg "取得QPKG設定值..."
  source $QPM_QPKG_CONFIGS

  QPM_QPKG_VER="${QPKG_VER_MAJOR}.${QPKG_VER_MINOR}.${QPKG_VER_BUILD}"
  QPM_QPKG_VER=${QPM_QPKG_VER:-0.1.0}
  
  # Check
  msg "檢查編譯環境..."
  [ -n "$QPKG_AUTHOR" ] || err_msg "$QPM_QPKG_CONFIGS: QPKG_AUTHOR 必須設定值"
  [ -n "$QPKG_NAME" ] || err_msg "$QPM_QPKG_CONFIGS: QPKG_NAME 必須設定值"

  # Build
  msg "編譯QPKG..."

  rm -rf build.$$
  mkdir -m 755 -p build.$$ || err_msg "無法建立暫存目錄 ${build.$$}"

  cp -afp ${QPM_QPKG_CONFIGS} "build.$$/${QPM_QPKG_CONFIGS}" || err_msg 找不到configs檔
  fetch_shell "QPM_QPKG_QPM_CONFIGS" >> "build.$$/${QPM_QPKG_CONFIGS}"
  edit_config "QPM_QPKG_VER" \"${QPM_QPKG_VER}\" "build.$$/${QPM_QPKG_CONFIGS}"

  local service_file="build.$$/${QPM_QPKG_SERVICE}"
  fetch_shell "QPM_QPKG_QPM_SERVICE_START" > ${service_file}
  cat ${QPM_QPKG_SERVICE} >> ${service_file} || err_msg 找不到service檔
  fetch_shell "QPM_QPKG_QPM_SERVICE_END" >> ${service_file}

  cp -af ${QPKG_DIR_ICONS:-${QPM_DIR_ICONS}} build.$$/${QPM_DIR_ICONS} || warn_msg 找不到icon目錄
  cp -af ${QPKG_DIR_ARM:-${QPM_DIR_ARM}} build.$$/${QPM_DIR_ARM} || warn_msg 找不到icon目錄
  cp -af ${QPKG_DIR_X86:-${QPM_DIR_X86}} build.$$/${QPM_DIR_X86} || warn_msg 找不到x86目錄
  cp -af ${QPKG_DIR_SHARE:-${QPM_DIR_SHARE}} build.$$/${QPM_DIR_SHARE} || warn_msg 找不到shared目錄

  fetch_shell "QPM_QPKG_INSTALL" > "build.$$/${QPM_QPKG_INSTALL}"
  fetch_shell "QPM_QPKG_UNINSTALL" > "build.$$/${QPM_QPKG_UNINSTALL}"

  mkdir -m 755 -p tmp.$$ || err_msg "無法建立暫存目錄 ${tmp.$$}"

  tar -zcpf "tmp.$$/${QPM_QPKG_DATA}" -C "build.$$" ${QPM_QPKG_SERVICE} ${QPM_DIR_ICONS} ${QPM_DIR_ARM} ${QPM_DIR_X86} ${QPM_DIR_SHARE} ${QPM_QPKG_INSTALL} ${QPM_QPKG_UNINSTALL} ${QPM_QPKG_CONFIGS}
  rm -rf build.$$

  mkdir -m 755 -p ${QPM_DIR_BUILD} || err_msg "無法建立編譯目錄"

  QPKG_FILE_NAME=${QPKG_FILE:-${QPKG_NAME}_${QPM_QPKG_VER}.qpkg}
  QPKG_FILE_PATH=${QPM_DIR_BUILD}/${QPKG_FILE_NAME}
  rm -f "${QPKG_FILE_PATH}"
  touch "${QPKG_FILE_PATH}" || err_msg "建立package失敗 ${QPKG_FILE_PATH}"

  fetch_shell "QPM_QPKG_SCRIPT" > tmp.$$/$QPM_QPKG_SCRIPT

  local script_len=$(ls -l tmp.$$/${QPM_QPKG_SCRIPT} | awk '{ print $5 }')
  sed "s/EXTRACT_SCRIPT_LEN=000/EXTRACT_SCRIPT_LEN=${script_len}/" tmp.$$/$QPM_QPKG_SCRIPT > ${QPKG_FILE_PATH}

  #dd if=tmp.$$/$QPM_QPKG_DATA of="${QPM_QPKG_BUILD}/${QPKG_FILE_PATH}"
  cat tmp.$$/$QPM_QPKG_DATA >> ${QPKG_FILE_PATH}

  rm -rf tmp.$$

  edit_config "QPKG_VER_BUILD" $(expr ${QPKG_VER_BUILD} + 1)

  echo "建立${QPKG_FILE_PATH}..."

  echo "[v] package編譯完成"

  if [ -n "${avg_upload}" ]; then
    echo "upload to ...${avg_upload}"
    scp ${QPKG_FILE_PATH} "${avg_upload}"
  fi
}

# Main
main(){
  while  [ $# -gt 0 ]
  do
    case $(echo "$1" | awk -F"=" '{ print $1 }') in
    --help|-h|-\?)  avg_help=TRUE ;;
    --version|-ver|-V) avg_version=TRUE ;;
    --create|-c) avg_qpkg_name="$2"
        [ -n "$avg_qpkg_name" ] || err_msg "--create, -c: 沒有package名稱"
        shift
        ;;
    --upload)
        avg_upload=$(echo "$1" | sed 's/--upload=//g')
        ;;
    esac
    shift
  done

  [ -n "$avg_version" ] && version
  [ -n "$avg_help" ] && help

  echo ${avg_upload}

  if [ -n "$avg_qpkg_name" ]; then 
    create_qpkg "$avg_qpkg_name"
  else
    build_qpkg # 2>/dev/null
  fi
}

main "$@"
exit 1