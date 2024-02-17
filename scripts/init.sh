
#!/bin/bash

sudo apt-get install --no-install-recommends zsh
#chsh -s $(which zsh)
sudo apt-get install --no-install-recommends fzf vim git zoxide ripgrep bat duf curl openssh-client todotxt-cli davfs2 at-spi2-core rtkit
sudo apt-get install --no-install-recommends xserver-xorg-input-libinput wireplumber pipewire-pulse pipewire-alsa syncthing ncmpcpp
sudo apt-get install --no-install-recommends lightdm bspwm polybar picom rofi feh dunst redshift x11-xserver-utils
sudo apt-get install --no-install-recommends alacritty
sudo apt-get install --no-install-recommends bibata-cursor-theme gnome-themes-extra librsvg2-common
sudo apt-get install --no-install-recommends fcitx fcitx-sunpinyin fcitx-ui-classic

sudo sed -i 's/# ignore_dav_header = 0/ignore_dav_header = 1/g' /etc/davfs2/davfs2.conf
sudo sed -i 's/# use_locks 1/use_locks 0/g' /etc/davfs2/davfs2.conf


script_content='export XMODIFIERS=@im=fcitx
export XIM=fcitx
export GTK_IM_MODULE=xim
export LC_CTYPE="zh_CN.UTF-8"

fcitx -d
'

echo "$script_content" | sudo tee /etc/X11/Xsession.d/95xinput > /dev/null

mount_context='[Unit]
Description=Mount WebDAV Service
After=network-online.target
Wants=network-online.target

[Mount]
What=https://dav.jianguoyun.com/dav/todo
Where=/home/uglyboy/.todo-txt
Options=uid=1000,file_mode=0664,dir_mode=2775,grpid
Type=davfs
TimeoutSec=15

[Install]
WantedBy=multi-user.target
'

echo "$mount_context" | sudo tee /etc/systemd/system/home-uglyboy-.todo\\x2dtxt.mount > /dev/null

automount_context='[Unit]
Description=Mount WebDAV Service

[Automount]
Where=/home/uglyboy/.todo-txt
TimeoutIdleSec=300

[Install]
WantedBy=remote-fs.target
'

echo "$automount_context" | sudo tee /etc/systemd/system/home-uglyboy-.todo\\x2dtxt.automount > /dev/null

sudo systemctl daemon-reload
sudo systemctl enable home-uglyboy-.todo\\x2dtxt.automount

echo "https://dav.jianguoyun.com/dav/todo uglyboy@aliyun.com augbtmbeyznr3f65" >> /etc/davfs2/secrets
sudo systemctl enable syncthing@uglyboy.service
sudo apt-get install --no-install-recommends python3-poetry python3-websocket libnotify-bin
cd /home/uglyboy/Code/Archive/gotify-dunst && sudo make install
sudo apt-get remove --purge vim-tiny tasksel nftables nano zhcon
#cd /home/uglyboy/Code/Archive/fastgithub && sudo ./fastgithub start
#sudo sed -i 's/XKBOPTIONS=""/XKBOPTIONS="ctrl:swapcaps,altwin:swap_lalt_lwin"/g' /etc/default/keyboard
#sudo groupadd -r autologin
#sudo gpasswd -a uglyboy autologin
#sudo sed -i 's/#autologin-user=/autologin-user=uglyboy/g' /etc/lightdm/lightdm.conf
sudo sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
sudo update-grub2
#sudo apt-get install --no-install-recommends celluloid

sudo sed -i '/^deb-src/s/^/#/' /etc/apt/sources.list
sudo sed -i 's/\(deb.*\) bookworm main non-free-firmware/\1 bookworm main contrib non-free non-free-firmware/' /etc/apt/sources.list

sudo apt-get update
sudo apt-get install --no-install-recommends linux-headers-amd64 nvidia-kernel-open-dkms nvidia-driver firmware-misc-nonfree
sudo apt-get install --no-install-recommends file ueberzug upower xdg-desktop-portal-gtk accountsservice policykit-1-gnome plymouth
#sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="quiet"/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nvidia-drm.modeset=1"/g' /etc/default/grub
#sudo plymouth-set-default-theme -R tribar
#sudo update-grub2

