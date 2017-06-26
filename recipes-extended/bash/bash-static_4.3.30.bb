#
# Copyright (C) 2017 Wind River Systems, Inc.
#

FILESEXTRAPATHS =. "${FILE_DIRNAME}/bash:"

require recipes-extended/bash/bash_${PV}.bb

S = "${WORKDIR}/bash-${PV}"

EXTRA_OECONF += " \
    --enable-static-link \
"

ALTERNATIVE_${PN}_pn-${PN}_forcevariable = ""

do_install_append () {
    rm -rf "${D}${bindir}"
    mv "${D}${base_bindir}/bash" "${D}${base_bindir}/bash.static"
}

pkg_postinst_${PN}_pn-${PN}_forcevariable () {
}

pkg_postrm_${PN}_pn-${PN}_forcevariable () {
}
