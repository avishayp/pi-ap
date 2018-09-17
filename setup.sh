#!/usr/bin/env bash

# run from reporoot/
pushd "$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"/..

get_ngrok() {
    wget https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-arm.zip -O /tmp/ngrok.zip
    sudo unzip /tmp/ngrok.zip -d /usr/local/bin/
    sudo ln -fs /usr/local/bin/ngrok /usr/bin/ngrok
    ngrok version
}

install_apt_deps() {
    sudo apt-get update
    sudo apt-get install -y \
        hostapd \
        dnsmasq \
        nginx \
        redis-server \
        python3-pip \
        supervisor
}

collect_py_deps() {
    cat on_pi/requirements.txt | cut -d ' ' -f2 | xargs -n 1 -IFN fgrep "==" FN | sort | uniq
}

install_py_deps() {
    collect_py_deps | xargs -n 1 sudo pip3 install
}

make_dirs() {
    sudo mkdir -p /www/static
    sudo chown -R pi:pi /www

    mkdir -p /home/pi/noyad
}

update_web_assets() {
    get_external_web_assets
    cp -R client/app/* /www/static/
}

update_config() {
    sudo cp -pRv on_pi/fakeroot/* /
    sudo chown root:root /etc/rc.local /etc/logrotate.d/applogs
    cp version.info /www/version
}

# only run after fresh image installation
# requires network
first_time_setup() {
    install_apt_deps && make_dirs
}

kill_supervisor() {
    sudo systemctl disable supervisor
    sudo systemctl stop supervisor
    sudo pkill python
}

on_boot() {
    # nginx <-> uwsgi:
    sudo mkdir -p /var/run/wsgi
    sudo chown -R pi:pi /var/run/wsgi

    # kick supervisor only after all files were copied
    sudo /usr/bin/python /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

    sudo iptables-restore < /etc/iptables.ipv4.nat
}

once() {
    which ngrok && echo "first-time setup not needed" || first_time_setup
}

update_hostname() {
    sed -i "s/noyad/${HOST}/g" /etc/hostname
    sed -i "s/noyad/${HOST}/g" /etc/hosts
    sed -i "s/noyad-pi/${HOST}/g" /etc/ngrok/ngrok.yml
}

echo "`date` $USER starting boot script from $PWD"

once && on_boot || echo "oops"
