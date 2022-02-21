#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.

log() {
    echo "[cont-init.d] $(basename $0): $*"
}

CROWDSEC_OPENRESTY_BOUNCER_VERSION=${CROWDSEC_BOUNCER_VERSION}
CROWDSEC_OPENRESTY_BOUNCER_URL=https://github.com/crowdsecurity/cs-openresty-bouncer/releases/download/v${CROWDSEC_OPENRESTY_BOUNCER_VERSION:=0.1.1}/crowdsec-openresty-bouncer.tgz

if [ ${CROWDSEC_BOUNCER} == "1" ]; then
    #Create required folders if they don't exist
    mkdir -p /tmp/crowdsec/ /config/crowdsec/templates /config/crowdsec/static_package 
    #Download the Crowdsec Openresty Bouncer if a static package is not found, this is useful for testing new versions or if we don't want to update
    if [ -f /config/crowdsec/static_package/crowdsec-openresty-bouncer.tgz ]; then 
        tar -xf /config/crowdsec/static_package/crowdsec-openresty-bouncer.tgz --strip=1 -C /tmp/crowdsec/ 
    else
        wget ${CROWDSEC_OPENRESTY_BOUNCER_URL} -O /tmp/crowdsec-openresty-bouncer.tgz
        tar -xf /tmp/crowdsec-openresty-bouncer.tgz --strip=1 -C /tmp/crowdsec/
        rm /tmp/crowdsec-openresty-bouncer.tgz
    fi
    
    # Manually Deploy Crowdsec Openresty Bouncer, this will be done by the install.sh script in crowdsec-openresty-bouncer in future.
    #https://github.com/crowdsecurity/cs-openresty-bouncer/pull/18
    if grep 'docker' /tmp/crowdsec/install.sh; then
        cd /tmp/crowdsec && bash ./install.sh --NGINX_CONF_DIR=/etc/nginx/conf.d --LIB_PATH=/var/lib/nginx/lualib --CONFIG_PATH=/config/crowdsec --DATA_PATH=/config/crowdsec --docker
    else
        echo "Deploy Crowdsec Openresty Bouncer manually.." 
        echo "Patching crowdsec_openresty.conf.." 
        #this will be handled by the installer but due to the current manual process this has to happen.
        sed -i 's|/etc/crowdsec/bouncers/crowdsec-openresty-bouncer.conf|/config/crowdsec/crowdsec-openresty-bouncer.conf|' /tmp/crowdsec/openresty/crowdsec_openresty.conf
        sed -i 's|/usr/local/openresty/lualib/plugins/crowdsec|/var/lib/nginx/lualib/plugins/crowdsec|' /tmp/crowdsec/openresty/crowdsec_openresty.conf 
        sed -i 's|${SSL_CERTS_PATH}|/etc/ssl/certs/ca-certificates.crt|' /tmp/crowdsec/openresty/crowdsec_openresty.conf
        sed -i 's|resolver local=on ipv6=off;||' /tmp/crowdsec/openresty/crowdsec_openresty.conf 
        echo "Deploy crowdsec_openresty.conf.." 
        cp /tmp/crowdsec/openresty/crowdsec_openresty.conf /etc/nginx/conf.d/
        echo "Deploy lau files.." 
        cp -r /tmp/crowdsec/lua/lib/*  /var/lib/nginx/lualib/
        if [ -f /config/crowdsec/crowdsec-openresty-bouncer.conf ]; then
            echo "Patch crowdsec-openresty-bouncer.conf .." 
            sed "s/=.*//g" /config/crowdsec/crowdsec-openresty-bouncer.conf > /tmp/crowdsec.conf.raw
            sed "s/=.*//g" /tmp/crowdsec/config/config_example.conf > /tmp/config_example.conf.raw
            if grep -vf /tmp/crowdsec.conf.raw /tmp/config_example.conf.raw ; then
                grep -vf /tmp/crowdsec.conf.raw /tmp/config_example.conf.raw > /tmp/config_example.newvals
                cp /config/crowdsec/crowdsec-openresty-bouncer.conf /config/crowdsec/crowdsec-openresty-bouncer.conf.bak
                grep -f /tmp/config_example.newvals /tmp/crowdsec/config/config_example.conf >> /config/crowdsec/crowdsec-openresty-bouncer.conf
            fi
        else
            echo "Deploy new crowdsec-openresty-bouncer.conf .." 
            cp /tmp/crowdsec/config/config_example.conf /config/crowdsec/crowdsec-openresty-bouncer.conf
            
        fi
        echo "Deploy Templates .." 
        sed -i 's|/var/lib/crowdsec/lua/templates|/config/crowdsec/templates|' /config/crowdsec/crowdsec-openresty-bouncer.conf
        cp -r /tmp/crowdsec/templates/* /config/crowdsec/templates/
    fi

    [ -n "${CROWDSEC_APIKEY}" ] && sed -i 's|API_KEY=.*|API_KEY='${CROWDSEC_APIKEY}'|' /config/crowdsec/crowdsec-openresty-bouncer.conf
    [ -n "${CROWDSEC_HOSTNAME}" ] && sed -i 's|API_URL=.*|API_URL='${CROWDSEC_HOSTNAME}'|' /config/crowdsec/crowdsec-openresty-bouncer.conf
fi
exit 0