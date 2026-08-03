#!/usr/bin/env bash

# Copies the local mermaid.min.js build over markdown-preview.nvim's bundled
# one. Run standalone anytime — e.g. after bumping the version, or after a
# plugin update reset the bundled file back to markdown-preview's default.

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()     { echo -e "${RED}[ERROR]${NC} $1"; }

MERMAID_VERSION="${1:-11.6.0}"   # override: ./mermaid-update.sh 11.7.0

CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"

SRC="$CONFIG_DIR/files/mermaid-${MERMAID_VERSION}.min.js"
DEST="$DATA_DIR/lazy/markdown-preview.nvim/app/_static/mermaid.min.js"

if [ ! -f "$SRC" ]; then
    err "Not found: $SRC"
    exit 1
fi

if [ ! -d "$(dirname "$DEST")" ]; then
    err "markdown-preview.nvim isn't installed yet (launch nvim in dev mode first)"
    exit 1
fi

cp -f "$SRC" "$DEST"
success "Copied mermaid ${MERMAID_VERSION} -> $DEST"
