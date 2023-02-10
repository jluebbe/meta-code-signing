require recipes-bsp/barebox/barebox.inc

SRC_URI[sha256sum] = "20532daff1720fbefa0e02dba0294e6817d29c155f49b9b549db9577435fc7b6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://defconfig \
            file://env \
            file://0001-of-base-factor-out-of_merge_nodes-from-of_copy_node.patch \
            file://0002-of-support-of_ensure_probed-for-top-level-machine-de.patch \
            file://0003-boards-qemu-virt-ensure-board-driver-probe-at-postco.patch \
            file://0004-boards-qemu-virt-support-passing-in-FIT-public-key.patch \
            "
