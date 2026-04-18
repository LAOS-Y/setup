#!/bin/bash

set -e

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [INSTALL_DIR]

Install uv and set up zsh shell completion.

Arguments:
  INSTALL_DIR        Directory to install the uv binary into (default: \$HOME/.local/bin)

Options:
  -f, --force        Force install over existing binary (does not delete cache/data)
  -s, --scratch      Delete existing binary, cache, and data, then install fresh
      --add-shim     Append a \`pip\` shell function to ~/.zshrc that forwards to \`uv pip\`
      --shim-only    Only install the \`pip\` shim in ~/.zshrc; skip downloading/installing uv
  -h, --help         Show this help message and exit

If the uv binary already exists in INSTALL_DIR and no mode is given, the script will abort.
EOF
}

MODE=""
INSTALL_DIR=""
ADD_SHIM=0
SHIM_ONLY=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) usage; exit 0 ;;
        -f|--force) MODE="force"; shift ;;
        -s|--scratch) MODE="scratch"; shift ;;
        --add-shim) ADD_SHIM=1; shift ;;
        --shim-only) SHIM_ONLY=1; shift ;;
        -*) echo "Unknown option: $1" >&2; usage; exit 1 ;;
        *)
            if [[ -n "$INSTALL_DIR" ]]; then
                echo "Unexpected argument: $1" >&2; exit 1
            fi
            INSTALL_DIR="$1"; shift ;;
    esac
done

if [[ "$SHIM_ONLY" -eq 1 ]]; then
    if [[ -n "$MODE" || "$ADD_SHIM" -eq 1 ]]; then
        echo "Error: --shim-only cannot be combined with other flags" >&2
        usage
        exit 1
    fi
    ADD_SHIM=1
fi

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
INSTALLER="/tmp/uv-install.sh"

install_shim() {
    local zshrc="$HOME/.zshrc"
    local marker_start="# >>> uv pip shim >>>"
    local marker_end="# <<< uv pip shim <<<"

    if [[ ! -f "$zshrc" ]]; then
        echo "Creating $zshrc"
        touch "$zshrc"
    fi

    if grep -qF "$marker_start" "$zshrc"; then
        echo "pip shim already present in $zshrc; skipping"
        return
    fi

    echo "Appending pip shim to $zshrc"
    cat >> "$zshrc" <<EOF

$marker_start
pip() { uv pip "\$@"; }
$marker_end
EOF
}

if [[ "$SHIM_ONLY" -eq 1 ]]; then
    if ! command -v uv >/dev/null 2>&1 && [[ ! -x "$INSTALL_DIR/uv" ]]; then
        echo "========================================================================" >&2
        echo "WARNING: uv not found on PATH or in $INSTALL_DIR" >&2
        echo "         The pip shim will fail until uv is installed." >&2
        echo "         Rerun this script without --shim-only to install uv." >&2
        echo "========================================================================" >&2
    fi
    install_shim
    echo "You need to run \`source ~/.zshrc\` for the pip shim to take effect"
    exit 0
fi

if [[ -e "$INSTALL_DIR/uv" ]]; then
    case "$MODE" in
        force) ;;
        scratch)
            echo "Removing existing uv binary, cache, and data"
            rm -f "$INSTALL_DIR/uv" "$INSTALL_DIR/uvx"
            rm -rf "$HOME/.cache/uv" "$HOME/.local/share/uv"
            ;;
        "")
            echo "Error: '$INSTALL_DIR/uv' already exists." >&2
            echo "Pass --force or --scratch to proceed." >&2
            exit 1
            ;;
    esac
fi

echo "Downloading uv installer to $INSTALLER"
curl -fsSL https://astral.sh/uv/install.sh -o "$INSTALLER"

echo "Installing uv to $INSTALL_DIR"
UV_INSTALL_DIR="$INSTALL_DIR" UV_NO_MODIFY_PATH=1 sh "$INSTALLER"

if [[ "$ADD_SHIM" -eq 1 ]]; then
    install_shim
fi

if ! command -v zsh >/dev/null 2>&1; then
    echo "zsh not found, skipping completion setup"
    if [[ "$ADD_SHIM" -eq 1 ]]; then
        echo "You need to run \`source ~/.zshrc\` for the pip shim to take effect"
    fi
    exit 0
fi

OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"

if [[ ! -d "$OMZ_DIR" ]]; then
    echo "oh-my-zsh not found, skipping completion setup"
    if [[ "$ADD_SHIM" -eq 1 ]]; then
        echo "You need to run \`source ~/.zshrc\` for the pip shim to take effect"
    fi
    exit 0
fi

COMPLETION_DIR="$OMZ_DIR/completions"
mkdir -p "$COMPLETION_DIR"

echo "Generating zsh completion for uv and uvx into $COMPLETION_DIR"
"$INSTALL_DIR/uv" generate-shell-completion zsh > "$COMPLETION_DIR/_uv"
"$INSTALL_DIR/uvx" --generate-shell-completion zsh > "$COMPLETION_DIR/_uvx"

echo "Clearing zsh completion cache"
rm -f "$HOME/.zcompdump"*

if [[ "$ADD_SHIM" -eq 1 ]]; then
    echo "You need to run \`source ~/.zshrc\` for uv completions and the pip shim to take effect"
else
    echo "You need to run \`source ~/.zshrc\` for uv completions to take effect"
fi
