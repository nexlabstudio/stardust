#!/bin/bash
set -e

# Stardust installer script
# Usage: curl -sSL https://raw.githubusercontent.com/nexlabstudio/stardust/dev/install.sh | bash

REPO="nexlabstudio/stardust"
INSTALL_DIR="${STARDUST_INSTALL_DIR:-/usr/local/bin}"
BINARY_NAME="stardust"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
    printf "${BLUE}==>${NC} %s\n" "$1"
}

success() {
    printf "${GREEN}==>${NC} %s\n" "$1"
}

warn() {
    printf "${YELLOW}Warning:${NC} %s\n" "$1"
}

error() {
    printf "${RED}Error:${NC} %s\n" "$1" >&2
    exit 1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "darwin" ;;
        Linux*)   echo "linux" ;;
        MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
        *)        error "Unsupported operating system: $(uname -s)" ;;
    esac
}

# Detect architecture
detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64)  echo "x64" ;;
        arm64|aarch64) echo "arm64" ;;
        *)             error "Unsupported architecture: $(uname -m)" ;;
    esac
}

# Get latest release version from GitHub
get_latest_version() {
    local latest_url="https://api.github.com/repos/${REPO}/releases/latest"

    if command -v curl &> /dev/null; then
        curl -sSL "$latest_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    elif command -v wget &> /dev/null; then
        wget -qO- "$latest_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/'
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Download file
download() {
    local url="$1"
    local output="$2"

    if command -v curl &> /dev/null; then
        curl -sSL "$url" -o "$output"
    elif command -v wget &> /dev/null; then
        wget -q "$url" -O "$output"
    else
        error "Neither curl nor wget found. Please install one of them."
    fi
}

# Verify checksum
verify_checksum() {
    local file="$1"
    local checksums_file="$2"
    local expected_name="$3"

    if command -v sha256sum &> /dev/null; then
        local actual=$(sha256sum "$file" | awk '{print $1}')
        local expected=$(grep "$expected_name" "$checksums_file" | awk '{print $1}')

        if [ "$actual" != "$expected" ]; then
            error "Checksum verification failed!\nExpected: $expected\nActual: $actual"
        fi
    elif command -v shasum &> /dev/null; then
        local actual=$(shasum -a 256 "$file" | awk '{print $1}')
        local expected=$(grep "$expected_name" "$checksums_file" | awk '{print $1}')

        if [ "$actual" != "$expected" ]; then
            error "Checksum verification failed!\nExpected: $expected\nActual: $actual"
        fi
    else
        warn "sha256sum/shasum not found, skipping checksum verification"
        return
    fi

    success "Checksum verified"
}

main() {
    local version="${1:-}"
    local os=$(detect_os)
    local arch=$(detect_arch)

    info "Detected OS: $os, Architecture: $arch"

    # Get version
    if [ -z "$version" ]; then
        info "Fetching latest version..."
        version=$(get_latest_version)
    fi

    if [ -z "$version" ]; then
        error "Could not determine version to install"
    fi

    info "Installing Stardust $version"

    # Determine archive name and extension
    local archive_name="stardust-${os}-${arch}"
    local extension="tar.gz"
    if [ "$os" = "windows" ]; then
        extension="zip"
    fi

    local download_url="https://github.com/${REPO}/releases/download/${version}/${archive_name}.${extension}"
    local checksums_url="https://github.com/${REPO}/releases/download/${version}/checksums.txt"

    # Create temp directory
    local tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    local archive_path="${tmp_dir}/${archive_name}.${extension}"
    local checksums_path="${tmp_dir}/checksums.txt"

    # Download archive and checksums
    info "Downloading ${archive_name}.${extension}..."
    download "$download_url" "$archive_path"

    info "Downloading checksums..."
    download "$checksums_url" "$checksums_path"

    # Verify checksum
    info "Verifying checksum..."
    verify_checksum "$archive_path" "$checksums_path" "${archive_name}.${extension}"

    # Extract
    info "Extracting..."
    cd "$tmp_dir"
    if [ "$os" = "windows" ]; then
        unzip -q "$archive_path"
    else
        tar -xzf "$archive_path"
    fi

    # Install
    info "Installing to ${INSTALL_DIR}..."

    if [ ! -d "$INSTALL_DIR" ]; then
        mkdir -p "$INSTALL_DIR" 2>/dev/null || sudo mkdir -p "$INSTALL_DIR"
    fi

    if [ -w "$INSTALL_DIR" ]; then
        mv "${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
        chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    else
        sudo mv "${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
        sudo chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    fi

    success "Stardust $version installed successfully!"
    echo ""

    # Verify installation
    if command -v stardust &> /dev/null; then
        info "Installed version:"
        stardust --version
    else
        warn "stardust is not in your PATH"
        echo "Add ${INSTALL_DIR} to your PATH:"
        echo ""
        echo "  export PATH=\"${INSTALL_DIR}:\$PATH\""
        echo ""
    fi
}

main "$@"
