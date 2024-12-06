#!/usr/bin/env bash
##############################################################################
# Readme: https://access.redhat.com/solutions/30564
# Don't forget to setup routing tables in : /etc/iproute2/rt_tables
# 3128 gb
# 3129 ru
# 3130 se
# ....
##############################################################################

country=vpn


if [ -n "$dev" ] || [ -n "$ifconfig_local" ] || [ -n "$route_vpn_gateway" ];
then 
  # Should change 10.7.7.48 -> 10.7.7.0 for rt_table
  ifconfig_subnet=`echo $ifconfig_local | grep -oE "([0-9]{1,3}\.){3}"`0


  ip route add $ifconfig_subnet/24 dev $dev src $ifconfig_local table $country
  ip route add table $country default via $route_vpn_gateway dev $dev
  ip rule add table $country from $ifconfig_local

fi
killall -9 dumbproxy
/usr/local/bin/dumbproxy $PROXY_AUTH  -ip-hints "$ifconfig_local"  -bind-address 0.0.0.0:8888 &

exit 0
