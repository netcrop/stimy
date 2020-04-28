#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
no warnings 'uninitialized';
#use Data::Dumper;
my $sharp = '#';
my $asterisk = '\*';
my $slash = '/';
my $backslash = '\\';
my $singlequote = '\'';
my $doublequote = '"';
my $equal = '=';
my $empty = '';
my $log = undef;
my $sp = '[ \t\v\n\f]';
my $nonsp = '[^ \t\v\n\f]';
my $tab = '\t';
my $lbrace = '{';
my $rbrace = '}';
my $col = ':';
my $space = ' ';
my $semicol = ';';
my $nl = "\n";
my $indent = $space x 4;
my $ignoreword ='(?:__typeof__)';
my $assignmentop = '(?:=|\+=|\-=|\*=|/=|\%=|\<\<=|\>\>=|\&=|\^=|\|=)';
my $alpha = '[0-9a-zA-Z_\-]';
my $nonalpha = '[^0-9a-zA-Z_\-]';
my $wordsep = '(?:[ \t\n!\(\;=])';
my $anyword = '(?:[a-z][0-9a-zA-Z_\-]*)';
my $otherword = '(?!return|if|[a-zA-Z_][0-9a-zA-Z_\-]*)';
my $arguments='(?:[[:alnum:]]|[\_\,\%\\\&\-\(\>\.\*\"\:\[\]]|\s*)+';
my $lparent = '(';
my $rparent = ')';
my $rparentnosemicol = '\)(?!\;)';
my $begin = '^';
my $end = '\$';
# Left-parent index list.
my @pparent = ();
# Comment start and end position list.
my @pcomment = (0,0);
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
    replacedi => 0,
    rparenti => 0,
    headi => 0,
    taili => 0,
    preprocessor => 0,
    inputi => -1,
    comment => 0,
    dquote => 0,
    squote => 0,
    fundef => 0,
    lookahead => 0,
    pattern => ' ',
    nexti => 0,
    replacement => ' ',
    logfile => '/tmp/stimy.log',
    infile => $ARGV[0],
    i => 0,
    unicodesize => 256,
    num_brace => 0,
    preinput => "#ifndef STIMY_H\n#include <stimy.h>\n#endif\n",
    insertbegin => "${lbrace}${nl}${indent}stimy_pre()${semicol}",
    insertend => "${nl}${indent}stimy_post()${semicol}${nl}${rbrace}",
);
sub debug{
    say $log "$_[0]";
}
sub tab{
    ord($tab);
}
sub space{
    ord($space);
}
sub sharp{
    ord($sharp);
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
sub backslash{
    ord($backslash);
}
sub fnothing {
    return if($me{preprocessor} || $me{squote} || $me{dquote} || $me{comment});
    flookahead() if($me{lookahead});
}
sub fspace {;}
sub ftab {;}
# Decision table arguments: 0, ASCII character. 1, function pointer.  
sub hash {
    $me{unicode}[$_[0]] = $_[1];
}
sub fbackslash {
    debug("fbackslash:");
    $me{inputi}++;
}
sub fnl {
    return if($me{squote} || $me{dquote});
    debug("fnl:");
    # End of Comment format: '//'
    if($me{comment}){
        debug("end comment 2:");
        $me{comment} = 0; 
        # Append
        $pcomment[1] = $me{inputi};
    }
    if($me{preprocessor}){
        debug("end preprocessor.");
        $me{preprocessor} = 0;
    }
    hash(nl(),\&fnothing);
}
sub fsharp {
    return if($me{preprocessor} || $me{squote} || $me{dquote} || $me{comment});
    debug("fsharp: start preprocessor.");
    $me{preprocessor} = 1;
    hash(nl(),\&fnl);
}
sub fslash {
    return if($me{squote} || $me{dquote} || $me{preprocessor});
    # End of Comment format: '*/'.
    if($me{comment}){
        debug("fslash: end comment 1.");
        $_ = substr($me{input},$me{inputi} - 1,1);
        return if(!m;$asterisk;);
        $me{comment} = 0;
        # Append
        $pcomment[1] = $me{inputi};
        hash(nl(),\&fnl);
        return;
    }
    $_ = substr($me{input},$me{inputi} + 1,1);
    #  Start of the Comment format: '/*'
    return if(!m;$asterisk|$slash;);
    if(m;$asterisk;){
        debug("fslash: start comment 1.");
        hash(nl(),\&fnothing);
    }else{
        # Start of Comment format: '//'
        debug("fslash: start comment 2.");
        hash(nl(),\&fnl);
    }
    $me{comment} = 1;
    $me{inputi}++;
    # String between Comments.
    $_ = substr($me{input},$pcomment[1] + 1,$me{inputi} - $pcomment[1] - 2);
    return if(m;^$sp*$;);
    # Non consecutive Comments.
    $pcomment[0] = $me{inputi} - 1; 
}
sub fsinglequote {
    return if($me{dquote} || $me{comment} || $me{preprocessor});
    debug("fsinglequote:");
    # Flip the indicator.
    return $me{squote} = 0 if($me{squote});
    $me{squote} = 1;
}
sub fdoublequote {
    return if($me{squote} || $me{comment} || $me{preprocessor});
    debug("fdoublequote:");
    # Flip the indicator.
    return $me{dquote} = 0 if($me{dquote});
    $me{dquote} = 1;
}
sub flbrace {
    # Counting brace is only valid inside function definition.
    return if($me{squote} || $me{dquote} || $me{comment}
         || $me{preprocessor} || !$me{fundef});
    debug("flbrace:");
    return if(++$me{num_brace} > 1);
    $me{lbracei} = $me{inputi};
}
sub frbrace {
    return if($me{squote} || $me{dquote} || $me{comment}
         || $me{preprocessor} || !$me{lbracei});
    debug("frbrace:");
    return if(--$me{num_brace} >0);
    fheadtail();
}
sub fheadtail()
{
    debug("fheadtail:");
    debug("$me{lbracei}::$me{inputi}");
    $me{replacedi} = $me{lbracei}; 
    $me{replaced} = $lbrace;
    $me{replacement} = $me{insertbegin};
    freplace();
    $me{replacedi} = $me{inputi}; 
    $me{replaced} = $rbrace;
    $me{replacement} = $me{insertend};
    freplace();
    $me{fundef} = 0;
    $me{lbracei} = 0;
}
sub flparent {
    return if($me{squote} || $me{dquote} || $me{comment} || $me{preprocessor});
    debug("flparent:");
    return if($me{num_brace} < 1);
    push(@pparent,$me{inputi});
    debug("size:" . scalar(@pparent));
}
sub frparent {
    return if($me{squote} || $me{dquote} || $me{comment} || $me{preprocessor});
    debug("frparent:");
    # Possible function definition.
    return $me{fundef} = 1 if($me{num_brace} < 1);
    flookahead() if($me{lookahead});
    $me{rparenti} = $me{inputi};
    flookbehind();
    pop(@pparent);
    debug("size:" . scalar(@pparent));
}
sub flookbehind {
    $_ = substr($me{input},$me{inputi},1);
    debug("flookbehind:$_");
    if($pcomment[1] > $pparent[-1]){
        $me{i} = $pparent[-1] - 1;
        foneline();
        return;
    }
    $me{i} = $pcomment[1] + 1;
    $_ = substr($me{input},$me{i},$pparent[-1] - $me{i});
    if(m;$nonsp;){
        $me{i} = $pparent[-1] - 1; 
    }else{
        $me{i} = $pcomment[0] - 1; 
    }
    foneline();
}
sub foneline {
    debug("foneline:");
    $me{pattern} = $sp;
    for (;$me{i} > 0;$me{i}--){
        $_ = substr($me{input},$me{i},1);
        #debug(":$_:");
        next if(m;$me{pattern};);
        if(m;$sp;){
            $me{headi} = $me{i} + 1;
            last; 
        }
        $me{pattern} = $nonsp;
        $me{taili} = $me{i};
    }
    $_ = substr($me{input},$me{headi},$me{taili} - $me{i}); 
    debug("$me{headi}:$_:$me{taili}");
    return if(!m;^$anyword$;);
    return if($keyword{$_});
    $me{lookahead} = 1;
}
sub flookahead {
    $_ = substr($me{input},$me{inputi},1);
    debug("flookahead:$_");
    $me{lookahead} = 0;
    $_ = substr($me{input},$me{inputi},3);
    s{
        ^(
           =[^=] |
           [\+\-\*%\/\^\|]= |
           >>= | <<=
        )
    }{
        "$1" && return;
    }sex;
    $_ = substr($me{input},$me{headi},$me{taili} - $me{i});
    debug("$me{headi}:$_:$me{taili}");
    $me{replacedi} = $me{headi};
    $me{replaced} = substr($me{input},$me{headi},$me{rparenti} - $me{i});
    $me{replacement} = "stimy_echo($_,$me{replaced})";
    freplace();
}
sub freplace {
    debug("freplace:");
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replacedi},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len}; 
    $me{input_len} += $me{increment};
    $me{inputi} += $me{increment};
