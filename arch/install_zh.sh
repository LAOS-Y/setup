#!/bin/bash

set -e

if sudo grep -q "\[archlinuxcn\]" /etc/pacman.conf; then
    echo "Detected archlinuxcn in /etc/pacman.conf, skip adding"
else
    echo "Adding archlinuxcn to /etc/pacman.conf"
    sudo sh -c 'echo -e "\n[archlinuxcn]\nServer = https://repo.archlinuxcn.org/\$arch" >> /etc/pacman.conf'
fi

echo "Updating Pacman package databases"
sudo pacman -Syy
echo "Trusting the key. See https://www.archlinuxcn.org/archlinux-cn-repo-and-mirror/ for more."
sudo pacman-key --lsign-key "farseerfc@archlinux.org"
sudo pacman -S --noconfirm archlinuxcn-keyring

echo "Installing full Noto fonts"
sudo pacman -S noto-fonts noto-fonts-cjk noto-fonts-emoji noto-fonts-extra

echo "Installing Chinese fonts"
sudo pacman -S --noconfirm adobe-source-han-sans-cn-fonts \
adobe-source-han-serif-cn-fonts \
wqy-microhei \
wqy-microhei-lite \
wqy-bitmapfont \
wqy-zenhei \
ttf-arphic-ukai \
ttf-arphic-uming

echo "Installing fcitx5-im fcitx5-chinese-addons"
sudo pacman -S --noconfirm fcitx5-im fcitx5-chinese-addons

echo "Initializing ~/.pam_environment"
echo "GTK_IM_MODULE=fcitx
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
INPUT_METHOD=fcitx
GLFW_IM_MODULE=ibus" > ~/.pam_environment

echo "Installing Offline dictionaries: Moegirl ZhWiki"
sudo pacman -S --noconfirm fcitx5-pinyin-moegirl fcitx5-pinyin-zhwiki

echo "Installing Fluent theme for fcitx5"
paru -S --noconfirm fcitx5-skin-fluentlight-git
paru -S --noconfirm fcitx5-skin-fluentdark-git

echo "You need to run \`fcitx5-config-qt\` and config these manually"

tput bold
tput setaf 4

echo "Add Pinyin to the input method group"

echo "Edit Fcitx5 global config"
echo "  1. Change input method: Super+Space"
# sed -i '/\[Hotkey\/TriggerKeys\]/,/^$/ s/0=.*$/0=Super+space/' ~/.config/fcitx5/config
echo "  2. Enumerate input method group forward: Control+Space"
# sed -i '/\[Hotkey\/EnumerateGroupForwardKeys\]/,/^$/ s/0=.*$/0=Control+space/' ~/.config/fcitx5/config
echo "  3. Enumerate input method group backward: Control+Shift+Space"
# sed -i '/\[Hotkey\/EnumerateGroupForwardKeys\]/,/^$/ s/0=.*$/0=Control+Shift+space/' ~/.config/fcitx5/config

echo "Edit Addons/Classic UI config"
echo "  1. Set default font to Sans Serif 14"
# sed -i "s/^Font=.*$/Font=\"Sans Serif 14\"/" ~/.config/fcitx5/conf/classicui.conf
echo "  2. Use Fluent as the theme"
# sed -i "s/^Theme=.*$/Theme=FluentLight/" ~/.config/fcitx5/conf/classicui.conf
# sed -i "s/^DarkTheme=.*$/DarkTheme=FluentDark/" ~/.config/fcitx5/conf/classicui.conf
# sed -i "s/^UseDarkTheme=.*$/UseDarkTheme=True/" ~/.config/fcitx5/conf/classicui.conf
echo "  3. Use Per Screen DPI"
# sed -i "s/^PerScreenDPI=.*$/PerScreenDPI=True/" ~/.config/fcitx5/conf/classicui.conf

echo "Edit Addons/Pinyin config"
echo "  1. Enable Cloud Pinyin"
# sed -i "s/^CloudPinyinEnabled=.*$/CloudPinyinEnabled=True/" ~/.config/fcitx5/conf/pinyin.conf
echo "  2. Edit fuzzy pinyin setting: partial shuangpin, en<->eng, in<->ing"
# sed -i "s/^PartialSp=.*$/PartialSp=True/" ~/.config/fcitx5/conf/pinyin.conf
# sed -i "s/^EN_ENG=.*$/EN_ENG=True/" ~/.config/fcitx5/conf/pinyin.conf
# sed -i "s/^IN_ING=.*$/IN_ING=True/" ~/.config/fcitx5/conf/pinyin.conf

# echo "Edit Punctuation config:"
# echo "  1. Use half width punctuation instead of full"
# sed -i "s/^HalfWidthPuncAfterLetterOrNumber=.*$/HalfWidthPuncAfterLetterOrNumber=True/" ~/.config/fcitx5/conf/punctuation.conf

tput sgr0

fcitx5-config-qt > /dev/null
