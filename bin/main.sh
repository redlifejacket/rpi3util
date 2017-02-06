#!/bin/bash

homedir=/home/pi
logdir=${homedir}/log
[[ ! -d ${logdir} ]] && mkdir ${logdir}
runtime=$(date +%Y%m%d%H%M%S)
logfile="${logdir}/rpi3util_${runtime}.log"
projdir=${homedir}/rpi3util-master
etc_runtime=${logdir}/etc_${runtime}
exec 3>&1 1>>${logfile} 2>&1

function createTar {
  local __resultvar=$1
  local srcdir=$2
  local destdir=$3
  local label=$4
  local files=$5
  local tarfile="${destdir}/rpi3util_${label}_${runtime}.tar"
  cd ${srcdir}

  tar cvf ${tarfile} ${files}
  cd -
  eval $__resultvar="${tarfile}"
}

function getConcatenatedFileList {
  local __resultvar=$1
  local tarfile1=$2
  local tarfile2=$3
  [[ -f ${tarfile1} ]] && private_list=$(tar tf ${tarfile1} | grep -v "\/$")
  [[ -f ${tarfile2} ]] && public_list=$(tar tf ${tarfile2} | grep -v "\/$")
  local flist="${private_list} ${public_list}"
  eval $__resultvar="${flist}"
}

function getPrivateTar {
  local __resultvar=$1
  local privtar=""
  mountdir=/media/rpi3util/private
  if [ ! -d ${mountdir} ]
    then
    mkdir -p ${mountdir}
    echo "/dev/sda1 ${mountdir} vfat user,owner,utf8,rw,umask=000 0 0" >> /etc/fstab
    mount -a
  fi
  createTar privtar ${mountdir} ${logdir} "private" "etc"
  eval $__resultvar="${privtar}"
}

function init {
  sudo -s 
  perl -p -i -e "s/country=GB/country=AU/" /etc/wpa_supplicant/wpa_supplicant.conf
  touch /boot/ssh
}

function runScripts {
  ${projdir}/bin/rpi3_ap_setup.sh
  ${projdir}/bin/adapter_passthrough.sh wlan1 eth0
  ${projdir}/bin/postfix_main.sh
  ${projdir}/bin/postfix_aliases.sh
  ${projdir}/bin/postfix_test.sh
}

function installEtcRuntimeTar {
  local privTar = $1
  local pubTar = $2

  echo "private_tar: ${privTar}"
  echo "public_tar:  ${pubTar}"
  [[ ! -d ${etc_runtime} ]] && echo "Creating ${etc_runtime}" && mkdir ${etc_runtime}
  cd ${etc_runtime}
  tar xvf ${private_tar}
  tar xvf ${public_tar}
  ls -lR ${etc_runtime}
  cd ${etc_runtime}
  etc_runtime_base=$(basename ${etc_runtime})
  etc_runtime_tar=${etc_runtime}/${etc_runtime_base}.tar
  tar cvf ${etc_runtime_tar} etc
  echo "${etc_runtime_tar} created"
  tar xvf ${etc_runtime_tar} -C /
  echo "${etc_runtime_tar} installed"
}

# Main Program
init
runScripts
getPrivateTar private_tar
createTar public_tar ${projdir} ${logdir} "public" "etc"
installEtcRuntimeTar ${private_tar} ${public_tar}
reboot
