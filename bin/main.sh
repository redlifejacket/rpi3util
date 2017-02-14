#!/bin/bash

homedir=${HOME}
logdir=${homedir}/log
[[ ! -d ${logdir} ]] && mkdir ${logdir}
runtime=$(date +%Y%m%d%H%M%S)
logfile="${logdir}/rpi3util_${runtime}.log"
projname=rpi3util
projdir=${homedir}/${projname}
etc_runtime=${logdir}/etc_${runtime}
runScripts_lck=${logdir}/runScripts.lck
etcInstall_lck=${logdir}/etcInstall.lck
exec 3>&1 1>>${logfile} 2>&1

function createTar {
  echo "executing createTar"
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
  echo "completed createTar"
}

function getConcatenatedFileList {
  echo "executing getConcatenatedFileList"
  local __resultvar=$1
  local tarfile1=$2
  local tarfile2=$3
  [[ -f ${tarfile1} ]] && private_list=$(tar tf ${tarfile1} | grep -v "\/$")
  [[ -f ${tarfile2} ]] && public_list=$(tar tf ${tarfile2} | grep -v "\/$")
  local flist="${private_list} ${public_list}"
  eval $__resultvar="${flist}"
  echo "completed getConcatenatedFileList"
}

function getPrivateTar {
  echo "executing getPrivateTar"
  local __resultvar=$1
  local privtar=""
  mountdir=/media/${projname}
  if [ ! -d ${mountdir} ]
    then
    mkdir -p ${mountdir}
    echo "/dev/sda1 ${mountdir} vfat user,owner,utf8,rw,umask=000 0 0" >> /etc/fstab
    mount -a
  fi
  createTar privtar ${mountdir}/private ${logdir} "private" "etc"
  eval $__resultvar="${privtar}"
  echo "completed getPrivateTar"
}

function init {
  echo "executing init"
  me=$(whoami)
  [[ "${me}" != "root" ]] && echo "Please execute as root." && exit
  chmod u+s /bin/ping
  perl -p -i -e "s/country=GB/country=AU/" /etc/wpa_supplicant/wpa_supplicant.conf
  touch /boot/ssh
  boot_config=/boot/config.txt
  uart_setting="enable_uart=1"
  ret=$(tail -1 ${boot_config})
  [[ "${ret}" != "${uart_setting}" ]] && echo "${uart_setting}" >> ${boot_config}
  user_profile=/etc/user.profile
  profile_setting="[[ -f ${user_profile} ]] && . ${user_profile}"
  ret=$(tail -1 ${user_profile})
  bashrc=${homedir}/.bashrc
  [[ "${ret}" != "${profile_setting}" ]] && echo "${profile_setting}" >> ${bashrc}
  echo "completed init"
}

function runScripts {
  echo "executing runScripts"
  [[ -f ${runScripts_lck} ]] && echo "${runScripts_lck} exists... skipping..." && return
  ${projdir}/bin/rpi3_ap_setup.sh bramble1234 rpi3sg
  ${projdir}/bin/adapter_passthrough.sh wlan1 eth0
  #${projdir}/bin/postfix_main.sh
  #${projdir}/bin/postfix_aliases.sh
  #${projdir}/bin/postfix_test.sh
  touch ${runScripts_lck}
  echo "completed runScripts"
}

function installEtcRuntimeTar {
  echo "executing installEtcRuntimeTar"
  local privTar=$1
  local pubTar=$2

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
  echo "completed installEtcRuntimeTar"
  touch ${etcInstall_lck}
}

# Main Program
if [ ! -f ${etcInstall_lck} ]
then
  [[ $# -eq 1 ]] && echo -n "Setting hostname to $1" && hostname=$1
  init $hostname
  getPrivateTar private_tar
  createTar public_tar ${projdir} ${logdir} "public" "etc"
  installEtcRuntimeTar ${private_tar} ${public_tar}
  reboot
fi

conn=$(ping -q -w 2 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo ok || echo error)
if [ "$conn" == "ok" ]
then
  apt-get update
  dns_conf=/etc/dnsmasq.conf
  dnsmasq_conf_before=${homedir}/log/dnsmasq.conf.before.${runtime}
  dnsmasq_conf_after=${homedir}/log/dnsmasq.conf.after.${runtime}
  cp ${dns_conf} ${dnsmasq_conf_before}
  runScripts
  cp ${dns_conf} ${dnsmasq_conf_after}
  cp ${dnsmasq_conf_before} ${dns_conf}
  reboot
fi
