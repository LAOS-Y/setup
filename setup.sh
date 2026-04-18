#!/bin/bash

set -e

echo "zsh location: $(which zsh)"

OMZ_DIR="$HOME/.oh-my-zsh"

if [ -d "$OMZ_DIR" ]; then
    # Create a unique backup name with a timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_DIR="${OMZ_DIR}.bak.${TIMESTAMP}"
    
    echo "Existing Oh-My-Zsh detected."
    echo "Backing up '$OMZ_DIR' to '$BACKUP_DIR'..."
    mv "$OMZ_DIR" "$BACKUP_DIR"
fi

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

echo "Adding ~/.local/bin to PATH"
sed -i '/^# export MANPATH=/a export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc

echo "Copying config for git and tmux"
script_path=$(readlink -f ${BASH_SOURCE[0]})
script_dir=$(dirname "$script_path")

cp "$script_dir"/.gitconfig ~/
cp "$script_dir"/.tmux.conf ~/

if [ -t 0 ]; then
    echo "Terminal detected. Switching to ZSH..."
    # 'exec' replaces the current script process with zsh
    # '-l' ensures it starts as a login shell (reads profile configs)
    exec zsh -l
else
    echo "No TTY detected (running in automation/pipe). Skipping interactive ZSH switch."
fi
