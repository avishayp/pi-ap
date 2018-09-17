#!/usr/bin/env bash

# enable access point on raspberry pi
# usage:
# ./setup.sh ssid_name ssid_pass hostname
#
# default values are all raspberry-ap (security at user's risk)

# run from reporoot/
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

first_time_setup() {
    sudo apt-get update
    sudo apt-get install -y \
        dnsmasq \
        hostapd
}

get_piapi() {
    which git || sudo apt-get install -y git
    pushd $(mktemp -d)
    git clone https://github.com/avishayp/pi-ap
}

update() {
    sed -i "s/ssid=.*/ssid=${SSID_NAME}/g; s/wpa_passphrase=.*/wpa_passphrase=${SSID_PASS}/g" fakeroot/etc/hostapd/hostapd.conf

    echo "$HOST_NAME" > fakeroot/etc/hostname
    sed -i "s/127.0.1.1.*/127.0.1.1 ${HOST_NAME}/g" fakeroot/etc/hosts

    sudo cp -pRv fakeroot/* /
    cp ap_setup.sh /etc/
    sudo reboot
}

is_uptodate() {
    cmp -s fakeroot/etc/version /etc/version \
        && [ "$SSID_NAME" == "$ssid" ] \
        && [ "$SSID_PASS" == "$wpa_passphrase" ] \
        && [ "$HOST_NAME" == "$hostname" ]
}

on_boot() {
    if [ ! -d fakeroot ] ; then
        get_piapi
        source pi-ap/ap_setup.sh "$SSID_NAME" "$SSID_PASS" "$HOST_NAME"
        exit $?
    fi

    is_uptodate && echo "nothing changed, ap is up to date" || update
}

once() {
    which hostapd && echo "hostapd already installed" || first_time_setup
}

get_params() {
    # get current values
    if [ -f /etc/hostapd/hostapd.conf ] ; then
        source <(grep ssid /etc/hostapd/hostapd.conf)
        source <(grep wpa_passphrase /etc/hostapd/hostapd.conf)
    fi
    hostname="$(hostname)"

    echo "ssid_name: $ssid ==> $SSID_NAME"
    echo "ssid_pass: $wpa_passphrase ==> $SSID_PASS"
    echo "hostname: $hostname ==> $HOST_NAME"
}

SSID_NAME=${1-"raspberry-ap"}
SSID_PASS=${2-"raspberry-ap"}
HOST_NAME=${3-"raspberry-ap"}

get_params
once && on_boot
