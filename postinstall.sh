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
    sudo apt remove -y fly-scan fly-admin-iso fly-jobviewer fly-admin-usbip fly-admin-multiseat k3b recoll guvcview
    sudo apt install -y fly-dm-rdp xrdp vino fonts-inter fish git systemd-timesyncd
    sudo apt autoremove -y
}

configure_os() {
sudo tee ~/.config/fish/config.fish &>/dev/null <<'EOF'
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
        echo "  aclr        - command: 'apt clear && sudo apt autoremove'"
        echo "  ase         - command: 'apt search'"
        
        echo "Aliases:"
        echo "  ..          - 'cd ..'"
        echo "  lsa         - 'ls -al'"
        echo "  fishfetch   - function 'fish_greeting'"
        echo "  fh          - function 'fishhelp'"
    end

    function fish_greeting
        ### Minimal system info from screenfetch sources (fishfetch)
        echo "$(set_color yellow)Logged as:  $(whoami)$(set_color normal)@$(set_color yellow)$(hostname)$(set_color normal)"
        echo "$(set_color yellow)OS:$(set_color normal)         $(grep '^NAME=' /etc/os-release | cut -d '"' -f 2)"
        # echo "OS: $(lsb_release -si) $(lsb_release -sr) ($(lsb_release -sc))"
        echo "$(set_color yellow)Kernel:$(set_color normal)     $(uname -m) $(uname -sr)"
        echo "$(set_color yellow)Shell:$(set_color normal)      $(echo $SHELL)"
        echo "$(set_color yellow)CPU:$(set_color normal)       $(awk -F':' '/^model name/ {split($2, A, " @"); print A[1]; exit}' /proc/cpuinfo) Cores: $(grep -c '^cpu core' /proc/cpuinfo)"
        set mem "$(free -b | awk -F ':' 'NR==2{print $2}' | awk '{print $1"-"$6}')"
        set memsplit (string split "-" -- $mem)
        # https://stackoverflow.com/questions/34188178/how-to-extract-substring-in-fish-shell
        # set memsplitused (string split "-" -- $mem)[1]
        # set memsplittotal (string split "-" -- $mem)[2]
		set usedmem "$(math -s 1 $(math $mem) / 1024 / 1024)"
		set totalmem "$(math -s 1 $memsplit[1] / 1024 / 1024)"
        echo "$(set_color yellow)RAM:$(set_color normal)        $usedmem MiB / $totalmem MiB"
		echo "$(set_color yellow)IP:$(set_color normal)         $(hostname -I)'('$(curl -s 2ip.io)')'"
        echo "Enter 'fishhelp' or 'fh' for more info"
    end

    function last_history_item
        echo $history[1]
    end

    ### Abbreviations
    abbr -a sd sudo
    abbr -a --position anywhere "!!" --function "last_history_item"
    abbr -a --position anywhere "ain" "apt install"
    abbr -a --position anywhere "arm" "apt remove"
    abbr -a --position anywhere "aup" "apt update"
    abbr -a --position anywhere "adup" "apt update && sudo apt dist-upgrade"
    abbr -a --position anywhere "aclr" "apt clear && sudo apt autoremove"
    abbr -a --position anywhere "ase" "apt search"

    ### Aliases
    alias ..="cd .."
    alias lsa="ls -al"
    alias fishfetch="fish_greeting"
    alias fh="fishhelp"
end
EOF
	sudo chsh -s /usr/bin/fish

	sudo timedatectl set-ntp true
	sudo systemctl start systemd-timesyncd

    #/usr/libexec/vino-server
	gsettings set org.gnome.Vino notify-on-connect false
	gsettings set org.gnome.Vino icon-visibility never
	/usr/lib/vino/vino-server &
}

configure_de() {
    git clone https://github.com/xnngee/al-postinstall.git
    cp ~/al-postinstall/fly-settings.tgz ~/fly-settings.tgz
    tar xfv ~/fly-settings.tgz && rm -rf ~/fly-settings.tgz
    # kwriteconfig5 --file ~/.fly/theme/current.themerc --group Variables --key UseStartButton true
    sudo curl https://aviakat.ru/images/avi.jpg --output /usr/share/wallpapers/avi.jpg
    kwriteconfig5 --file ~/.fly/theme/current.themerc --group Variables --key WallPaper "/usr/share/wallpapers/avi.jpg"
    kwriteconfig5 --file ~/Desktops/Desktop1/.directory --group "Desktop Entry" --key X-FLY-WallPaper "/usr/share/wallpapers/avi.jpg"
    kwriteconfig5 --file ~/Desktops/Desktop2/.directory --group "Desktop Entry" --key X-FLY-WallPaper "/usr/share/wallpapers/avi.jpg"
    kwriteconfig5 --file ~/Desktops/Desktop3/.directory --group "Desktop Entry" --key X-FLY-WallPaper "/usr/share/wallpapers/avi.jpg"
    kwriteconfig5 --file ~/Desktops/Desktop4/.directory --group "Desktop Entry" --key X-FLY-WallPaper "/usr/share/wallpapers/avi.jpg"
    sudo fly-admin-dm
    sudo fly-admin-grub2
}


auto() {
    set_time
    enable_repos
    manage_apps
    configure_os
    configure_de
}

echo '== astralinux-1.8 postinstall script =='
echo 'options: '
echo '    auto              - auto postinstall'
echo '    set_time          - set real time'
echo '    enable_repose     - enable astra repository'
echo '    manage_apps       - remove unneeded packages and install RDP, VNC and some bits'
echo '    configure_os      - configurate shell, time via NTP, start VNC/RDP'
echo '    configure_de      - dark theme and some things'

$@
