#!/bin/bash
apt update &&
cpan HTML::Template &&
cpan JSON &&
apt install unclutter &&
cp config_autostart/etc_xdg_lxsession_LXDE_autostart /etc/xdg/lxsession/LXDE/autostart &&
mkfifo /var/www/omxplayerpipe &&
chown www-data:www:data /var/www/omxplayerpipe
usermod -a -G video www-data &&
usermod -a -G audio www-data &&
cp config_autostart/boot_cmdline.txt /boot/cmdline.txt
