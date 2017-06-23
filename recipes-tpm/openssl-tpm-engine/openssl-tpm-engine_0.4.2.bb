DESCRIPTION = " OpenSSL secure engine based on TPM hardware"
HOMEPAGE = "http://www.openssl.org/"
SECTION = "libs/network"
PR = "r0"
LICENSE = "openssl"

DEPENDS = "openssl trousers"
RDEPENDS_${PN} = "libcrypto libtspi"

SRC_URI = "http://sourceforge.net/projects/trousers/files/OpenSSL%20TPM%20Engine/0.4.2/openssl_tpm_engine-0.4.2.tar.gz \
	file://0001-create-tpm-key-support-well-known-key-option.patch \
	file://0002-libtpm-support-env-TPM_SRK_PW.patch \
	file://0003-tpm-openssl-tpm-engine-parse-an-encrypted-tpm-SRK-pa.patch \
"
SRC_URI[md5sum] = "5bc8d66399e517dde25ff55ce4c6560f"
SRC_URI[sha256sum] = "2df697e583053f7047a89daa4585e21fc67cf4397ee34ece94cf2d4b4f7ab49c"
LIC_FILES_CHKSUM = "file://LICENSE;md5=11f0ee3af475c85b907426e285c9bb52"

inherit autotools-brokensep

S = "${WORKDIR}/openssl_tpm_engine-${PV}"

do_configure_prepend () {
	cd ${S}
	cp LICENSE COPYING
	touch NEWS AUTHORS ChangeLog
}

FILES_${PN}-staticdev += "${libdir}/ssl/engines/libtpm.la"
FILES_${PN}-dbg += "${libdir}/ssl/engines/.debug \
	${libdir}/engines/.debug \
	${prefix}/local/ssl/lib/engines/.debug \
"
FILES_${PN} += "${libdir}/ssl/engines/libtpm.so* \
	${libdir}/engines/libtpm.so* \
	${libdir}/libtpm.so* \
	${prefix}/local/ssl/lib/engines/libtpm.so* \
"

do_install_append () {
	install -m 755 -d ${D}${libdir}/engines
	install -m 755 -d ${D}${prefix}/local/ssl/lib/engines
	install -m 755 -d ${D}${libdir}/ssl/engines

	cp -f ${D}${libdir}/openssl/engines/libtpm.so.0.0.0 ${D}${libdir}/libtpm.so.0
	cp -f ${D}${libdir}/openssl/engines/libtpm.so.0.0.0 ${D}${libdir}/engines/libtpm.so
	cp -f ${D}${libdir}/openssl/engines/libtpm.so.0.0.0 ${D}${prefix}/local/ssl/lib/engines/libtpm.so
	mv -f ${D}${libdir}/openssl/engines/libtpm.so.0.0.0 ${D}${libdir}/ssl/engines/libtpm.so
	mv -f ${D}${libdir}/openssl/engines/libtpm.la ${D}${libdir}/ssl/engines/libtpm.la
	rm -rf ${D}${libdir}/openssl
}

INSANE_SKIP_${PN} = "libdir"
INSANE_SKIP_${PN}-dbg = "libdir"

#It is allowed to define the values in 3 forms: string, hex number and the hybrid.
#PW = "incendia"
#PW = "\x69\x6e\x63\x65\x6e\x64\x69\x61"
#PW = "\x1""nc""\x3""nd""\x1""a"

#The definitions below are used to decrypt the srk password.
srk_dec_pw ?= "\\"\\\x1\\"\\"nc\\"\\"\\\x3\\"\\"nd\\"\\"\\\x1\\"\\"a\\""
srk_dec_salt ?= "\\"r\\"\\"\\\x00\\\x00\\"\\"t\\""
CFLAGS_append += "-DSRK_DEC_PW=${srk_dec_pw} -DSRK_DEC_SALT=${srk_dec_salt}"
#Due to the limit of escape, the hybrid must be written in above style.
#The actual values defined above are:
#srk_dec_pw[] = {0x01, 'n', 'c', 0x03, 'n', 'd', 0x01, 'a'};
#srk_dec_salt[] = {'r', 0x00, 0x00, 't'};

#Uncomment below one line if using the plain srk password for development
#CFLAGS_append += "-DTPM_SRK_PLAIN_PW"
