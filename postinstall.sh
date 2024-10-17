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
    sudo apt install -y fish zenity fly-dm-rdp xrdp vino fonts-inter astra-ad-sssd-client
    sudo apt autoremove -y
}

configure_os() {
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
        echo "\$(set_color yellow)IP:\$(set_color normal)         \$(hostname -I)'('\$(curl -s 2ip.io)')'"
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
    sudo chsh -s /usr/bin/fish

    #/usr/libexec/vino-server
    gsettings set org.gnome.Vino notify-on-connect false
    gsettings set org.gnome.Vino icon-visibility never
    sudo gsettings set org.gnome.Vino notify-on-connect false
    sudo gsettings set org.gnome.Vino icon-visibility never
    /usr/lib/vino/vino-server &
}

configure_de() {
    sudo curl https://aviakat.ru/images/avi_optimized.jpg --output /usr/share/wallpapers/avi.jpg
    
    # sudo fly-admin-dm
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key NumLock On
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --key path "/usr/share/wallpapers/avi.jpg"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "blur" --key radius "7"
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "logo" --key path ""
    sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-modern/settings.ini --group "background" --group "logo" --key enable false
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Core" --key DefaultUser "$USER"
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Core" --key FocusPasswd true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Core" --key PreselectUser Default
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key DefaultUser "$USER"
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key FocusPasswd true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-*-Greeter" --key PreselectUser Default
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:*-Greeter" --key FocusPasswd true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Core" --key AutoLoginEnable true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Core" --key AutoLoginUser "$USER"
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Greeter" --key DefaultUser "$USER"
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Greeter" --key FocusPasswd true
    # sudo kwriteconfig5 --file /etc/X11/fly-dm/fly-dmrc --group "X-:0-Greeter" --key PreselectUser Default
    
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
    bash /usr/local/bin/postinstall_user.sh
    echo ""
    echo "> AstraLinux 1.8 PostInstall Sys"
    echo "> Enter sudo password for running this script."
    echo ""
    echo "> Enable Repos"
    enable_repos
    echo "> Manage Apps"
    manage_apps
    echo "> Configure OS"
    configure_os
    echo "> Configure DE"
    configure_de
    logout
    touch "$FLAG_FILE"
    rm -rf "$HOME/.config/autostart/postinstall.desktop"
}  

auto
