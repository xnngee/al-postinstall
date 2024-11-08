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
    # sudo apt dist-upgrade -y
}

manage_apps() {
    echo ">> Remove unused packages:"
    sudo apt remove -y fly-admin-iso fly-admin-usbip fly-admin-format fly-admin-multiseat k3b recoll guvcview

    echo ">> Install needed packages:"
    sudo apt install -y fish zenity fly-dm-rdp xrdp vino fonts-inter astra-ad-sssd-client ffmpeg gwenview yandex-browser-stable firefox audacious vlc-astra libreoffice-astra okular ark doublecmd-common
    sudo apt autoremove -y
}

sethostname() {
    read -p "Enter hostname (example: k1309-01): " hostnamequery
    sudo hostnamectl hostname $hostnamequery
    sudo sed -i '/aviakat.local/d' /etc/hosts
    echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts
}

IPprefix_by_netmask() {
    bits=0
    for octet in $(echo $1| sed 's/\./ /g'); do
         binbits=$(echo "obase=2; ibase=10; ${octet}"| bc | sed 's/0//g')
         let bits+=${#binbits}
    done
    echo "${bits}"
}

# based on https://gitflic.ru/project/gabidullin-aleks/espd-astra-linux/
modify_ip() {
    IP_TYPE=$(ip route list default | awk '{print $7}')
    IP_LINK=$(ip route list default | awk '{print $5}')
    IP_UUID=$(nmcli --get-values UUID,DEVICE connection show | awk -F[":"] '/'${IP_LINK}'/ {print $1}')
    
    if [[ ${IP_TYPE} == "dhcp" ]]; then
        echo ">> Now is DHCP"
    else
        echo ">> Now is Static"
    fi
    
    echo "Internet interface: ${IP_LINK}"
    echo "Internet type: ${IP_TYPE}"
    
    read -p "Setup static internet? (y/n): " QUERY
    if [[ ${QUERY} == "y" ]]; then
        # echo "Введите статический ip-address:"
        # read IPADDRES
        read -p "Enter static IP address (192.168.XXX.XXX): " IPADDRES
    
        # echo "Введите маску подсети:"
        # read MASK
        MASK="255.255.0.0"
    
        # echo "Введите gateway (криптошлюз):"
        # read GATEWAY
        GATEWAY="192.168.1.1"
    
        # echo "Введите ip-address ДНС:"
        # read DNS
        DNS="192.168.9.1,192.168.9.2"
    
        # Assuming IPprefix_by_netmask is a function you have elsewhere
        MASK=$(IPprefix_by_netmask ${MASK})
    
        #echo "ip $IPADDRES mask $MASK gateway $GATEWAY dns $DNS"
        #echo "${IP_UUID} ipv4.method manual ipv4.address "${IPADDRES}/${MASK}" ipv4.gateway ${GATEWAY} ipv4.dns ${DNS}"
    
        echo ">> IP..."
        nmcli connection modify ${IP_UUID} ipv4.address "${IPADDRES}/${MASK}"
        nmcli conn modify ${IP_UUID} ipv4.method manual
        echo ">> Gateway..."
        nmcli connection modify ${IP_UUID} ipv4.gateway ${GATEWAY}
        echo ">> DNS..."
        nmcli connection modify ${IP_UUID} ipv4.dns ${DNS}
        #nmcli conn modify ${IP_UUID} ipv4.method manual ipv4.address "${IPADDRES}/${MASK}" ipv4.gateway ${GATEWAY} ipv4.dns ${DNS}
        nmcli connection down ${IP_UUID}
        nmcli connection up ${IP_UUID}
        # sudo reboot
    else
        read -p "Setup DHCP internet? (y/n): " QUERY
        if [[ ${QUERY} == "y" ]]; then
            nmcli connection modify ${IP_UUID} ipv4.address ""
            nmcli connection modify ${IP_UUID} ipv4.method auto
            nmcli connection modify ${IP_UUID} ipv4.gateway ""
            nmcli connection modify ${IP_UUID} ipv4.dns ""
            nmcli connection down ${IP_UUID}
            nmcli connection up ${IP_UUID}
            # sudo reboot
        fi
    fi
}

configure_os() {
    while true; do
        read -p "> Set hostname? (y/n): " -r choice
        case $choice in
            [yY]) sethostname; break;;
            [nN]) break;;
            *) echo "Invalid choice";;
        esac
    done

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

