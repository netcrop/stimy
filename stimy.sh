stimy.substitute()
{
    local cmdlist reslist devlist pkg pkglist cmd i 
    cmdlist=(dirname basename cat ls mv sudo cp chmod ln chown rm touch
    head mkdir perl mktemp shred egrep make sed realpath find less)
    devlist=(dot valgrind stimy nocomments gcc diff indent)
    pkglist=()
    for cmd in ${cmdlist[@]};do
        i=($(\builtin type -afp $cmd))
        [[ -n $i ]] || {
            \builtin printf "%s\n" "$FUNCNAME Require: $cmd"
            return
        }
        \builtin eval "local ${cmd//-/_}=${i:-:}"
    done
    for pkg in ${pkglist[@]};do
        pacman -Qi $pkg >/dev/null 2>&1 && continue
        \builtin printf "%s\n" "$FUNCNAME Require: $pkg"
        return
    done
    for cmd in ${devlist[@]};do
        i=($(\builtin type -afp $cmd))
        [[ -n $i ]] || {
            \builtin printf "%s\n" "$FUNCNAME Optional: $cmd"
            continue
        }
        \builtin eval "local ${cmd//-/_}=${i:-:}"
    done

    local perl_version="$($perl -e 'print $^V')"
    local vendor_perl=/usr/share/perl5/vendor_perl/
    local libdir=/usr/local/lib
    local includedir=/usr/local/include/
    local bindir=/usr/local/bin/
    local testdir=test/
    local logfile=/tmp/stimy.log
    \builtin source <($cat<<-EOF

stimy.distribute()
{
    : Distribute lib and header file for testing without gcc
    $cp -f src/libstimy.so ${libdir}
    $chmod go=r ${libdir}/libstimy.so
    $cp -f src/stimy.h ${includedir}
    $chmod go=r ${includedir}/stimy.h
}
stimy.target()
{
    local offset configfile targetdir=\${1:?[target source dir]}
    [[ \$PWD =~ 'stimy' ]] || {
        \builtin echo "Should run inside stimy directory."
        return 1
    }
    targetdir=\$($realpath \${targetdir})
    offset=\$((\${#targetdir}-1))
    stimy.install 0
    [[ "\${targetdir:\$offset:1}" == '~' ]] && targetdir="\${targetdir:0:\$offset}" 
    [[ -d \${targetdir} ]] || {
        \builtin echo "invalid directory: \${targetdir}"
        return 1
    }

    $mv \$targetdir \$targetdir~
    $cp -a \$targetdir~ \$targetdir
 
    declare -a Target=(\$($find \${targetdir} -regextype sed -regex ".*\.[c,h]$" \
    ! -path "*/config.h" ! -path "*/config.def.h" ! -path "*/stimy.h" ! -path "*/stimy.c"))
    for i in \${Target[@]};do
        [[ -r \${i} ]] || continue
        $stimy -c \${i} > \${i}~ && $mv -f \${i}~ \${i}
    done
    configfile="\$($find \${targetdir} -regextype sed -regex ".*/config.mk$")" 
    if [[ -w \${configfile} ]];then
       $sed -i "s;^\([[:alnum:]]*LDFLAGS.*\)\$;\1 ${libdir}/libstimy.so;" \${configfile}
       return
    fi
    declare -a Configfile=(\$($find \${targetdir} -regextype sed -regex ".*/Makefile\.in$")) 
    for i in \${Configfile[@]};do
        [[ -w \${i} ]] || continue
        $sed -i \
        "s;^\([[:alnum:]]*LDFLAGS *[\+]\{0,1\}=\)\(.*\)\$;\1 ${libdir}/libstimy.so \2;" \
        \${i}
#        $sed -E -i "s;^(CFLAGS *=.*)\$;\1 ${libdir}/libstimy.so;" \${i}
    done
    declare -a Configfile=(\$($find \${targetdir} -regextype sed -regex ".*/Makefile$")) 
    for i in \${Configfile[@]};do
        [[ -w \${i} ]] || continue
        $sed -i \
        "s;^\([[:alnum:]]*LDFLAGS *[\+]\{0,1\}=\)\(.*\)\$;\1 ${libdir}/libstimy.so \2;" \
        \${i}
    done
}
stimy.restore.target()
{
    local offset sourcedir targetdir=\${1:?[target original source dir~.]}
    targetdir=\$($realpath \${targetdir})
    offset=\$((\${#targetdir}-1))
    [[ "\${targetdir:\$offset:1}" == '~' ]] || targetdir="\${targetdir}~" 
    [[ -d \${targetdir} ]] || {
        \builtin echo "invalid directory: \${targetdir}"
        return 1
    }
#    set -x
    sourcedir=\${targetdir:0:\$offset}
    [[ -d \${sourcedir} ]] || {
       \builtin echo "invalid directory: \${sourcedir}"
        return 1
    }
    $rm -rf \${sourcedir}
    $mv \${targetdir} \${sourcedir}
    set +x
}
stimy.test()
{
    local testfile=\${1:?[test header file]}
    [[ -r \${testfile} ]] || return
    stimy.install 1
    \builtin echo "---------" >$logfile
    $cat \${testfile} >>$logfile
    \builtin echo "=========" >>$logfile
    $stimy -c \${testfile} >>$logfile 
    \builtin echo "---------" >>$logfile
    $less $logfile
}
stimy.difflog()
{
    declare -a Tests=(
#    ${testdir}/misc.h
#    ${testdir}/quote.h
    ${testdir}/comments.h
#    ${testdir}/definition.h
    )
    local i
    for i in \${Tests[@]};do
        $stimy -c \${i} >/tmp/stimy.log
        $cat \${i} >>/tmp/stimy.log
    done
}
stimy.funcall()
{
    local input=\${1:?[C source/header file]}   
    [[ -r "\${input}" ]] || return
    $perl - "\${input}" <<-'CFUN'
    use $perl_version;
    use strict;
    my \$input = \$ARGV[0];
    my \$sp = '\s*';
    my \$semicol = ';';
    my \$lparent = '\(';
    my \$rparent ='\)';
    my \$lbrace = '\{';
    my \$space = ' ';
    my \$nl = '\n';
    my \$nonkeyword = '(?!return|if|while|for|switch)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
    open(INPUT, '<', "\${input}") 
    or die "Cann't open file: \${input}";
    {
        local \$/ = undef;
        \$_ = <INPUT>;
        s{
            \$sp(\$nonkeyword\$lparent\$rparent)\$sp\$lbrace
        }{
            say "\$1;";
        }sexg;
    }
CFUN
}
stimy.make()
{
    (
        \builtin cd test/
        $make clean && $make && ./verify
        $make clean
    )
}
stimy.syntax()
{
    local file=\${1:?[include header file]}
    local filename=\${file##*/}
    [[ -r \${file} ]] || return
    declare -a Fun=(\$(stimy.funcall \${file}))
    $mv ${testdir}/verify.c ${testdir}/verify.c~
    $cat <<-CSYNTAX > ${testdir}/verify.c
#include <stdio.h>
#include "\${filename}"
int main()
{
    \${Fun[@]}
    fprintf(stdout,"%s\n","main");
    return 0;
}
CSYNTAX
    stimy.make
    $mv ${testdir}/verify.c~ ${testdir}/verify.c
}
stimy.squeeze()
{
    local input=\${1:?[input file]}
    $perl - "\${input}" <<-'STIMYSQUEEZE' | $less
    use $perl_version;
    use strict;
    no warnings 'uninitialized';
#    use Data::Dumper;
    my \$sp = '[ ]+';
    my \$nl ='\n';
    my \$zeroone = '[0-1]';
    my \$digits = '[0-9]+';
    my @res;
    my @fun = ('','');
    my %me=(
        input => \$ARGV[0],
        index => 0,
    );
    my %hash=();
   # Compare with 2 step behind on next loop.
    sub flipindex()
    {
        \$me{index} = 0 if(\$me{index}++ > 0);
    }
    open(INPUT, '<', "\$me{input}")
    or die "Cann't open file \$me{intput}.";
    {
        @{res} = <INPUT>;
        \$fun[0] = \$res[0];
        \$fun[1] = \$res[1];
        foreach(@{res}){
            if(m;\$sp\$digits\$sp\$digits\$sp(.*)(\$zeroone);){
                # When Not equal: cmp => 1.
                print \$_ if("\$1\$2" cmp \$fun[\$me{index}]);
                \$fun[\$me{index}] = "\$1\$2";
                flipindex();
            }elsif(m;\$sp\$digits\$sp\$digits\$sp(.*);){
                print \$_ if("\$1" cmp \$fun[\$me{index}]);
                \$fun[\$me{index}] = "\$1";
            }
        }
    }
#    say Dumper(\\%me);
STIMYSQUEEZE
}
stimy.info()
{
    $cat<<-STIMYINFO
    # append to config.mk
    LDFLAGS = $libdir/libstimy.so
    # Or append to Makefile.mk
    LDADD = $libdir/libstimy.so
STIMYINFO
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
    $nocomments "\$input" >\$tmpfile
    $stimy "\$tmpfile"
    stimy_delocate
}


stimy.preprocessor()
{
    local infile=\${1:?[C/h file]}
    $gcc -E \${@}
}
stimy.uninstall()
{
     $rm -f ${bindir}/stimy
     $rm -f ${bindir}/nocomments
     $rm -f ${libdir}/libstimy.so
     $rm -f ${includedir}/stimy.h 
}
stimy.lib()
{
    (
        \builtin cd src &&\
        $cp -f stimy.h ${includedir}/ &&\
        $gcc -g3 -fPIC -c stimy.c &&\
        $gcc -g3 -shared -o libstimy.so stimy.o  
    )
}
stimy.install()
{
    local debugging=\${1:?[ debugging: 1 | 0]}
    stimy.uninstall
    stimy.lib
    $cp src/libstimy.so ${libdir}
    $chmod u=r,go=r ${libdir}/libstimy.so
    $sudo $ln -sf ${libdir}/libstimy.so /usr/lib/
    $cp src/stimy.h ${includedir}/
    $chmod u=r,go=r ${includedir}/stimy.h 
    $sudo $ln -sf ${includedir}/stimy.h /usr/include/
    $sed -e "s;PERLVERSION;$perl_version;" \
    -e "s;DEBUGGING;\$debugging;" \
    src/stimy.py >${bindir}/stimy
    $chmod u=rx,go= ${bindir}/stimy
}
stimy.verify()
{
    stimy.install 0
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
        \builtin \cd test/ && $rm -f *.o verify
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
test/.*
src/.*
src/libstimy.so
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
stimy.indent()
{
    local infile=\${1:?[C file]}
    $indent --linux-style --indent-level8 --no-tabs \
    --line-length200 \
    --standard-output \${infile}
}
EOF
)
}
stimy.substitute
builtin unset -f stimy.substitute
