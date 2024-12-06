#!/usr/bin/env bash
#ret=$(curl  -s http://ip-api.com/json | jq '.countryCode' | tr '[:upper:]' '[:lower:]' | tr -d '"'|  grep "$COUNTRY" | wc -l)
ret=$(curl  --proxy-anyauth --proxy-user "$PROXY_USER:$PROXY_PASS" -s --proxy localhost:8888  https://ifconfig.io/country_code | tr '[:upper:]' '[:lower:]' | tr -d '"'|  grep "$COUNTRY" | wc -l)
if [ $ret -eq 1 ]; then
    exit 0
else
    exit 1
fi

