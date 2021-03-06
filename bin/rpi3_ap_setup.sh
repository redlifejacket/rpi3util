#!/bin/bash
#
# Taken from https://gist.github.com/Lewiscowles1986/fecd4de0b45b2029c390
# This version uses September 2016 rpi jessie image, please use this image
#

if [ "$EUID" -ne 0 ]
then echo "Must be root"
  exit
fi

if [[ $# -lt 1 ]]; 
then echo "You need to pass a password!"
  echo "Usage:"
  echo "sudo $0 yourChosenPassword [apName]"
  exit
fi

APPASS="$1"
APSSID="rPi3"

if [[ $# -eq 2 ]]; then
  APSSID=$2
fi

apt-get remove --purge hostapd -y
apt-get install hostapd dnsmasq -y

cat > /etc/systemd/system/hostapd.service <<EOF
[Unit]
Description=Hostapd IEEE 802.11 Access Point
After=sys-subsystem-net-devices-wlan0.device
BindsTo=sys-subsystem-net-devices-wlan0.device

[Service]
Type=forking
PIDFile=/var/run/hostapd.pid
ExecStart=/usr/sbin/hostapd -B /etc/hostapd/hostapd.conf -P /var/run/hostapd.pid

[Install]
WantedBy=multi-user.target

EOF

cat > /etc/dnsmasq.conf <<EOF
interface=wlan0
dhcp-range=10.0.0.2,10.0.0.5,255.255.255.0,12h
EOF

cat > /etc/hostapd/hostapd.conf <<EOF
interface=wlan0
hw_mode=g
channel=10
auth_algs=1
wpa=2
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
rsn_pairwise=CCMP
wpa_passphrase=$APPASS
ssid=$APSSID
EOF

sed -i -- 's/allow-hotplug wlan0//g' /etc/network/interfaces
sed -i -- 's/iface wlan0 inet manual//g' /etc/network/interfaces
sed -i -- 's/    wpa-conf \/etc\/wpa_supplicant\/wpa_supplicant.conf//g' /etc/network/interfaces

  #wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf
cat >> /etc/network/interfaces <<EOF

# Added by rPi Access Point Setup
allow-hotplug wlan0
iface wlan0 inet static
  address 10.0.0.1
  netmask 255.255.255.0
  network 10.0.0.0
  broadcast 10.0.0.255

EOF

echo "denyinterfaces wlan0" >> /etc/dhcpcd.conf

systemctl enable hostapd

echo "All done! Please reboot"
