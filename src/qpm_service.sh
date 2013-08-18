#!/bin/sh

#===
# QPKG definitions
#===
source "$( cd "$( dirname "${0}" )" && pwd )/qpkg.cfg"

case "$1" in
  start)
    echo "service start..."
    ##### register web interface #####
    local web_dir=${SYS_QPKG_DIR}/${QPKG_DIR_WEB}
    if [ -n ${QPKG_DIR_WEB} ] &&
       [ -d ${web_dir}] &&
       [$(ls -l ${web_dir} | grep "index." | awk 'END {print NR}') -gt 0]; then
      local qpkg_web_path="${SYS_QPKG_DIR}/${QPM_QPKG_WEB_CONFIG}"
      cat > $qpkg_web_path <<EOF
Alias /${QPKG_WEBUI:-$QPKG_NAME}/ "${web_dir}"
<Directory "${web_dir}">
    Options Indexes FollowSymLinks
    AllowOverride All
    Order allow,deny
    Allow from all
</Directory>
EOF
      echo "Include ${qpkg_web_path} # QPM {$QPKG_NAME} web" >> ${SYS_WEB_CONFIG}
    fi
    ##### register bin interface #####
    local bin_dir=${SYS_QPKG_DIR}/${QPKG_DIR_BIN}
    if [ -n ${QPKG_DIR_BIN} ] &&
       [ -d ${bin_dir}] &&
       [$(ls -l | grep '\-rwx' | awk 'END {print NR}') -gt 0]; then
      rm -f "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}" 2>/dev/null
      for bin in `ls`; do
        if [ -f $bin ] && [ -x $bin ]; then
          $CMD_LN -sf "${bin_dir}/${bin}" "${SYS_BIN_DIR}/${bin}"
          echo ${bin} >> "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}"
        fi
      done

    fi
    ;;

  stop)
    echo "service stop..."
    ##### remove web interface #####
    $CMD_SED '/^Include.*# QPM {$QPKG_NAME} web/d' ${SYS_WEB_CONFIG}
    ##### remove bin interface #####
    for bin in `cat ${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}`; do
      rm -f "${SYS_BIN_DIR}/${bin}" 2>/dev/null
    done
    rm -f "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}" 2>/dev/null
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  install|unistall)
    if [ ${2} != ${QPKG_NAME} ]; then
      echo "Usage: $0 {start|stop|restart}"
      exit 1
    fi
    ;;
  *)
    echo "Usage: $0 {start|stop|restart}"
    exit 1
esac