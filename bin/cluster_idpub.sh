#!/bin/bash

iplist=$(grep rpi3 /etc/dhcp.machines | awk -F',' '{print $2}')

echo "iplist: ${iplist}"

for ip in ${iplist}
do
  scp /home/pi/.ssh/id_rsa.pub pi@${ip}:/home/pi/.ssh/authorized_keys
done

