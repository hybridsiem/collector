#!/bin/sh
tmp=`/opt/immune/bin/li-admin/iptables.sh -nvL INPUT | grep 10.98.11.1 | awk '{print $3}'`
#echo "$tmp"
if [ -z $tmp ]
then
/opt/immune/bin/li-admin/iptables.sh -I INPUT 2 -p tcp -s 10.98.1.1 --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
fi

tmp=`/opt/immune/bin/li-admin/iptables.sh -nvL INPUT | grep 10.98.12.1 | awk '{print $3}'`
#echo "$tmp"
if [ -z $tmp ]
then
/opt/immune/bin/li-admin/iptables.sh -I INPUT 2 -p tcp -s 10.98.1.1 --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
fi

tmp=`/opt/immune/bin/li-admin/iptables.sh -nvL INPUT | grep 10.98.13.1 | awk '{print $3}'`
#echo "$tmp"
if [ -z $tmp ]
then
/opt/immune/bin/li-admin/iptables.sh -I INPUT 2 -p tcp -s 10.98.1.1 --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
fi


echo "Please provide to BESECURE the following address for remote support"

ifconfig | grep tun10001 -C1 | awk '{print $2}'