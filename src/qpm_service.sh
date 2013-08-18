#!/bin/sh

#===
# QPKG definitions
#===
source "$( cd "$( dirname "${0}" )" && pwd )/qpkg.cfg"

case "$1" in
  start)
    echo "service start..."
    ##### setup web interface #####
    local web_dir=${SYS_QPKG_DIR}/${QPKG_DIR_WEB}
    if [ -n ${QPKG_DIR_WEB} ] &&
       [ -d ${web_dir}] &&
       [$(ls -l ${web_dir} | grep "index." | awk 'END {print NR}') -gt 0]; then
      local qpkg_web_path="${SYS_QPKG_DIR}/${QPM_QPKG_WEB_CONFIG}"
      echo "Include ${qpkg_web_path} # QPM {$QPKG_NAME} web" >> ${SYS_WEB_CONFIG}
    fi
    ##### setup bin interface #####
    ;;

  stop)
    echo "service stop..."
    ##### remove web interface #####
    awk '/^Include.*# QPM {$QPKG_NAME} web/ {print NR}' ${SYS_WEB_CONFIG}
    ##### remove bin interface #####
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  install|unistall)
    if [ ${2} != $QPKG_NAME ]; then
      echo "Usage: $0 {start|stop|restart}"
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac