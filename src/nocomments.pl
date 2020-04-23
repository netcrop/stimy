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
my $ignoreword ='(?:__typeof__)';
my $anyword = '(?:[a-z][0-9a-zA-Z_\-]*)';
my $lparent = '(';
my $rparent = ')';
my $rparentnosemicol = '\)(?!\;)';
my $begin = '^';
my $end = '\$';
# Left-parent index list.
my @path = ();
my %me = (
    comment => 0,
    comment_start => 0,
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
    debug("fslash:");
    return if($me{squote} || $me{dquote});
    if($me{comment}){
        $_ = substr($me{input},$me{input_index} - 1,1);
        $me{comment} = 0 if(m;[\*];);
        return;
    }
    $_ = substr($me{input},$me{input_index} + 1,1);
    return if(!m;[\*/];);
    $me{comment} = 1;
    return if(m;[\*];);
}
sub fsinglequote {
    debug("fsinglequote:");
    if($me{dquote} > 0){
        debug("1d:$me{dquote},s:$me{squote}");
        return; 
    }
    $_ = substr($me{input},$me{input_index} - 1,3);
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
    if($me{squote} > 0){
        debug("1d:$me{dquote},s:$me{squote}");
        return;
    }
    $_ = substr($me{input},$me{input_index} - 1,3);
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
    for ($me{input_index} = 0; $me{input_index} < $me{input_len}; $me{input_index}++){
        $me{character} = substr($me{input},$me{input_index},1);
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
    print "$me{input}";
    close $log;
}
openfile();
prerun();
run();
postrun();
#say Dumper(\%me);
