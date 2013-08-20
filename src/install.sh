#!/bin/sh

#===
# QPKG definitions
#===
source "$( cd "$( dirname "${0}" )" && pwd )/qpkg.cfg"
SYS_QPKG_TMP=$( cd "$( dirname "${0}" )" && pwd )

###########################################
# System messages
###########################################
SYS_MSG_FILE_NOT_FOUND="Data file not found."
SYS_MSG_FILE_ERROR="Data file error."
SYS_MSG_PUBLIC_NOT_FOUND="Public share not found."
SYS_MSG_FAILED_CONFIG_RESTORE="Failed to restore saved configuration data."

#===
# Inform web interface about progress
#===
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

#===
# Log
#===
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
  local message="$QPKG_NAME $QPKG_VER installation failed. $1"
  $CMD_ECHO "$message" 1>&2
  $write_err "$message"

  set_progress_fail
  exit 1
}

#===
# Remove specified file or directory (if empty).
#===
remove_file_and_empty_dir(){
  [ -n "$1" ] || return 1
  local file=
  # Files relative to QPKG directory are changed to full path.
  if [ -n "${1##/*}" ]; then
    file="$SYS_QPKG_DIR/$1"
  else
    file="$1"
  fi
  if [ -f "$file" ]; then
    $CMD_RM -f "$file"
  elif [ -d "$file" ]; then
    $CMD_RMDIR "$file" 2>/dev/null
  fi
}

#===
# library
#===

