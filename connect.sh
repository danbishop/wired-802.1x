#!/bin/bash

# sudo check
if [ "$EUID" -ne 0 ]
  then echo "Please run with sudo"
  exit
fi

echo -n York Password: 
read -s password
echo

name=$(nmcli --get-values NAME c show --active)
uuid=$(nmcli --get-values UUID c show --active)
interfacename=$(nmcli --get-values DEVICE c show --active)


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

echo "Disabling network connection..."
nmcli con down "$name"
echo "Re-enabling network connection..."
nmcli con up "$name"