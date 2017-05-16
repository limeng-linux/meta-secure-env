#
# Copyright (C) 2016-2017 Wind River Systems Inc.
#

include packagegroup-storage-encryption.inc

DESCRIPTION = "The storage-encryption packages for initramfs."

RDEPENDS_${PN} += " \
    cryptfs-tpm2-initramfs \
    packagegroup-tpm2-initramfs \
"
