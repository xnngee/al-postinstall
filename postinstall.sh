#!/bin/bash

set_time() {
    sudo timedatectl set-timezone Europe/Kirov
    sudo ntpdig -S 0.ru.pool.ntp.org
}

enable_repos() {
sudo tee /etc/apt/sources.list &>/dev/null <<EOF
#deb cdrom:[OS Astra Linux 1.8.1.6 1.8_x86-64 DVD ]/ 1.8_x86-64 contrib main non-free non-free-firmware
deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-main/ 1.8_x86-64 main contrib non-free non-free-firmware
#deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-devel/ 1.8_x86-64 main contrib non-free non-free-firmware
deb https://download.astralinux.ru/astra/stable/1.8_x86-64/repository-extended/ 1.8_x86-64 main contrib non-free non-free-firmware
#deb https://dl.astralinux.ru/astra/frozen/1.8_x86-64/1.8.1/main-repository/     1.8_x86-64 main contrib non-free
#deb https://dl.astralinux.ru/astra/frozen/1.8_x86-64/1.8.1/extended-repository/ 1.8_x86-64 main contrib non-free
EOF
    sudo apt update
}

manage_apps() {
    sudo apt remove -y fly-scan fly-admin-iso fly-jobviewer fly-shutdown-scheduler fly-admin-usbip fly-admin-multiseat k3b recoll guvcview
    sudo apt install -y fly-dm-rdp xrdp vino fonts-inter git
    sudo apt autoremove -y
}

configure_de() {
    git clone https://github.com/xnngee/al-postinstall.git
    cp ~/al-postinstall/fly-settings.tgz ~
    tar xfv ~/fly-settings.tgz
    rm -rf ~/fly-settings.tgz
    kwriteconfig5 --file ~/.fly/theme/current.themerc --group Variables --key UseStartButton true
    sudo fly-admin-dm
    sudo fly-admin-grub2
}


auto() {
    set_time
    enable_repos
    manage_apps
    configure_de
}

echo '== astralinux-1.8 postinstall script =='
echo 'options: '
echo '    auto              - auto postinstall'
echo '    set_time          - set real time'
echo '    enable_repose     - enable astra repository'
echo '    manage_apps       - remove unneeded packages and install RDP, VNC and some bits'
echo '    configure_de      - dark theme and some things'

$@
