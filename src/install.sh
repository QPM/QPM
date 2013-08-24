#!/bin/sh

IFS=" "

#---
# QPKG definitions
#---
source "$( cd "$( dirname "${0}" )" && pwd )/qpkg.cfg"
SYS_QPKG_TMP=$( cd "$( dirname "${0}" )" && pwd )

#---
# System messages
#---
SYS_MSG_BASE_NOT_FOUND="Base folder not found."

#---
# Inform web interface about progress
#---
set_progress(){
  $CMD_ECHO ${1:--1} > /tmp/update_process
}
set_progress_begin(){
  set_progress 0
}
set_progress_before_install(){
  set_progress 1
}
set_progress_after_install(){
  set_progress 2
}
set_progress_end(){
  set_progress 3
}
set_progress_fail(){
  set_progress -1
}

#---
# Log
#---
log() {
  local write_msg="$CMD_LOG_TOOL -t0 -uSystem -p127.0.0.1 -mlocalhost -a"
  [ -n "$1" ] && $CMD_ECHO "$1" && $write_msg "$1"
}

warn_log() {
  local write_warn="$CMD_LOG_TOOL -t1 -uSystem -p127.0.0.1 -mlocalhost -a"
  [ -n "$1" ] && $CMD_ECHO "$1" 1>&2 && $write_warn "$1"
}

err_log(){
  local write_err="$CMD_LOG_TOOL -t2 -uSystem -p127.0.0.1 -mlocalhost -a"
  local message="$QPKG_NAME $QPM_QPKG_VER installation failed. $1"
  $CMD_ECHO "$message" 1>&2
  $write_err "$message"

  set_progress_fail
  exit 1
}

#---
# library
#---

# edit qpkg.cfg
edit_config(){
  local field="$1"
  local value="$2"
  local qpkg_cfg="${3:-$QPM_QPKG_CONFIGS}"
  if [ -n "$field" ] && [ -n "$value" ] && [ -f "$qpkg_cfg" ]; then
    local space=$($CMD_AWK 'BEGIN{i=0;while(i++<'$(expr 48 - ${#field} - ${#value} - 1)')printf " "}')
    value=$($CMD_ECHO ${value} | $CMD_SED 's/\//\\\//g')
    $CMD_SED -i "s/${field}=[^#]*/${field}=${value}${space}/" ${qpkg_cfg}
  else
    return 1
  fi
}

#---
# compare version (=:0 >:1 <:2)
#---
compare_version(){
  for (( i=1; i<=3; i=i+1 )); do
    local left=$($CMD_ECHO "${1}" | $CMD_AWK -F '.' '{print $'$i'}')
    local right=$($CMD_ECHO "${2}" | $CMD_AWK -F '.' '{print $'$i'}')
    if [ "${left}" != "${right}" ]; then
      left=$($CMD_ECHO "${left}" | $CMD_SED 's/\([0-9]*\)\(.*\)/0\1/')
      right=$($CMD_ECHO "${right}" | $CMD_SED 's/\([0-9]*\)\(.*\)/0\1/')
      if [ ${left} -gt ${right} ]; then
        return 1
      elif [ ${left} -lt ${right} ]; then
        return 2
      fi
    fi
  done

  return 0
}

#---
# check installed
#---
pre_install_check_qpkg_installed(){
  for qpkg in $($CMD_ECHO ${1} | $CMD_SED 's/ //g' | $CMD_TR '|' ' '); do
    qpkg=$($CMD_ECHO "$qpkg" | $CMD_SED 's/\(.*[^=<>!]\)\([=<>!]\+\)\(.*\)/\1 \2 \3/')
    qpkg_name=$($CMD_ECHO "$qpkg" | $CMD_AWK '{print $1}')
    qpkg_op=$($CMD_ECHO "$qpkg" | $CMD_AWK '{print $2}')
    qpkg_ver=$($CMD_ECHO "$qpkg" | $CMD_AWK '{print $3}')
    local installed = $(get_qpkg_cfg "${SYS_QPKG_CFG_VERSION}" "" "${qpkg_name}")
    if [ -n "${installed}" ]; then
      if [ -z "${qpkg_ver}" ]; then
        return 0
      else
        compare_version "${installed}" "${qpkg_ver}"
        local result=$?
        case "$op" in
        =|==)
          [ ${result} -eq 0 ] && return 0 ;;
        !=)
          [ ${result} -ne 0 ] && return 0 ;;
        \>=|=\>)
          ([ ${result} -ne 1 ] || [ ${result} -eq 0 ]) && return 0 ;;
        \<=|=\>)
          ([ ${result} -ne 2 ] || [ ${result} -eq 0 ]) && return 0 ;;
        \>)
          [ ${result} -ne 1 ] && return 0 ;;
        \<)
          [ ${result} -ne 2 ] && return 0 ;;
        esac
      fi
    fi
  done

  return 1
}

