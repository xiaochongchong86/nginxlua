#!/bin/bash

if [ ! -d /home/s/logs/history ]; then
	mkdir /home/s/logs/history
fi

cd $(dirname $0) && cd ..
idc=$(hostname |awk -F "." '{printf $3}')

ln -sf nginx_$idc.conf conf/nginx.conf
if [ $(ps -ef | grep nginx | grep -v grep| wc -l) -gt 2 ] ; then
    /home/s/apps/openresty/nginx/sbin/nginx -p . -s reload
else
    /home/s/apps/openresty/nginx/sbin/nginx -p .
fi
