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

getPrivateTar private_tar
echo "private_tar: ${private_tar}"
createTar public_tar ${projdir} ${logdir} "public" "etc"
echo "public_tar: ${public_tar}"

[[ ! -d $etc_runtime ]] && mkdir $etc_runtime
cd $etc_runtime
tar xvf ${private_tar}
tar xvf ${public_tar}
ls -lR $etc_runtime

touch /boot/ssh
$projdir/bin/rpi3_ap_setup.sh
$projdir/bin/adapter_passthrough.sh wlan1 eth0
tar xvf $tarfile_after -C /
$projdir/bin/postfix_main.sh
$projdir/bin/postfix_aliases.sh
$projdir/bin/postfix_test.sh

