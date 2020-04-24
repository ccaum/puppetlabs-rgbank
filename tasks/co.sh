#!/bin/sh

cd /opt/rgbank-rgbank/wp-content/themes/rgbank
git fetch --all
git co $PT_tag
echo "Deployed version ${PT_tag} to disk"

systemctl restart nginx
echo "Successfully deployed version ${PT_tag}"
