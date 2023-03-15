#!/bin/bash

# sudo check
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

# Check there's only one wired connection
number_connections=$(nmcli -t -f NAME,TYPE connection show --active|grep -ethernet|wc -l)

if [ $number_connections -gt 1 ]
  then echo "There's more than one wired connection active. Sorry, I can't handle that."
  exit
fi

# Get password
echo -n York Password: 
read -s password
echo

# Reset eduroam password
cat >"/etc/NetworkManager/system-connections/eduroam.nmconnection" <<EOF
[connection]
id=eduroam
uuid=aaed9a44-5d63-4701-bb13-bd71f913a798
type=wifi
interface-name=wlp1s0

[wifi]
mode=infrastructure
ssid=eduroam

[wifi-security]
auth-alg=open
key-mgmt=wpa-eap

[802-1x]
anonymous-identity=@york.ac.uk
ca-cert=/etc/ssl/certs/Comodo_AAA_Services_root.pem
eap=ttls;
identity=drb502@york.ac.uk
password=$password
phase2-auth=mschapv2

[ipv4]
method=auto

[ipv6]
addr-gen-mode=stable-privacy
method=auto

[proxy]
EOF
chmod 600 "/etc/NetworkManager/system-connections/eduroam.nmconnection"

name=$(nmcli -t -f NAME,TYPE connection show --active|grep -ethernet|cut -d ":" -f1)
uuid=$(nmcli -t -f UUID,TYPE connection show --active|grep -ethernet|cut -d ":" -f1)
interfacename=$(nmcli -t -f DEVICE,TYPE connection show --active|grep -ethernet|cut -d ":" -f1)

cat >"/etc/NetworkManager/system-connections/$name.nmconnection" <<EOF
[connection]
id=$name
uuid=$uuid
type=ethernet
autoconnect-priority=-999
interface-name=$interfacename
timestamp=$EPOCHSECONDS

[ethernet]

[802-1x]
anonymous-identity=@york.ac.uk
ca-cert=/etc/ssl/certs/Comodo_AAA_Services_root.pem
eap=peap;
identity=drb502@york.ac.uk
password=$password
phase2-auth=mschapv2

[ipv4]
method=auto

[ipv6]
addr-gen-mode=stable-privacy
method=auto

[proxy]
EOF

chmod 600 "/etc/NetworkManager/system-connections/$name.nmconnection"

nmcli connection reload

echo "Disabling network connection..."
nmcli connection down "$name"
sleep 5
echo "Re-enabling network connection..."
nmcli connection up "$name"