# edit qpkg.cfg
edit_config(){
  local field="$1"
  local value="$2"
  local qpkg_cfg="${3:-$QPM_QPKG_CONFIGS}"
  if [ -n "$field" ] && [ -n "$value" ] && [ -f "$qpkg_cfg" ]; then
    local space=$(perl -E 'say " " x '$(expr 48 - ${#field} - ${#value} - 1))
    value=$($CMD_ECHO ${value} | $CMD_SED 's/\//\\\//g')
    $CMD_SED -i "s/${field}=[^#]*/${field}=${value}${space}/" ${qpkg_cfg}
  else
    return 1
  fi
}

# split MAJOR.MINOR.BUILD version
split_version(){
  [ -n "$1" ] || return 1
  local version="$1"
  local prefix="$2"

  local major=$($CMD_EXPR "$version" : '\([^.]*\)')
  local minor=$($CMD_EXPR "$version" : '[^.]*[.]\([^.]*\)')
  local build=$($CMD_EXPR "$version" : '[^.]*[.][^.]*[.]\([^.]*\)')
  eval ${prefix}MAJOR=${major:-0}
  eval ${prefix}MINOR=${minor:-0}
  eval ${prefix}BUILD=${build:-0}
}

##################################################################
# Check if versions are equal
#
# Returns 0 if versions are equal, otherwise it returns 1.
##################################################################
is_equal(){
  [ -n "$1" ] && [ -n "$2" ] || return 1

  split_version $1
  split_version $2 REQ_

  if $CMD_EXPR $MAJOR != $REQ_MAJOR >/dev/null ||
     $CMD_EXPR $MINOR != $REQ_MINOR >/dev/null ||
     $CMD_EXPR $BUILD != $REQ_BUILD >/dev/null; then
    return 1
  fi
}

##################################################################
# Check if versions are unequal
#
# Returns 0 if versions are unequal, otherwise it returns 1.
##################################################################
is_unequal(){
  [ -n "$1" ] && [ -n "$2" ] || return 1

  split_version $1
  split_version $2 REQ_

  if $CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null &&
     $CMD_EXPR $MINOR = $REQ_MINOR >/dev/null &&
     $CMD_EXPR $BUILD = $REQ_BUILD >/dev/null; then
    return 1
  fi
}

##################################################################
# Check if one version is less than or equal to another version
#
# Returns 0 if VERSION1 is less than or equal to VERSION2,
# otherwise it returns 1.
##################################################################
is_less_or_equal(){
  [ -n "$1" ] && [ -n "$2" ] || return 1

  split_version $1
  split_version $2 REQ_

  # if $CMD_EXPR $MAJOR \> $REQ_MAJOR >/dev/null ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     $CMD_EXPR $MINOR \> $REQ_MINOR >/dev/null) ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
  #     $CMD_EXPR $BUILD \> $REQ_BUILD >/dev/null); then
  #   return 1
  # fi
}

##################################################################
# Check if one version is less than another version
#
# Returns 0 if VERSION1 is less than VERSION2,
# otherwise it returns 1.
##################################################################
is_less(){
  [ -n "$1" ] && [ -n "$2" ] || return 1

  split_version $1
  split_version $2 REQ_

  # if $CMD_EXPR $MAJOR \> $REQ_MAJOR >/dev/null ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     $CMD_EXPR $MINOR \> $REQ_MINOR >/dev/null) ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
  #     $CMD_EXPR $BUILD \>= $REQ_BUILD >/dev/null); then
  #   return 1
  # fi
}

##################################################################
# Check if one version is greater than another version
#
# Returns 0 if VERSION1 is greater than VERSION2,
# otherwise it returns 1.
##################################################################
is_greater(){
  [ -n "$1" ] && [ -n "$2" ] || return 1

  split_version $1
  split_version $2 REQ_

  # if $CMD_EXPR $MAJOR \< $REQ_MAJOR >/dev/null ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     $CMD_EXPR $MINOR \< $REQ_MINOR >/dev/null) ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
  #     $CMD_EXPR $BUILD \<= $REQ_BUILD >/dev/null); then
  #   return 1
  # fi
}

##################################################################
# Check if one version is greater than or equal to another version
#
# Returns 0 if VERSION1 is greater than or equal to VERSION2,
# otherwise it returns 1.
##################################################################
is_greater_or_equal(){
  [ -n "$1" ] && [ -n "$2" ] || return 1

  split_version $1
  split_version $2 REQ_

  # if $CMD_EXPR $MAJOR \< $REQ_MAJOR >/dev/null ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     $CMD_EXPR $MINOR \< $REQ_MINOR >/dev/null) ||
  #    (($CMD_EXPR $MAJOR = $REQ_MAJOR >/dev/null) &&
  #     ($CMD_EXPR $MINOR = $REQ_MINOR >/dev/null) &&
  #     $CMD_EXPR $BUILD \< $REQ_BUILD >/dev/null); then
  #   return 1
  # fi
}

############################################################
# Check that given QPKG package isn't installed or that
# specified Optware package isn't installed. An optional
# version check can also be performed.
#
# Returns 0 if package is not installed, otherwise it
# returns 1.
############################################################
is_qpkg_not_installed(){
  [ -n "$1" ] || return 1
  local qpkg_name="$1"
  local op="$2"
  local conflict="$3"

  local available=
  local pkg="$($CMD_EXPR "$qpkg_name" : "OPT/\(.*\)")"
  if [ -z "$pkg" ]; then
    available=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CFG_NAME" -f $SYS_QPKG_CONFIG)
  elif [ -n "$CMD_PKG_TOOL" ]; then
    available=$($CMD_PKG_TOOL status $pkg | $CMD_GREP "^Version:")
  else
    return 0
  fi
  local status=0
  if [ -n "$available" ]; then
    status=1
    local installed=
    if [ -z "$pkg" ]; then
      installed=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CFG_VERSION" -d "" -f $SYS_QPKG_CONFIG)
    else
      installed="$($CMD_PKG_TOOL status $pkg | $CMD_SED -n 's/^Version: \(.*\)/\1/p')"
    fi

    if [ -n "$conflict" ] && [ -n "$installed" ]; then
      case "$op" in
      =|==)
        is_equal $installed $conflict || status=0 ;;
      !=)
        is_unequal $installed $conflict || status=0 ;;
      \<=)
        is_less_or_equal $installed $conflict || status=0 ;;
      \<)
        is_less $installed $conflict || status=0 ;;
      \>)
        is_greater $installed $conflict || status=0 ;;
      \>=)
        is_greater_or_equal $installed $conflict || status=0 ;;
      *)
        status=1
        ;;
      esac
    fi
  else
    [ "$qpkg_name" = "$QPKG_NAME" ] && [ -d "$SYS_QPKG_DIR" ] && status=1
  fi

  return $status
}

