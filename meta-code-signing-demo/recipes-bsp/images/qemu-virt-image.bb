LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit genimage

# define the image's layout
SRC_URI += "file://genimage.config"

DEPENDS += "virtual/bootloader linux-fit-image"
DEPENDS += "e2fsprogs-native genext2fs-native qemu-system-native"
DEPENDS += "qemu-normal-flash"
# TF-A and OP-TEE are not used yet
#DEPENDS += "qemu-secure-flash"

# add dependency to the required images
do_genimage[depends] += "linux-fit-image:do_deploy"

GENIMAGE_IMAGE_NAME = "qemu-virt-image"
GENIMAGE_IMAGE_SUFFIX = "qcow"
