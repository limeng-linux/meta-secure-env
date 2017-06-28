#
# Copyright (C) 2017 Wind River Systems, Inc.
#

PACKAGES =+ "${PN}-static"

do_compile_append_class-target() {
    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        src/grep.o src/searchutils.o src/dfa.o src/dfasearch.o \
        src/kwset.o src/kwsearch.o src/pcresearch.o lib/libgreputils.a \
        lib/libgreputils.a -o src/grep.static
}

do_install_append_class-target() {
    install -d "${D}${base_bindir}"
    install -m 0755 "${B}/src/grep.static" "${D}${base_bindir}/grep.static"
}

FILES_${PN}-static = "${base_bindir}/grep.static"
