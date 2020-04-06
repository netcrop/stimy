stimy.substitute()
{
    local reslist devlist libdir includedir bindir cmd i perl_version \
    vendor_perl \
    cmdlist='dirname basename cat ls mv sudo cp chmod ln chown rm touch
    chmod head mkdir perl mktemp shred egrep make sed realpath find'

    declare -A Devlist=(
    [dot]='dot'
    [valgrind]='valgrind'
    [indent]='indent'
    [stimy]='stimy'
    [gcc]='gcc'
    )
    cmdlist="${Devlist[@]} $cmdlist"
    for cmd in $cmdlist;do
        i="$(\builtin type -fp $cmd 2>/dev/null)"
        if [[ -z $i ]];then
            if [[ -z ${Devlist[$cmd]} ]];then
                reslist+=$cmd
            else
                devlist+="$cmd "
            fi
        fi
        \builtin eval "${cmd//-/_}=${i:-:}"
    done
    [[ -z $reslist ]] ||\
    { 
        \builtin printf "%s\n" \
        "$FUNCNAME says: ( $reslist ) These Required Commands are missing."
        return
    }
    [[ -z $devlist ]] ||\
    \builtin printf "%s\n" \
    "$FUNCNAME says: ( $devlist ) These Optional Commands for further development."

    perl_version="$($perl -e 'print $^V')"
    vendor_perl=/usr/share/perl5/vendor_perl/
    libdir=/usr/local/lib
    includedir=/usr/local/include/
    bindir=/usr/local/bin/

    \builtin source <($cat<<-EOF

stimy.info()
{
    $cat<<-STIMYINFO
    # append to config.mk
    LDFLAGS = $libdir/libstimy.so
    # Or append to Makefile.mk
    LDADD = $libdir/libstimy.so
STIMYINFO
}
stimy.indent()
{
  local infile=\${1:?[C file]}
  $indent --indent-level8 --no-tabs \
    --line-length200 \
    --standard-output \${infile}
}
stimy.parser()
{
    \builtin trap "stimy_delocate" SIGHUP SIGTERM SIGINT
    stimy_delocate()
    {
        \builtin trap - SIGHUP SIGTERM SIGINT
        $shred -fu \$tmpfile
        \builtin unset stimy_delocate
    }
    local input=\${1:?[input]}
    local trace=\${2:+'-d:Trace'}
    local tmpfile=\$($mktemp)
    stimy.indent "\$input" >\$tmpfile
    $stimy "\$tmpfile"
    stimy_delocate
}
stimy.restore.target()
{
    local sourcedir targetdir=\${1:?[target original source dir~.]}
    targetdir=\$($realpath \${targetdir})
    [[ -d \${targetdir} ]] || return
    set -o xtrace
    sourcedir=\${targetdir%%~*}
    [[ -d \${sourcedir} ]] && $rm -rf \${sourcedir}
    $mv \${targetdir} \${sourcedir}
    set +o xtrace
}
stimy.target()
{
    local configfile targetdir=\${1:?[target source dir]}
    targetdir=\$($realpath \${targetdir})
    [[ -d \${targetdir} ]] || return
    (
        $mv \$targetdir \$targetdir~
        $cp -a \$targetdir~ \$targetdir
        \builtin cd \$targetdir &&\
        for i in \$($find -regextype sed -regex ".*\.c$"|\
            $egrep -v 'stimy.c|config.h|config.def.h');do
            stimy.indent \$i > \$i~
            $stimy \$i~ > \$i
            $rm -f \$i~
        done
    )
    configfile="\$(find \${targetdir} -regextype sed -regex ".*/Makefile.am$")" 
    if [[ -w \${configfile} ]];then
        \builtin printf "%s" "LDADD=${libdir}/libstimy.so" >> \${configfile} 
        return
    fi
    configfile="\$(find \${targetdir} -regextype sed -regex ".*/config.mk$")" 
    if [[ -w \${configfile} ]];then
       $sed -i "s;^\([[:alnum:]]*LDFLAGS.*\)\$;\1 ${libdir}/libstimy.so;" \${configfile}
        return
    fi
    configfile="\$(find \${targetdir} -regextype sed -regex ".*/Makefile$")" 
    if [[ -w \${configfile} ]];then
        $sed -i \
       "s;^\([[:alnum:]]*LDFLAGS *[\+]\{0,1\}=\)\(.*\)\$;\1 ${libdir}/libstimy.so \2;" \
        \${configfile}
        return
    fi
}
stimy.preprocessor()
{
    local infile=\${1:?[C/h file]}
    $gcc -E \${@}
}
stimy.uninstall()
{
     $sudo $rm -f ${bindir}/stimy
     $sudo $rm -f ${libdir}/libstimy.so
     $sudo $rm -f ${includedir}/stimy.h 
}
stimy.lib()
{
    (
        \builtin cd src &&\
        $sudo $cp -f stimy.h ${includedir}/stimy.h &&\
        $chown \$USER:\$USER ${includedir}/stimy.h &&\
        $chmod a=r ${includedir}/stimy.h &&\
        $gcc -g3 -fPIC -c stimy.c &&\
        $gcc -g3 -shared -o libstimy.so stimy.o  
    )
}
stimy.install()
{
    stimy.uninstall
    [[ -r src/libstimy.so ]] || return
    $sudo $cp src/libstimy.so ${libdir}/ &&\
    $sudo $chmod u=r,go=r ${libdir}/libstimy.so &&\
    $sudo $cp src/stimy.h ${includedir}/ &&\
    $sudo $chmod u=r,go=r ${includedir}/stimy.h 
    $sudo $sed "s;PERLVERSION;$perl_version;" src/stimy.pl >${bindir}/stimy &&\
    $sudo $chmod u=rx,go= ${bindir}/stimy
}
stimy.test()
{
    stimy.lib
    stimy.install
    stimy.restore.target test~/
    stimy.target test/
    (
        \builtin \cd test/ && $make &&\
        $valgrind --leak-check=full --show-leak-kinds=all ./verify
    )
    stimy.restore.target test~/
}
stimy.clear()
{
    (
        \builtin \cd test/ && $rm -f *.o
    )
    (
        \builtin \cd src/ && $rm -f *.so *.o
    )
}
stimy.exclude()
{
    $cat<<-DWMEXCLUDE>.git/info/exclude
pkg
master
origin
Makefile.in
configure
config.log
config.status
autom4te.cache/
config.h.in
test/verify
.*
*.o
stimy
*~
*.xz
*.so
DWMEXCLUDE
}
stimy.dot()
{
    local infile=\${1:?[infile gv]}
    local name=\$(basename ${infile/.gv/})
    $dot -Tpng \$infile -o /tmp/\$name.png
    $chown \$USER:users /tmp/\$name.png
    $chmod u=rw,go=r /tmp/\$name.png
}
EOF
)
}
stimy.substitute
builtin unset -f stimy.substitute