############################################################
# Check if given QPKG package exists and is enabled or that
# specified Optware package exists. An optional version
# check can also be performed.
#
# Returns 0 if package is valid, otherwise it returns 1.
############################################################
is_qpkg_enabled(){
  [ -n "$1" ] || return 1
  local qpkg_name="$1"
  local op="$2"
  local required="$3"

  local enabled="FALSE"
  local pkg="$($CMD_EXPR "$qpkg_name" : "OPT/\(.*\)")"
  if [ -z "$pkg" ]; then
    enabled=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CFG_ENABLE" -d "FALSE" -f $SYS_QPKG_CONFIG)
  elif [ -n "$CMD_PKG_TOOL" ]; then
    $CMD_PKG_TOOL status $pkg | $CMD_GREP -q "^Version:" && enabled="TRUE"
  else
    return 1
  fi
  local status=1
  if [ "$enabled" = "TRUE" ]; then
    status=0
    local installed=
    if [ -z "$pkg" ]; then
      installed=$($CMD_GETCFG "$qpkg_name" "$SYS_QPKG_CFG_VERSION" -d "" -f $SYS_QPKG_CONFIG)
    else
      installed="$($CMD_PKG_TOOL status $pkg | $CMD_SED -n 's/^Version: \(.*\)/\1/p')"
      # Installed packages with no specific version check shall always be upgraded
      # if a new version is available.
      [ -z "$required" ] && [ -z "$SYS_PKG_INSTALLED" ] && status=1
    fi
    if [ -n "$required" ] && [ -n "$installed" ]; then
      case "$op" in
      =|==)
        is_equal $installed $required || status=1 ;;
      !=)
        is_unequal $installed $required || status=1 ;;
      \<=)
        is_less_or_equal $installed $required || status=1 ;;
      \<)
        is_less $installed $required || status=1 ;;
      \>)
        is_greater $installed $required || status=1 ;;
      \>=)
        is_greater_or_equal $installed $required || status=1 ;;
      *)
        status=1
        ;;
      esac
    fi
  fi
  # Try to install the latest version and then re-check the requirement.
  if [ $status -eq 1 ] && [ -n "$pkg" ] && [ -z "$SYS_PKG_INSTALLED" ]; then
    if [ -z "$SYS_PKG_UPDATED" ]; then
      $CMD_PKG_TOOL $SYS_PKG_TOOL_OPTS update || warn_log "$CMD_PKG_TOOL update failed"
      SYS_PKG_UPDATED="TRUE"
    fi
    $CMD_PKG_TOOL $SYS_PKG_TOOL_OPTS install $pkg || warn_log "$CMD_PKG_TOOL install $pkg failed"
    # Avoid never-ending loop...
    SYS_PKG_INSTALLED="TRUE"
    is_qpkg_enabled "$qpkg_name" $op $required && status=0
  fi
  SYS_PKG_INSTALLED=
  return $status
}

#####################################################################
# Append requirements to output message
#####################################################################
append_install_msg(){
  if [ -n "$1" ]; then
    if $CMD_EXPR "$1" : "OPT/.*" >/dev/null; then
      opt_file=$($CMD_ECHO "$1" | $CMD_SED 's#OPT/\(.*\)#\1#g' )
      opt_install_msg="${opt_install_msg}${opt_install_msg:+, }$opt_file"
    else
      install_msg="${install_msg}${install_msg:+, }$1"
    fi
  fi
}
append_remove_msg(){
  if [ -n "$1" ]; then 
    if $CMD_EXPR "$1" : "OPT/.*" >/dev/null; then
      opt_file=$($CMD_ECHO "$1" | $CMD_SED 's#OPT/\(.*\)#\1#g' )
      opt_remove_msg="${opt_remove_msg}${opt_remove_msg:+, }$opt_file"
      [ -n "$2" ] && [ -n "$3" ] && opt_remove_msg="$opt_remove_msg $2 $3"
    else
      remove_msg="${remove_msg}${remove_msg:+, }$1"
      [ -n "$2" ] && [ -n "$3" ] && remove_msg="$remove_msg $2 $3"
    fi
  fi
}

