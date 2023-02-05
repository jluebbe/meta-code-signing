LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://COPYING.MIT;md5=838c366f69b72c5df05c96dff79b35f2"

inherit signing

SRC_URI = "git://git.pengutronix.de/git/ptx-code-signing-dev;protocol=https;branch=master"
SRCREV = "10b225437acab4db58c321035f7f34965e1553da"

S = "${WORKDIR}/git"
B = "${WORKDIR}/build"

PROVIDES = "virtual/imx-hab-signing virtual/fit-signing virtual/rauc-signing"

do_compile() {
    signing_import_prepare

    signing_import_define_role fit
    signing_import_cert_from_pem fit "${S}/fit/fit-4096-development.crt"
    signing_import_key_from_pem fit "${S}/fit/fit-4096-development.key"

    export IMPORT_PASS_FILE="${S}/habv4/keys/key_pass.txt"
    for i in 1 2 3 4; do
        r="imx_habv4_srk${i}"
        signing_import_define_role ${r}
        signing_import_cert_from_der ${r} ${S}/habv4/crts/SRK${i}_sha256_4096_65537_v3_ca_crt.der
        signing_import_key_from_pem ${r} ${S}/habv4/keys/SRK${i}_sha256_4096_65537_v3_ca_key.pem
        
        r="imx_habv4_csf${i}"
        signing_import_define_role ${r}
        signing_import_cert_from_der ${r} ${S}/habv4/crts/CSF${i}_1_sha256_4096_65537_v3_usr_crt.der
        signing_import_key_from_pem ${r} ${S}/habv4/keys/CSF${i}_1_sha256_4096_65537_v3_usr_key.pem
        
        r="imx_habv4_img${i}"
        signing_import_define_role ${r}
        signing_import_cert_from_der ${r} ${S}/habv4/crts/IMG${i}_1_sha256_4096_65537_v3_usr_crt.der
        signing_import_key_from_pem ${r} ${S}/habv4/keys/IMG${i}_1_sha256_4096_65537_v3_usr_key.pem
    done

    signing_import_define_role rauc
    signing_import_cert_from_pem rauc "${S}/rauc/rauc.cert.pem"
    signing_import_key_from_pem rauc "${S}/rauc/rauc.key.pem"

    signing_import_finish
}

do_install() {
    signing_import_install
}

inherit native
