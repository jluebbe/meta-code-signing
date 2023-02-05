inherit bundle signing

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

RAUC_BUNDLE_COMPATIBLE ?= "code-signing demo"
RAUC_BUNDLE_VERSION ?= "v2023.1"

RAUC_BUNDLE_FORMAT = "verity"

RAUC_BUNDLE_SLOTS = "fit root"
RAUC_SLOT_fit = "linux-fit-image"
RAUC_SLOT_fit[type] = "file"
RAUC_SLOT_fit[file] = "fit-image-qemuarm.bin"
RAUC_SLOT_root = "core-image-minimal"
RAUC_SLOT_root[fstype] = "ext4"
RAUC_SLOT_root[adaptive] = "block-hash-index"

DEPENDS += "virtual/rauc-signing"

RAUC_KEY_FILE = "$(signing_get_uri 'rauc')"
RAUC_CERT_FILE = "$(signing_get_uri 'rauc')"

do_bundle:prepend() {
    signing_prepare
    signing_use_role rauc
}