#---
# check requirements
#---
pre_install_check_requirements(){
  local install_msg=
  local remove_msg=
  local err_msg=
  if [ -n "$QPKG_REQUIRE" ]; then
    QPKG_REQUIRE=$($CMD_ECHO "${QPKG_REQUIRE}" | $CMD_SED 's/ //g' | $CMD_TR ',' ' ')
    for item in ${QPKG_REQUIRE}; do
      pre_install_check_qpkg_installed "${item}"
      [ $? -ne 0 ] && "${install_msg}${install_msg:+, }${item## }"
    done
  fi
  if [ -n "$QPKG_CONFLICT" ]; then
    QPKG_CONFLICT=$($CMD_ECHO "${QPKG_CONFLICT}" | $CMD_SED 's/ //g' | $CMD_TR ',' ' ')
    for item in $QPKG_REQUIRE; do
      pre_install_check_qpkg_installed "${item}"
      [ $? -ne 1 ] && "${remove_msg}${remove_msg:+, }${item## }"
    done
  fi
  [ -n "$install_msg" ] && err_msg="${err_msg}The following QPKG must be installed and enabled: ${install_msg}. "
  [ -n "$remove_msg" ] && err_msg="${err_msg}The following QPKG must be removed: ${remove_msg}. "
  [ -n "$err_msg" ] && err_log "${err_msg}"
}

#---
# get system information
#---
pre_install_get_sys_info(){
  if [ $(expr match "$(/bin/uname -m)" 'arm') -ne 0 ]; then
    SYS_PLATFORM="arm"
  else
    SYS_PLATFORM="x86"
  fi;
  if [ -n "${QPM_QPKG_PLATFORM}" ] && [ "${QPM_QPKG_PLATFORM}" != "${SYS_PLATFORM}" ]; then
    err_log "The QPKG file install ${QPM_QPKG_PLATFORM} only."
  fi
  edit_config "SYS_PLATFORM" \"${SYS_PLATFORM}\"

  msg "get system platform" ${SYS_PLATFORM}
}

#---
# get base dir
#---
pre_install_get_base_dir_from(){
  [ -n "$1" ] && [ -n "$2" ] || return 1
  local sys_base=""
  local sys_share=$($CMD_GETCFG SHARE_DEF ${1} -d ${2} -f ${SYS_CONFIG_DIR}/def_share.info)
  local sys_dir=$($CMD_GETCFG ${sys_share} path -f ${SYS_CONFIG_DIR}/smb.conf)
  [ -d ${sys_dir} ] && sys_base=$($CMD_ECHO ${sys_dir} | $CMD_AWK -F'/' '{print "/"$2"/"$3}')
  
  if [ -z ${sys_base} ] || [ ${sys_base} = '//' ]; then
    for dirtest in /share/HDA_DATA /share/HDB_DATA /share/HDC_DATA \
           /share/HDD_DATA /share/HDE_DATA /share/HDF_DATA \
           /share/HDG_DATA /share/HDH_DATA /share/MD0_DATA \
           /share/MD1_DATA /share/MD2_DATA /share/MD3_DATA
    do
      [ -d "$dirtest/${sys_share}" ] && sys_base="$dirtest"
    done
  fi

  echo ${sys_base}
}

#---
# get base dir & qpkg dir
#---
pre_install_get_base_dir(){
  if [ -d $(pre_install_get_base_dir_from defPublic Public) ]; then
    SYS_BASE_DIR=$(pre_install_get_base_dir_from defPublic Public)
  elif [ -d $(pre_install_get_base_dir_from defDownload Qdownload) ]; then
    SYS_BASE_DIR=$(pre_install_get_base_dir_from defDownload Qdownload)
  elif [ -d $(pre_install_get_base_dir_from defMultimedia Qmultimedia) ]; then
    SYS_BASE_DIR=$(pre_install_get_base_dir_from defMultimedia Qmultimedia)
  elif [ -d $(pre_install_get_base_dir_from defWeb Qweb) ]; then
    SYS_BASE_DIR=$(pre_install_get_base_dir_from defWeb Qweb)
  else
    err_log "$SYS_MSG_BASE_NOT_FOUND"
  fi

  SYS_QPKG_STORE="${SYS_BASE_DIR}/.qpkg"
  SYS_QPKG_DIR="${SYS_QPKG_STORE}/${QPKG_NAME}"

  edit_config "SYS_BASE_DIR" \"${SYS_BASE_DIR}\"
  edit_config "SYS_QPKG_STORE" \"${SYS_QPKG_STORE}\"
  edit_config "SYS_QPKG_DIR" \"${SYS_QPKG_DIR}\"
  
  msg "get system base dir" ${SYS_BASE_DIR}
  msg "get ${QPKG_NAME} qpkg dir" ${SYS_QPKG_DIR}
}

