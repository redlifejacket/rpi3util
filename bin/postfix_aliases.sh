#!/bin/bash
# Set the aliases
echo "root: rpi3" | sudo tee -a /etc/aliases
echo "rpi3: rpi3@shyamg.com" | sudo tee -a /etc/aliases
#
# Rebuild alias db and restart Postfix
sudo newaliases
sudo /etc/init.d/postfix start
