#!/bin/bash
set -e

arch='arm64'
version='20.04.3'
hardware='raspi'
cachedir='./cache'
tmpdir='./tmp'
scriptfile=''
cloudinitfile=''
outputfile=''
enableqemu=false

# Parse arguments.
while getopts a:v:h:s:c:i:o:q flag; do
    case "${flag}" in
        a) arch=${OPTARG} ;;
        v) version=${OPTARG} ;;
        h) hardware=${OPTARG} ;;
        s) scriptfile=${OPTARG} ;;
        c) cloudinitfile=${OPTARG} ;;
        o) outputfile=${OPTARG} ;;
        q) enableqemu=true ;;
    esac
done

# Check root.
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit
fi

# Install dependencies.
echo "Install dependencies..."
apt-get install mount parted e2fsprogs wget xz-utils -y

if [ ! -z "$scriptfile" ]; then
    apt-get install schroot debootstrap -y
fi

if [ "$enableqemu" = true ]; then
    # TODO: Compile QEMU from source and apply patches for better stability.
    apt-get install qemu qemu-user-static binfmt-support -y
fi

# Download base image.
image="ubuntu-$version-preinstalled-server-$arch+$hardware"
if [ ! -f "$cachedir/$image.img.xz" ]; then
    echo "Downloading image..."
    mkdir -p "$cachedir"
    wget -O "$cachedir/$image.img.xz" "https://cdimage.ubuntu.com/releases/$version/release/$image.img.xz"
else
    echo "Using cached image."
fi

# Decompress image to unique file.
echo "Decompressing image..."
uuid=$(uuidgen)
mkdir -p "$tmpdir"
xz -dcv "$cachedir/$image.img.xz" >"$tmpdir/$uuid.img"

# Add space for second partition.
# TODO: Define size via parameter.
echo "Extending image..."
dd if=/dev/zero bs=1M count=1024 >>"$tmpdir/$uuid.img"

# Create loopback device.
dev=$(losetup --partscan --find --show "$tmpdir/$uuid.img")

# Resize second partition.
# TODO: Calculate offsets.
parted --script $dev \
print \
rm 2 \
mkpart primary 269 3698 \
print \
quit \
resize2fs "$dev"p2

# Mount partitions.
echo "Mounting partitions..."
mkdir -p "/mnt/$uuid"
mount "$dev"p2 "/mnt/$uuid"
mount "$dev"p1 "/mnt/$uuid/boot/firmware"

# Run chroot.
if [ ! -z "$scriptfile" ]; then
    # Check script file.
    if [ -f "$scriptfile" ]; then
        # Mount host directories.
        echo "Mounting host directories..."
        mount --bind /run "/mnt/$uuid/run/"
        mount --bind /dev "/mnt/$uuid/dev/"
        mount --bind /sys "/mnt/$uuid/sys/"
        mount --bind /proc "/mnt/$uuid/proc/"
        mount --bind /dev/pts "/mnt/$uuid/dev/pts"
        
        # Copy script file and ensure there is an exit statement in it.
        echo "Running chroot..."
        cp "$scriptfile" "/mnt/$uuid/tmp/run"
        echo -e "\nexit" >>"/mnt/$uuid/tmp/run"
        
        # Execute chroot. The architecture of the current system must align with
        # the target architecture. Unless virtualization is enabled with QEMU.
        chroot "/mnt/$uuid" /bin/bash /tmp/run
        
        # Remove script file.
        rm "/mnt/$uuid/tmp/run"
        
        # Unmount host directories.
        echo "Unmounting host directories..."
        umount "/mnt/$uuid/run"
        umount "/mnt/$uuid/dev/pts"
        umount "/mnt/$uuid/dev"
        umount "/mnt/$uuid/sys"
        umount "/mnt/$uuid/proc"
    else
        echo "Cannot find chroot file."
    fi
fi

# Run cloud-init file.
if [ ! -z "$cloudinitfile" ]; then
    # Check cloud-init file.
    if [ -f "$cloudinitfile" ]; then
        # Copy cloud-init file.
        echo "Copying cloud-init file..."
        cp "$cloudinitfile" "/mnt/$uuid/etc/cloud/cloud.cfg"
    else
        echo "Cannot find cloud-init file."
    fi
fi

# Unmount partitions.
echo "Unmounting partitions..."
umount "/mnt/$uuid/boot/firmware"
umount "/mnt/$uuid"
rmdir "/mnt/$uuid"

# Remove loopback device.
losetup -d "$dev"

# Compress image.
echo "Compressing image..."
if [ -z "$outputfile" ]; then
    outputfile="$image.img.xz"
fi
xz -zcv "$tmpdir/$uuid.img" > "$outputfile"
echo "Output: $outputfile"
