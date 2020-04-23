#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
no warnings 'uninitialized';
# use Data::Dumper;
my $asterisk = '\*';
my $slash = '/';
my $singlequote = '\'';
my $doublequote = '"';
my $equal = '=';
my $empty = '';
my $log = undef;
my $sp = '\s*';
my $nonsp = '\S';
my $tab = '\t';
my $lbrace = '{';
my $rbrace = '}';
my $col = ':';
my $space = ' ';
my $semicol = ';';
my $nl = "\n";
my $wordsep = '(?:[ \t\n!\(\;])';
my $indent = $space x 4;
my $insertbegin = $lbrace . $nl . $indent . 'stimy_pre();';
my $insertend = $nl . $indent . 'stimy_post();' . $nl . $rbrace;
my $ignoreword ='(?:__typeof__)';
my $assignmentop = '(?:=|\+=|\-=|\*=|/=|\%=|\<\<=|\>\>=|\&=|\^=|\|=)';
my $anyword = '(?:[a-z][0-9a-zA-Z_\-]*)';
my $otherword = '(?!return|if|[a-zA-Z_][0-9a-zA-Z_\-]*)';
my $arguments='(?:[[:alnum:]]|[\_\,\%\\\&\-\(\>\.\*\"\:\[\]]|\s*)+';
my $lparent = '(';
my $rparent = ')';
my $rparentnosemicol = '\)(?!\;)';
my $begin = '^';
my $end = '\$';
# Left-parent index list.
my @path = ();
my %keyword = (
    error => 'error',
    pragma => 'pragma',
    operator => 'operator',
    elif => 'elif',
    line => 'line',
    endif => 'endif',
    ifdef => 'ifdef',
    include => 'include',
    undef => 'undef',
    defined => 'defined',
    auto => 'auto',
    char => 'char',   
    default => 'default',
    else => 'else',
    for => 'for',
    inline => 'inline',
    return => 'return',
    static => 'static',
    union => 'union',
    while => 'while',
    _Bool => '_Bool',
    _Complex => '_Complex',
    restrict => 'restrict',
    enum => 'enum',
    goto => 'goto',
    int => 'int',
    short => 'short',
    struct => 'struct',
    unsigned => 'unsigned',
    break => 'break',
    const => 'const',
    do => 'do',
    extern => 'extern',
    if => 'if',
    long => 'long',
    signed => 'signed',
    switch => 'switch',
    void => 'void',
    case => 'case',
    continue => 'continue',
    double => 'double',
    float => 'float',
    _Imaginary => '_Imaginary',
    register => 'register',
    sizeof => 'sizeof',
    typeof => 'typeof',
    typedef => 'typedef',
    volatile => 'volatile',
);
my %me = (
    commenti => -1,
    dquote => 0,
    squote => 0,
    fundef => 0,
    pi => -1,
    headstr => ' ',
    nexti => 0,
    replacement => ' ',
    logfile => '/tmp/stimy.txt',
    infile => $ARGV[0],
    i => 0,
    unicodesize => 256,
    num_brace => 0,
    preinput => "#ifndef STIMY_H\n#include <stimy.h>\n#endif\n",
);
sub debug{
    say $log "$_[0]";
}
sub rparent{
    ord($rparent);
}
sub lparent{
    ord($lparent);
}
sub lbrace{
    ord($lbrace);
}
sub rbrace{
    ord($rbrace);
}
sub nl{
    ord($nl);
}
sub semicol{
    ord($semicol);
}
sub singlequote{
    ord($singlequote);
}
sub doublequote{
    ord($doublequote);
}
sub slash{
    ord($slash);
}
sub fnothing { ; }
# Decision table arguments: 0, ASCII character. 1, function pointer.  
sub hash{
    $me{unicode}[$_[0]] = $_[1];
}
sub fslash {
    debug("fslash:commenti:$me{commenti}");
    return if($me{squote} || $me{dquote});
    # End of Comment.
    if($me{commenti} >= 0){
        $_ = substr($me{input},$me{inputi} - 1,1);
        return if(!m;[\*];);
        $me{replacedi} = $me{commenti};
        $me{replaced}=substr($me{input},$me{replacedi},$me{inputi}-$me{replacedi} + 1);
        $me{replacement} = $space;
        freplace();
        $me{commenti} = -1;
    }
    $_ = substr($me{input},$me{inputi} + 1,1);
    # the next char indicate Not Start of the Comment.
    return if(!m;[\*/];);
    # the next char indicate Start of the Comment format: '/*'
    return $me{commenti} = $me{inputi} if(m;[\*];);
    # loop through the current line to include Comment format: '//'
    # Do not reposition but only change the length of input.
    for (my $i = $me{inputi} + 1; $i <= $me{input_len}; $i++){
        $_ = substr($me{input},$i,1);
        if(m;$nl;){
            substr($me{input},$me{inputi},$i - $me{inputi},$space);
            $me{input_len} -= $i - $me{inputi};
            $me{commenti} = -1;
            return;
        }
    }
}
sub fsinglequote {
    debug("fsinglequote:");
    return if($me{commenti} >=0);
    if($me{dquote} > 0){
        debug("1d:$me{dquote},s:$me{squote}");
        return; 
    }
    $_ = substr($me{input},$me{inputi} - 1,3);
    if(m;[\\]${singlequote};){
        debug("2d:$me{dquote},s:$me{squote}");
        return;
    }
    if($me{squote} > 0){
        $me{squote} = 0;
    }else{
        $me{squote} = 1;
    }
    debug("3d:$me{dquote},s:$me{squote}");
}
sub fdoublequote {
    debug("fdoublequote:");
    return if($me{commenti} >=0);
    if($me{squote} > 0){
        debug("1d:$me{dquote},s:$me{squote}");
        return;
    }
    $_ = substr($me{input},$me{inputi} - 1,3);
    if(m;[\\]${doublequote};){
        debug("2d:$me{dquote},s:$me{squote}");
        return;
    }
    if($me{dquote} > 0){
        $me{dquote} = 0;
    }else{
        $me{dquote} = 1;
    }
    debug("3d:$me{dquote},s:$me{squote}");
}
# Find function definition.
sub flookbehind {
    debug("flookbehind:");
    for(my $i = $me{inputi} - 1; $i >= 0; $i--){
        $_ = substr($me{input},$i,1);
        if(m;[${rparent}];){
            # Not a preprocessor
            for(my $j = $i - 1; $j >= 0; $j--){
                $_ = substr($me{input},$j,1);
                if(m;$nl;){
                    $me{headstr} = substr($me{input},$j + 1,7);
                    debug("L$me{headstr}:");
                    return $me{fundef} = 0 if($me{headstr} =~ '#define');
                    return $me{fundef} = 1;
                }
            }
            return $me{fundef} = 1; 
        }
        return $me{fundef} = 0 if(m;$nonsp;);
    }
}
sub flbrace {
    debug("flbrace:$me{num_brace},d:$me{dquote},s:$me{squote}");
    return if($me{squote} || $me{dquote} || $me{commenti} >=0);
    return if(++$me{num_brace} > 1);
    return if(flookbehind() == 0);
    $me{replaced} = $lbrace;
    $me{replacement} = $insertbegin;
    $me{replacedi} =$me{inputi}; 
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replacedi},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{inputi} += $me{increment};
    $me{input_len} += $me{increment};
}
sub flookahead {
    for(my $i = $me{inputi} + 1; $i < $me{input_len}; $i++){
        $_ = substr($me{input},$i,1);
        return 1 if(m;$nonsp;);
        return 0 if(m;$nl;);
    }
}
sub freplace {
    debug("freplace: inputi:$me{inputi},inputl:$me{input_len}");
#    debug("$me{replaced} WITH $me{replacement}");
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replacedi},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{inputi} += $me{increment};
    $me{input_len} += $me{increment};
    debug("inputi:$me{inputi},inputl:$me{input_len}");
}
# End of bracket-block.
sub frbrace {
    debug("frbrace:$me{num_brace}");
    return if($me{squote} || $me{dquote} || $me{commenti} >=0);
    return if(--$me{num_brace} >0);
    return if($me{fundef} == 0);
    return if(flookahead());
    $me{replaced} = $rbrace;
    $me{replacement} = $insertend;
    $me{replacedi} = $me{inputi}; 
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replacedi},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{inputi} += $me{increment};
    $me{input_len} += $me{increment};
}
sub flparent {
    return if($me{squote} || $me{dquote} || $me{commenti} >=0);
    return if($me{num_brace} < 1);
    $path[++$me{pi}] = $me{inputi};
    debug("flparent:$me{pi} i:$me{inputi}");
}
# End of one statement-block.
sub frparent {
    return if($me{squote} || $me{dquote} || $me{commenti} >=0);
    return if($me{num_brace} < 1);
    $_ = substr($me{input},$me{inputi},1);
    debug("frparent:$me{pi} i:$me{inputi}: $_");
    fparentlookahead();
    $path[$me{pi}--] = 0 if($me{pi} >=0);
}
# Find function names
sub fparentlookbehind {
    debug("fparentlookbehind:"); 
    for(my $i = $path[$me{pi}] - 1; $i >= 0; $i--){
        $_ = substr($me{input},$i,1);
        if(m;$nl;){
            $me{nexti} = $i + 1;
            $i = -1;
        }
    }
    $_ = substr($me{input},$me{nexti},$path[$me{pi}] - $me{nexti});
    s{
        $wordsep($anyword)($sp)$
    }{
        "$1" || return;
        $me{replaced} = "$1$2";
        return if($keyword{$1});
        $me{replaced} .= substr($me{input},$path[$me{pi}],
            $me{inputi} - $path[$me{pi}]);
        $me{replacement} = "stimy_echo($1,$me{replaced})";
        $me{replacedi} = $me{nexti} + $-[1];
        freplace();
    }sex;
}
# Ignore all assignment operators.
sub fparentlookahead {
    debug("fparentlookahead:"); 
    for(my $i = $me{inputi} + 1; $i < $me{input_len} - 3; $i++){
        $_ = substr($me{input},$i,1);
        if(m;$nonsp;){
            $_ = substr($me{input},$i,3);
            s{
                ^(
                   =[^=] |
                   [\+\-\*%\/\^\|]= |
                   >>= | <<=
                )
            }{
                "$1" && return; 
            }sex;
            fparentlookbehind();
            return;
        }
    }
}
sub openfile {
    open($log, '>', "$me{logfile}") or die "Cann't open file: $me{logfile}. $!";
    open(INPUT, '<', "$me{infile}") or die "Cann't open file: $me{infile}. $!";
    local $/ = undef;
    $me{input} = <INPUT>;
}
sub run {
    # Definition end Execution begin.
    # Prepare unicode Hash decision table.
    for (my $i = 0; $i < $me{unicodesize}; $i++){
        hash($i,\&fnothing);
    }
    # Prepare specific ASCII => function name decision.
    hash(lbrace(),\&flbrace);
    hash(rbrace(),\&frbrace);
    hash(lparent(),\&flparent);
    hash(rparent(),\&frparent);
    hash(singlequote(),\&fsinglequote);
    hash(doublequote(),\&fdoublequote);   
    hash(slash(),\&fslash);
    # Execute function to each character inside C source code from Hash table.
    for ($me{inputi} = 0; $me{inputi} < $me{input_len}; $me{inputi}++){
        $me{character} = substr($me{input},$me{inputi},1);
        $me{unicode}[ord($me{character})]();
    }
}
sub prerun()
{
    debug("prerun:");
    $_ = $me{input};
#    s{
#      ((['"]) (?: \. | .)*? \2) | # skip quoted strings
#       /\* .*? \*/ |  # delete C comments
#       // [^\n\r]*   # delete C++ comments
#    }{
#         $1 || ' '   # change comments to a single space
#    }sexg;    # ignore white space, treat as single line
   # Stretch lines.
    s{
        ($sp[\\][\n]$sp)
    }{
        $1 && ' ';
    }sexg;
    $me{input} = $_;
    $me{input_len} = length($me{input});
}
sub postrun {
    $_ = $me{input};
    s{
        ${wordsep}(?:return)${sp}([^;]*)$semicol
    }{
        "stimy_post($1);";
    }mexg;
    $me{input} = $_;
    print "$me{preinput}$me{input}";
    close $log;
}
openfile();
prerun();
run();
postrun();
#say Dumper(\%me);
