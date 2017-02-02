#!/bin/bash
# Based on https://gist.github.com/Lewiscowles1986/f303d66676340d9aa3cf6ef1b672c0c9
# -i wlan1 -o eth0

if [ "$EUID" -ne 0 ]
	then echo "Must be root"
	exit
fi

MAXARG=2
#ADAPTER="eth0"
[[ $# -ne ${MAXARG} ]] && echo "Usage: $0 <IN_ADAPTER> <OUT_ADAPTER>" && exit
# Allow overriding from eth0 by passing in a single argument
if [ $# -eq ${MAXARG} ]; then
    IN_ADAPTER="$1"
    OUT_ADAPTER="$2"
fi
echo "IN_ADAPTER:  ${IN_ADAPTER}"
echo "OUT_ADAPTER: ${OUT_ADAPTER}"

#Uncomment net.ipv4.ip_forward
sed -i -- 's/#net.ipv4.ip_forward/net.ipv4.ip_forward/g' /etc/sysctl.conf
#Change value of net.ipv4.ip_forward if not already 1
sed -i -- 's/net.ipv4.ip_forward=0/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
#Activate on current system
echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -t nat -A POSTROUTING -o $OUT_ADAPTER -j MASQUERADE  
iptables -A FORWARD -i $IN_ADAPTER -o $IN_ADAPTER -m state --state RELATED,ESTABLISHED -j ACCEPT  
iptables -A FORWARD -i $IN_ADAPTER -o $OUT_ADAPTER -j ACCEPT