#####################################################################
# Check requirements routines
#
# Only returns if all requirements are fulfilled, otherwise err_log
# is called with a relevant error message.
#####################################################################
pre_install_check_requirements(){
  local install_msg=
  local opt_install_msg=
  local remove_msg=
  local opt_remove_msg=
  if [ -n "$QPKG_REQUIRE" ]; then
    OLDIFS="$IFS"; IFS=,
    set $QPKG_REQUIRE
    IFS="$OLDIFS"
    for require
    do
      local statusOK="FALSE"
      OLDIFS="$IFS"; IFS=\|
      set $require
      IFS="$OLDIFS"
      for statement
      do
        set $($CMD_ECHO "$statement" | $CMD_SED 's/\(.*[^=<>!]\)\([=<>!]\+\)\(.*\)/\1 \2 \3/')
        qpkg=$1
        op=$2
        version=$3
        statusOK="TRUE"
        is_qpkg_enabled "$qpkg" $op $version && break
        statusOK="FALSE"
      done 
      [ "$statusOK" = "TRUE" ] || append_install_msg "${require## }"
    done
  fi
  if [ -n "$QPKG_CONFLICT" ]; then
    OLDIFS="$IFS"; IFS=,
    set $QPKG_CONFLICT
    IFS="$OLDIFS"
    for conflict
    do
      set $($CMD_ECHO "$conflict" | $CMD_SED 's/\(.*[^=<>!]\)\([=<>!]\+\)\(.*\)/\1 \2 \3/')
      qpkg=$1
      op=$2
      version=$3
      is_qpkg_not_installed "$qpkg" $op $version || append_remove_msg "$qpkg" $op $version
    done
  fi
  local err_msg=
  [ -n "$opt_install_msg" ] || [ -n "$opt_remove_msg" ] && [ -z "$CMD_PKG_TOOL" ] && append_install_msg "Optware | opkg" && opt_remove_msg= && opt_install_msg=
  [ -n "$install_msg" ] && err_msg="${err_msg}The following QPKG must be installed and enabled: ${install_msg}. "
  [ -n "$remove_msg" ] && err_msg="${err_msg}The following QPKG must be removed: ${remove_msg}. "
  [ -n "$opt_install_msg" ] &&  err_msg="${err_msg}The following Optware package must be installed: ${opt_install_msg}. "
  [ -n "$opt_remove_msg" ] && err_msg="${err_msg}The following Optware package must be removed: ${opt_remove_msg}. "
  [ -n "$err_msg" ] && err_log "$err_msg"

  # Package specific routines as defined in package_routines.
  call_defined_routine pkg_check_requirement
}

############################################################
# Call package specific routine if it is defined
############################################################
call_defined_routine(){
  [ -n "$(command -v $1)" ] && $1
  cd $SYS_EXTRACT_DIR
}

###############
# Init routine
###############
init(){
  # Assign path to optional package tool.
  if [ -x /opt/bin/opkg ]; then
    CMD_PKG_TOOL="/opt/bin/opkg"
    SYS_PKG_TOOL_OPTS="--force-maintainer"
  elif [ -x /opt/bin/ipkg ]; then
    CMD_PKG_TOOL="/opt/bin/ipkg"
    SYS_PKG_TOOL_OPTS="-force-defaults"
  fi
  if [ -n "$CMD_PKG_TOOL" ] && [ -f $SYS_QPKG_DATA_PACKAGES_FILE ]; then
    $CMD_ECHO "src/gz _qdk file://$(pwd)" > ipkg.conf
    SYS_PKG_TOOL_OPTS="$SYS_PKG_TOOL_OPTS -f ipkg.conf"
    $CMD_PKG_TOOL $SYS_PKG_TOOL_OPTS update || warn_log "$CMD_PKG_TOOL update failed"
    SYS_PKG_UPDATED="TRUE"
  fi
}

