FILESEXTRAPATHS_prepend := "${THISDIR}/files:"
# keep in mind: the "system.conf" content must be perfect from the beginning
# you cannot change its content at run-time without restarting the RAUC dbus service!
SRC_URI_append := "file://system.conf"

inherit signing

DEPENDS += "extract-cert-native virtual/rauc-signing"
RAUC_KEYRING_FILE = "extracted.cert.pem"
RAUC_KEYRING_URI = ""

do_configure_prepend() {
    signing_prepare

    signing_use_role rauc
    extract-cert "$PKCS11_URI" ${WORKDIR}/${RAUC_KEYRING_FILE}.der
    openssl x509 -inform der -in ${WORKDIR}/${RAUC_KEYRING_FILE}.der \
        -out ${WORKDIR}/${RAUC_KEYRING_FILE}
}

RDEPENDS_${PN} += "dt-utils-barebox-state"
