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
    sudo apt dist-upgrade
}

manage_apps() {
    sudo apt remove -y fly-admin-iso fly-admin-usbip fly-admin-format fly-admin-multiseat k3b recoll guvcview
    sudo apt install -y fish zenity fly-dm-rdp xrdp vino fonts-inter astra-ad-sssd-client ffmpeg gwenview yandex-browser-stable firefox audacious vlc-astra libreoffice-astra okular ark doublecmd-common
    sudo apt autoremove -y
}

sethostname() {
    read -p "Set hostname (example: k1309-01): " hostnamequery
    sudo hostnamectl hostname $hostnamequery
    sudo sed -i '/aviakat.local/d' /etc/hosts
    echo $(hostname -I | cut -d\  -f1) $(hostname) | sudo tee -a /etc/hosts
}

configure_os() {
    read -p "Set hostname (example: k1309-01): " hostnamequery
    sudo hostnamectl hostname $hostnamequery

    while true; do
        echo "> Set hostname?"
        read -p "> Enter choice number (y/n): " -r choice
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
        echo "\$(set_color yellow)IP:\$(set_color normal)         \$(hostname -I)(\$(curl -s 2ip.io))"
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

slogout() {
    fly-wmfunc FLYWM_LOGOUT
}

sreboot() {
    sudo reboot
}

update() {
    sudo wget https://raw.githubusercontent.com/xnngee/al-postinstall/refs/heads/main/postinstall.sh -O /usr/local/bin/postinstall.sh 
}

start_user(){
    echo "> Start postinstal ($USER)"
    
    echo "> Configure OS for $USER"
    configure_os_user
    echo "> Configure DE for $USER"
    сonfigure_de_user
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

auto() {
    if [ -f "$FLAG_FILE" ]; then
        echo "> Script has been executed before. If you want to run it again, delete the file $HOME/.config/.postinstall_done"
        exit 0
    fi
    
    echo "> AstraLinux 1.8 PostInstall"

    start_user
    
    touch "$FLAG_FILE"

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
    echo "    - enable_repos"
    echo "    - manage_apps"
    echo "    - configure_os"
    echo "    - configure_de"
    echo "    - configure_os_user"
    echo "    - configure_de_user"
    echo "    - slogout"
    echo "    - sreboot"
    echo "    - update (this is a script update)"
}

if [[ -z "$1" ]]; then
    auto
else
    $@
fi