#===
# get system information
#===
pre_install_get_sys_info(){
  if [ $(expr match "$(/bin/uname -m)" 'arm') -ne 0 ]; then
    SYS_PLATFORM="arm"
  else
    SYS_PLATFORM="x86"
  fi;
  edit_config "SYS_PLATFORM" ${SYS_PLATFORM}

  msg "get system platform" ${SYS_PLATFORM}
}

#===
# get base dir
#===
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

#===
# get base dir & qpkg dir
#===
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
    err_log "$SYS_MSG_PUBLIC_NOT_FOUND"
  fi

  SYS_QPKG_STORE="${SYS_BASE_DIR}/.qpkg"
  SYS_QPKG_DIR="${SYS_QPKG_STORE}/${QPKG_NAME}"

  edit_config "SYS_BASE_DIR" ${SYS_BASE_DIR}
  edit_config "SYS_QPKG_STORE" ${SYS_QPKG_STORE}
  edit_config "SYS_QPKG_DIR" ${SYS_QPKG_DIR}
  
  msg "get system base dir" ${SYS_BASE_DIR}
  msg "get ${QPKG_NAME} qpkg dir" ${SYS_QPKG_DIR}
}

#===
# check whether is already installed
#===
pre_check_qpkg_status(){
  local ori_qpkg_ver=$(get_qpkg_cfg ${SYS_QPKG_CFG_VERSION} "not installed")
  msg "original ${QPKG_NAME} version" ${ori_qpkg_ver}
  msg "new ${QPKG_NAME} version" ${QPM_QPKG_VER}
  if [ ori_qpkg_ver = "not installed" ]; then
    msg "setup will now perform" "installing"
  else
    msg "setup will now perform" "upgrading"
  fi
  $CMD_MKDIR -p $SYS_QPKG_DIR
}

#===
# stop service
#===
pre_install_stop_service(){
  if [ -x ${SYS_INIT_DIR}/${QPKG_NAME} ]; then
    msg "stop ${QPKG_NAME} service"
    ${SYS_INIT_DIR}/${QPKG_NAME} stop &>/dev/null
    $CMD_SLEEP 5
    $CMD_PRINTF "[v]\n"
  fi
}

#===
# put data
#===
install_put_data(){
  $CMD_CP -arf "${SYS_QPKG_TMP}/${QPM_DIR_SHARE}/"* "${SYS_QPKG_DIR}/"
  if [ SYS_PLATFORM = 'arm' ]; then
    $CMD_CP -arf "${SYS_QPKG_TMP}/${QPM_DIR_ARM}/"* "${SYS_QPKG_DIR}/" 
  else
    $CMD_CP -arf "${SYS_QPKG_TMP}/${QPM_DIR_X86}/"* "${SYS_QPKG_DIR}/"
  fi;
}

#===
# put script
#===
install_put_script(){
  # put configs
  $CMD_CP -af ${QPM_QPKG_CONFIGS} "${SYS_QPKG_DIR}/.${QPM_QPKG_CONFIGS}"
  # put service script
  $CMD_CP -af ${QPM_QPKG_SERVICE} "${SYS_QPKG_DIR}/.${QPM_QPKG_SERVICE}"
  # put uninstall script
  $CMD_CP -af ${QPM_QPKG_UNINSTALL} "${SYS_QPKG_DIR}/.${QPM_QPKG_UNINSTALL}"
}

