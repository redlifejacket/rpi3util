#!/bin/bash
# Set the aliases
echo "root: rpi" | sudo tee -a /etc/aliases
echo "rpi: rpi@shyamg.com" | sudo tee -a /etc/aliases
#
# Rebuild alias db and restart Postfix
sudo newaliases
sudo /etc/init.d/postfix start
