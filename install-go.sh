#!/bin/bash
#
# Install or update Go by downloading from go.dev
# Usage: ./install-go.sh [version]
# Example: ./install-go.sh 1.25.5
#

set -e

# Default version if not specified
DEFAULT_VERSION="1.25.5"
VERSION="${1:-$DEFAULT_VERSION}"

# Installation directory
INSTALL_DIR="/usr/local"
GO_DIR="$INSTALL_DIR/go"

# Detect OS
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$OS" in
    darwin) OS="darwin" ;;
    linux) OS="linux" ;;
    *) echo "❌ Unsupported OS: $OS"; exit 1 ;;
esac

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
esac

# Construct download URL
FILENAME="go${VERSION}.${OS}-${ARCH}.tar.gz"
URL="https://go.dev/dl/${FILENAME}"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🐹 Go Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Version:      $VERSION"
echo "OS:           $OS"
echo "Architecture: $ARCH"
echo "Download URL: $URL"
echo "Install to:   $GO_DIR"
echo ""

# Check current installation
if command -v go &>/dev/null; then
    CURRENT_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo "Current Go:   $CURRENT_VERSION"
    if [ "$CURRENT_VERSION" = "$VERSION" ]; then
        echo ""
        echo "✅ Go $VERSION is already installed!"
        exit 0
    fi
else
    echo "Current Go:   Not installed"
fi
echo ""

# Confirm with user
read -p "Proceed with installation? [y/N] " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi
echo ""

# Create temp directory
TMPDIR=$(mktemp -d)
trap "rm -rf $TMPDIR" EXIT

# Download
echo "📥 Downloading Go $VERSION..."
if command -v curl &>/dev/null; then
    curl -fsSL -o "$TMPDIR/$FILENAME" "$URL"
elif command -v wget &>/dev/null; then
    wget -q -O "$TMPDIR/$FILENAME" "$URL"
else
    echo "❌ Neither curl nor wget found"
    exit 1
fi

# Verify download
if [ ! -f "$TMPDIR/$FILENAME" ]; then
    echo "❌ Download failed"
    exit 1
fi

FILESIZE=$(ls -lh "$TMPDIR/$FILENAME" | awk '{print $5}')
echo "✅ Downloaded ($FILESIZE)"
echo ""

# Remove existing installation
if [ -d "$GO_DIR" ]; then
    echo "🗑️  Removing existing Go installation..."
    sudo rm -rf "$GO_DIR"
fi

# Extract
echo "📦 Extracting to $INSTALL_DIR..."
sudo tar -C "$INSTALL_DIR" -xzf "$TMPDIR/$FILENAME"
echo "✅ Extracted"
echo ""

# Verify installation
if [ -x "$GO_DIR/bin/go" ]; then
    NEW_VERSION=$("$GO_DIR/bin/go" version | awk '{print $3}' | sed 's/go//')
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Go $NEW_VERSION installed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if Go is in PATH
    if ! command -v go &>/dev/null; then
        echo "⚠️  Go is not in your PATH. Add this to your shell profile:"
        echo ""
        echo "   export PATH=\$PATH:/usr/local/go/bin"
        echo ""
    fi
else
    echo "❌ Installation verification failed"
    exit 1
fi
