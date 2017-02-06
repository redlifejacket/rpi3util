#!/bin/bash

iplist=$(grep rpi3 /etc/dhcp.machines | awk -F',' '{print $2}')

echo "iplist: ${iplist}"

for ip in ${iplist}
do
  ssh pi@${ip} shutdown -h now
done

