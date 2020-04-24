#!/bin/sh

cd /opt/rgbank-rgbank/wp-content/themes/rgbank
git fetch --all
git co $PT_tag

systemctl restart nginx
