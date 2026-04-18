#!/bin/bash

set -e

if [ -t 1 ]; then
    C_INFO=$'\033[1;36m'
    C_OK=$'\033[1;32m'
    C_WARN=$'\033[1;33m'
    C_ERR=$'\033[1;31m'
    C_RESET=$'\033[0m'
else
    C_INFO=""; C_OK=""; C_WARN=""; C_ERR=""; C_RESET=""
fi

echo "${C_INFO}zsh location:${C_RESET} $(which zsh)"

OMZ_DIR="$HOME/.oh-my-zsh"

if [ -d "$OMZ_DIR" ]; then
    # Create a unique backup name with a timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="${OMZ_DIR}.bak.${TIMESTAMP}"
    
    echo "${C_WARN}Existing Oh-My-Zsh detected.${C_RESET}"
    echo "${C_INFO}Backing up${C_RESET} '$OMZ_DIR' ${C_INFO}to${C_RESET} '$BACKUP_DIR'..."
    mv "$OMZ_DIR" "$BACKUP_DIR"
fi

echo "${C_INFO}Installing oh-my-zsh${C_RESET}"
RUNZSH=no sh -c "$(curl -fsSL https://install.ohmyz.sh/)"

echo "${C_INFO}Backing up .zshrc to .zshrc.bak${C_RESET}"
cp ~/.zshrc ~/.zshrc.bak

NEW_THEME="ys"
# NEW_THEME=agnoster  # one other theme
echo "${C_INFO}Setting the theme to${C_RESET} '$NEW_THEME'"
sed -i "s/^ZSH_THEME=\".*\"$/ZSH_THEME=\"$NEW_THEME\"/" ~/.zshrc

echo "${C_INFO}Installing plugins${C_RESET}"
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
sed -i 's/^plugins=(.*)$/\plugins=(\
    git\
    tmux\
    colored-man-pages\
    zsh-autosuggestions\
    zsh-syntax-highlighting\
)/' ~/.zshrc

echo "${C_INFO}Adding ~/.local/bin to PATH${C_RESET}"
sed -i '/^# export MANPATH=/a export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc

echo "${C_INFO}Copying config for git and tmux${C_RESET}"
script_path=$(readlink -f ${BASH_SOURCE[0]})
script_dir=$(dirname "$script_path")

cp "$script_dir"/.gitconfig ~/
cp "$script_dir"/.tmux.conf ~/

if [ -t 0 ]; then
    echo "${C_OK}Terminal detected. Switching to ZSH...${C_RESET}"
    # 'exec' replaces the current script process with zsh
    # '-l' ensures it starts as a login shell (reads profile configs)
    exec zsh -l
else
    echo "${C_WARN}No TTY detected (running in automation/pipe). Skipping interactive ZSH switch.${C_RESET}"
fi
