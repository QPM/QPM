#!/bin/sh
#===
# QPKG definitions
#===
source "$( cd "$( dirname "${0}" )" && pwd )/.qpkg.cfg"

##### stop service & run unistall before script #####
if [ -x ${SYS_QPKG_SERVICE} ]; then
  ${SYS_QPKG_SERVICE} stop
  $CMD_SLEEP 5
  $CMD_SYNC
  ${SYS_QPKG_SERVICE} unistall ${QPKG_NAME}
fi

##### remove QPKG directory #####
$CMD_RM -rf ${SYS_QPKG_DIR}
$CMD_RM -f ${SYS_QPKG_SERVICE}
$CMD_FIND $SYS_STARTUP_DIR -type l -name 'QS*${QPKG_NAME}' | $CMD_XARGS $CMD_RM -f 
$CMD_FIND $SYS_SHUTDOWN_DIR -type l -name 'QK*${QPKG_NAME}' | $CMD_XARGS $CMD_RM -f

##### remove icon for rss #####
$CMD_RM -f "${SYS_RSS_IMG_DIR}/${QPKG_NAME}.gif"
$CMD_RM -f "${SYS_RSS_IMG_DIR}/${QPKG_NAME}_80.gif"
$CMD_RM -f "${SYS_RSS_IMG_DIR}/${QPKG_NAME}_gray.gif"

##### remove QPKG configs #####
rmcfg ${QPKG_NAME} -f ${SYS_QPKG_CONFIG}