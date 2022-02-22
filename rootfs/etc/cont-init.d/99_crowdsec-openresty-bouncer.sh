#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

mkdir -p /config/crowdsec
echo "Deploy Crowdsec Openresty Bouncer manually.." 
if [ -f /config/crowdsec/crowdsec-openresty-bouncer.conf ]; then
    echo "Patch crowdsec-openresty-bouncer.conf .." 
    sed "s/=.*//g" /config/crowdsec/crowdsec-openresty-bouncer.conf > /tmp/crowdsec.conf.raw
    sed "s/=.*//g" /defaults/crowdsec/config_example.conf > /tmp/config_example.conf.raw
    if grep -vf /tmp/crowdsec.conf.raw /tmp/config_example.conf.raw ; then
        grep -vf /tmp/crowdsec.conf.raw /tmp/config_example.conf.raw > /tmp/config_example.newvals
        cp /config/crowdsec/crowdsec-openresty-bouncer.conf /config/crowdsec/crowdsec-openresty-bouncer.conf.bak
        grep -f /tmp/config_example.newvals /defaults/crowdsec/config_example.conf >> /config/crowdsec/crowdsec-openresty-bouncer.conf
    fi
else
    echo "Deploy new crowdsec-openresty-bouncer.conf .." 
    cp /defaults/crowdsec/config_example.conf /config/crowdsec/crowdsec-openresty-bouncer.conf    
fi
echo "Deploy Templates .." 
sed -i 's|/defaults/crowdsec/templates|/config/crowdsec/templates|' /config/crowdsec/crowdsec-openresty-bouncer.conf
cp -r /defaults/crowdsec/templates/* /config/crowdsec/templates/