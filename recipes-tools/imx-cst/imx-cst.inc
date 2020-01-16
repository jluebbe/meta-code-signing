SUMMARY = "NXP i.MX Code signing Tool for the High Assurance Boot library"
DESCRIPTION = "Provides software code signing support designed for use with \
i.MX processors that integrate the HAB library in the internal boot ROM."
HOMEPAGE = "https://www.nxp.com/webapp/Download?colCode=IMX_CST_TOOL"

LICENSE = "Proprietary"
LIC_FILES_CHKSUM = " \
    file://LICENSE.nxp;md5=6604ef69bd4ea2c604f8779985efd277 \
    file://LICENSE.openssl;md5=06698624268f7be8151210879bbcbcab \
"

DEPENDS = "openssl"

SRC_URI = "file://${IMX_CST_ARCHIVE};downloadfilename=cst-${PV}.tgz"

S = "${WORKDIR}/release"

python do_fetch_prepend() {
    if not d.getVar("IMX_CST_ARCHIVE"):
        bb.fatal(
            "Download the cst-%s.tgz archive from %s manually and set IMX_CST_ARCHIVE in your local.conf." %
            (d.getVar("PV"), d.getVar("HOMEPAGE"))
        )
}

get_imx_cst_arch() {
    if [ "${HOST_ARCH}" = "i686" ]; then
        IMX_CST_ARCH="linux32"
    elif [ "${HOST_ARCH}" = "x86_64" ]; then
        IMX_CST_ARCH="linux64"
    else
        bbfatal "imx-cst does not support this HOST_ARCH (${HOST_ARCH})."
    fi
}

do_compile() {
    get_imx_cst_arch
    cd ${S}/code/back_end/src && ${BUILD_CC} \
       -Wall -O2 -g3 -o ../../../$IMX_CST_ARCH/bin/cst \
       -I ../hdr -L ../../../$IMX_CST_ARCH/lib *.c -lfrontend -lcrypto
}

do_install() {
    get_imx_cst_arch
    install -d ${D}${bindir}
    install -m 0755 ${B}/$IMX_CST_ARCH/bin/cst ${D}${bindir}/cst
    install -m 0755 ${B}/$IMX_CST_ARCH/bin/srktool ${D}${bindir}/srktool
}

FILES_${PN} = "${bindir}"

INSANE_SKIP_${PN} += "already-stripped"

BBCLASSEXTEND = "native"
