IMAGE_INSTALL += "rauc dt-utils-barebox-state systemd-extra-utils"

# No NLS required
IMAGE_LINGUAS = ""

#IMAGE_FEATURES += "read-only-rootfs"

IMAGE_FSTYPES = "ext4"
# 4096 byte block size to match dm-verity
EXTRA_IMAGECMD:ext4 += "-b 4096 -I 256 -O ^has_journal"

# derive the rootfs size from the total file sizes
IMAGE_ROOTFS_SIZE = "0"
IMAGE_OVERHEAD_FACTOR = "1.1"
IMAGE_ROOTFS_ALIGNMENT = "4"

VERITY_SALT="c1f4f49868a70acf30621d78342aa30b350f61857898cf638d05bccad5afd4d0"

require verity.inc
