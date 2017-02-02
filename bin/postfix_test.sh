#!/bin/bash

interfaces=$(ifconfig -s | awk '{print $1}' | grep -v Iface | grep -v lo)
addresses=$(for f in $interfaces; do ifconfig $f | grep "inet addr"; done)
echo -e "FROM: root\nTO: root\nSubject: Test email from ${HOSTNAME}\n\n${HOSTNAME}\n\n${addresses}" | sendmail -t
echo -e "\e[33mTest email sent. Make sure it turns up :)\e[0m"
#echo -e "FROM: root\nTO: root\nSubject: Test email from ${HOSTNAME}\n\nThis is a test email sent from ${HOSTNAME}" | sendmail -t
