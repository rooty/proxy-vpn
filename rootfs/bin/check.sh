#!/usr/bin/env bash
ret=$(curl  -s http://ip-api.com/json | jq '.countryCode' | tr '[:upper:]' '[:lower:]' | tr -d '"'|  grep "$COUNTRY" | wc -l)
if [ $ret -eq 1 ]; then
    echo 0
else
    echo 1
fi

