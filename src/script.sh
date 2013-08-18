#!/bin/sh
/bin/echo "Install QNAP package on TS-NAS..."
/bin/grep "/mnt/HDA_ROOT" /proc/mounts >/dev/null 2>&1 || exit 1
EXTRACT_DIR_TEMP="/mnt/HDA_ROOT/update_pkg/tmp.$$"
EXTRACT_SCRIPT_LEN=
/bin/mkdir -p $EXTRACT_DIR_TEMP || exit 1
/bin/dd if=${0} bs=$EXTRACT_SCRIPT_LEN skip=1 | /bin/tar -xz -C $EXTRACT_DIR_TEMP || exit 1
( cd $EXTRACT_DIR_TEMP && /bin/sh install.sh || echo "Installation Abort." )
/bin/rm -rf $EXTRACT_DIR_TEMP && exit 10
exit 1