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

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [INSTALL_DIR]

Install micromamba and initialize it for zsh.

Arguments:
  INSTALL_DIR        Directory to install micromamba root prefix into (default: \$HOME/micromamba)

Options:
  -f, --force        Force install over existing directory (does not delete)
  -s, --scratch      Delete existing directory and binary, then install fresh
      --add-alias    Append \`alias mm=micromamba\` inside the mamba initialize block
      --alias-only   Only append the alias; skip installing/initializing micromamba
  -h, --help         Show this help message and exit

If INSTALL_DIR already exists and no mode is given, the script will abort.
EOF
}

MODE=""
INSTALL_DIR=""
ADD_ALIAS=0
ALIAS_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -f|--force) MODE="force"; shift ;;
        -s|--scratch) MODE="scratch"; shift ;;
        --add-alias) ADD_ALIAS=1; shift ;;
        --alias-only) ALIAS_ONLY=1; shift ;;
        -*) echo "${C_ERR}Unknown option: $1${C_RESET}" >&2; usage; exit 1 ;;
        *)
            if [[ -n "$INSTALL_DIR" ]]; then
                echo "${C_ERR}Unexpected argument: $1${C_RESET}" >&2; exit 1
            fi
            INSTALL_DIR="$1"; shift ;;
    esac
done

if [[ "$ALIAS_ONLY" -eq 1 ]]; then
    if [[ -n "$MODE" || "$ADD_ALIAS" -eq 1 || -n "$INSTALL_DIR" ]]; then
        echo "${C_ERR}Error: --alias-only cannot be combined with other flags${C_RESET}" >&2
        usage
        exit 1
    fi
    ADD_ALIAS=1
fi

INSTALL_DIR="${INSTALL_DIR:-$HOME/micromamba}"
BIN_DIR="$HOME/.local/bin"
INSTALLER="/tmp/micromamba-install.sh"
ZSHRC="$HOME/.zshrc"

add_alias() {
    if [[ ! -f "$ZSHRC" ]]; then
        echo "${C_ERR}Error: $ZSHRC does not exist; cannot add alias${C_RESET}" >&2
        exit 1
    fi
    if ! grep -q '^# >>> mamba initialize >>>$' "$ZSHRC" \
        || ! grep -q '^# <<< mamba initialize <<<$' "$ZSHRC"; then
        echo "${C_ERR}Error: mamba initialize block not found in $ZSHRC; run \`micromamba shell init -s zsh\` first${C_RESET}" >&2
        exit 1
    fi
    if grep -q '^alias mm=micromamba$' "$ZSHRC"; then
        echo "${C_WARN}Alias 'mm' already present in $ZSHRC; skipping${C_RESET}"
        return
    fi
    echo "${C_INFO}Appending 'mm' alias inside the mamba initialize block${C_RESET}"
    sed -i '/^# <<< mamba initialize <<<$/i\
# user addition (not part of `micromamba shell init`): shorthand alias,\
# placed inside the block so `micromamba shell deinit` removes it too\
alias mm=micromamba
' "$ZSHRC"
}

if [[ "$ALIAS_ONLY" -eq 1 ]]; then
    add_alias
    echo "${C_OK}You need to run \`source ~/.zshrc\` for the alias to take effect${C_RESET}"
    exit 0
fi

if [[ -d "$INSTALL_DIR" ]]; then
    case "$MODE" in
        force) ;;
        scratch)
            case "$INSTALL_DIR" in
                ""|/|"$HOME"|"$HOME/")
                    echo "${C_ERR}Refusing to delete '$INSTALL_DIR'${C_RESET}" >&2; exit 1 ;;
            esac
            echo "${C_WARN}Removing existing $INSTALL_DIR and $BIN_DIR/micromamba${C_RESET}"
            rm -rf "$INSTALL_DIR"
            rm -f "$BIN_DIR/micromamba"
            ;;
        "")
            echo "${C_ERR}Error: '$INSTALL_DIR' already exists.${C_RESET}" >&2
            echo "${C_ERR}Pass --force or --scratch to proceed.${C_RESET}" >&2
            exit 1
            ;;
    esac
fi

echo "${C_INFO}Downloading micromamba installer to${C_RESET} $INSTALLER"
curl -fsSL https://micro.mamba.pm/install.sh -o "$INSTALLER"

echo "${C_INFO}Installing micromamba (binary in $BIN_DIR, root prefix $INSTALL_DIR)${C_RESET}"
BIN_FOLDER="$BIN_DIR" \
PREFIX_LOCATION="$INSTALL_DIR" \
INIT_YES=N \
CONDA_FORGE_YES=N \
bash "$INSTALLER" </dev/null

echo "${C_INFO}Initializing micromamba for zsh${C_RESET}"
"$BIN_DIR/micromamba" shell init -s zsh -r "$INSTALL_DIR"

if [[ "$ADD_ALIAS" -eq 1 ]]; then
    add_alias
fi

if [[ "$ADD_ALIAS" -eq 1 ]]; then
    echo "${C_OK}You need to run \`source ~/.zshrc\` for micromamba initialization and the alias to take effect${C_RESET}"
else
    echo "${C_OK}You need to run \`source ~/.zshrc\` for micromamba initialization to take effect${C_RESET}"
fi
