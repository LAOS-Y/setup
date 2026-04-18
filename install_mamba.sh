#!/bin/bash

set -e

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
        -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *)
            if [[ -n "$INSTALL_DIR" ]]; then
                echo "Unexpected argument: $1" >&2; exit 1
            fi
            INSTALL_DIR="$1"; shift ;;
    esac
done

if [[ "$ALIAS_ONLY" -eq 1 ]]; then
    if [[ -n "$MODE" || "$ADD_ALIAS" -eq 1 || -n "$INSTALL_DIR" ]]; then
        echo "Error: --alias-only cannot be combined with other flags" >&2
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
        echo "Error: $ZSHRC does not exist; cannot add alias" >&2
        exit 1
    fi
    if ! grep -q '^# >>> mamba initialize >>>$' "$ZSHRC" \
        || ! grep -q '^# <<< mamba initialize <<<$' "$ZSHRC"; then
        echo "Error: mamba initialize block not found in $ZSHRC; run \`micromamba shell init -s zsh\` first" >&2
        exit 1
    fi
    if grep -q '^alias mm=micromamba$' "$ZSHRC"; then
        echo "Alias 'mm' already present in $ZSHRC; skipping"
        return
    fi
    echo "Appending 'mm' alias inside the mamba initialize block"
    sed -i '/^# <<< mamba initialize <<<$/i\
# user addition (not part of `micromamba shell init`): shorthand alias,\
# placed inside the block so `micromamba shell deinit` removes it too\
alias mm=micromamba
' "$ZSHRC"
}

if [[ "$ALIAS_ONLY" -eq 1 ]]; then
    add_alias
    echo "You need to run \`source ~/.zshrc\` for the alias to take effect"
    exit 0
fi

if [[ -d "$INSTALL_DIR" ]]; then
    case "$MODE" in
        force) ;;
        scratch)
            case "$INSTALL_DIR" in
                ""|/|"$HOME"|"$HOME/")
                    echo "Refusing to delete '$INSTALL_DIR'" >&2; exit 1 ;;
            esac
            echo "Removing existing $INSTALL_DIR and $BIN_DIR/micromamba"
            rm -rf "$INSTALL_DIR"
            rm -f "$BIN_DIR/micromamba"
            ;;
        "")
            echo "Error: '$INSTALL_DIR' already exists." >&2
            echo "Pass --force or --scratch to proceed." >&2
            exit 1
            ;;
    esac
fi

echo "Downloading micromamba installer to $INSTALLER"
curl -fsSL https://micro.mamba.pm/install.sh -o "$INSTALLER"

echo "Installing micromamba (binary in $BIN_DIR, root prefix $INSTALL_DIR)"
BIN_FOLDER="$BIN_DIR" \
PREFIX_LOCATION="$INSTALL_DIR" \
INIT_YES=N \
CONDA_FORGE_YES=N \
bash "$INSTALLER" </dev/null

echo "Initializing micromamba for zsh"
"$BIN_DIR/micromamba" shell init -s zsh -r "$INSTALL_DIR"

if [[ "$ADD_ALIAS" -eq 1 ]]; then
    add_alias
fi

if [[ "$ADD_ALIAS" -eq 1 ]]; then
    echo "You need to run \`source ~/.zshrc\` for micromamba initialization and the alias to take effect"
else
    echo "You need to run \`source ~/.zshrc\` for micromamba initialization to take effect"
fi
