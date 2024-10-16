#!/bin/bash
#title              : AstraLinux 1.8 PostInstall Sys
#description        : Automation script after setup
#author             : xenongee
#date               : 10.2024
#==============================================================================

mkdir -p "$HOME/.config"
FLAG_FILE="$HOME/.config/.postinstall_done"

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
    sudo apt remove -y fly-admin-iso fly-admin-usbip fly-admin-format fly-admin-multiseat k3b recoll guvcview
    sudo apt install -y fish zenity fly-dm-rdp xrdp vino fonts-inter astra-ad-sssd-client ffmpeg yandex-browser-stable firefox
    sudo apt autoremove -y
}

configure_os() {
    sudo chsh -s /usr/bin/fish

    #/usr/libexec/vino-server
    gsettings set org.gnome.Vino notify-on-connect false
    gsettings set org.gnome.Vino icon-visibility never
    sudo gsettings set org.gnome.Vino notify-on-connect false
    sudo gsettings set org.gnome.Vino icon-visibility never
    /usr/lib/vino/vino-server &
}

configure_de() {
    fly-admin-theme apply-color-scheme /usr/share/color-schemes/AstraProximaAdmin.colors
    sudo curl https://aviakat.ru/images/avi_optimized.jpg --output /usr/share/wallpapers/avi.jpg && sleep 1

    # plan b:
    # sudo cp -rf /etc/skel/ /etc/skel.bak
    # sudo wget https://github.com/xnngee/al-postinstall/raw/refs/heads/main/fly-settings.tgz -O /tmp/fly-settings.tgz
    # sudo tar -xvf /tmp/fly-settings.tgz -C /tmp/fly-settings
    # sudo cp -f /tmp/fly-settings/.config/ /etc/skel
    # sudo cp -f /tmp/fly-settings/.fly/ /etc/skel

    # sudo fly-admin-dm
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key NumLock On
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --key path "/usr/share/wallpapers/avi.jpg"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "blur" --key radius "7"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "logo" --key path ""
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "logo" --key enable false

    # sudo fly-admin-grub2
    sudo kwriteconfig5 --file /etc/default/grub --group '<default>' --key GRUB_TIMEOUT 0
    sudo update-grub2
}

logout() {
    sleep 5 && fly-wmfunc FLYWM_LOGOUT
}

auto() {
    if [ -f "$FLAG_FILE" ]; then
        exit 0
    fi
    echo ""
    echo "> AstraLinux 1.8 PostInstall Sys"
    echo ""
    echo "> Start postinstal for user"
    bash /usr/local/bin/postinstall_user.sh
    echo "> Enter sudo password for running this script."
    echo "> Enable Repos"
    enable_repos
    echo "> Manage Apps"
    manage_apps
    echo "> Configure OS"
    configure_os
    echo "> Configure DE"
    configure_de
    # logout
    bash /usr/local/bin/connect_domain.sh
    touch "$FLAG_FILE"
}  

auto
