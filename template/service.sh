#!/bin/sh
case "$1" in
  start)
    : ADD START ACTIONS HERE
    ;;

  stop)
    : ADD STOP ACTIONS HERE
    ;;

  install)
    # Install after forced start service
    : ADD INSTALL ACTIONS HERE
    ;;

  unistall)
    # Uninstall before forced stop service
    : ADD UNSTALL ACTIONS HERE
    ;;
esac