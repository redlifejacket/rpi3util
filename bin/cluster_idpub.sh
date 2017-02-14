#!/bin/bash

iplist=$(grep rpi /etc/dhcp.machines | awk -F',' '{print $3}')
user=pirate
homedir=/home/${user}

echo "iplist: ${iplist}"

for ip in ${iplist}
do
  scp ${homedir}/.ssh/id_rsa.pub pirate@${ip}:${homedir}/.ssh/authorized_keys
done

