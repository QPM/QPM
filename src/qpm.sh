##############################################################################
#
# $Id: qbuild $
#
# This script is used to build QPKGs.
#
##############################################################################

IFS=" "

#---
# Default Configs
#---
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
QPM_QPKG_CORE="/sbin/qpkg"
QPM_QPKG_TEMPLATE="template"

QPM_QPKG_NAME_MAX=20
QPM_QPKG_VER_MAX=10


#---
# Message
#---

# Error messages
err_msg(){
  echo "[ERROR] $1" 1>&1
  echo "[x] 任務失敗"
  rm -rf build.$$ &>/dev/null
  rm -rf tmp.$$ &>/dev/null
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

#---
# Library
#---

edit_config(){
  local field="$1"
  local value="\"$2\""
  local qpkg_cfg="${3:-$QPM_QPKG_CONFIGS}"
  if [ -n "$field" ] && [ -n "$value" ] && [ -f "$qpkg_cfg" ]; then
    local space=$(awk 'BEGIN{i=0;while(i++<'$(expr 48 - ${#field} - ${#value} - 1)')printf " "}')
    value=$(echo ${value} | sed 's/\//\\\//g')
    sed "s/${field}=[^#]*/${field}=${value}${space}/" $qpkg_cfg > $qpkg_cfg.$$
    rm -f $qpkg_cfg
    mv -f $qpkg_cfg.$$ $qpkg_cfg
  else
    return 1
  fi
}

#---
# Main
#---

# Help messages
help(){
  cat <<EOF
Usage: $(/usr/bin/basename $0) [options] [--create NAME]
Options:
  --create, -c NAME       建立一個package目錄
  -?, -h, --help          顯示操作訊息
  -V, -ver, --version     列出qbuild的版本資訊.
  -nas                    設定QNAP的NAS IP.
  ---push-key             上傳SSH公開金鑰至NAS.
EOF
  exit 0
}

# Create directory with template build environment
create_qpkg(){

  [ -n "$1" ] || err_msg "internal error: create called with no argument"
  local qpkg_name="$1"

  [ -d "$qpkg_name" ] && err_msg "$(pwd)/${qpkg_name} 已經存在"

  echo "建立 $qpkg_name 目錄..."
  mkdir -m 755 -p "${qpkg_name}" || err_msg "${qpkg_name}: 主目錄建立失敗"
  local qpm_len=$(sed -n "2s/ */ /p" ${0} | awk -F ' ' '{print $5}')
  dd if=${0} bs=${qpm_len} skip=1 | tar -xz -C ${qpkg_name} || exit 1
  mv ${qpkg_name}/${QPM_QPKG_TEMPLATE}/* ${qpkg_name}
  rm -rf ${qpkg_name}/${QPM_QPKG_TEMPLATE}

  echo "初始化 QPKG設定檔..."

  local configs_path="${qpkg_name}/${QPM_QPKG_CONFIGS}"

  edit_config "QPKG_NAME" "${qpkg_name}" "${configs_path}"
  edit_config "QPKG_DISPLAY_NAME" "${qpkg_name}" "${configs_path}"
  edit_config "QPKG_AUTHOR" "$(/usr/bin/whoami)" "${configs_path}"
  edit_config "#QPKG_DIR_ICONS" "${QPM_DIR_ICONS}" "${configs_path}"
  edit_config "#QPKG_DIR_ARM" "${QPM_DIR_ARM}" "${configs_path}"
  edit_config "#QPKG_DIR_X86" "${QPM_DIR_X86}" "${configs_path}"
  edit_config "#QPKG_DIR_WEB" "${QPM_DIR_WEB}" "${configs_path}"
  edit_config "#QPKG_DIR_BIN" "${QPM_DIR_BIN}" "${configs_path}"
  edit_config "#QPKG_DIR_SHARE" "${QPM_DIR_SHARE}" "${configs_path}"

  echo "[v] package初始化完成"
}

pad_field(){
  [ -n "$1" ] || err_msg "internal error: pad_field called with no argument"

  local field="$1"
  local field_val=
  eval "field_val=\$$field"
  local pad_len=$(expr ${2:-10} - ${#field_val})

  [ $pad_len -ge 0 ] || err_msg "the length of $field_val must be less than or equal to ${2:-10}"
  while [ $pad_len -gt 0 ]
  do
    field_val="$field_val "
    pad_len=$(expr $pad_len - 1)
  done
  eval $field=\""$field_val"\"
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
  [ ${#QPKG_NAME} -gt ${QPM_QPKG_NAME_MAX} ] && err_msg "QPKG的NAME不可以超過${QPM_QPKG_NAME_MAX}個字元"
  [ ${#QPM_QPKG_VER} -gt ${QPM_QPKG_VER_MAX} ] && err_msg "QPKG的VERSION不可以超過${QPM_QPKG_VER_MAX}個字元"

  # Build
  msg "編譯QPKG..."

  rm -rf build.$$
  mkdir -m 755 -p build.$$ || err_msg "無法建立暫存目錄 ${build.$$}"
  mkdir -m 755 -p tmp.$$ || err_msg "無法建立暫存目錄 ${tmp.$$}"

  local script_len=$(sed -n "2s/ */ /p" ${0} | awk -F ' ' '{print $4}')
  local qpm_len=$(sed -n "2s/ */ /p" ${0} | awk -F ' ' '{print $5}')
  qpm_len=$(expr ${qpm_len} - ${script_len})
  dd if=${0} bs=${script_len} skip=1 | tar -xz -C tmp.$$ || exit 1


  local config_file="build.$$/${QPM_QPKG_CONFIGS}"
  cp -afp ${QPM_QPKG_CONFIGS} ${config_file} || err_msg 找不到configs檔
  printf "\n" >> ${config_file}
  cat "tmp.$$/qpm_qpkg.cfg" >> ${config_file}
  edit_config "QPM_QPKG_VER" "${QPM_QPKG_VER}" ${config_file}
  edit_config "QPKG_WEB_PATH" "$(echo ${QPKG_WEB_PATH} | sed 's/^\///g')" ${config_file}
  edit_config "QPM_QPKG_PLATFORM" "${1}" ${config_file}
  sed '/^$/d' ${config_file} > "tmp.$$/${QPM_QPKG_CONFIGS}"
  sed 's/# .*//g' "tmp.$$/${QPM_QPKG_CONFIGS}" | sed '/^#.*/d' > ${config_file}
  local data="${QPM_QPKG_CONFIGS}"

  local service_file="build.$$/${QPM_QPKG_SERVICE}"
  cat tmp.$$/qpm_service_pre.sh > ${service_file}
  printf "\n" >> ${service_file}
  cat ${QPM_QPKG_SERVICE} >> ${service_file} || err_msg 找不到service檔
  printf "\n" >> ${service_file}
  cat tmp.$$/qpm_service_post.sh >> ${service_file}
  data+=" ${QPM_QPKG_SERVICE}"

  cat tmp.$$/${QPM_QPKG_INSTALL} > "build.$$/${QPM_QPKG_INSTALL}"
  data+=" ${QPM_QPKG_INSTALL}"
  cat tmp.$$/${QPM_QPKG_UNINSTALL} > "build.$$/${QPM_QPKG_UNINSTALL}"
  data+=" ${QPM_QPKG_UNINSTALL}"

  cp -af ${QPKG_DIR_ICONS:-${QPM_DIR_ICONS}} build.$$/${QPM_DIR_ICONS} || warn_msg 找不到icon目錄
  data+=" ${QPM_DIR_ICONS}"
  cp -af ${QPKG_DIR_SHARE:-${QPM_DIR_SHARE}} build.$$/${QPM_DIR_SHARE} || warn_msg 找不到share目錄
  data+=" ${QPM_DIR_SHARE}"

  if [ "${1}" = "arm" ] || [ -z "${1}" ]; then
    cp -af ${QPKG_DIR_ARM:-${QPM_DIR_ARM}} build.$$/${QPM_DIR_ARM} || warn_msg 找不到arm目錄
    data+=" ${QPM_DIR_ARM}"
  fi
  if [ "${1}" = "x86" ] || [ -z "${1}" ]; then
    cp -af ${QPKG_DIR_X86:-${QPM_DIR_X86}} build.$$/${QPM_DIR_X86} || warn_msg 找不到x86目錄
    data+=" ${QPM_DIR_X86}"
  fi

  tar -zcpf "tmp.$$/${QPM_QPKG_DATA}" -C "build.$$" ${data}
  rm -rf build.$$

  mkdir -m 755 -p ${QPM_DIR_BUILD} || err_msg "無法建立編譯目錄"

  if [ -n "${1}" ]; then
    local qpkg_file_name=${QPKG_FILE:-${QPKG_NAME}_${QPM_QPKG_VER}_${1}.qpkg}
  else
    local qpkg_file_name=${QPKG_FILE:-${QPKG_NAME}_${QPM_QPKG_VER}.qpkg}
  fi
  local qpkg_file_path=${QPM_DIR_BUILD}/${qpkg_file_name}
  rm -f "${qpkg_file_path}"
  touch "${qpkg_file_path}" || err_msg "建立package失敗 ${qpkg_file_path}"

  printf "\n" >> tmp.$$/${QPM_QPKG_SCRIPT}
  local script_len=$(ls -l tmp.$$/${QPM_QPKG_SCRIPT} | awk '{ print $5 }')
  sed "s/EXTRACT_SCRIPT_LEN=000/EXTRACT_SCRIPT_LEN=${script_len}/" tmp.$$/$QPM_QPKG_SCRIPT > ${qpkg_file_path}

  #dd if=tmp.$$/$QPM_QPKG_DATA of="${QPM_QPKG_BUILD}/${qpkg_file_path}"
  cat tmp.$$/$QPM_QPKG_DATA >> ${qpkg_file_path}

  rm -rf tmp.$$

  ######
  # [MODEL(10)|RESERVED(40])|FW_VERSION(10)|NAME(20)|VERSION(10)|FLAG(10)]
  local enc_space=$(awk 'BEGIN{i=0;while(i++<60)printf " "}')
  local enc_flag="QNAPQPKG  "
  local enc_qpkg_name="${QPKG_NAME}$(awk 'BEGIN{i=0;while(i++<'$(expr 20 - ${#QPKG_NAME})')printf " "}')"
  local enc_qpkg_ver="${QPM_QPKG_VER}$(awk 'BEGIN{i=0;while(i++<'$(expr 10 - ${#QPM_QPKG_VER})')printf " "}')"
  printf "${enc_space}${enc_qpkg_name}${enc_qpkg_ver}${enc_flag}" >> ${qpkg_file_path}
  ######

  [ -z "${avg_no_version}" ] && edit_config "QPKG_VER_BUILD" "$(expr ${QPKG_VER_BUILD} + 1)"

  echo "建立${qpkg_file_path}..."

  if [ -x "${QPM_QPKG_CORE}" ]; then
    echo "認證QPKG..."
    ${QPM_QPKG_CORE} --encrypt ${qpkg_file_path}
  else
    echo "傳送至${avg_host}認證QPKG..."
    local nas_qpkg="/share/Public/${qpkg_file_name}"
    scp ${qpkg_file_path} "admin@${avg_host}:${nas_qpkg}"
    ssh admin@${avg_host} "${QPM_QPKG_CORE} --encrypt ${nas_qpkg}" >/dev/null
    scp "admin@${avg_host}:${nas_qpkg}" ${qpkg_file_path}
    ssh admin@${avg_host} "rm -f ${nas_qpkg}" >/dev/null
  fi

  echo "[v] package編譯完成"
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
    -n|--nas) avg_host=$(echo "$1" | sed 's/^-[^=]*=//g') ;;
    --push-key) avg_push_key=TRUE ;;
    -nv|--no-version) avg_no_version=TRUE ;;
    -ps|--platform-split) avg_platform_split=TRUE ;;
    -p|--platform) avg_platform=$(echo "$1" | sed 's/^-[^=]*=//g') ;;
    esac
    shift
  done

  [ -n "${avg_version}" ] && version
  [ -n "${avg_help}" ] && help

  if [ -n "$avg_qpkg_name" ]; then
    [ ${#avg_qpkg_name} -gt ${QPM_QPKG_NAME_MAX} ] && err_msg "QPKG的NAME不可以超過${QPM_QPKG_NAME_MAX}個字元"
    create_qpkg "$avg_qpkg_name"
  elif [ -n "$avg_push_key" ]; then
    local id_rsa_client="$HOME/.ssh/id_rsa.pub"
    local id_rsa_server="\$HOME/.ssh/id_rsa_$(/usr/bin/whoami).pub"
    if [ ! -e "${id_rsa_client}" ]; then
      echo "系統將為您建立公開金鑰，請依照步驟按下[ENTER]鍵"
      sleep 3
      ssh-keygen -t rsa
    fi
    while [ -z "$avg_host" ]; do
      printf "請輸入要配置的NAS IP:"
      read avg_host
      echo "連線至${avg_host}..."
      ping -c 1 ${avg_host} &> /dev/null
      if [ $? -ne 0 ]; then
        avg_host=""
        printf "IP有誤，"
      fi
    done
    scp "${id_rsa_client}" "admin@${avg_host}:${id_rsa_server}"
    ssh "admin@${avg_host}" "cat ${id_rsa_server} >> .ssh/authorized_keys"
  else
    if [ ! -x "${QPM_QPKG_CORE}" ] && [ -z "$avg_host" ]; then
      while [ -z "$avg_host" ]; do
        printf "請輸入用來編譯的NAS IP:"
        read avg_host
        echo "檢測${avg_host}..."
        ping -c 1 ${avg_host} &> /dev/null
        if [ $? -ne 0 ]; then
          avg_host=""
          printf "IP有誤，"
        fi
      done
      echo "提醒您，可使用[--nas]參數輸入NAS IP"
    fi
    if [ -n "${avg_platform_split}" ]; then
      no_version=avg_no_version
      avg_no_version=TRUE
      build_qpkg "x86" # 2>/dev/null
      build_qpkg "arm" # 2>/dev/null
      [ -z "${no_version}" ] && edit_config "QPKG_VER_BUILD" "$(expr ${QPKG_VER_BUILD} + 1)"
    elif [ -n "${avg_platform}" ]; then
      if [ "${avg_platform}" != "x86" ] && [ "${avg_platform}" != "arm" ]; then
        err_msg "目前platform只支援x86或arm兩種"
      fi
      build_qpkg "${avg_platform}" # 2>/dev/null
    else
      build_qpkg # 2>/dev/null
    fi
  fi
}

main "$@"
exit 1