configure_os_user() {
	fish &
	sleep 1
	tee "$HOME/.config/fish/config.fish" &>/dev/null <<EOF
if status is-interactive
    ### Functions
    function fishhelp
        echo "Help for Fish Shell configurations by xenongee"
        echo "Functions:"
        echo "  fishhelp                - this help"
        echo "  fish_greeting           - minimal system info from screenfetch sources (fishfetch)"
        echo "  last_history_item       - last command from history"
        
        echo "Abbrieviations:"
        echo "  !!          - last command from history"
        echo "  sd          - command: 'sudo'"
        echo "  ain         - command: 'apt install'"
        echo "  arm         - command: 'apt remove'"
        echo "  aup         - command: 'apt update'"
        echo "  adup        - command: 'apt update && sudo apt dist-upgrade'"
        echo "  aclr        - command: 'apt clean && sudo apt autoremove'"
        echo "  ase         - command: 'apt search'"
        
        echo "Aliases:"
        echo "  ..          - 'cd ..'"
        echo "  lsa         - 'ls -al'"
        echo "  fishfetch   - function 'fish_greeting'"
        echo "  fh          - function 'fishhelp'"
        echo "  cl          - clear"
        echo "  ipe         - curl 2ip.io"
        echo "  halt        - sudo /sbin/halt"
        echo "  reboot      - sudo /sbin/reboot"
        echo "  poweroff    - sudo /sbin/poweroff"
        echo "  shutdown    - sudo /sbin/shutdown"
    end

    function fish_greeting
        ### Minimal system info from screenfetch sources (fishfetch)
        echo "\$(set_color yellow)Logged as:  \$(whoami)\$(set_color normal)@\$(set_color yellow)\$(hostname)\$(set_color normal)"
        echo "\$(set_color yellow)OS:\$(set_color normal)         \$(grep '^NAME=' /etc/os-release | cut -d '"' -f 2)"
        # echo "OS: \$(lsb_release -si) \$(lsb_release -sr) (\$(lsb_release -sc))"
        echo "\$(set_color yellow)Kernel:\$(set_color normal)     \$(uname -m) \$(uname -sr)"
        echo "\$(set_color yellow)CPU:\$(set_color normal)       \$(awk -F':' '/^model name/ {split(\$2, A, " @"); print A[1]; exit}' /proc/cpuinfo) Cores: \$(grep -c '^cpu core' /proc/cpuinfo)"
        set mem "\$(free -b | awk -F ':' 'NR==2{print \$2}' | awk '{print \$1"-"\$6}')"
        set memsplit (string split "-" -- \$mem)
        # https://stackoverflow.com/questions/34188178/how-to-extract-substring-in-fish-shell
        # set memsplitused (string split "-" -- \$mem)[1]
        # set memsplittotal (string split "-" -- \$mem)[2]
        set usedmem "\$(math -s 1 \$(math \$mem) / 1024 / 1024)"
        set totalmem "\$(math -s 1 \$memsplit[1] / 1024 / 1024)"
        echo "\$(set_color yellow)RAM:\$(set_color normal)        \$usedmem MiB / \$totalmem MiB"
        echo "\$(set_color yellow)IP:\$(set_color normal)         \$(hostname -I)"
        echo "Enter 'fishhelp' or 'fh' for more info"
    end

    function last_history_item
        echo \$history[1]
    end

    ### Abbreviations
    abbr -a sd sudo
    abbr -a --position anywhere "!!" --function "last_history_item"
    abbr -a --position anywhere "ain" "apt install"
    abbr -a --position anywhere "arm" "apt remove"
    abbr -a --position anywhere "aup" "apt update"
    abbr -a --position anywhere "adup" "apt update && sudo apt dist-upgrade"
    abbr -a --position anywhere "aclr" "apt clean && sudo apt autoremove"
    abbr -a --position anywhere "ase" "apt search"

    ### Aliases
    alias ..="cd .."
    alias lsa="ls -al"
    alias fishfetch="fish_greeting"
    alias fh="fishhelp"
    alias cl="clear"
    alias ipe="curl 2ip.io"
    alias halt="sudo /sbin/halt"
    alias reboot="sudo /sbin/reboot"
    alias poweroff="sudo /sbin/poweroff"
    alias shutdown="sudo /sbin/shutdown"
end
EOF

    gsettings set org.gnome.Vino notify-on-connect false
    gsettings set org.gnome.Vino icon-visibility never
    /usr/lib/vino/vino-server &
}

