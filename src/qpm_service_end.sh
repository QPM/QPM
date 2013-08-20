#!/bin/sh

case "$1" in
  start)
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