#---
# check whether is already installed
#---
pre_check_qpkg_status(){
  local ori_qpkg_ver=$(get_qpkg_cfg ${SYS_QPKG_CFG_VERSION} "not installed")
  msg "original ${QPKG_NAME} version" "${ori_qpkg_ver}"
  msg "new ${QPKG_NAME} version" ${QPM_QPKG_VER}
  if [ "${ori_qpkg_ver}" = "not installed" ]; then
    msg "setup will now perform" "installing"
  elif [ "${ori_qpkg_ver}" = "${QPM_QPKG_VER}" ]; then
    msg "setup will now perform" "reinstalling"
  else
    msg "setup will now perform" "upgrading"
  fi
  $CMD_MKDIR -p $SYS_QPKG_DIR
}

#---
# stop service
#---
pre_install_stop_service(){
  local service=$(get_qpkg_cfg "$SYS_QPKG_CFG_SHELL" "${SYS_INIT_DIR}/${QPKG_NAME}")
  if [ -x "${service}" ]; then
    msg "stop original ${QPKG_NAME} service"
    ${service} stop &>/dev/null
    $CMD_SLEEP 5
    $CMD_SYNC
    $CMD_PRINTF "[v]\n"
  fi
}

#---
# put data
#---
install_put_data(){
  msg "put QPKG data"
  $CMD_CP -arf "${SYS_QPKG_TMP}/${QPM_DIR_SHARE}/"* "${SYS_QPKG_DIR}/"
  if [ "${SYS_PLATFORM}" = 'arm' ]; then
    $CMD_CP -arf "${SYS_QPKG_TMP}/${QPM_DIR_ARM}/"* "${SYS_QPKG_DIR}/" 
  else
    $CMD_CP -arf "${SYS_QPKG_TMP}/${QPM_DIR_X86}/"* "${SYS_QPKG_DIR}/"
  fi;
  $CMD_PRINTF "[v]\n"
}

#---
# put script
#---
install_put_script(){
  # put configs
  msg "put QPKG configs" "${QPM_QPKG_CONFIGS}"
  $CMD_CP -af ${QPM_QPKG_CONFIGS} "${SYS_QPKG_DIR}/.${QPM_QPKG_CONFIGS}"
  # put service script
  msg "put QPKG service script" "${QPM_QPKG_SERVICE}"
  $CMD_CP -af ${QPM_QPKG_SERVICE} "${SYS_QPKG_DIR}/.${QPM_QPKG_SERVICE}"
  # put uninstall script
  msg "put QPKG uninstall script" "${QPM_QPKG_UNINSTALL}"
  $CMD_CP -af ${QPM_QPKG_UNINSTALL} "${SYS_QPKG_DIR}/.${QPM_QPKG_UNINSTALL}"
}

#---
# put icons
#---
install_put_icons(){
  msg "put QPKG icon"
  $CMD_CP -af "${QPM_DIR_ICONS}/qpkg_icon.png" "${SYS_QPKG_DIR}/.qpkg_icon.png"
  $CMD_CP -af "${QPM_DIR_ICONS}/qpkg_icon_80.png" "${SYS_QPKG_DIR}/.qpkg_icon_80.png"
  $CMD_CP -af "${QPM_DIR_ICONS}/qpkg_icon_gray.png" "${SYS_QPKG_DIR}/.qpkg_icon_gray.png"
  $CMD_CP -af "${SYS_QPKG_DIR}/.qpkg_icon.png" "${SYS_RSS_IMG_DIR}/${QPKG_NAME}.gif"
  $CMD_CP -af "${SYS_QPKG_DIR}/.qpkg_icon_80.png" "${SYS_RSS_IMG_DIR}/${QPKG_NAME}_80.gif"
  $CMD_CP -af "${SYS_QPKG_DIR}/.qpkg_icon_gray.png" "${SYS_RSS_IMG_DIR}/${QPKG_NAME}_gray.gif"
  $CMD_PRINTF "[v]\n"
}

#---
# link service script
#---
post_install_link_service(){
  if [ -n "$QPM_QPKG_SERVICE" ]; then
    local qpkg_service="${SYS_QPKG_DIR}/.${QPM_QPKG_SERVICE}"
    local init_service="${SYS_INIT_DIR}/${QPKG_NAME}"
    local qpkg_dir=$($CMD_ECHO ${SYS_QPKG_DIR} | $CMD_SED 's/\//\\\//g')
    $CMD_SED -i "s/\${SYS_QPKG_DIR}/${qpkg_dir}/" ${qpkg_service}
    [ -f ${qpkg_service} ] || err_log "$QPM_QPKG_SERVICE: no such file"
    $CMD_LN -nfs ${qpkg_service} ${init_service}
    $CMD_LN -nfs ${init_service} "${SYS_STARTUP_DIR}/QS${QPM_QPKG_SERVICE_ID}${QPKG_NAME}"
    $CMD_LN -nfs ${init_service} "${SYS_SHUTDOWN_DIR}/QK${QPM_QPKG_SERVICE_ID}${QPKG_NAME}"
    $CMD_CHMOD 755 ${qpkg_service}
    msg "link ${QPKG_NAME} service script" ${init_service}
  fi
}

