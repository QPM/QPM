#!/bin/sh
TODAY=`date +%Y%m%d`
QPM_PATH=build/qpm_${TODAY}
QPM_TMP="${QPM_PATH}".$$

rm $QPM_PATH 2>/dev/null

echo "#!/bin/sh" > ${QPM_TMP}

######
# [SPACE(20)|NAME(10)|VERSION(10)|SHELL_SIZE(10)]
enc_space=\#$(perl -E 'say " " x 19')
enc_name="QPM       "
enc_version="0.1.0     "
enc_shell_size="SHELL_SIZE"
echo "${enc_space}${enc_name}${enc_version}${enc_shell_size}" >> ${QPM_TMP}
######

cat src/qpm.sh >> ${QPM_TMP}

echo "\n###QPM_QPKG_SCRIPT START" >> ${QPM_TMP}
cat src/script.sh >> ${QPM_TMP}
echo "\n###QPM_QPKG_SCRIPT END" >> ${QPM_TMP}

echo "\n###QPM_QPKG_QPM_CONFIGS START" >> ${QPM_TMP}
cat src/qpm_qpkg.cfg >> ${QPM_TMP}
echo "\n###QPM_QPKG_QPM_CONFIGS END" >> ${QPM_TMP}

echo "\n###QPM_QPKG_QPM_SERVICE_START START" >> ${QPM_TMP}
cat src/qpm_service_start.sh >> ${QPM_TMP}
echo "\n###QPM_QPKG_QPM_SERVICE_START END" >> ${QPM_TMP}

echo "\n###QPM_QPKG_QPM_SERVICE_END START" >> ${QPM_TMP}
cat src/qpm_service_end.sh >> ${QPM_TMP}
echo "\n###QPM_QPKG_QPM_SERVICE_END END" >> ${QPM_TMP}

echo "\n###QPM_QPKG_INSTALL START" >> ${QPM_TMP}
cat src/install.sh >> ${QPM_TMP}
echo "\n###QPM_QPKG_INSTALL END" >> ${QPM_TMP}

echo "\n###QPM_QPKG_UNINSTALL START" >> ${QPM_TMP}
cat src/uninstall.sh >> ${QPM_TMP}
echo "\n###QPM_QPKG_UNINSTALL END" >> ${QPM_TMP}

script_len=$(ls -l "${QPM_TMP}" | awk '{ print $5 }')
script_len=${script_len}$(perl -E 'say " " x '$(expr 10 - ${#script_len}))
sed "2s/SHELL_SIZE/${script_len}/g" ${QPM_TMP} > ${QPM_PATH}
rm -f ${QPM_TMP} &>/dev/null

tar -zcpf ${QPM_TMP} template
cat ${QPM_TMP} >> ${QPM_PATH}
rm -f ${QPM_TMP} &>/dev/null

chmod 755 ${QPM_PATH}