#!/bin/sh
get_qpkg_info(){
  #data=$(grep -oP "<internalName>${1}</internalName>" ${2})
  data=$(grep "<internalName>${1}</internalName>" ${2} -A 100 | grep ">TS-NASX86<" -A 1 | sed -n 2p | grep -o "http[^<]\+")
  #end=$(expr ${start} + $(sed -n "${start},\$p" ${2} | grep -n "</item>" | head -1 | awk -F "[/:]" '{print $1}') - 1)
  #data=$(echo $data | grep -n "</item>")
  echo $data
}

get_qpkg_info "nodejs" "qpkg.xml"