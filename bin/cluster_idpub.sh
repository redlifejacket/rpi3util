#!/bin/bash

iplist=$(grep rpi /etc/dhcp.machines | awk -F',' '{print $3}')
user=pirate
homedir=/home/${user}
sshdir=${homedir}/.ssh
idpub=${sshdir}/id_rsa.pub
authkeys=${sshdir}/authorized_keys
endpoint=${user}@$(hostname)

echo "iplist: ${iplist}"

if [ ! -f ${idpub} ]
then
  ssh-keygen -t rsa -c "${endpoint}"
fi
for ip in ${iplist}
do
  #scp ${idpub} pirate@${ip}:${homedir}/.ssh/authorized_keys
  cat ${idpub} | ssh ${endpoint} 'cat >> ${authkeys}'
done

