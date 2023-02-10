LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

inherit signing native

SRC_URI = "file://modsign.cfg file://modsign.key.pem"

B = "${WORKDIR}/build"

PROVIDES = "virtual/kernel-module-signing"

do_compile() {
    rm -f "${B}/modsign.crt.pem"

    # Generate a certificate for the fixed private key with a validity of only
    # 7 days to encourage use of a proper key.
    openssl req -new -key "${WORKDIR}/modsign.key.pem" -utf8 -sha256 -days 7 \
                -batch -x509 -config ${WORKDIR}/modsign.cfg \
                -outform pem -out "${B}/modsign.crt.pem"

    # Log generated certificate for debugging.
    openssl x509 -in "${B}/modsign.crt.pem" -text

    signing_import_prepare

    signing_import_define_role modsign
    signing_import_cert_from_pem modsign "${B}/modsign.crt.pem"
    signing_import_key_from_pem modsign "${WORKDIR}/modsign.key.pem"

    signing_import_finish
}

do_install() {
    signing_import_install
}
