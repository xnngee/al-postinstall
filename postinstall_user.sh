#!/bin/bash
#title              : AstraLinux 1.8 PostInstall User
#description        : Automation script after setup
#author             : xenongee
#date               : 10.2024
#==============================================================================

mkdir -p "$HOME/.config"
FLAG_FILE="$HOME/.config/.postinstall_done"

configure_os() {
    gsettings set org.gnome.Vino notify-on-connect false
    gsettings set org.gnome.Vino icon-visibility never
    /usr/lib/vino/vino-server &
}

configure_de() {
    fly-admin-theme apply-color-scheme /usr/share/color-schemes/AstraProximaAdmin.colors

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

    fly-wmfunc FLYWM_UPDATE_VAL CtrlMenuFont "Inter Display-9:normal"
    fly-wmfunc FLYWM_UPDATE_VAL DefaultFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL DialogFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL IconFont "Inter Display-9:normal"
    fly-wmfunc FLYWM_UPDATE_VAL StartMenuFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL TaskbarBoldFont "Inter Display-10:bold"
    fly-wmfunc FLYWM_UPDATE_VAL TaskbarClockFont "Inter Display-12:normal"
    fly-wmfunc FLYWM_UPDATE_VAL TaskbarDateFont "Inter Display-9:normal"
    fly-wmfunc FLYWM_UPDATE_VAL TaskbarFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL TaskbarLangFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL TitleFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL TooltipFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL CascadeMenuFont "Inter Display-10:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerEnterFont "Inter Display-13:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerInputFont "Inter Display-15:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerMonthDayFont "Inter Display-36:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerMsgFont "Inter Display-15:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerTimeFont "Inter Display-36:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerUsernameFont "Inter Display-13:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerWeekDayFont "Inter Display-11:normal"
    fly-wmfunc FLYWM_UPDATE_VAL LockerWelcomeFont "Inter Display-14:normal"

    fly-wmfunc FLYWM_NUMLOCK_ON
}


auto() {
    if [ -f "$FLAG_FILE" ]; then
        exit 0
    fi
    echo ""
    echo "> AstraLinux 1.8 PostInstall User"
    echo ""
    echo "> Configure OS"
    configure_os
    echo "> Configure DE"
    configure_de
    touch "$FLAG_FILE"
    rm -rf "$HOME/.config/autostart/postinstall.desktop"
}  

auto
