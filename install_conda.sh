#!/bin/bash

set -e

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
        -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *)
            if [[ -n "$INSTALL_DIR" ]]; then
                echo "Unexpected argument: $1" >&2; exit 1
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
                    echo "Refusing to delete '$INSTALL_DIR'" >&2; exit 1 ;;
            esac
            echo "Removing existing $INSTALL_DIR"
            rm -rf "$INSTALL_DIR"
            ;;
        "")
            echo "Error: '$INSTALL_DIR' already exists." >&2
            echo "Pass --update, --force, or --scratch to proceed." >&2
            exit 1
            ;;
    esac
fi

echo "Downloading Miniconda installer to $INSTALLER"
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o "$INSTALLER"

echo "Installing Miniconda to $INSTALL_DIR"
bash "$INSTALLER" "${INSTALL_FLAGS[@]}"

echo "Initializing Miniconda for zsh"
"$INSTALL_DIR/bin/conda" init zsh

echo "You need to run \`source ~/.zshrc\` for conda initialization to take effect"
