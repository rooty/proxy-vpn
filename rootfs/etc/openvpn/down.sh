#!/usr/bin/env bash
##############################################################################
# Readme: https://access.redhat.com/solutions/30564
# Don't forget to setup routing tables in : /etc/iproute2/rt_tables
# 3128 gb
# 3129 ru
# 3130 se
# ....
##############################################################################

killall -9 dumbproxy
/usr/local/bin/dumbproxy ${CMD_OPTS}   -bind-address 0.0.0.0:8888 &

exit 0
