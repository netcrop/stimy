#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
#  no warnings 'uninitialized';
use Data::Dumper;
my ($arg) = @ARGV;
my $sp = '\s*';
my $tab = "\t";
my $lbrace = '{';
my $rbrace = '}';
my $col = ":";
my $space = ' ';
my $semicol = ';';
my $nl = "\n";
my $indent = $space x 4;
my $insertbegin = $lbrace . $nl . $indent . 'stimy_demand();';
my $insertend = $nl . $indent . 'stimy_reply();' . $nl . $rbrace;
my $word = '(?!return)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
my $otherword = '(?!return|if|while|for|switch)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
my $arguments='(?:[[:alnum:]]|[\_\,\%\\\&\-\(\>\.\*\"\:\[\]]|\s*)+';
my $lparent = '\(';
my $rparent = '\)';
my $rparentnosemicol = '\)(?!\;)';
my $begin = '^';
my $end = '\$';
my %keywords = (
    if => 1,
    while => 1,
);
my %keywords2 = (
    for => 1,
    switch => 1,
);
my %me = (
    i => 0,
    unicodesize => 256,
    brace_indicater => 2,
    block => 0,
    num_brace => 0,
    output => "#ifndef STIMY_H\n#include <stimy.h>\n#endif\n",
);
my %block = (0 => 0,1 => 1);
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
sub ftranslation_unit {
    $me{output} .= "$me{character}";
}
sub fnothing { ; }
# Decision table argument:
# 0, ascii character. 1, block indicator. 2, function pointer.  
sub hash{
    $me{unicode}[$_[0]][$_[1]] = $_[2];
}
sub removecomments {
    $_ = $me{input};
    s{
      ((['"]) (?: \. | .)*? \2) | # skip quoted strings
       /\* .*? \*/ |  # delete C comments
       // [^\n\r]*   # delete C++ comments
     }{
         $1 || ' '   # change comments to a single space
    }xseg;    # ignore white space, treat as single line
    $me{input} = $_;
}
sub fblock {
    $me{block_index} = $me{input_index};
    $me{block} = 1;
}
sub flbrace {
    $me{num_brace}++;    
}
# When nr of brace has been decresed to zero.
sub frbrace {
    if($me{num_brace} >0){
        $me{num_brace}--;
        return;
    }
    $me{block_len} = $me{input_index} - $me{block_index};
    fblock_list();
    $me{block} = 0;
}
sub fblock_list()
{
    for ($me{i} = $me{input_index} + 1; $me{i} < $me{input_len};$me{i}++){
        $_ = substr($me{input},$me{i},1);
        if(m;$nl;){
            fstatement_list();
            return;
        }
        if(m;$semicol;){
            fother_list();
            return;
        }
    }
}
sub fother_list {
    $me{output} .= substr($me{input},$me{block_index},$me{block_len}+1);
}
sub fstatement_list {
    $me{output} .= "$insertbegin";
    $_ = substr($me{input},$me{block_index} + 1,$me{block_len} - 2);
    s{
        return$sp(.*);
    }{stimy_reply($1);}mxg;
    $me{output} .= "$_";
    $me{output} .= "$insertend";
}
# Definition end Execution begin.
# Prepare all ASCII => function pointer into the unicode Hash table/decision table.
for (my $i = 0; $i < $me{unicodesize}; $i++){
    for (my $j = 0; $j < $me{brace_indicater}; $j++){
        if($j == 0){
            hash($i,$j,\&ftranslation_unit);
        }else{
            hash($i,$j,\&fnothing);
        }
    }
}
# Prepare specific ASCII => function name decision.
hash(lbrace(),$block{0},\&fblock);
hash(lbrace(),$block{1},\&flbrace);
hash(rbrace(),$block{1},\&frbrace);

open(INPUT, '<', "$arg") or die "Cann't open file: $arg. $!";
local $/ = undef;
$me{input} = <INPUT>;
removecomments();
$me{input_len} = length($me{input});
# Execute function name equal to each character inside C source code from Hash table.
for ($me{input_index} = 0; $me{input_index} < $me{input_len}; $me{input_index}++) {
    $me{character} = substr($me{input},$me{input_index},1);
    $me{unicode}[ord($me{character})][$me{block}]();
}
print $me{output};
#say Dumper(\%me);
