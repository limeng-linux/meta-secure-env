#
# Copyright (C) 2017 Wind River Systems, Inc.
#

IMA_ENABLED = "${@bb.utils.contains('DISTRO_FEATURES', 'ima', '1', '0', d)}"

pkg_preinst_${PN}_append() {
    # %post is always launched with /bin/sh but /bin/sh pointing to
    # bash may be just updated without having a valid IMA signature.
    # In order to handle this gap, temporarily change the symbol link
    # and eventually the link will be recovered after bash installation.
    if [ ${IMA_ENABLED} -eq 1 ]; then
        ln -sfn "${base_bindir}/bash.static" "${base_bindir}/sh"
    else
        true
    fi
}
