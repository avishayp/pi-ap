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
    sed -i "s/.*ssid=.*/ssid=${SSID_NAME}/g; s/.*wpa_passphrase.*/wpa_passphrase=${SSID_PASS}/g" fakeroot/etc/hostapd/hostapd.conf

    echo "$HOST_NAME" > fakeroot/etc/hostname
    sed -i "s/.*127.0.1.1.*/127.0.1.1 ${HOST_NAME}/g" fakeroot/etc/hosts

    sudo cp -pRv fakeroot/* /
    cp ap_setup.sh /etc/
    sudo reboot
}

on_boot() {
    if [ ! -d fakeroot ] ; then
        get_piapi
        source pi-ap/ap_setup.sh "$SSID_NAME" "$SSID_PASS" "$HOST_NAME"
        exit $?
    fi

    cmp -s fakeroot/etc/version /etc/version && echo "latest version installed" || update
}

once() {
    which hostapd && echo "dnsmasq already installed" || first_time_setup
}

SSID_NAME=${1-"raspberry-ap"}
SSID_PASS=${2-"raspberry-ap"}
HOST_NAME=${3-"raspberry-ap"}

once && on_boot
