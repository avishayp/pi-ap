#!/usr/bin/env bash

# run from reporoot/
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

first_time_setup() {
    sudo apt-get update
    sudo apt-get install -y \
        hostapd \
        dnsmasq
}

on_boot() {
    cmp fakeroot/etc/version.info /etc/version.info >/dev/null 2>&1 && echo "latest version installed" || sudo cp -pRv fakeroot/* /
    sudo iptables-restore < /etc/iptables.ipv4.nat
}

once() {
    which dnsmasq && echo "dnsmasq already installed - first-time setup not needed" || first_time_setup
}

echo "`date` $USER starting boot script from $PWD"

once && on_boot || echo "oops"
