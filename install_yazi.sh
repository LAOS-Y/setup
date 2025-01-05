set -e

if [ $# -eq 0 ]; then
    USE_PACMAN=0
elif [ "$1" == "arch" ]; then
    USE_PACMAN=1
else
    echo "Usage: $0 [arch]"
    echo "If 'arch' is provided as an argument, pacman will be used to install yazi."
    echo "Otherwise, the script will download the latest release from GitHub and install it $HOME/.local/."
    exit 1
fi

echo "Detecting current shell"
if [ "$SHELL" = "/bin/bash" ] || [ "$SHELL" = "/usr/bin/bash" ]; then
    CONFIG_FILE="$HOME/.bashrc"
    echo "Bash detected. Config file path: $CONFIG_FILE"
elif [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]; then
    CONFIG_FILE="$HOME/.zshrc"
    echo "Zsh detected. Config file path: $CONFIG_FILE"
else
    echo "Unsupported shell: $SHELL"
    exit 1
fi

if [ $USE_PACMAN -eq 1 ]; then
    echo "Using pacman for the installation."
    sudo pacman -Sy
    sudo pacman -S yazi
else
    GITHUB_REPO="sxyazi/yazi"
    LATEST_URL=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | grep '"browser_download_url.*/yazi-x86_64-unknown-linux-gnu.zip"$' | cut -d '"' -f 4)
    echo "Downloading the latest release from GitHub: $LATEST_URL"
    wget -O yazi-x86_64-unknown-linux-gnu.zip -L $LATEST_URL
    unzip yazi-x86_64-unknown-linux-gnu.zip
    rm yazi-x86_64-unknown-linux-gnu.zip
    mkdir -p $HOME/.local
    mv yazi-x86_64-unknown-linux-gnu $HOME/.local
    echo -e "\n" >> $CONFIG_FILE
    echo 'export PATH="$HOME/.local/yazi-x86_64-unknown-linux-gnu/:$PATH"' >> $CONFIG_FILE
    PATH="$HOME/.local/yazi-x86_64-unknown-linux-gnu/:$PATH"
fi

echo "Start installing plugins"

ya pack -a yazi-rs/plugins:smart-enter
ya pack -a yazi-rs/plugins:git
ya pack -a KKV9/compress
ya pack -a h-hg/yamb
ya pack -a llanosrocas/yaziline
ya pack -a yazi-rs/plugins:full-border
ya pack -a yazi-rs/plugins:max-preview
ya pack -a dedukun/relative-motions
echo "You should try mactag.yazi if you are using MacOS."

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
    echo "The shell warper is added to $CONFIG_FILE"
else
    echo "The shell warper already exists in $CONFIG_FILE"
fi
echo "See https://yazi-rs.github.io/docs/quick-start#shell-wrapper"

echo "start copying config files to $HOME/.config/yazi"
script_path=$(readlink -f ${BASH_SOURCE[0]})
script_dir=$(dirname "$script_path")

ls "$script_dir"/yazi/
cp "$script_dir"/yazi/* $HOME/.config/yazi
