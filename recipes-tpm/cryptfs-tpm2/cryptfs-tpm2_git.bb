#
# Copyright (C) 2016-2017 Wind River Systems, Inc.
#

SUMMARY = "A tool used to create, persist, evict a passphrase \
for full-disk-encryption with TPM 2.0"
DESCRIPTION = " \
This project provides with an implementation for \
creating, persisting and evicting a passphrase with TPM 2.0. \
The passphrase and its associated primary key are automatically \
created by RNG engine in TPM. In order to avoid saving the \
context file, the created passphrase and primary key are always \
persistent in TPM. \
"
SECTION = "devel"
LICENSE = "BSD"
LIC_FILES_CHKSUM = "file://${S}/LICENSE;md5=89c8ce1346a3dfe75379e84f3ba9d641"

SRC_URI = " \
    git://github.com/WindRiver-OpenSourceLabs/cryptfs-tpm2.git \
"
SRCREV = "e39abe57c9432789de9ac118666b95ddf7996f00"
PV = "0.6.0+git${SRCPV}"

DEPENDS += "tpm2.0-tss tpm2-abrmd pkgconfig-native"
RDEPENDS_${PN} += "libtss2 libtctidevice libtctisocket"

PACKAGES =+ " \
    ${PN}-initramfs \
"

PARALLEL_MAKE = ""

S = "${WORKDIR}/git"

EXTRA_OEMAKE = " \
    sbindir="${sbindir}" \
    libdir="${libdir}" \
    includedir="${includedir}" \
    tpm2_tss_includedir="${STAGING_INCDIR}" \
    tpm2_tss_libdir="${STAGING_LIBDIR}" \
    tpm2_tabrmd_includedir="${STAGING_INCDIR}" \
    CC="${CC}" \
    PKG_CONFIG="${STAGING_BINDIR_NATIVE}/pkg-config" \
    EXTRA_CFLAGS="${CFLAGS}" \
    EXTRA_LDFLAGS="${LDFLAGS}" \
"

do_install() {
    oe_runmake install DESTDIR="${D}"

    if [ x"${@bb.utils.contains('DISTRO_FEATURES', 'storage-encryption', '1', '0', d)}" = x"1" ]; then
        install -m 0500 ${S}/script/init.cryptfs ${D}
    fi
}

FILES_${PN}-initramfs = "\
    /init.cryptfs \
"
