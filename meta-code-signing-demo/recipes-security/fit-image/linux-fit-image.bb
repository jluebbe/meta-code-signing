LICENSE = "MIT"

PACKAGE_ARCH = "${MACHINE_ARCH}"

# We need the 'mkimage' tool from the u-boot tools and a device tree compiler
# to do our job here
DEPENDS += "linux-yocto u-boot-tools-native coreutils-native dtc-native virtual/fit-signing verity-initramfs-image"

inherit nopackages signing

# use documented defaults if not otherwise set
# these defaults must correspond to the values used in barebox_%.bbappend
# Supported checksum and signing algorithms are:
# - sha1,rsa2048
# - sha256,rsa2048
# - sha256,rsa4096
#
FIT_IMAGE_SIGNING_KEY_ROLE ?= "fit"
FIT_IMAGE_CHECKSUM_ALGO ?= "sha256"
FIT_IMAGE_SIGNING_ALGO ?= "${FIT_IMAGE_CHECKSUM_ALGO},rsa4096"

#
# We need a simple device tree to describe the fit image and its content
#
# $1 ... .its output filename
# $2 ... kernel image file name
# $3 ... initramfs image file name
# $4 ... device tree blob file name
create_fitimage_description() {
	cat << EOF > ${1}
/dts-v1/;

/ {
	description = "fit image for ${DISTRO_NAME}/${PV}/${MACHINE}";
	#address-cells = <1>;

	images {
		kernel {
			description = "kernel";
			data = /incbin/("${2}");
			type = "kernel";
			arch = "arm";
			os = "linux";
			compression = "none";
			hash-1 {
				algo = "${FIT_IMAGE_CHECKSUM_ALGO}";
			};
		};

		ramdisk {
			description = "initramfs";
			data = /incbin/("${3}");
			type = "ramdisk";
			arch = "arm";
			os = "linux";
			compression = "none";
			hash-1 {
				algo = "${FIT_IMAGE_CHECKSUM_ALGO}";
			};
		};
		
		/* FDT is passed from barebox in this case. */
	};

	configurations {
		default = "code-signing-demo";
		code-signing-demo {
			description = "Code Signing Demo Configuration";
			kernel = "kernel";
			ramdisk = "ramdisk";
			signature {
				algo = "${FIT_IMAGE_SIGNING_ALGO}";
				key-name-hint = "${FIT_IMAGE_SIGNING_KEY_ROLE}";
				sign-images = "kernel", "ramdisk";
			};
		};
	};
};
EOF
}

# Create the FIT from the kernel, initramfs and the devicetree binaries.
do_compile() {
	signing_prepare
	signing_use_role "${FIT_IMAGE_SIGNING_KEY_ROLE}"

	# Creating a temp. parametrized ITS, describing the FIT image content and layout
	# Due to external configuration (or shared defaults) it matches automatically
	# the compiled-in public key of the bootloader (refer barebox_%.bbappend)
	create_fitimage_description \
		${B}/boot_fit_image.its \
		${DEPLOY_DIR_IMAGE}/${KERNEL_IMAGETYPE}-${MACHINE}.bin \
		${DEPLOY_DIR_IMAGE}/verity-initramfs-image-${MACHINE}.cpio.lzo
		#${DEPLOY_DIR_IMAGE}/${KERNEL_DEVICETREE}

	# assemble the FIT image and sign it
	uboot-mkimage -N pkcs11 -k "${PKCS11_URI#pkcs11:}" -r -f ${B}/boot_fit_image.its ${B}/fit-image.bin
}

do_compile[depends] += "verity-initramfs-image:do_image_complete"
do_compile[depends] += "linux-yocto:do_deploy"

inherit deploy

FIT_NAME ??= "fit-image-${MACHINE}-${DATETIME}.bin"
FIT_NAME[vardepsexclude] = "DATETIME"
FIT_LINK_NAME ??= "fit-image-${MACHINE}.bin"

do_deploy() {
	install -d ${DEPLOYDIR}
	install -m 0644 ${B}/fit-image.bin ${DEPLOYDIR}/${FIT_NAME}
	truncate -s %4096 ${DEPLOYDIR}/${FIT_NAME}
	ln -sf ${FIT_NAME} ${DEPLOYDIR}/${FIT_LINK_NAME}
}
addtask deploy after do_compile before do_build
do_deploy[cleandirs] = "${DEPLOYDIR}"
