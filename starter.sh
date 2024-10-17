#!/bin/bash
#title              : AstraLinux 1.8 Starter Script
#description        : Тут будут меню с дополнительными командами
#author             : xenongee
#date               : 10.2024
#==============================================================================

while true; do
    echo ""
    echo "@ AstraLinux 1.8 Starter"
    echo ""
    echo "[none]"
    echo ""
    echo "0. Exit"
    echo ""

    read -p "> Enter choice number: " -r choice
    case $choice in
    0)
        exit 0
        ;;
    *)
        echo "> Warn: unknown option: "
        sleep 2
        ;;
    esac
done