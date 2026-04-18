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

Install Miniconda and initialize it for zsh.

Arguments:
  INSTALL_DIR        Directory to install Miniconda into (default: \$HOME/miniconda)

Options:
  -u, --update       Update an existing installation (preserves envs/configs)
  -f, --force        Force install over existing directory (does not delete)
  -s, --scratch      Delete existing directory, then install fresh
  -h, --help         Show this help message and exit

If INSTALL_DIR already exists and no mode is given, the script will abort.
EOF
}

MODE=""
INSTALL_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -u|--update) MODE="update"; shift ;;
        -f|--force) MODE="force"; shift ;;
        -s|--scratch) MODE="scratch"; shift ;;
        -*) echo "${C_ERR}Unknown option: $1${C_RESET}" >&2; usage; exit 1 ;;
        *)
            if [[ -n "$INSTALL_DIR" ]]; then
                echo "${C_ERR}Unexpected argument: $1${C_RESET}" >&2; exit 1
            fi
            INSTALL_DIR="$1"; shift ;;
    esac
done

INSTALL_DIR="${INSTALL_DIR:-$HOME/miniconda}"
INSTALLER="/tmp/Miniconda3-latest-Linux-x86_64.sh"

INSTALL_FLAGS=(-b -p "$INSTALL_DIR")
if [[ -d "$INSTALL_DIR" ]]; then
    case "$MODE" in
        update)  INSTALL_FLAGS+=(-u) ;;
        force)   INSTALL_FLAGS+=(-f) ;;
        scratch)
            # Guard against accidental rm -rf on dangerous paths
            case "$INSTALL_DIR" in
                ""|/|"$HOME"|"$HOME/")
                    echo "${C_ERR}Refusing to delete '$INSTALL_DIR'${C_RESET}" >&2; exit 1 ;;
            esac
            echo "${C_WARN}Removing existing $INSTALL_DIR${C_RESET}"
            rm -rf "$INSTALL_DIR"
            ;;
        "")
            echo "${C_ERR}Error: '$INSTALL_DIR' already exists.${C_RESET}" >&2
            echo "${C_ERR}Pass --update, --force, or --scratch to proceed.${C_RESET}" >&2
            exit 1
            ;;
    esac
fi

echo "${C_INFO}Downloading Miniconda installer to${C_RESET} $INSTALLER"
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o "$INSTALLER"

echo "${C_INFO}Installing Miniconda to${C_RESET} $INSTALL_DIR"
bash "$INSTALLER" "${INSTALL_FLAGS[@]}"

echo "${C_INFO}Initializing Miniconda for zsh${C_RESET}"
"$INSTALL_DIR/bin/conda" init zsh

echo "${C_OK}You need to run \`source ~/.zshrc\` for conda initialization to take effect${C_RESET}"
