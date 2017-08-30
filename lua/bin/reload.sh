#!/bin/bash

cd $(dirname $0) && cd ..
/home/s/apps/openresty/nginx/sbin/nginx -p . -s reload
