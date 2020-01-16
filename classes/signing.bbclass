# Recipes access the available keys via a specific role. Depending on whether
# we're building during development or for release, a given role can refer to
# different keys.
#
# For the development case, the roles are defined by import recipes which also
# load the key material into a softhsm token.
# For release, the PKCS#11 URI and module path should be defined in the local
# bitbake configuration.

SIGNING_PKCS11_URI ?= ""
SIGNING_PKCS11_MODULE ?= ""

def signing_class_prepare(d):
    import os.path

    def export(role, k, v):
        k = k % (role, )
        d.setVar(k, v)
        d.setVarFlag(k, "export", "1")

    roles = set()
    roles |= (d.getVarFlags("SIGNING_PKCS11_URI") or {}).keys()
    roles |= (d.getVarFlags("SIGNING_PKCS11_MODULE") or {}).keys()
    for role in roles:
        if not set(role).issubset("abcdefghijklmnopqrstuvwxyz0123456789_"):
            bb.fatal("key role name '%s' must consist of only [a-z0-9_]" % (role,))

        pkcs11_uri = d.getVarFlag("SIGNING_PKCS11_URI", role) or d.getVar("SIGNING_PKCS11_URI")
        if not pkcs11_uri.startswith("pkcs11:"):
            bb.fatal("URI for key role '%s' must start with 'pkcs11:'" % (role,))

        pkcs11_module = d.getVarFlag("SIGNING_PKCS11_MODULE", role) or d.getVar("SIGNING_PKCS11_MODULE")
        if not os.path.isfile(pkcs11_module):
            bb.fatal("module path for key role '%s' must be an existing file" % (role,))

        if pkcs11_uri and not pkcs11_module:
            bb.warn("SIGNING_PKCS11_URI[%s] is set without SIGNING_PKCS11_MODULE[%s]" % (role, role))
        if pkcs11_module and not pkcs11_uri:
            bb.warn("SIGNING_PKCS11_MODULE[%s] is set without SIGNING_PKCS11_URI[%s]" % (role, role))

        export(role, "SIGNING_PKCS11_URI_%s_", pkcs11_uri)
        export(role, "SIGNING_PKCS11_MODULE_%s_", pkcs11_module)

signing_pkcs11_tool() {
    pkcs11-tool --module "${STAGING_LIBDIR_NATIVE}/softhsm/libsofthsm2.so" --login --pin 1111 $*
}

signing_import_prepare() {
    export _SIGNING_ENV_FILE_="${B}/meta-signing.env"
    rm -f "$_SIGNING_ENV_FILE_"

    export SOFTHSM2_CONF="${B}/softhsm2.conf"
    export SOFTHSM2_DIR="${B}/softhsm2.tokens"
    export SOFTHSM2_MOD="${STAGING_LIBDIR_NATIVE}/softhsm/libsofthsm2.so"

    echo "directories.tokendir = $SOFTHSM2_DIR" > "$SOFTHSM2_CONF"
    rm -rf "$SOFTHSM2_DIR"
    mkdir -p "$SOFTHSM2_DIR"

    softhsm2-util --module $SOFTHSM2_MOD --init-token --free --label ${PN} --pin 1111 --so-pin 222222
}

signing_import_define_role() {
    local role="${1}"
    case "${1}" in
        (*[!a-z0-9_]*) false;;
        (*) true;;
    esac || bbfatal "invalid role name '${1}', must consist of [a-z0-9_]"

    echo "_SIGNING_PKCS11_URI_${role}_=\"pkcs11:token=${PN};object=$role;pin-value=1111\"" >> $_SIGNING_ENV_FILE_
    echo "_SIGNING_PKCS11_MODULE_${role}_=\"softhsm\"" >> $_SIGNING_ENV_FILE_
}

# signing_import_cert_from_der <role> <der>
#
# Import a certificate from DER file to a role. To be used
# with SoftHSM.
signing_import_cert_from_der() {
    local role="${1}"
    local der="${2}"

    signing_pkcs11_tool --type cert --write-object "${der}" --label "${role}"
}

# signing_import_cert_from_pem <role> <pem>
#
# Import a certificate from PEM file to a role. To be used
# with SoftHSM.
signing_import_cert_from_pem() {
    local role="${1}"
    local pem="${2}"

    openssl x509 \
        -in "${pem}" -inform pem -outform der |
    signing_pkcs11_tool --type cert --write-object /proc/self/fd/0 --label "${role}"
}

