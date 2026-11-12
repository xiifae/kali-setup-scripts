#!/bin/bash
set -e

# Default XFCE DPI is 96; bump to 110 for readable terminal fonts
# at size 10 on a 2560x1440 display without changing font size.

apply() {
    xfconf-query -c xsettings -p /Xft/DPI -s 110

    # System font from Cantarell 11 to 10
    xfconf-query -c xsettings -p /Gtk/FontName -s "Cantarell 10"

    echo "Font DPI set to 110 (default was 96). System font set to Cantarell 10."
}

reset() {
    xfconf-query -c xsettings -p /Xft/DPI -s 96
    xfconf-query -c xsettings -p /Gtk/FontName -s "Cantarell 11"

    echo "Font DPI reset to 96. System font reset to Cantarell 11."
}

case "${1:-apply}" in
    apply) apply ;;
    reset) reset ;;
    *) echo "Usage: $0 [apply|reset]"; exit 1 ;;
esac
