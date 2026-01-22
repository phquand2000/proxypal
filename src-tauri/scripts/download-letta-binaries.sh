#!/bin/bash
# Download Letta-enhanced CLIProxyAPI binaries from your fork
# Usage: ./download-letta-binaries.sh [target]

set -e

BINARY_NAME="${1:-}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BINARIES_DIR="$SCRIPT_DIR/../binaries"

# Point to your fork with Letta integration
# Change this to your GitHub username/repo
CLIPROXYAPI_REPO="${CLIPROXYAPI_REPO:-phquand2000/CLIProxyAPI}"

# Get latest letta-* release
get_latest_letta_version() {
    curl -s "https://api.github.com/repos/${CLIPROXYAPI_REPO}/releases" | \
        grep '"tag_name"' | \
        grep 'letta-v' | \
        head -1 | \
        sed -E 's/.*"letta-v([^"]+)".*/\1/'
}

VERSION=$(get_latest_letta_version)
if [ -z "$VERSION" ]; then
    echo "Error: Could not fetch latest Letta version from ${CLIPROXYAPI_REPO}"
    echo "Make sure you have pushed and released your Letta fork"
    exit 1
fi
echo "Using Letta CLIProxyAPI version: $VERSION"

mkdir -p "$BINARIES_DIR"

# Map target to release asset name
get_asset_name() {
    local target="$1"
    case "$target" in
    cliproxyapi-aarch64-apple-darwin)
        echo "cliproxyapi-aarch64-apple-darwin"
        ;;
    cliproxyapi-x86_64-apple-darwin)
        echo "cliproxyapi-x86_64-apple-darwin"
        ;;
    cliproxyapi-x86_64-unknown-linux-gnu)
        echo "cliproxyapi-x86_64-unknown-linux-gnu"
        ;;
    cliproxyapi-x86_64-pc-windows-msvc.exe)
        echo "cliproxyapi-x86_64-pc-windows-msvc.exe"
        ;;
    *)
        echo ""
        ;;
    esac
}

download_binary() {
    local target="$1"
    local asset_name=$(get_asset_name "$target")
    
    if [ -z "$asset_name" ]; then
        echo "Unknown target: $target"
        return 1
    fi
    
    echo "Downloading $asset_name..."
    URL="https://github.com/${CLIPROXYAPI_REPO}/releases/download/letta-v${VERSION}/${asset_name}"
    
    if curl -L -f -o "$BINARIES_DIR/$target" "$URL"; then
        chmod +x "$BINARIES_DIR/$target"
        echo "✓ Downloaded to $BINARIES_DIR/$target"
    else
        echo "✗ Failed to download: $URL"
        return 1
    fi
}

if [ -n "$BINARY_NAME" ]; then
    download_binary "$BINARY_NAME"
else
    # Download all binaries
    for target in \
        "cliproxyapi-aarch64-apple-darwin" \
        "cliproxyapi-x86_64-apple-darwin" \
        "cliproxyapi-x86_64-unknown-linux-gnu" \
        "cliproxyapi-x86_64-pc-windows-msvc.exe"; do
        download_binary "$target" || echo "Warning: Failed to download $target"
    done
fi

echo ""
echo "Done! Binaries are in $BINARIES_DIR"
echo "Run 'pnpm tauri dev' to test with Letta memory injection"