#    debug("$me{headi}:$2:$me{rparenti}");
}
sub openfile {
    open($log, '>', "$me{logfile}") or die "Cann't open file: $me{logfile}. $!";
    open(INPUT, '<', "$me{infile}") or die "Cann't open file: $me{infile}. $!";
    local $/ = undef;
    $me{input} = <INPUT>;
    $me{input_len} = length($me{input});
}
sub run {
    # Prepare unicode Hash decision table.
    for (my $i = 0; $i < $me{unicodesize}; $i++){
        hash($i,\&fnothing);
    }
    # Prepare specific ASCII => function name decision.
    hash(space(),\&fspace);
    hash(tab(),\&ftab);
    hash(lparent(),\&flparent);
    hash(rparent(),\&frparent);
    hash(lbrace(),\&flbrace);
    hash(rbrace(),\&frbrace);
    hash(singlequote(),\&fsinglequote);
    hash(doublequote(),\&fdoublequote);   
    hash(slash(),\&fslash);
    hash(sharp(),\&fsharp);
    hash(backslash(),\&fbackslash);
    # Indirect function lookahead based on previous prepared hash table.
    while (++$me{inputi} < $me{input_len}){
        $me{unicode}[ord(substr($me{input},$me{inputi},1))]();
    }
}
sub postrun()
{
    debug("=====================");
    print "$me{preinput}$me{input}";
    close $log;
}
openfile();
run();
postrun();
#say Dumper(\%me);
#say Dumper(\@pcomment);
