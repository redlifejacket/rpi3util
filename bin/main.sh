#!/bin/bash

projdir=/home/pi/rpi3util_master
cd $projdir
runtime=$(date +%Y%m%d%H%M%S)
tarfile_before=/tmp/etc_before_${runtime}.tar
tarfile_after=/tmp/etc_after_${runtime}.tar
tar cvf $tarfile_before $(for f in `find etc`; do echo "/${f}"; done)
tar cvf $tarfile_after etc

$projdir/bin/rpi3_ap_setup.sh
$projdir/bin/adapter_passthrough.sh wlan1 eth0
tar xvf $tarfile_after -C /
$projdir/bin/postfix_main.sh
$projdir/bin/postfix_aliases.sh
$projdir/bin/postfix_test.sh
