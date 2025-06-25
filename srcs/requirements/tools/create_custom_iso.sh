#!/bin/bash

set -e

# Create Custom Debian ISO with Embedded Preseed
echo "   🔄 Creating custom Debian ISO..."

# Check required parameters
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 <ORIGINAL_ISO> <CUSTOM_ISO> <PRESEED_TEMPLATE> <ISOLINUX_TEMPLATE> <DEBIAN_USER_PASSWORD> <WORK_DIR>"
    exit 1
fi

ORIGINAL_ISO="$1"
CUSTOM_ISO="$2"
PRESEED_TEMPLATE="$3"
ISOLINUX_TEMPLATE="$4"
DEBIAN_USER_PASSWORD="$5"
WORK_DIR="$6"

# Install required tools if missing
if ! command -v xorriso >/dev/null 2>&1 && ! command -v genisoimage >/dev/null 2>&1; then
    echo "   Installing missing tools: genisoimage"
    sudo apt-get update -qq
    sudo apt-get install -y genisoimage
fi

# Clean up previous work
rm -rf "$WORK_DIR" 2>/dev/null || true
mkdir -p "$WORK_DIR"

# Extract original ISO
echo "   Extracting original ISO..."
cd "$WORK_DIR"
if command -v isoinfo >/dev/null 2>&1; then
    isoinfo -R -X -i "$ORIGINAL_ISO" > iso_contents.tar
    tar -xf iso_contents.tar
    rm iso_contents.tar
elif command -v xorriso >/dev/null 2>&1; then
    xorriso -osirrox on -indev "$ORIGINAL_ISO" -extract / .
else
    echo "   ❌ Error: No ISO extraction tool available"
    exit 1
fi

# Fix permissions for extracted files
echo "   Fixing file permissions..."
chmod -R u+w "$WORK_DIR"

# Generate preseed file
echo "   Generating preseed configuration..."
PRESEED_FILE="$WORK_DIR/preseed.cfg"
if [ ! -f "$PRESEED_TEMPLATE" ]; then
    echo "   ❌ Error: Preseed template not found: $PRESEED_TEMPLATE"
    exit 1
fi
sed "s/{{DEBIAN_USER_PASSWORD}}/$DEBIAN_USER_PASSWORD/g" "$PRESEED_TEMPLATE" > "$PRESEED_FILE"

# Modify isolinux.cfg for automatic installation
echo "   Modifying boot configuration..."
ISOLINUX_CFG="$WORK_DIR/isolinux/isolinux.cfg"
if [ ! -f "$ISOLINUX_TEMPLATE" ]; then
    echo "   ❌ Error: Isolinux template not found: $ISOLINUX_TEMPLATE"
    exit 1
fi
cat "$ISOLINUX_TEMPLATE" > "$ISOLINUX_CFG"

# Create new custom ISO
echo "   Building custom ISO..."
if command -v genisoimage >/dev/null 2>&1; then
    genisoimage -r -J -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -V "Debian 11 Auto Install" \
        -o "$CUSTOM_ISO" "$WORK_DIR"
elif command -v xorriso >/dev/null 2>&1; then
    xorriso -as mkisofs -r -J -joliet-long -l \
        -b isolinux/isolinux.bin -c isolinux/boot.cat \
        -no-emul-boot -boot-load-size 4 -boot-info-table \
        -V "Debian 11 Auto Install" \
        -o "$CUSTOM_ISO" "$WORK_DIR"
else
    echo "   ❌ Error: No ISO creation tool available"
    exit 1
fi

# Make the ISO bootable
echo "   Making ISO bootable..."
isohybrid "$CUSTOM_ISO" 2>/dev/null || true

echo "   ✅ Custom ISO created: $CUSTOM_ISO"

# Clean up work directory
echo "   Cleaning up temporary files..."
rm -rf "$WORK_DIR"

echo "   ✅ Custom ISO creation complete!"
