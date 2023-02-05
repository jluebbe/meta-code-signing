SUMMARY = "initramfs-framework module for configuring dm-verity"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"
RDEPENDS:${PN} = "libdevmapper"

PR = "r0"

inherit allarch

SRC_URI = "file://verity"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/init.d
    install -m 0755 ${WORKDIR}/verity ${D}/init.d/05-verity
}

FILES:${PN} = "/init.d/05-verity"
