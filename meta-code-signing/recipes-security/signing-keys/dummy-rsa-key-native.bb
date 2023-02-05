LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit signing native

SRC_URI = "file://modsign.cfg"

B = "${WORKDIR}/build"

PROVIDES = "virtual/kernel-module-signing"

do_compile() {
    signing_import_prepare

    rm -f "${B}/modsign.crt" "${B}/modsign.key"

    openssl req -new -nodes -utf8 -sha256 -days 7 \
                -batch -x509 -config ${WORKDIR}/modsign.cfg \
                -outform PEM -out "${B}/modsign.crt" -keyout "${B}/modsign.key"

    signing_import_define_role modsign
    signing_import_cert_from_pem modsign "${B}/modsign.crt"
    signing_import_key_from_pem modsign "${B}/modsign.key"

    signing_import_finish
}

do_install() {
    signing_import_install
}
