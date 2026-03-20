#!/bin/bash
set -e

# 🔹 Check input
if [ -z "$1" ]; then
    echo "❌ Usage: $0 <bluez-version>"
    echo "👉 Example: $0 5.85"
    exit 1
fi

BLUEZ_VERSION=$1
BLUEZ_TAR="bluez-$BLUEZ_VERSION.tar.xz"
BLUEZ_DIR="bluez-$BLUEZ_VERSION"

echo "🔹 Installing BlueZ version: $BLUEZ_VERSION"

echo "🔹 Step 1: Stop Bluetooth service"
sudo systemctl stop bluetooth || true

echo "🔹 Step 2: Remove old BlueZ"
sudo apt-get remove --purge -y bluez || true
sudo apt-get autoremove -y || true

echo "🔹 Step 3: Clean /usr/local"
sudo rm -f /usr/local/bin/btmgmt \
            /usr/local/bin/bluetoothctl \
            /usr/local/bin/btmon \
            /usr/local/bin/btattach || true

sudo rm -rf /usr/local/lib/bluetooth \
            /usr/local/include/bluetooth \
            /usr/local/lib/pkgconfig/bluetooth.pc || true

sudo ldconfig

echo "🔹 Step 4: Install dependencies"
sudo apt-get update
sudo apt-get install -y \
    build-essential libdbus-1-dev libglib2.0-dev libudev-dev libical-dev \
    libreadline-dev libusb-dev make automake libtool pkg-config wget git

echo "🔹 Step 5: Download BlueZ $BLUEZ_VERSION"
cd "$HOME"
wget https://www.kernel.org/pub/linux/bluetooth/$BLUEZ_TAR
tar xf $BLUEZ_TAR
cd $BLUEZ_DIR

echo "🔹 Step 6: Build & Install"
./configure --prefix=/usr --mandir=/usr/share/man --sysconfdir=/etc \
            --localstatedir=/var --enable-experimental \
            --enable-deprecated --enable-testing

make -j$(nproc)
sudo make install

echo "🔹 Step 7: Create symbolic links"
cd tools
for file in *; do
    sudo ln -sf $(pwd)/$file /usr/bin/$file
done

echo "🔹 Step 8: Restart Bluetooth"
sudo systemctl daemon-reexec
sudo systemctl start bluetooth

cd /home/ifx
sudo rm -rf /home/ifx/bluez-$BLUEZ_VERSION.tar*

echo "✅ BlueZ $BLUEZ_VERSION installation complete!"
echo "👉 Check version: btmgmt -v"