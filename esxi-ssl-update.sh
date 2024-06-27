#!/bin/bash

declare -a HOSTS=("esxi1" "esxi2" "esxi3" "esxi4")
DOMAIN=my.domain.com

for HOST in "${HOSTS[@]}"
do
        CURRENT_CERT=$(openssl s_client -connect $HOST.$DOMAIN:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -noout -in /dev/stdin | awk -F "=" '{print $2}')
        ESXI_CERT=$(openssl x509 -in /root/.acme.sh/$HOST.$DOMAIN/$HOST.$DOMAIN.cer -noout -fingerprint | awk -F "=" '{print $2}')

        echo Checking if the certificate is up for renewal on $HOST.$DOMAIN
        if [ "$ESXI_CERT" != "$CURRENT_CERT" ]; then
                echo Updating SSL certificate
                scp /root/.acme.sh/$HOST.$DOMAIN/$HOST.$DOMAIN.cer $HOST.$DOMAIN:/etc/vmware/ssl/rui.crt
                scp /root/.acme.sh/$HOST.$DOMAIN/$HOST.$DOMAIN.key $HOST.$DOMAIN:/etc/vmware/ssl/rui.key
                ssh $HOST.$DOMAIN 'for s in /etc/init.d/*; do $s | grep ssl_reset > /dev/null; if [ $? == 0 ]; then $s ssl_reset; fi; done'
        else
                echo The current certificate is valid.
        fi
done
