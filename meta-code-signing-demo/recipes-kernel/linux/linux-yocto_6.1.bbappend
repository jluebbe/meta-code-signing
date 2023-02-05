FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += " \
    file://v2-0001-certs-Fix-build-error-when-PKCS-11-URI-contains-s.patch \
    file://v2-0002-kbuild-modinst-Fix-build-error-when-CONFIG_MODULE.patch \
    file://modsign.cfg \
    file://overlay.cfg \
"

inherit signing

DEPENDS += "virtual/kernel-module-signing"

do_configure:append() {
    signing_prepare
    signing_use_role modsign
    sed -i -e "s|^CONFIG_MODULE_SIG_KEY=.*$|CONFIG_MODULE_SIG_KEY=\"$(signing_get_uri 'modsign')\"|" "${B}/.config"
}

do_compile:prepend() {
    signing_prepare
    signing_use_role modsign
}

do_install:prepend() {
    signing_prepare
    signing_use_role modsign
}
