#!/bin/bash

iplist=$(grep rpi3 /etc/dhcp.machines | awk -F',' '{print $3}')
user=pirate

echo "iplist: ${iplist}"

for ip in ${iplist}
do
  ssh ${user}@${ip} shutdown -h now
done

