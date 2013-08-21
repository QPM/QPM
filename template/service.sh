#!/bin/sh
case "$1" in
  start)
    : ADD START ACTIONS HERE
    ;;

  stop)
    : ADD STOP ACTIONS HERE
    ;;

  pre_install)
    : ADD PRE INSTALL ACTIONS HERE
    ;;
  post_install)
    # Install after forced start service
    : ADD POST INSTALL ACTIONS HERE
    ;;
  pre_uninstall)
    # Uninstall before forced stop service
    : ADD PRE UNINSTALL ACTIONS HERE
    ;;
  post_uninstall)
    : ADD POST UNINSTALL ACTIONS HERE
    ;;
esac