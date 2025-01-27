#!/usr/bin/env bash

# Error codes:
# 0 - Exited without problems
# 1 - Unsupported parameters or unexpected error
# 2 - OS not supported
# 3 - Installed version of rclone is already up to date
# 4 - Required unzip tools not available

set -e

# List of supported unzip tools
unzip_tools_list=('unzip' '7z' 'busybox')

usage() {
    echo "Usage: curl https://rclone.org/install.sh | sudo bash [-s beta]"
    exit 1
}

# Check for beta flag
install_beta=""
if [ -n "$1" ]; then
    if [ "$1" = "beta" ]; then
        install_beta="beta"
    else
        usage
    fi
fi

# Create a temporary directory
tmp_dir=$(mktemp -d 2>/dev/null || mktemp -d -t 'rclone-install.XXXXXXXXXX')
cd "$tmp_dir"

# Ensure an unzip tool is available
unzip_tool=""
for tool in "${unzip_tools_list[@]}"; do
    if command -v "$tool" &> /dev/null; then
        unzip_tool="$tool"
        break
    fi
done

if [ -z "$unzip_tool" ]; then
    echo "Error: None of the supported unzip tools (${unzip_tools_list[*]}) were found. Please install one and try again."
    exit 4
fi

# Determine the operating system
OS="$(uname)"
case "$OS" in
    Linux) OS="linux" ;;
    FreeBSD) OS="freebsd" ;;
    NetBSD) OS="netbsd" ;;
    OpenBSD) OS="openbsd" ;;
    Darwin) OS="osx" ;;
    SunOS) 
        echo "Error: SunOS is not supported."
        exit 2
        ;;
    *)
        echo "Error: Operating system not supported."
        exit 2
        ;;
esac

# Determine the system architecture
OS_type="$(uname -m)"
case "$OS_type" in
    x86_64|amd64) OS_type="amd64" ;;
    i?86|x86) OS_type="386" ;;
    aarch64|arm64) OS_type="arm64" ;;
    arm*) OS_type="arm" ;;
    *)
        echo "Error: System architecture not supported."
        exit 2
        ;;
esac

# Check the installed version of rclone
version=$(rclone --version 2>/dev/null | head -n 1 || true)
current_version=$(curl -fsS "https://downloads.rclone.org/version.txt")

if [ "$version" = "$current_version" ]; then
    echo "The latest ${install_beta} version of rclone (${version}) is already installed."
    exit 3
fi

# Download and extract the correct rclone version
if [ -z "$install_beta" ]; then
    download_link="https://downloads.rclone.org/rclone-current-${OS}-${OS_type}.zip"
else
    download_link="https://beta.rclone.org/rclone-beta-latest-${OS}-${OS_type}.zip"
fi

echo "Downloading rclone from ${download_link}..."
curl -OfsS "$download_link"
unzip_dir="tmp_unzip_dir_for_rclone"
mkdir -p "$unzip_dir"

case "$unzip_tool" in
    "unzip") unzip -a rclone*.zip -d "$unzip_dir" ;;
    "7z") 7z x rclone*.zip "-o$unzip_dir" ;;
    "busybox") busybox unzip rclone*.zip -d "$unzip_dir" ;;
esac

cd "$unzip_dir"/*

# Install rclone binary and man pages
echo "Installing rclone..."
case "$OS" in
    linux)
        install -m 755 rclone /usr/bin/rclone
        mkdir -p /usr/local/share/man/man1
        install -m 644 rclone.1 /usr/local/share/man/man1/
        mandb || true
        ;;
    freebsd|openbsd|netbsd)
        install -m 755 rclone /usr/bin/rclone
        mkdir -p /usr/local/man/man1
        install -m 644 rclone.1 /usr/local/man/man1/
        makewhatis || true
        ;;
    osx)
        mkdir -p /usr/local/bin
        install -m 755 rclone /usr/local/bin/rclone
        mkdir -p /usr/local/share/man/man1
        install -m 644 rclone.1 /usr/local/share/man/man1/
        ;;
esac

# Verify installation
installed_version=$(rclone --version 2>/dev/null | head -n 1 || true)
if [ "$installed_version" != "$current_version" ]; then
    echo "Warning: Installed rclone version ($installed_version) does not match the latest version ($current_version)."
else
    echo "rclone $installed_version has been successfully installed!"
fi

echo "To configure rclone, run: rclone config"
exit 0
