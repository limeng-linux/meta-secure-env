#
# Copyright (C) 2017 Wind River Systems, Inc.
#

PACKAGES =+ "${PN}-ln.static ${PN}-echo.static ${PN}-base64.static"

do_compile_append_class-target() {
    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        src/ln.o src/relpath.o src/libver.a \
        lib/libcoreutils.a lib/libcoreutils.a \
        -o src/ln.static

    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        src/echo.o src/libver.a lib/libcoreutils.a \
        lib/libcoreutils.a -o src/echo.static

    ${CC} ${CFLAGS} ${LDFLAGS} -static \
        src/base64.o src/libver.a lib/libcoreutils.a \
        lib/libcoreutils.a -o src/base64.static
}

do_install_append_class-target() {
    install -d "${D}${base_bindir}"
    install -m 0755 "${B}/src/ln.static" "${D}${base_bindir}/ln.static"
    install -m 0755 "${B}/src/echo.static" "${D}${base_bindir}/echo.static"
    install -m 0755 "${B}/src/base64.static" "${D}${base_bindir}/base64.static"
}

FILES_${PN}-ln.static = "${base_bindir}/ln.static"
FILES_${PN}-echo.static = "${base_bindir}/echo.static"
FILES_${PN}-base64.static = "${base_bindir}/base64.static"
