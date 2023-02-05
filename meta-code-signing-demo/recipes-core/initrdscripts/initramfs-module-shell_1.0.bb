SUMMARY = "initramfs-framework module for starting a shell"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

PR = "r0"

inherit allarch

SRC_URI = "file://shell"

S = "${WORKDIR}"

do_install() {
    install -d ${D}/init.d
    install -m 0755 ${WORKDIR}/shell ${D}/init.d/98-shell
}

FILES:${PN} = "/init.d/98-shell"
