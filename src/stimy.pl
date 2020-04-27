#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;
my $sharp = '#';
my $asterisk = '\*';
my $slash = '/';
my $backslash = '\\';
my $singlequote = '\'';
my $doublequote = '"';
my $equal = '=';
my $empty = '';
my $log = undef;
my $sp = '\s';
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
    preprocessor => 0,
    inputi => -1,
    comment => 0,
    dquote => 0,
    squote => 0,
    rparent => 0,
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
    return if(!$me{lookahead} || $me{preprocessor}
         || $me{squote} || $me{dquote} || $me{comment});
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
    # debug(":$_:");
    # Non consecutive Comments.
    if(m;$nonsp;){
        return $pcomment[0] = $me{inputi}; 
    }
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
    return if($me{squote} || $me{dquote} || $me{comment}
         || $me{preprocessor} || !$me{rparent});
    debug("flbrace:");
    return if(++$me{num_brace} > 1);
    $me{lbrace} = 1; 
}
sub frbrace {
    return if($me{squote} || $me{dquote} || $me{comment}
         || $me{preprocessor} || !$me{lbrace});
    debug("frbrace:");
    return if(--$me{num_brace} >0);
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
    return $me{rparent} = 1 if($me{num_brace} < 1);
    flookbehind();
    pop(@pparent);
    debug("size:" . scalar(@pparent));
}
sub foneline {
    for (;$me{i} > 0;$me{i}--){
        $_ = substr($me{input},$me{i},1);
        next if(m;$me{pattern};);
        $me{pattern} = $nonsp;
        last if(m;$sp;);
    }
}
sub flookbehind {
    $_ = substr($me{input},$me{inputi},1);
    debug("flookbehind:$_");
    $me{pattern} = $sp;
    if($pcomment[1] < $pparent[-1]){
        $me{i} = $pcomment[1] + 1;
        $_ = substr($me{input},$me{i},$pparent[-1] - $me{i});
        if(m;$nonsp;){
            debug("$me{i}:$_:$pparent[-1]");
            return;
        }
        $me{i} = $pcomment[0] - 1; 
        foneline();
        $_ = substr($me{input},$me{i} - 1,$pcomment[0] - $me{i});
        debug("$me{i}:$_:$pcomment[0]");
        return;
    }
    $me{i} = $pparent[-1] - 1;
    foneline();
    $_ = substr($me{input},$me{i} + 1,$pparent[-1] - $me{i} - 1);
    debug("$me{i}:$_:$pparent[-1]");
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
    print "$me{input}";
    close $log;
}
openfile();
run();
postrun();
#say Dumper(\%me);
#say Dumper(\@pcomment);
