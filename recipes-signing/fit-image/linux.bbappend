PACKAGES += "kernel-image-fitimage"
RDEPENDS_${KERNEL_PACKAGE_NAME}-image += "kernel-image-fitimage"

FILESEXTRAPATHS_prepend := "${THISDIR}/files:"

# We need the 'mkimage' tool from the u-boot tools and a device tree compiler
# to do our job here
DEPENDS += "u-boot-tools-native dtc-native virtual/fit-signing"

# use documented defaults if not otherwise set
FIT_IMAGE_SIGNING_KEY_ROLE ?= "fit"
FIT_IMAGE_KERNEL_CHECKSUM_ALGO ?= "sha256"
FIT_IMAGE_DTB_CHECKSUM_ALGO ?= "${FIT_IMAGE_KERNEL_CHECKSUM_ALGO}"
FIT_IMAGE_SIGNING_ALGO ?= "sha1,rsa4096"

#
# We need a simple device tree to describe the fit image and its content
#
# $1 ... .its output filename
# $2 ... kernel image file name
# $3 ... device tree blob file name
create_fitimage_description() {
	cat << EOF > ${1}
/dts-v1/;

/ {
	description = "image for ${DISTRO_NAME}/${PV}/${MACHINE}";
	#address-cells = <1>;

	images {
		kernel@1 {
			description = "kernel";
			data = /incbin/("${2}");
			type = "kernel";
			arch = "arm";
			os = "linux";
			compression = "none";
			hash@1 {
				algo = "${FIT_IMAGE_KERNEL_CHECKSUM_ALGO}";
			};
		};

		fdt@1 {
			description = "DeviceTree";
			data = /incbin/("${3}");
			type = "flat_dt";
			arch = "arm";
			compression = "none";
			fdt-version = <1>;
			hash@1 {
				algo = "${FIT_IMAGE_DTB_CHECKSUM_ALGO}";
			};
		};
	};

	configurations {
		default = "config@1";
		config@1 {
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

# simple way to count words in a list
count_files() {
	echo ${#}
}

# append the default build rule by creating the FIT from the kernel and the
# devicetree binaries.
do_compile_append() {
	signing_prepare
	signing_use_role "${FIT_IMAGE_SIGNING_KEY_ROLE}"

	# check for some expectations of this rule

	# no real paths to the binary results are available, we must guess them
	# - for the kernel binary (e.g. zImage)
	if [ ! -d "arch/${ARCH}/boot" ]; then
		bbfatal "Unhandled path to the compressed kernel binary image. Cannot continue."
	fi
	# - for the device tree binary (e.g. dtb blob)
	if [ ! -d "arch/${ARCH}/boot/dts" ]; then
		bbfatal "Unhandled path to the binary device tree blob. Cannot continue."
	fi

	# currently we support *one* device tree only
	cnt=`count_files ${KERNEL_DEVICETREE}`
	if [ ${cnt} -ne 1 ]; then
		bbfatal "More than one device tree isn't supported yet. Cannot continue."
	fi

	# currently we support *one* kernel image only
	cnt=`count_files ${KERNEL_IMAGETYPE}`
	if [ ${cnt} -ne 1 ]; then
		bbfatal "More than one kernel image isn't supported yet. Cannot continue."
	fi

	# we expect these files exactly here:
	DEVTREE="${KERNEL_OUTPUT_DIR}/dts/${KERNEL_DEVICETREE}"
	KERNEL="${KERNEL_OUTPUT_DIR}/${KERNEL_IMAGETYPE}"

	# Creating a temp. parametrized ITS, describing the FIT image content and layout
	# Due to external configuration (or shared defaults) it matches automatically
	# the compiled-in public key of the bootloader (refer barebox.bbappend)
	create_fitimage_description ${B}/boot_fit_image.its ${B}/${KERNEL} ${B}/${DEVTREE}

	# assemble the FIT image and sign it
	uboot-mkimage -N pkcs11 -k "${PKCS11_URI#pkcs11:}" -r -f ${B}/boot_fit_image.its ${B}/${MACHINE}.bin
}

do_install_append() {
	# install the FIT image (instead of the plain kernel binary image and device tree blob)
	install -d ${D}/boot
	install -m 0644 ${B}/${MACHINE}.bin ${D}/boot/${MACHINE}.bin
}

FILES_kernel-image-fitimage = "/boot/*.bin"

# append the kernel's deploy rule to install the FIT binary as well
kernel_do_deploy_append() {
	install -m 0644 ${B}/${MACHINE}.bin $deployDir/${MACHINE}.bin
}
