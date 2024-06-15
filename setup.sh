#!/bin/bash

set -e

echo "zsh location: $(which zsh)"

echo "Installing oh-my-zsh"
RUNZSH=no sh -c "$(curl -fsSL https://install.ohmyz.sh/)"

echo "Backing up .zshrc to .zshrc.bak"
cp ~/.zshrc ~/.zshrc.bak

NEW_THEME="ys"
# NEW_THEME=agnoster  # one other theme
echo "Setting the theme to '$NEW_THEME'"
sed -i "s/^ZSH_THEME=\".*\"$/ZSH_THEME=\"$NEW_THEME\"/" ~/.zshrc

echo "Installing plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i 's/^plugins=(.*)$/\plugins=(\
    git\
    tmux\
    colored-man-pages\
    zsh-autosuggestions\
    zsh-syntax-highlighting\
)/' ~/.zshrc

echo "Copying config for git and tmux"
script_path=$(readlink -f ${BASH_SOURCE[0]})
script_dir=$(dirname "$script_path")

cp "$script_dir"/.gitconfig ~/
cp "$script_dir"/.tmux.conf ~/

echo "Switching to ZSH"
zsh
