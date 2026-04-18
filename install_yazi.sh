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

if [ $# -eq 0 ]; then
    USE_PACMAN=0
elif [ "$1" == "arch" ]; then
    USE_PACMAN=1
else
    echo "${C_ERR}Usage: $0 [arch]${C_RESET}"
    echo "${C_INFO}If 'arch' is provided as an argument, pacman will be used to install yazi.${C_RESET}"
    echo "${C_INFO}Otherwise, the script will download the latest release from GitHub and install it $HOME/.local/.${C_RESET}"
    exit 1
fi

echo "${C_INFO}Detecting current shell${C_RESET}"
if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    CONFIG_FILE="$HOME/.bashrc"
    echo "${C_OK}Bash detected.${C_RESET} ${C_INFO}Config file path:${C_RESET} $CONFIG_FILE"
elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    CONFIG_FILE="$HOME/.zshrc"
    echo "${C_OK}Zsh detected.${C_RESET} ${C_INFO}Config file path:${C_RESET} $CONFIG_FILE"
else
    echo "${C_ERR}Unsupported shell: $SHELL${C_RESET}"
    exit 1
fi

if [ $USE_PACMAN -eq 1 ]; then
    echo "${C_INFO}Using pacman for the installation.${C_RESET}"
    sudo pacman -Sy
    sudo pacman -S yazi
else
    GITHUB_REPO="sxyazi/yazi"
    LATEST_URL=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"browser_download_url.*/yazi-x86_64-unknown-linux-gnu.zip"$' | cut -d '"' -f 4)
    echo "${C_INFO}Downloading the latest release from GitHub:${C_RESET} $LATEST_URL"
    wget -O yazi-x86_64-unknown-linux-gnu.zip -L $LATEST_URL
    unzip yazi-x86_64-unknown-linux-gnu.zip
    rm yazi-x86_64-unknown-linux-gnu.zip
    mkdir -p $HOME/.local
    mv yazi-x86_64-unknown-linux-gnu $HOME/.local
    echo -e "\n" >> $CONFIG_FILE
    echo 'export PATH="$HOME/.local/yazi-x86_64-unknown-linux-gnu/:$PATH"' >> $CONFIG_FILE
    PATH="$HOME/.local/yazi-x86_64-unknown-linux-gnu/:$PATH"
fi

echo "${C_INFO}Start installing plugins${C_RESET}"

ya pack -a yazi-rs/plugins:smart-enter
ya pack -a yazi-rs/plugins:git
ya pack -a KKV9/compress
ya pack -a h-hg/yamb
ya pack -a llanosrocas/yaziline
ya pack -a yazi-rs/plugins:full-border
ya pack -a yazi-rs/plugins:max-preview
ya pack -a dedukun/relative-motions
echo "${C_WARN}You should try mactag.yazi if you are using MacOS.${C_RESET}"

CONTENT='
# For Yazi, provides the ability to change the current working directory when exiting Yazi
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
    fi
    rm -f -- "$tmp"
}
'

if ! grep -Fxq "function y() {" "$CONFIG_FILE"; then
    echo "$CONTENT" >> "$CONFIG_FILE"
    echo "${C_OK}The shell warper is added to${C_RESET} $CONFIG_FILE"
else
    echo "${C_WARN}The shell warper already exists in${C_RESET} $CONFIG_FILE"
fi
echo "${C_INFO}See https://yazi-rs.github.io/docs/quick-start#shell-wrapper${C_RESET}"

echo "${C_INFO}start copying config files to $HOME/.config/yazi${C_RESET}"
script_path=$(readlink -f ${BASH_SOURCE[0]})
script_dir=$(dirname "$script_path")

ls "$script_dir"/yazi/
cp "$script_dir"/yazi/* $HOME/.config/yazi
