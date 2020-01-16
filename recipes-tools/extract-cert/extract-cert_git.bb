LICENSE = "LGPL-2.1"
LIC_FILES_CHKSUM = "file://extract-cert.c;endline=13;md5=502b9e9b983dd75af55c4c12dde990a2"

DEPENDS = "openssl"

SRC_URI = "git://git.pengutronix.de/git/extract-cert;protocol=https"
SRCREV = "1f3b85a94e27f8de104d66c3b39447c0c9d87724"

PV = "0.1"

S = "${WORKDIR}/git"

inherit meson

BBCLASSEXTEND = "native nativesdk"
