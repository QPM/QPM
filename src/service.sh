#!/bin/sh
case "$1" in
  start)
    : ADD START ACTIONS HERE
    setup_web_interface
    setup_bin_interface
    ;;

  stop)
    : ADD STOP ACTIONS HERE
    remove_web_interface
    remove_bin_interface
    ;;

  restart)
    $0 stop
    $0 start
    ;;

  install)
    # Install after forced start service
    ;;

  unistall)
    # Uninstall before forced stop service

    ;;
esac