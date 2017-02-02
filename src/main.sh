#!/bin/bash

runtime=$(date +%Y%m%d%H%M%S)
tarfile_before=/tmp/etc_before_${runtime}.tar
tarfile_after=/tmp/etc_after_${runtime}.tar
tar cvf $tarfile_before $(for f in `find etc`; do echo "/${f}"; done)
tar cvf $tarfile_after ../etc
tar xvf $tarfile_after -C /

../bin/rpi3_ap_setup.sh
../bin/adapter_passthrough.sh
../bin/postfix_main.sh
../bin/postfix_aliases.sh
../bin/postfix_test.sh
