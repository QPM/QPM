#!/bin/sh
EXTRACT_SCRIPT_LEN=000
if [ -n "${1}" ] && [ "${1}" = "--output" ]; then
  echo "Output QNAP package on output.$$..."
  mkdir -p ./output.$$ || exit 1
  dd if=${0} bs=$EXTRACT_SCRIPT_LEN skip=1 | tar -zx -C ./output.$$
else
  /bin/echo "Install QNAP package on TS-NAS..."
  /bin/grep "/mnt/HDA_ROOT" /proc/mounts >/dev/null 2>&1 || exit 1
  EXTRACT_DIR_TEMP="/mnt/HDA_ROOT/update_pkg/tmp.$$"
  /bin/mkdir -p $EXTRACT_DIR_TEMP || exit 1
  /bin/dd if=${0} bs=$EXTRACT_SCRIPT_LEN skip=1 | /bin/tar -zx -C $EXTRACT_DIR_TEMP &>/dev/null || exit 1
  ( cd $EXTRACT_DIR_TEMP && /bin/sh install.sh || echo "Installation Abort." )
  /bin/rm -rf $EXTRACT_DIR_TEMP && exit 10
fi
exit 1