LICENSE = "MIT"
# Do not pollute the initrd image with rootfs features
IMAGE_FEATURES = ""
IMAGE_LINGUAS = ""

INITRAMFS_SCRIPTS ?= "\
                      initramfs-framework-base \
                      initramfs-module-debug \
                      initramfs-module-verity \
                     "

PACKAGE_INSTALL = "${INITRAMFS_SCRIPTS} ${VIRTUAL-RUNTIME_base-utils} util-linux-mountpoint"

# Do not include depmod data in the initramfs
KERNELDEPMODDEPEND = ""
IMAGE_FSTYPES = "cpio.lzo"

IMAGE_ROOTFS_SIZE = "8192"
IMAGE_ROOTFS_EXTRA_SPACE = "0"

ROOTFS_POSTPROCESS_COMMAND += "add_verity_params;"

inherit image

add_verity_params () {
    cp "${DEPLOY_DIR_IMAGE}/core-image-minimal-${MACHINE}.ext4.verity-params" "${IMAGE_ROOTFS}/verity-params"
}

do_rootfs[depends] += "core-image-minimal:do_image_complete"