#---
# register QPKG information
#---
post_install_register_qpkg(){
  msg "set QPKG information in" ${SYS_QPKG_CONFIG}
  [ -f $SYS_QPKG_CONFIG ] || $CMD_TOUCH $SYS_QPKG_CONFIG

  set_qpkg_cfg ${SYS_QPKG_CFG_NAME} ${QPKG_NAME}
  set_qpkg_cfg ${SYS_QPKG_CFG_DISPLAY_NAME} ${QPKG_DISPLAY_NAME}
  msg "set QPKG display name" ${QPKG_DISPLAY_NAME}
  set_qpkg_cfg ${SYS_QPKG_CFG_VERSION} ${QPM_QPKG_VER}
  set_qpkg_cfg ${SYS_QPKG_CFG_AUTHOR} ${QPKG_AUTHOR}
  msg "set QPKG author" ${QPKG_AUTHOR}

  set_qpkg_cfg ${SYS_QPKG_CFG_QPKGFILE} "${QPKG_NAME}.qpkg"
  set_qpkg_cfg ${SYS_QPKG_CFG_DATE} $($CMD_DATE +%F)

  set_qpkg_cfg ${SYS_QPKG_CFG_SHELL} "${SYS_QPKG_DIR}/.${QPM_QPKG_SERVICE}"
  set_qpkg_cfg ${SYS_QPKG_CFG_INSTALL_PATH} ${SYS_QPKG_DIR}

  local web_dir="${SYS_QPKG_DIR}/${QPKG_DIR_WEB}"
  if [ -n "${QPKG_DIR_WEB}" ] &&
     [ -d ${web_dir} ] &&
     [ $(ls -l ${web_dir} | grep "index." | awk 'END {print NR}') -gt 0 ]; then
     $QPKG_WEB_PATH=${QPKG_WEB_PATH:-$QPKG_NAME}
  fi
  if [ -n "$QPKG_WEB_PATH" ]; then
    set_qpkg_cfg ${SYS_QPKG_CFG_WEB_PATH} "/${QPKG_WEB_PATH:-$QPKG_NAME}"
    set_qpkg_cfg ${SYS_QPKG_CFG_WEB_PORT} ${QPKG_WEB_PORT:-80}
    msg "set QPKG web path" "host:${QPKG_WEB_PORT:-80}/${QPKG_WEB_PATH}"
  fi
  
  set_qpkg_cfg ${SYS_QPKG_CFG_DESKTOP_APP} ${QPKG_DESKTOP_APP}
  msg "set QPKG desktop app" ${QPKG_DESKTOP_APP:-"FALSE"}
}

#---
# start service
#---
post_install_start_service(){
  if [ -x ${SYS_INIT_DIR}/${QPKG_NAME} ]; then
    ${SYS_INIT_DIR}/${QPKG_NAME} start
    $CMD_SLEEP 5
  fi
}

#---
# Main installation
#---
main(){
  ##### pre-install #####
  # inform about progress
  set_progress_begin
  # get system information
  pre_install_get_sys_info
  # get base dir & get qpkg dir
  pre_install_get_base_dir
  # run pre-install custom script
  ${SYS_QPKG_SERVICE} pre_install ${QPKG_NAME}
  # check QPKG_REQUIRE & QPKG_CONFLICT
  pre_install_check_requirements
  # check whether is already installed
  pre_check_qpkg_status
  # uninstall service
  pre_install_stop_service

  ##### install #####
  # inform about progress
  set_progress_before_install
  # put data
  install_put_data 2>/dev/null
  # put script
  install_put_script 2>/dev/null
  # put icons
  install_put_icons 2>/dev/null

  $CMD_SLEEP 5
  $CMD_SYNC

  ##### post-install #####
  # link service script
  post_install_link_service
  # register QPKG information
  post_install_register_qpkg
  # run post-install custom script
  ${SYS_QPKG_SERVICE} post_install ${QPKG_NAME}
  # inform about progress
  set_progress_after_install
  # start service
  post_install_start_service

  ##### print "QPKG has been installed" #####
  # inform system log
  log "${QPKG_NAME} ${QPM_QPKG_VER} has been installed in $SYS_QPKG_DIR."
  # inform about progress
  set_progress_end
}

main "$@"