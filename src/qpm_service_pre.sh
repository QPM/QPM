#!/bin/sh

#===
# QPKG definitions
#===
source "${SYS_QPKG_DIR}/.qpkg.cfg"
cd ${SYS_QPKG_DIR}

case "$1" in
  start)
    msg "${QPKG_NAME} service will now perform" "start"
    ;;

  stop)
    msg "${QPKG_NAME} service will now perform" "stop"
    ##### remove web interface #####
    qpkg_web_config="${SYS_WEB_EXTRA}/${QPM_QPKG_WEB_CONFIG}"
    if [ -f "${qpkg_web_config}" ]; then
      msg "remove web interface"
      $CMD_SED -i "/${QPM_QPKG_WEB_CONFIG}/d" ${SYS_WEB_CONFIG}
      ${SYS_WEB_INIT} restart &>/dev/null
      $CMD_PRINTF "[v]\n"
    fi
    ##### remove bin interface #####
    if [ -f "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}" ]; then
      for bin in `cat ${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}`; do
        rm -f "${SYS_BIN_DIR}/${bin}" 2>/dev/null
        msg "remove bin interface" "${bin}"
      done
      rm -f "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}" 2>/dev/null
    fi
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  pre_install|post_install|pre_uninstall|post_uninstall)
    if [ "$2" != ${QPKG_NAME} ]; then
      $CMD_ECHO "Usage: $0 {start|stop|restart}"
      exit 1
    fi
    ;;
  *)
    $CMD_ECHO "Usage: $0 {start|stop|restart}"
    exit 1
esac