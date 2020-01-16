require recipes-bsp/barebox/barebox.inc

SRC_URI[md5sum] = "45bf108b22de94a73dfe5c024c873486"
SRC_URI[sha256sum] = "607165b96d98fcc114fbd07e4001e7b527739a543e7adbe019854fbd8c78777f"

LIC_FILES_CHKSUM = "file://COPYING;md5=f5125d13e000b9ca1f0d3364286c4192"

PV = "2019.11.0"

COMPATIBLE_MACHINE = "(foo-imx)"

SRC_URI += "file://defconfig \
           "

inherit signing

DEPENDS += "imx-cst-native extract-cert-native virtual/imx-hab-signing virtual/fit-signing"

do_configure_prepend() {
    signing_prepare

    signing_use_role imx_habv4_srk1
    extract-cert $PKCS11_URI ${WORKDIR}/srk1.der
    openssl x509 -inform der -in ${WORKDIR}/srk1.der -out ${WORKDIR}/srk1.pem

    signing_use_role imx_habv4_srk2
    extract-cert $PKCS11_URI ${WORKDIR}/srk2.der
    openssl x509 -inform der -in ${WORKDIR}/srk2.der -out  ${WORKDIR}/srk2.pem

    signing_use_role imx_habv4_srk3
    extract-cert $PKCS11_URI ${WORKDIR}/srk3.der
    openssl x509 -inform der -in ${WORKDIR}/srk3.der -out ${WORKDIR}/srk3.pem

    signing_use_role imx_habv4_srk4
    extract-cert $PKCS11_URI ${WORKDIR}/srk4.der
    openssl x509 -inform der -in ${WORKDIR}/srk4.der -out ${WORKDIR}/srk4.pem

    srktool --hab_ver 4 \
        --table "${WORKDIR}/imx-srk-table.bin" \
        --efuses "${WORKDIR}/imx-srk-fuse.bin" \
        --digest sha256 \
        --certs ${WORKDIR}/srk1.pem ${WORKDIR}/srk2.pem ${WORKDIR}/srk3.pem ${WORKDIR}/srk4.pem
}

do_configure_append() {
    echo 'CONFIG_HABV4=y' >> ${B}/.config
    echo 'CONFIG_HABV4_TABLE_BIN="${WORKDIR}/imx-srk-table.bin"' >> ${B}/.config
    echo 'CONFIG_HABV4_CSF_CRT_PEM="__ENV__CSFURI"' >> ${B}/.config
    echo 'CONFIG_HABV4_IMG_CRT_PEM="__ENV__IMGURI"' >> ${B}/.config
}

do_compile_prepend() {
    signing_prepare

    signing_use_role imx_habv4_csf1
    export CSFURI="$PKCS11_URI"

    signing_use_role imx_habv4_img1
    export IMGURI="$PKCS11_URI"
}
