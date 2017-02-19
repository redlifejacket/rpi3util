#!/bin/bash
homedir=${HOME}
logdir=${homedir}/log
[[ ! -d ${logdir} ]] && mkdir ${logdir}
runtime=$(date +%Y%m%d%H%M%S)
logfile="${logdir}/rpi3util_${runtime}.log"
projname=rpi3util
projdir=${homedir}/${projname}
mountdir=/media
etc_runtime=${logdir}/etc_${runtime}
runScripts_lck=${logdir}/runScripts.lck
etcInstall_lck=${logdir}/etcInstall.lck
mount_device=/dev/sda1
wap_ssid=rpi3sg
wap_password=bramble1234

function usage {
  echo "Usage: $0 -c|--config [-m|--mount mount_device_usb]"
  echo "       $0 -w|--wap [-s|--ssid SSID] [-p|--password PASSWORD]"
  echo "       $0 -h|--help"
  echo "where: -c|--config:   Installs config files"
  echo "       -m|--mount:    Mount device (defaults to ${mount_device})"
  echo "       -w|--wap:      Sets up a wireless access point"
  echo "       -s|--ssid:     WiFi SSID (defaults to ${wap_ssid})"
  echo "       -p|--password: Wifi Password"
  echo "       -h|--help:     Displays this message"
  exit;
}

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
  createTar privtar ${mountdir}/private ${logdir} "private" "etc"
  eval $__resultvar="${privtar}"
  echo "completed getPrivateTar"
}

function setLocale {
  echo "executing setLocale"
	locale-gen en_AU.UTF-8
	localedef -i en_AU -f UTF-8 en_AU.UTF-8
  echo "completed setLocale"
}

function init {
  echo "executing init"
  me=$(whoami)
  [[ "${me}" != "root" ]] && echo "Please execute as root." && exit
  ret=$(grep ${mount_device} /etc/fstab)
  if [ -z "${ret}" ]
    then
    echo -n "Mounting ${mount_device} to ${mountdir}..."
    echo "${mount_device} ${mountdir} vfat user,owner,utf8,rw,umask=000 0 0" >> /etc/fstab
    mount -a
    echo "Done"
  fi
  exec 3>&1 1>>${logfile} 2>&1
  chmod u+s /bin/ping
  perl -p -i -e "s/country=GB/country=AU/" /etc/wpa_supplicant/wpa_supplicant.conf
  touch /boot/ssh
  boot_config=/boot/config.txt
  uart_setting="enable_uart=1"
  ret=$(tail -1 ${boot_config})
  [[ "${ret}" != "${uart_setting}" ]] && echo "${uart_setting}" >> ${boot_config}
  user_profile=/etc/user.profile
  profile_setting="[[ -f ${user_profile} ]] && . ${user_profile}"
  for f in ${homedir} /home/*
  do
    bashrc=${f}/.bashrc
    ret=$(tail -1 ${bashrc})
    [[ "${ret}" != "${profile_setting}" ]] && echo "${profile_setting}" >> ${bashrc}
  done
	setLocale
  echo "completed init"
}

function runScripts {
  echo "executing runScripts"
  [[ -f ${runScripts_lck} ]] && echo "${runScripts_lck} exists... skipping..." && return
  ${projdir}/bin/rpi3_ap_setup.sh ${wap_password} ${wap_ssid}
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

function installConfig {
  if [ ! -f ${etcInstall_lck} ]
  then
    init
    getPrivateTar private_tar
    createTar public_tar ${projdir} ${logdir} "public" "etc"
    installEtcRuntimeTar ${private_tar} ${public_tar}
    reboot
  else 
    echo "${etcInstall_lck}: Please delete lock file and re-execute"
  fi
}

function installWap {
  conn=$(ping -q -w 2 -c 1 `ip r | grep default | cut -d ' ' -f 3` > /dev/null && echo ok || echo error)
  if [ "$conn" == "ok" ]
  then
    echo "Logging output to ${logfile}..."
    exec 3>&1 1>>${logfile} 2>&1
    apt-get update
    dns_conf=/etc/dnsmasq.conf
    dnsmasq_conf_before=${homedir}/log/dnsmasq.conf.before.${runtime}
    dnsmasq_conf_after=${homedir}/log/dnsmasq.conf.after.${runtime}
    cp ${dns_conf} ${dnsmasq_conf_before}
    runScripts
    cp ${dns_conf} ${dnsmasq_conf_after}
    cp ${dnsmasq_conf_before} ${dns_conf}
    reboot
  else
    echo "Please check internet connectivity..."
  fi
}

function parseArgs {
  while [[ $# -ge 1 ]]
  do
    key="$1"
    case $key in
      -h|--help)
        usage
        ;;
      -c|--config)
        opt_config="true"
        ;;
      -m|--mount)
        mount_device=$2
        shift
        ;;
      -w|--wap)
        opt_wap="true"
        ;;
      -s|--ssid)
        wap_ssid=$2
        shift
        ;;
      -p|--password)
        wap_password=$2
        shift
        ;;
      *)
        ;;
    esac
    shift
  done

  if [ -n "$opt_config" ] && [ -n "$opt_wap" ]; then
    usage
  elif [ -n "$opt_config" ]; then
    installConfig
  elif [ -n "$opt_wap" ]; then
    installWap
  else
    usage
  fi
}

# Main Program
parseArgs $@
