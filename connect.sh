#!/bin/bash

# Get password
echo -n York Password: 
read -s password
echo

# Eduroam
# Is eduroam already configured?
if nmcli con show eduroam > /dev/null ; then
  echo "Eduroam already exists, updating password..."
  nmcli con modify "eduroam" 802-1x.password "$password"
else
  echo "Setting up eduroam..."
  nmcli con add\
    type wifi\
    con-name "eduroam"\
    ssid "eduroam"\
    wifi-sec.key-mgmt "wpa-eap"\
    802-1x.identity "drb502@york.ac.uk"\
    802-1x.password "$password"\
    802-1x.ca-cert "/etc/ssl/certs/Comodo_AAA_Services_root.pem"\
    802-1x.domain-suffix-match "york.ac.uk"\
    802-1x.eap "peap"\
    802-1x.phase2-auth "mschapv2"
  
  nmcli connection up eduroam
fi

# Wired Connection

# Check there's only one wired connection
number_connections=$(nmcli -t -f NAME,TYPE connection show --active|grep -ethernet|wc -l)

if [ $number_connections -gt 1 ]
  then echo "There's more than one wired connection active. Sorry, I can't handle that."
  exit
fi

# Define wired variables
name=$(nmcli -t -f NAME,TYPE connection show --active|grep -ethernet|cut -d ":" -f1)
uuid=$(nmcli -t -f UUID,TYPE connection show --active|grep -ethernet|cut -d ":" -f1)
interfacename=$(nmcli -t -f DEVICE,TYPE connection show --active|grep -ethernet|cut -d ":" -f1)

echo "Disabling network connection..."
nmcli connection down "$name"

#sleep 2

echo "Applying network settings..."
nmcli con modify "$name" 802-1x.eap peap\
 802-1x.identity drb502@york.ac.uk\
 802-1x.phase2-auth mschapv2\
 802-1x.password "$password"\
 802-1x.ca-cert "/etc/ssl/certs/Comodo_AAA_Services_root.pem"\
 802-1x.anonymous-identity "@york.ac.uk"

echo "Re-enabling network connection..."
nmcli connection up "$name"
