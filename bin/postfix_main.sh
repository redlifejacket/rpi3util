# taken from
# https://blog.dantup.com/2016/04/setting-up-raspberry-pi-raspbian-jessie-to-send-email/
sudo tee /etc/postfix/main.cf > /dev/null <<EOF

# Where to read account aliases, used to map all emails onto one account
# and then on to a real email address
alias_maps = hash:/etc/aliases

# This sets the hostname, which will be used for outgoing email
myhostname = rpi3-lite0

# This is the mailserver to connect to deliver email
# NOTE: This must be the MX server for the account you wish to deliver email to
# or an open relay (but you hopefully won't find one of them). In my case, this
# is Google's first MX server (which can be found by doing an MX lookup on my domain).
relayhost = aspmx.l.google.com

# Which interfaces to listen on. We don't want anyone connected to our Pi to send email,
# so we set this to the local loopback interface only.
inet_interfaces = loopback-only

# This one is important for the reasons mentioned above. This means only IPv4 will be used,
# avoiding the IPv6 restrictions Google have in place.
inet_protocols = ipv4

EOF