#===
# put icons
#===
install_put_icons(){
  $CMD_CP -af "${QPM_DIR_ICONS}/qpkg_icon.png" "${SYS_QPKG_DIR}/.qpkg_icon.png"
  $CMD_CP -af "${QPM_DIR_ICONS}/qpkg_icon_80.png" "${SYS_QPKG_DIR}/.qpkg_icon_80.png"
  $CMD_CP -af "${QPM_DIR_ICONS}/qpkg_icon_gray.png" "${SYS_QPKG_DIR}/.qpkg_icon_gray.png"
  $CMD_CP -af "${SYS_QPKG_DIR}/.qpkg_icon.png" "${SYS_RSS_IMG_DIR}/${QPKG_NAME}.gif"
  $CMD_CP -af "${SYS_QPKG_DIR}/.qpkg_icon_80.png" "${SYS_RSS_IMG_DIR}/${QPKG_NAME}_80.gif"
  $CMD_CP -af "${SYS_QPKG_DIR}/.qpkg_icon_gray.png" "${SYS_RSS_IMG_DIR}/${QPKG_NAME}_gray.gif"
}

#===
# link service script
#===
post_install_link_service(){
  if [ -n "$QPM_QPKG_SERVICE" ]; then
    local qpkg_service="${SYS_QPKG_DIR}/.${QPM_QPKG_SERVICE}"
    local init_service="${SYS_INIT_DIR}/${QPKG_NAME}"
    local qpkg_dir=$($CMD_ECHO ${SYS_QPKG_DIR} | $CMD_SED 's/\//\\\//g')
    $CMD_SED -i "s/\${SYS_QPKG_DIR}/${qpkg_dir}/" ${qpkg_service}
    [ -f ${qpkg_service} ] || err_log "$QPM_QPKG_SERVICE: no such file"
    $CMD_LN -sf ${qpkg_service} ${init_service}
    $CMD_LN -sf ${init_service} "${SYS_STARTUP_DIR}/QS${QPM_QPKG_SERVICE_ID}${QPKG_NAME}"
    $CMD_LN -sf ${init_service} "${SYS_SHUTDOWN_DIR}/QK${QPM_QPKG_SERVICE_ID}${QPKG_NAME}"
    $CMD_CHMOD 755 ${qpkg_service}
    msg "link ${QPKG_NAME} service script" ${init_service}
  fi
}

#===
# register QPKG information
#===
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

  set_qpkg_cfg ${SYS_QPKG_CFG_SHELL} ${QPM_QPKG_SERVICE}
  set_qpkg_cfg ${SYS_QPKG_CFG_INSTALL_PATH} ${SYS_QPKG_DIR}

  set_qpkg_cfg ${SYS_QPKG_CFG_WEB_PATH} ${QPKG_WEB_PATH}
  set_qpkg_cfg ${SYS_QPKG_CFG_WEB_PORT} ${QPKG_WEB_PORT}
  if [ -n "$QPKG_WEB_PATH" ]; then
    msg "set QPKG web path" "host:${QPKG_WEB_PORT:-80}/${QPKG_WEB_PATH}"
  fi
  
  set_qpkg_cfg ${SYS_QPKG_CFG_DESKTOP_APP} ${QPKG_DESKTOP_APP}
  msg "set QPKG desktop app" ${QPKG_DESKTOP_APP:-"FALSE"}
}

#===
# start service
#===
post_install_start_service(){
  if [ -x ${SYS_INIT_DIR}/${QPKG_NAME} ]; then
    ${SYS_INIT_DIR}/${QPKG_NAME} start
    $CMD_SLEEP 5
  fi
}

#===
# Main installation
#===
main(){
  ##### pre-install #####
  # inform about progress
  set_progress_begin
  # WTF
  #init
  # get system information
  pre_install_get_sys_info
  # get base dir & get qpkg dir
  pre_install_get_base_dir
  # check QPKG_REQUIRE & QPKG_CONFLICT
  #pre_install_check_requirements
  # check whether is already installed
  pre_check_qpkg_status
  # stop service
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
  # inform about progress
  set_progress_after_install

  ##### post-install #####
  # link service script
  post_install_link_service
  # register QPKG information
  post_install_register_qpkg
  # run post-install custom script
  ${SYS_QPKG_SERVICE} install ${QPKG_NAME}
  # start service
  post_install_start_service

  ##### print "QPKG has been installed" #####
  # inform system log
  log "${QPKG_NAME} ${QPM_QPKG_VER} has been installed in $SYS_QPKG_DIR."
  # inform about progress
  set_progress_end
}

main