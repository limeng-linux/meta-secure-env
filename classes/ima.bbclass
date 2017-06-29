#
# Copyright (C) 2017 Wind River Systems, Inc.
#

inherit package

PACKAGEFUNCS =+ "package_ima_hook"

# security.ima is generated during the RPM build, and the base64-encoded
# value is written during RPM installation. In addition, if the private
# key is deployed on board, re-sign the updated files during RPM
# installation in higher priority.
python package_ima_hook() {
    packages = d.getVar('PACKAGES', True)
    pkgdest = d.getVar('PKGDEST', True)

    pkg_suffix_blacklist = ('dbg', 'dev', 'doc', 'locale', 'staticdev')

    pkg_blacklist = ()
    with open('${IMA_SIGNING_BLACKLIST}', 'r') as f:
        pkg_blacklist = [ _.strip() for _ in f.readlines() ]
        pkg_blacklist = tuple(pkg_blacklist)

    import base64, pipes, stat

    for pkg in packages.split():
        if (pkg.split('-')[-1] in pkg_suffix_blacklist) is True:
            continue

        if pkg.startswith(pkg_blacklist) is True:
            continue

        bb.note("Writing IMA %%post hook for %s ..." % pkg)

        pkgdestpkg = os.path.join(pkgdest, pkg)

        cmd = 'evmctl ima_sign --rsa --hashalgo sha256 -n --sigfile --key ${IMA_KEYS_DIR}/ima_privkey.pem '
        sig_list = []
        pkg_sig_list = []

        for _ in pkgfiles[pkg]:
            # Ignore the symbol links.
            if os.path.islink(_):
                continue

            # IMA appraisal is only applied to the regular file.
            if not stat.S_ISREG(os.stat(_)[stat.ST_MODE]):
                continue

            bb.note("Preparing to sign %s ..." % _)

            sh_name = pipes.quote(_)
            print("Signing command: %s" % cmd + sh_name)
            rc, res = oe.utils.getstatusoutput(cmd + sh_name + " >/dev/null")
            if rc:
                bb.fatal('Calculate IMA signature for %s failed with exit code %s:\n%s' % \
                    (_, rc, res if res else ""))

            with open(_ + '.sig', 'r') as f:
                s = base64.b64encode(f.read()) + '|'
                sig_list.append(s + os.sep + os.path.relpath(_, pkgdestpkg))

            os.remove(_ + '.sig')

        ima_sig_list = '&'.join(sig_list)

        # When the statically linked binary is updated, use the
        # dynamically linked one to resign or set. This situation
        # occurs in runtime only.
        setfattr_bin = 'setfattr.static'
        evmctl_bin = 'evmctl.static'
        ln_bin = 'ln.static'
        echo_bin = 'echo.static'
        grep_bin = 'grep.static'
        # By default, the build system always uses bash to launch %post
        safe_shell = '1'
        if pkg == 'attr-setfattr.static':
            setfattr_bin = 'setfattr'
        elif pkg == 'ima-evm-utils-evmctl.static':
            evmctl_bin = 'evmctil'
        elif pkg == 'coreutils-echo.static':
            echo_bin = 'echo'
        elif pkg == 'coreutils-ln.static':
            ln_bin = 'ln'
        elif pkg == 'grep-static':
            grep_bin = 'grep'
        elif pkg in ('bash', 'glibc', 'ncurses-libtinfo'):
            safe_shell = '0'

        # The %pre and %post are dynamically constructed according to the currently
        # installed package and enviroment.

        if safe_shell == '0':
            preinst = d.getVar('pkg_preinst_%s' % pkg, True) or ''
            preinst = preinst + r'''

''' + ln_bin + r''' -sfn "${base_bindir}/bash.static" "${base_bindir}/sh"
'''
            d.setVar('pkg_preinst_%s' % pkg, preinst)

        postinst = r'''
# %post hook for IMA appraisal
ima_resign=0
sig_list="''' + ima_sig_list + r'''"
safe_shell=''' + safe_shell + r'''

if [ -z "$D" ]; then
    # ln belongs to coreutils and it doesn't cause safe_shell == 0.
    [ $safe_shell -eq 0 ] && ''' + ln_bin + r''' -sfn "${base_bindir}/bash" "${base_bindir}/sh"

    evmctl_bin="${sbindir}/''' + evmctl_bin + r'''"
    setfattr_bin="${bindir}/''' + setfattr_bin + r'''"

    [ -f "/etc/keys/privkey_evm.pem" -a -x "$evmctl_bin" ] && \
        ima_resign=1

    saved_IFS="$IFS"
    IFS="&"
    for entry in $sig_list; do
        IFS="|"

        tokens=""
        for token in $entry; do
            tokens="$tokens$token|"
        done

        for sig in $tokens; do
            break
        done

        IFS="$saved_IFS"

        f="$token"

        # If the filesystem doesn't support xattr, skip the following steps.
        res=`"$setfattr_bin" -x security.ima "$f" 2>&1 | ''' + grep_bin + r''' "Operation not supported$"`
        [ x"$res" != x"" ] && {
            ''' + echo_bin + r''' "Current file system doesn't support to set xattr"
            break
        }

        if [ $ima_resign -eq 0 ]; then
            ''' + echo_bin + r''' "Setting up security.ima for $f ..."

            "$setfattr_bin" -n security.ima -v "0s$sig" "$f" || {
                err=$?
                ''' + echo_bin + r''' "Unable to set up security.ima for $f (err: $err)"
                exit 1
            }
        else
            ''' + echo_bin + r''' "IMA signing for $f ..."

            "$evmctl_bin" ima_sign --hashalgo sha256 --rsa "$f" || {
                err=$?
                ''' + echo_bin + r''' "Unable to sign $f (err: $err)"
                exit 1
            }
        fi

        IFS="&"
    done

    IFS="$saved_IFS"
fi

'''
        postinst = postinst + (d.getVar('pkg_postinst_%s' % pkg, True) or '')
        d.setVar('pkg_postinst_%s' % pkg, postinst)
}

do_package[depends] += "ima-evm-utils-native:do_populate_sysroot"
