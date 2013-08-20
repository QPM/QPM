#!/bin/sh
TODAY=`date +%Y%m%d`
QPM_PATH=build/qpm_${TODAY}

rm $QPM_PATH 2>/dev/null

cat src/qpm.sh >> ${QPM_PATH}

echo "\n###QPM_QPKG_SCRIPT START" >> ${QPM_PATH}
cat src/script.sh >> ${QPM_PATH}
echo "\n###QPM_QPKG_SCRIPT END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_QPM_CONFIGS START" >> ${QPM_PATH}
cat src/qpm_qpkg.cfg >> ${QPM_PATH}
echo "\n###QPM_QPKG_QPM_CONFIGS END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_CONFIGS START" >> ${QPM_PATH}
cat src/qpkg.cfg >> ${QPM_PATH}
echo "\n###QPM_QPKG_CONFIGS END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_QPM_SERVICE_START START" >> ${QPM_PATH}
cat src/qpm_service_start.sh >> ${QPM_PATH}
echo "\n###QPM_QPKG_QPM_SERVICE_START END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_QPM_SERVICE_END START" >> ${QPM_PATH}
cat src/qpm_service_end.sh >> ${QPM_PATH}
echo "\n###QPM_QPKG_QPM_SERVICE_END END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_SERVICE START" >> ${QPM_PATH}
cat src/service.sh >> ${QPM_PATH}
echo "\n###QPM_QPKG_SERVICE END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_INSTALL START" >> ${QPM_PATH}
cat src/install.sh >> ${QPM_PATH}
echo "\n###QPM_QPKG_INSTALL END" >> ${QPM_PATH}

echo "\n###QPM_QPKG_UNINSTALL START" >> ${QPM_PATH}
cat src/uninstall.sh >> ${QPM_PATH}
echo "\n###QPM_QPKG_UNINSTALL END" >> ${QPM_PATH}

echo "\n###QPM_ICONS_64 START" >> ${QPM_PATH}
cat icon/qpkg_icon.png >> ${QPM_PATH}
echo "\n###QPM_ICONS_64 END" >> ${QPM_PATH}

echo "\n###QPM_ICONS_64_GRAY START" >> ${QPM_PATH}
cat icon/qpkg_icon_gray.png >> ${QPM_PATH}
echo "\n###QPM_ICONS_64_GRAY END" >> ${QPM_PATH}

echo "\n###QPM_ICONS_80 START" >> ${QPM_PATH}
cat icon/qpkg_icon_80.png >> ${QPM_PATH}
echo "\n###QPM_ICONS_80 END" >> ${QPM_PATH}

chmod 755 ${QPM_PATH}