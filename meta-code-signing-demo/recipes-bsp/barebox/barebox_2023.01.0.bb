require recipes-bsp/barebox/barebox.inc

SRC_URI[sha256sum] = "20532daff1720fbefa0e02dba0294e6817d29c155f49b9b549db9577435fc7b6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://defconfig \
            file://env \
            "
