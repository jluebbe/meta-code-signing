LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit genimage

# define the image's layout
SRC_URI += "file://genimage.config"

DEPENDS += "barebox"

# add dependency to the required images
do_genimage[depends] += "barebox:do_deploy"

GENIMAGE_IMAGE_NAME = "qemu-normal-flash"
GENIMAGE_IMAGE_SUFFIX = "img"