configure_de_user() {
    fly-admin-theme apply-color-scheme /usr/share/color-schemes/AstraDark.colors

    fly-wmfunc FLYWM_UPDATE_VAL TaskbarHeight 38
    fly-wmfunc FLYWM_UPDATE_VAL WallPaper "/usr/share/wallpapers/avi.jpg"
    fly-wmfunc FLYWM_UPDATE_VAL LogoPixmap "/usr/share/wallpapers/_astra_logo_light.svg"

    fly-wmfunc FLYWM_UPDATE_VAL LockerOnDPMS false
    fly-wmfunc FLYWM_UPDATE_VAL LockerOnLid false
    fly-wmfunc FLYWM_UPDATE_VAL LockerOnSleep false
    fly-wmfunc FLYWM_UPDATE_VAL LockerOnSwitch false
    fly-wmfunc FLYWM_UPDATE_VAL ScreenSaverDelay 0

    kwriteconfig5 --file "$HOME/.config/powermanagementprofilesrc" --group "AC" --group "DPMSContol" --key idleTime 0
    kwriteconfig5 --file "$HOME/.config/powermanagementprofilesrc" --group "AC" --group "DimDisplay" --key idleTime 0
    kwriteconfig5 --file "$HOME/.config/powermanagementprofilesrc" --group "AC" --group "HandleButtonEvents" --key lidAction 0
    kwriteconfig5 --file "$HOME/.config/powermanagementprofilesrc" --group "AC" --group "HandleButtonEvents" --key triggerLidActionWhenExternalMonitorPresent true
    qdbus org.kde.Solid.PowerManagement /org/kde/Solid/PowerManagement org.kde.Solid.PowerManagement.refreshStatus

    # fly-wmfunc FLYWM_UPDATE_VAL CtrlMenuFont "Inter Display-9:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL DefaultFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL DialogFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL IconFont "Inter Display-9:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL StartMenuFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL TaskbarBoldFont "Inter Display-10:bold"
    # fly-wmfunc FLYWM_UPDATE_VAL TaskbarClockFont "Inter Display-12:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL TaskbarDateFont "Inter Display-9:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL TaskbarFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL TaskbarLangFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL TitleFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL TooltipFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL CascadeMenuFont "Inter Display-10:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerEnterFont "Inter Display-13:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerInputFont "Inter Display-15:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerMonthDayFont "Inter Display-36:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerMsgFont "Inter Display-15:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerTimeFont "Inter Display-36:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerUsernameFont "Inter Display-13:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerWeekDayFont "Inter Display-11:normal"
    # fly-wmfunc FLYWM_UPDATE_VAL LockerWelcomeFont "Inter Display-14:normal"

    fly-wmfunc FLYWM_NUMLOCK_ON
}

logout() {
    fly-wmfunc FLYWM_LOGOUT
}

reboot() {
    sudo reboot
}

pinst_upd() {
    sudo rm -rf /usr/local/bin/postinstall_user.sh # remove old script

    sudo tee "/usr/local/bin/usrs" &>/dev/null <<EOF
#!/bin/bash
if [[ \$1 -eq "--help" ]]
    echo "this script lists users (uid >= 1000)\n    --sys - lists system users (uid < 1000)"
    exit 0
fi
if [[ \$1 -eq "--sys" ]]
    awk -F: '(\$3<1000){print \$1}' /etc/passwd
    exit 0
fi
    awk -F: '(\$3>=1000)&&(\$1!="nobody"){print \$1}' /etc/passwd
EOF
    sudo chmod +x /usr/local/bin/usrs
    
    echo ">> update postinstall_download.su"
    sudo tee "/usr/local/bin/postinstall_download.sh" &>/dev/null <<EOF
#!/bin/bash
sudo wget https://raw.githubusercontent.com/xnngee/al-postinstall/refs/heads/main/postinstall.sh -O /usr/local/bin/postinstall.sh 
chmod +x /usr/local/bin/postinstall.sh
exit 0
EOF
    echo ">> run postinstall_download.su"
    sudo bash /usr/local/bin/postinstall_download.sh && exit 0
}

pinst_autostart() {
    read -p "Select version (1 - shell script, 2 - desktop file, 3 - systemd service, 4 - clear all): " QUERY
    case $QUERY in
        1) 
            pinst_autostart_script
            sudo cp -rf '/etc/postinstall-autostart.sh' '/etc/xdg/autostart/postinstall-autostart.sh'
        ;;
        2) 
            pinst_autostart_desktopfile
        ;;
        3) 
            pinst_autostart_systemd
        ;;
        4)
            pinst_autostart_clear
        ;;
        *) 
            echo ''
        ;;
    esac
}

pinst_autostart_clear() {
    echo ">> Remove old starters"
    sudo rm -rf /etc/postinstall-autostart.sh &>/dev/null 
    sudo rm -rf /etc/xdg/autostart/postinstall.sh &>/dev/null # old
    sudo rm -rf /etc/xdg/autostart/postinstall-autostart.sh &>/dev/null 

    systemctl --user stop postinstall-autostart.service
    systemctl --user disable postinstall-autostart.service
    systemctl --user daemon-reload
}

