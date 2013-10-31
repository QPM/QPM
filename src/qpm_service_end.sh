#!/bin/sh
case "$1" in
  start)
    ##### register web interface #####
    web_dir="${SYS_QPKG_DIR}/${QPKG_DIR_WEB}"
    if [ -n "${QPKG_DIR_WEB}" ] && [ -d "${web_dir}" ]; then
       msg "register web interface"
      qpkg_web_config="${SYS_WEB_EXTRA}/${QPM_QPKG_WEB_CONFIG}"
      cat > $qpkg_web_config <<EOF
<IfModule alias_module>
  Alias /${QPKG_WEB_PATH:-$QPKG_NAME} "${web_dir}"
  <Directory "${web_dir}">
      AllowOverride All
      Order allow,deny
      Allow from all
  </Directory>
</IfModule>
EOF
      $CMD_ECHO "Include ${qpkg_web_config}" >> ${SYS_WEB_CONFIG}
      ${SYS_WEB_INIT} restart &>/dev/null
      $CMD_PRINTF "[v]\n"
    fi
    ##### register bin interface #####
    bin_dir=${SYS_QPKG_DIR}/${QPKG_DIR_BIN}
    if [ -n "${QPKG_DIR_BIN}" ] && [ -d "${bin_dir}" ]; then
      rm -f "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}" 2>/dev/null
      for bin in `ls ${bin_dir}`; do
        if [ -f "${bin_dir}/${bin}" ] && [ -x "${bin_dir}/${bin}" ]; then
          $CMD_LN -nfs "${bin_dir}/${bin}" "${SYS_BIN_DIR}/${bin}"
          msg "register bin interface" "${bin}"
          $CMD_ECHO ${bin} >> "${SYS_QPKG_DIR}/${QPM_QPKG_BIN_LOG}"
        fi
      done
    fi
    set_qpkg_cfg ${SYS_QPKG_CFG_ENABLE} "TRUE"
    ;;
  stop)
    set_qpkg_cfg ${SYS_QPKG_CFG_ENABLE} "FALSE"
    ;;
  install)
    ;;
  unistall)
    ;;
esac