inherit bundle signing

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/COPYING.MIT;md5=3da9cfbcb788c80a0384361b4de20420"

RAUC_BUNDLE_COMPATIBLE ?= "imx-foo test board"
RAUC_BUNDLE_VERSION ?= "v2020-01-15-1"

RAUC_BUNDLE_SLOTS = "system"
RAUC_SLOT_system = "firmware-system-image"
# must be 'ext4' as a keyword for a 'filesystem', independend of the really used filesystem type
RAUC_SLOT_system[fstype] = "ext4"

DEPENDS += "virtual/rauc-signing"

RAUC_KEY_FILE = "$(signing_get_uri 'rauc')"
RAUC_CERT_FILE = "$(signing_get_uri 'rauc')"

do_bundle_prepend() {
    signing_prepare
    signing_use_role rauc
}