pinst_autostart_script() {
    sudo tee "/etc/postinstall-autostart.sh" &>/dev/null <<EOF
#!/bin/bash
LOG_FILE="\$HOME/.config/.postinstall_log"
echo "\$(date) - started postinstall (auto)" | tee -a "\$LOG_FILE"
if [ -f "\$HOME/.config/.postinstall_done" ]; then
    echo "\$(date) - started postinstall (start_user)" | tee -a "\$LOG_FILE"
    bash /usr/local/bin/postinstall.sh start_user
    exit 0
fi
bash /usr/local/bin/postinstall.sh
EOF
    sudo chmod +x /etc/postinstall-autostart.sh
}

pinst_autostart_desktopfile() {
    pinst_autostart_script
#Exec=bash -c 'echo LOG_FILE="\$HOME/.config/.postinstall_log"; "\$(date) - started postinstall (auto)" | tee -a "\$LOG_FILE"; if [ -f "\$HOME/.config/.postinstall_done" ]; then echo "\$(date) - started postinstall (start_user)" | tee -a "\$LOG_FILE"; bash /usr/local/bin/postinstall.sh start_user; exit 0; fi; xterm -e /usr/local/bin/postinstall.sh'
    sudo tee "/etc/xdg/autostart/postinstall.desktop" &>/dev/null <<EOF
[Desktop Entry]
Name=PostInstall
Type=Application
Exec=bash /etc/postinstall-autostart.sh
Icon=utilities-terminal
Terminal=false
Categories=System;
EOF
}

pinst_autostart_systemd() {
    # /etc/systemd/system/postinstall-autostart.service
    # $HOME/.config/systemd/user/postinstall-autostart.service
    pinst_autostart_script
    mkdir -p $HOME/.config/systemd/user/
    sudo $HOME/.config/systemd/user/postinstall-autostart.service > /dev/null <<EOF
[Unit]
Description=Postinstall Autostart Script
After=graphical.target

[Service]
ExecStart=bash /etc/postinstall-autostart.sh
Restart=oneshot
Environment=XDG_RUNTIME_DIR=/run/user/%U

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl enable --user postinstall-autostart.service
    systemctl start --user postinstall-autostart.service
    systemctl status --user postinstall-autostart.service
}

start_user(){
    echo "> Start postinstal ($USER)"

    if [[ $1 -eq 0 ]]; then
        touch "$FLAG_FILE"
    fi
    
    echo "> Configure OS for $USER"
    configure_os_user
    
    echo "> Configure DE for $USER"
    configure_de_user
}

start_system() {
    echo "> Start postinstal (system)"
    echo "> Enter sudo password for running this script."
    
    echo "> Enable Repos"
    enable_repos
    
    echo "> Manage Apps"
    manage_apps
    
    echo "> Configure OS"
    configure_os
    
    echo "> Configure DE"
    configure_de
}

rm_done () {
    rm -rf "$FLAG_FILE"
}

auto() {
    if [ -f "$FLAG_FILE" ]; then
        echo "> Script has been executed before. If you want to run it again, delete the file $HOME/.config/.postinstall_done"
        exit 0
    fi
    
    echo "> AstraLinux 1.8 PostInstall"

    start_user 0

    CHECK_DOMAIN=$(whoami | grep -oq "aviakat.local"; echo $?)
    if [ "$CHECK_DOMAIN" -eq 0 ]; then
        echo "User is not local admin. Exit..."
        touch "$FLAG_FILE"
        exit 0
    fi

    start_system

    # CONNECT_DOMAIN="/usr/local/bin/connect_domain.sh"
    # if [ -f "$CONNECT_DOMAIN" ]; then
    #     bash "$CONNECT_DOMAIN"
    # else
    #     logout
    # fi

    sreboot
}

help() {
    echo "> AstraLinux 1.8 PostInstall"
    echo "  Commands:"
    echo "    - auto"
    echo "      - start_user [0 - create flag]"
    echo "        - configure_os_user"
    echo "        - configure_de_user"
    echo "      - start_system"
    echo "        - enable_repos"
    echo "        - manage_apps"
    echo "        - configure_os"
    echo "        - configure_de"
    echo " "
    echo "    - modify_ip"
    echo "    - espd_proxy"
    echo "    - espd_proxy_off"
    echo "    - logout"
    echo "    - reboot"
    echo "    - rm_done"
    echo "    - pinst_upd"
    echo "    - pinst_autostart"
}

if [[ -z "$1" ]]; then
    auto
else
    $@
fi
