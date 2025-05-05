#!/bin/bash
set -e

# Define version and URL
JUST_VERSION="1.40.0"
JUST_TAR="just-${JUST_VERSION}-x86_64-unknown-linux-musl.tar.gz"
JUST_URL="https://github.com/casey/just/releases/download/${JUST_VERSION}/${JUST_TAR}"

# Temp directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

# Download and extract
echo "Downloading just ${JUST_VERSION}..."
wget "$JUST_URL"
tar -xzf "$JUST_TAR"

# Move to /usr/local/bin
echo "Installing just..."
sudo mv just /usr/local/bin/

# Cleanup
cd ~
rm -rf "$TMP_DIR"

echo "Done! just ${JUST_VERSION} installed successfully!"
