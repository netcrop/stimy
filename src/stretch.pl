#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
#  no warnings 'uninitialized';
#use Data::Dumper;
my $empty = '';
my $log = undef;
my $sp = '\s*';
my $nonsp = '\S';
my $tab = "\t";
my $lbrace = '{';
my $rbrace = '}';
my $col = ":";
my $space = ' ';
my $semicol = ';';
my $nl = '\n';
my $indent = $space x 4;
my $anyword = '(?:[a-zA-Z_][0-9a-zA-Z_-]*)';
my $keyword = '(?:return|if|while|for|switch)';
my $word = '(?!return)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
my $otherword = '(?!return|if|while|for|switch)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
my $arguments='(?:[[:alnum:]]|[\_\,\%\\\&\-\(\>\.\*\"\:\[\]]|\s*)+';
my $lparent = '(';
my $rparent = ')';
my $rparentnosemicol = '\)(?!\;)';
my $begin = '^';
my $end = '\$';
my %me = (
    tmp => ' ',
    replacement => ' ',
    logfile => '/tmp/stimy.txt',
    infile => $ARGV[0],
    i => 0,
    unicodesize => 256,
    num_brace => 0,
    num_parent => 0,
);
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
sub fnothing { ; }
# Decision table argument:
# 0, ascii character. 1, function pointer.  
sub hash{
    $me{unicode}[$_[0]] = $_[1];
}
sub nocomments {
    say $log "prerun";
    $_ = $me{input};
    s{
      ((['"]) (?: \. | .)*? \2) | # skip quoted strings
       /\* .*? \*/ |  # delete C comments
       // [^\n\r]*   # delete C++ comments
     }{
         $1 || ' '   # change comments to a single space
    }sexg;    # ignore white space, treat as single line
    $me{input} = $_;
}
sub squeeze()
{
   say $log "squeeze";
    $_ = $me{input};
    s{
        $sp($semicol)
    }{
        $1;
    }sexg;
    $me{input} = $_;
}
sub emptyline()
{
    say $log "emptyline";
    $_ = $me{input};
    s{
        $nl$sp($nl)
    }{
        $1;
    }sexg;
    $me{input} = $_;
}
sub flbrace {
    say $log "flbrace:$me{num_brace}";
    if($me{num_brace} == 0) {
        $me{brace_index} = $me{input_index};
        $me{brace_len} = $me{brace_index};
    }
    $me{num_brace}++;    
}
# End of bracket-block.
sub frbrace {
    say $log "frbrace:$me{num_brace}";
    if($me{num_brace} >0){
        $me{num_brace}--;
        return;
    }
}
sub flparent {
    return if($me{num_brace} <= 0 );
    say $log "flparent:num_parent:$me{num_parent},input_i:$me{input_index}";
    if($me{num_parent} == 0){
        $me{parent_index} = $me{input_index};
    }
    $me{num_parent}++;
}
# End of one parenthesis-block.
sub frparent {
    return if($me{num_brace} <= 0 );
    say $log "frparent:$me{num_parent}";
    if($me{num_parent} > 0){
        $me{num_parent}--;
    }
    fparenthesis() if($me{num_parent} == 0);
}
sub fparenthesis {
    print $log "fparenthesis:";
    $me{replaced_len} = $me{input_index} - $me{parent_index} + 1;
    $_ = substr($me{input},$me{parent_index},$me{replaced_len});
    s{
        ($nl$sp)
    }{
        $1 && ''
    }sexg;
    substr($me{input},$me{parent_index},$me{replaced_len},"$_");
    $me{increment} = length("$_") - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
    say $log "$_";
}
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

open($log, '>', "$me{logfile}") or die "Cann't open file: $me{logfile}. $!";
open(INPUT, '<', "$me{infile}") or die "Cann't open file: $me{infile}. $!";
local $/ = undef;
$me{input} = <INPUT>;
nocomments();
squeeze();
emptyline();
$me{input_len} = length($me{input});
# Execute function name equal to each character inside C source code from Hash table.
for ($me{input_index} = 0; $me{input_index} < $me{input_len}; $me{input_index}++) {
    $me{character} = substr($me{input},$me{input_index},1);
    $me{unicode}[ord($me{character})]();
}
print "$me{input}";
close $log;
#say Dumper(\%me);