# signing_import_pubkey_from_pem <role> <pem>
#
# Import a public key from PEM file to a role. To be used with SoftHSM.
signing_import_pubkey_from_pem() {
    local openssl_keyopt
    local role="${1}"
    local pem="${2}"

    if [ -n "${IMPORT_PASS_FILE}" ]; then
        openssl rsa \
            -passin "file:${IMPORT_PASS_FILE}" \
            -in "${pem}" -inform pem -pubout -outform der
    else
        openssl rsa \
            -in "${pem}" -inform pem -pubout -outform der
    fi |
    signing_pkcs11_tool --type pubkey --write-object /proc/self/fd/0 --label "${role}"
}

# signing_import_privkey_from_pem <role> <pem>
#
# Import a private key from PEM file to a role. To be used with SoftHSM.
signing_import_privkey_from_pem() {
    local openssl_keyopt
    local role="${1}"
    local pem="${2}"

    if [ -n "${IMPORT_PASS_FILE}" ]; then
        openssl rsa \
            -passin "file:${IMPORT_PASS_FILE}" \
            -in "${pem}" -inform pem -outform der
    else
        openssl rsa \
            -in "${pem}" -inform pem -outform der
    fi |
    signing_pkcs11_tool --type privkey --write-object /proc/self/fd/0 --label "${role}"
}

# signing_import_key_from_pem <role> <pem>
#
# Import a private and public key from PEM file to a role. To be used
# with SoftHSM.
signing_import_key_from_pem() {
    local role="${1}"
    local pem="${2}"

    signing_import_pubkey_from_pem "${role}" "${pem}"
    signing_import_privkey_from_pem "${role}" "${pem}"
}

signing_import_finish() {
    echo "loaded objects:"
    signing_pkcs11_tool --list-objects
}

signing_import_install() {
    install -d ${D}${localstatedir}/lib/softhsm/tokens/${PN}
    install -m 600 -t ${D}${localstatedir}/lib/softhsm/tokens/${PN} ${B}/softhsm2.tokens/*/*
    install -d ${D}${localstatedir}/lib/meta-signing.env.d
    install -m 644 "${B}/meta-signing.env" ${D}${localstatedir}/lib/meta-signing.env.d/${PN}
}

signing_prepare() {
    export OPENSSL_CONF=${STAGING_ETCDIR_NATIVE}/ssl/openssl.cnf
    export OPENSSL_ENGINES=${STAGING_LIBDIR_NATIVE}/engines-1.1

    export SOFTHSM2_CONF="${WORKDIR}/softhsm2.conf"
    export SOFTHSM2_DIR="${STAGING_DIR_NATIVE}/var/lib/softhsm/tokens"

    echo "directories.tokendir = $SOFTHSM2_DIR" > "$SOFTHSM2_CONF"

    for env in $(ls "${STAGING_DIR_NATIVE}/var/lib/meta-signing.env.d"); do
        . "${STAGING_DIR_NATIVE}/var/lib/meta-signing.env.d/$env"
    done
}
# make sure these functions are exported
signing_prepare[vardeps] += "signing_get_uri signing_get_module"

signing_use_role() {
    local role="${1}"

    export PKCS11_MODULE_PATH="$(signing_get_module $role)"
    export PKCS11_URI="$(signing_get_uri $role)"
}

signing_get_uri() {
    local role="${1}"

    # prefer local configuration
    eval local uri="\$SIGNING_PKCS11_URI_${role}_"
    if [ -n "$uri" ]; then
        echo "$uri"
        return
    fi

    # fall back to softhsm
    eval echo "\$_SIGNING_PKCS11_URI_${role}_"
}

signing_get_module() {
    local role="${1}"

    # prefer local configuration
    eval local module="\$SIGNING_PKCS11_MODULE_${role}_"
    if [ -n "$module" ]; then
        echo "$module"
        return
    fi

    # fall back to softhsm
    eval local module="\$_SIGNING_PKCS11_MODULE_${role}_"
    if [ "$module" = "softhsm" ]; then
        echo "${STAGING_LIBDIR_NATIVE}/softhsm/libsofthsm2.so"
    else
        echo "$module"
    fi
}

python () {
    signing_class_prepare(d)
}

DEPENDS += "softhsm-native libp11-native opensc-native"
