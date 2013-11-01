#!/bin/sh
TODAY=`date +%Y%m%d`
QPM_PATH=build/qpm_${TODAY}
QPM_TMP="${QPM_PATH}".$$

rm $QPM_PATH 2>/dev/null

echo "#!/bin/sh" > ${QPM_TMP}

######
# [SPACE(10)|NAME(10)|VERSION(10)|SHELL_SIZE(10)]
enc_space=\#$(perl -E 'say " " x 9')
enc_name="QPM       "
enc_version="0.1.0     "
enc_shell_size="SHELL_SIZE"
enc_qpm_size="QPMCF_SIZE"
echo "${enc_space}${enc_name}${enc_version}${enc_shell_size}${enc_qpm_size}" >> ${QPM_TMP}
######

cat src/qpm.sh >> ${QPM_TMP}

echo "\n#qpm#" >> ${QPM_TMP}
script_len=$(ls -l "${QPM_TMP}" | awk '{ print $5 }')
script_len=${script_len}$(perl -E 'say " " x '$(expr 10 - ${#script_len}))
sed "2s/SHELL_SIZE/${script_len}/g" ${QPM_TMP} > ${QPM_PATH}
rm -f ${QPM_TMP} &>/dev/null

tar -zcpf ${QPM_TMP} -C "src" "script.sh" "qpm_qpkg.cfg" "qpm_service_pre.sh" "qpm_service_post.sh" "install.sh" "uninstall.sh"
cat ${QPM_TMP} >> ${QPM_PATH}
rm -f ${QPM_TMP} &>/dev/null
mv ${QPM_PATH} ${QPM_TMP}

echo "\n#qpm#" >> ${QPM_TMP}
qpm_len=$(ls -l "${QPM_TMP}" | awk '{ print $5 }')
qpm_len=${qpm_len}$(perl -E 'say " " x '$(expr 10 - ${#qpm_len}))
sed "2s/QPMCF_SIZE/${qpm_len}/g" ${QPM_TMP} > ${QPM_PATH}
rm -f ${QPM_TMP} &>/dev/null

tar -zcpf ${QPM_TMP} template
cat ${QPM_TMP} >> ${QPM_PATH}
rm -f ${QPM_TMP} &>/dev/null

chmod 755 ${QPM_PATH}