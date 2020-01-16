#
# Provide a device tree snippet with the public key information for bootloader's device tree inclusion
#
# Documentation: refer 'documentation/chain_of_trust.rst'
#
# Note: due to the use of a source type device tree snippet, the generation is
# more complex than the binary attachment procedure u-boot uses.
#
# The signing must be setup globally, because it must be consistent in the
# bootloader's public key and the generated FIT image to boot later on.
#
# The checksum algorithm for the FIT image component 'kernel'
#   FIT_IMAGE_KERNEL_CHECKSUM_ALGO = "sha1"
# -> defaults to "sha1" if not otherwise set.
#
# The checksum algorithm for the FIT image component 'device-tree'
#  FIT_IMAGE_DTB_CHECKSUM_ALGO = "sha1"
# -> defaults to the one for the 'kernel' component if not otherwise set
#
# The signing key to be used. Provide the:
#  FIT_IMAGE_SIGNING_KEY_ROLE = "name"
# -> needs to match the signing key role (as requred by uboot-mkimage)
#
# The signing algorithm
#  FIT_IMAGE_SIGNING_ALGO = "sha1,rsa4096"
# -> defaults to "sha1,rsa4096" if not otherwise set
#
FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# We need the 'mkimage' tool from the u-boot tools and a device tree compiler
# to do our job here
DEPENDS += "u-boot-tools-native dtc-native"

# use documented defaults if not otherwise set
FIT_IMAGE_SIGNING_KEY_ROLE ?= "fit"
FIT_IMAGE_KERNEL_CHECKSUM_ALGO ?= "sha1"
FIT_IMAGE_DTB_CHECKSUM_ALGO ?= "${FIT_IMAGE_KERNEL_CHECKSUM_ALGO}"
FIT_IMAGE_SIGNING_ALGO ?= "sha1,rsa4096"

# Where the bootloader's build system expects the public key snippet for inclusion
FIT_IMAGE_PUB_KEY = "${WORKDIR}/signature-snippet.dtsi"

#
# Setup a simple device tree source file to let DTC create an empty device tree blob.
# This blob is required as an input file to generate an empty, but fully signed
# blob in a next step.
# $1 filename
create_dts_for_empty_blob() {
	cat << EOF > ${1}
/dts-v1/;

/ {
};
EOF
}

#
# Setup a simple device tree source file to create an empty, but fully signed
# blob. This blob is required to extract the public key part in a next step.
# $1 filename
create_its_for_signature_extraction() {
	cat << EOF > ${1}
/*
 * This ITS file is used to create the dummy, but signed FIT image.
 * It is required as an interim step to extract the 'signature' part from it to
 * include it into the bootloader's devicetree later on. The result FIT image
 * isn't used anywhere else.
 */

/dts-v1/;

/ {
	description = "Dummy Signed FIT Image for ${DISTRO_NAME}/${PV}/${MACHINE}";
	#address-cells = <1>;

	images {
		kernel@1 {
			data = /incbin/("/dev/null");
			hash@1 {
				algo = "${FIT_IMAGE_KERNEL_CHECKSUM_ALGO}";
			};
		};
		fdt@1 {
			data = /incbin/("/dev/null");
			hash@1 {
				algo = "${FIT_IMAGE_DTB_CHECKSUM_ALGO}";
			};
		};
	};

	configurations {
		default = "conf@1";
		conf@1 {
			kernel = "kernel@1";
			fdt = "fdt@1";
			signature@1 {
				algo = "${FIT_IMAGE_SIGNING_ALGO}";
				key-name-hint = "${FIT_IMAGE_SIGNING_KEY_ROLE}";
				sign-images = "fdt", "kernel";
			};
		};
	};
};
EOF
}

inherit signing

# create a "[…]/${FIT_IMAGE_PUB_KEY}" snippet for bootloader's device tree inclusion
do_public_key_device_tree_snippet_create() {
	signing_prepare

	signing_use_role "${FIT_IMAGE_SIGNING_KEY_ROLE}"
	echo "Creating FIT public cryptography key as a DTS snippet..."
	echo " Step one: provide an empty devicetree blob..."
	create_dts_for_empty_blob ${WORKDIR}/dummy-fit-image.dts
	dtc -I dts -O dtb ${WORKDIR}/dummy-fit-image.dts -o ${WORKDIR}/dummy-fit-image.dtb
	echo " Step two: create a dummy, but fully signed FIT image..."
	create_its_for_signature_extraction ${WORKDIR}/dummy-fit-image.its
	uboot-mkimage -N pkcs11 -k "${PKCS11_URI#pkcs11:}" -r -f ${WORKDIR}/dummy-fit-image.its -K ${WORKDIR}/dummy-fit-image.dtb ${WORKDIR}/.dummy-fit.img
	echo " Step three: extract public key part for bootloader inclusion..."
	dtc -I dtb -O dts ${WORKDIR}/dummy-fit-image.dtb | tail -n +3 > ${FIT_IMAGE_PUB_KEY}
}

# the snippet is required when compiling the bootloader
addtask do_public_key_device_tree_snippet_create before do_compile after do_configure
