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
    sudo apt install -y fish zenity fly-dm-rdp xrdp vino fonts-inter astra-ad-sssd-client ffmpeg gwenview yandex-browser-stable firefox audacious vlc-astra libreoffice-astra okular ark doublecmd-common
    sudo apt autoremove -y
}

configure_os() {
    read -p "Set hostname (example: k1309-01): " hostnamequery
    sudo hostnamectl hostname $hostnamequery

    sudo sed -i '/aviakat.local/d' /etc/hosts
    echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts

    #/usr/libexec/vino-server
    gsettings set org.gnome.Vino notify-on-connect false
    gsettings set org.gnome.Vino icon-visibility never
    sudo gsettings set org.gnome.Vino notify-on-connect false
    sudo gsettings set org.gnome.Vino icon-visibility never
    /usr/lib/vino/vino-server &
}

configure_de() {
    # TODO: Disable some desktop files

    fly-admin-theme apply-color-scheme /usr/share/color-schemes/AstraProximaAdmin.colors
    sudo curl https://aviakat.ru/images/avi_optimized.jpg --output /usr/share/wallpapers/avi.jpg
    fly-wmfunc FLYWM_UPDATE_VAL WallPaper "/usr/share/wallpapers/avi.jpg"
    fly-wmfunc FLYWM_UPDATE_VAL LogoPixmap "/usr/share/wallpapers/astra_logo_light.svg"

    # plan b:
    # sudo cp -rf /etc/skel/ /etc/skel.bak
    # sudo wget https://github.com/xnngee/al-postinstall/raw/refs/heads/main/fly-settings.tgz -O /tmp/fly-settings.tgz
    # sudo tar -xvf /tmp/fly-settings.tgz -C /tmp/fly-settings
    # sudo cp -f /tmp/fly-settings/.config/ /etc/skel
    # sudo cp -f /tmp/fly-settings/.fly/ /etc/skel

    # sudo fly-admin-dm
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key NumLock On
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --key path "/usr/share/wallpapers/avi.jpg"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "blur" --key radius "7"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "logo" --key path ""
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "logo" --key enable false

    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Core" --key DefaultUser "$USER"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Core" --key FocusPasswd true
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Core" --key PreselectUser Previous
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key DefaultUser "$USER"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key FocusPasswd true
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key PreselectUser Previous
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:*-Greeter" --key FocusPasswd true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Core" --key AutoLoginEnable true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Core" --key AutoLoginUser "$USER"
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Greeter" --key DefaultUser "$USER"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Greeter" --key FocusPasswd true
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Greeter" --key PreselectUser Previous

    # sudo fly-admin-grub2
    sudo kwriteconfig5 --file /etc/default/grub --group '<default>' --key GRUB_TIMEOUT 0
    sudo update-grub2
}

logout() {
    sleep 5 && fly-wmfunc FLYWM_LOGOUT
}

auto() {
    if [ -f "$FLAG_FILE" ]; then
        echo "> Script has been executed before. If you want to run it again, delete the file $HOME/.config/.postinstall_done"
        exit 0
    fi
    echo ""
    echo "> AstraLinux 1.8 PostInstall Sys"
    echo ""
    echo "> Start postinstal for user"
    bash /usr/local/bin/postinstall_user.sh

    CHECK_DOMAIN=$(whoami | grep -oq "aviakat.local"; echo $?)
    if [ "$CHECK_DOMAIN" -eq 0 ]; then
        echo "User is not local admin. Exit..."
        touch "$FLAG_FILE"
        exit 0
    fi
    echo "> Enter sudo password for running this script."
    echo "> Enable Repos"
    enable_repos
    echo "> Manage Apps"
    manage_apps
    echo "> Configure OS"
    configure_os
    echo "> Configure DE"
    configure_de

    # CONNECT_DOMAIN="/usr/local/bin/connect_domain.sh"
    # if [ -f "$CONNECT_DOMAIN" ]; then
    #     bash "$CONNECT_DOMAIN"
    # else
    #     logout
    # fi
    
    touch "$FLAG_FILE"
    sudo reboot
}  

auto
