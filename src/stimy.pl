#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
#  no warnings 'uninitialized';
# use Data::Dumper;
my ($input) = @ARGV;
my $sp = '\s*';
my $tab = "\t";
my $lbrace = '{';
my $rbrace = '}';
my $col = ":";
my $space = ' ';
my $semicol = ';';
my $nl = "\n";
my $indent = $space x 4;
my $insertstart = $lbrace . $nl . $indent . 'stimy_demand();' . $nl;
my $insertend = $indent . 'stimy_reply();' . $nl . $rbrace . $nl;
my $word = '(?!return)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
my $otherword = '(?!return|if|while|for|switch)(?:[a-zA-Z_][0-9a-zA-Z_]*)';
my $arguments='(?:[[:alnum:]]|[\_\,\%\\\&\-\(\>\.\*\"\:\[\]]|\s*)+';
my $lparent = '\(';
my $rparent = '\)';
my $rparentnosemicol = '\)(?!\;)';
my $start = '^';
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
    unicodesize => 256,
    brace_indicater => 2,
    fundef_indicater => 2,
    block_end => 0,
    block_start => 0,
    num_brace => 0,
);
sub blockstart{
    $_[0];
}
sub blockend{
    $_[0];
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
sub fblock_start {
    $me{num_brace}++;
    $me{block_start_index} = $me{text_index};
    $me{block_start} = 1;
    $me{block_end} = 0;
}
sub fbrace_incre {
    $me{num_brace}++;    
}
sub fbrace_decre {
    $me{num_brace}--;
}
sub fsearch_block {
    return if($me{num_brace} >0);
    $me{block_end_len} = $me{text_index} - $me{block_start_index};
    block_find();
    $me{block_start} = 0;
    $me{block_end} = 0;
}
sub fstruct_print {
    return if($me{num_brace} >0);
    $me{block_end_len} = $me{text_index} - $me{block_start_index};
    print substr($me{text},$me{block_start_index},$me{block_end_len} + 1);
    $me{block_start} = 0;
    $me{block_end} = 0;
}
sub fother_print {
    print $me{val};
}
sub fprepare{
    $me{unicode}[$_[0]][$_[1]][$_[2]] = $_[3];
}
sub block_find {
    print $insertstart;
    $_ = substr($me{text},$me{block_start_index} + 1,$me{block_end_len} - 2);
    s{
      ((['"]) (?: \. | .)*? \2) | # skip quoted strings
       /\* .*? \*/ |  # delete C comments
       // [^\n\r]*   # delete C++ comments
     }{
         $1 || ' '   # change comments to a single space
    }xseg;    # ignore white space, treat as single line
    s{
        $start
        $sp
        (if|while)
        $sp
        $lparent
        (.*)
        $rparent
    }{
        "${indent}$1(stimy_echo($2) && $2)";
    }mxge;
    s{
        $start
        $sp
        (for|switch)
        ($sp
        $lparent
        .*
        $rparent)
    }{
        "${indent}$1$2";
    }mxge;
    s{
        $start
        $sp
        ($otherword)
        ($sp
        $lparent
        .*
        $rparent$sp$semicol)
    }{
       "${indent}stimy_print($1$2);";
    }mxge;
    s{
        return$sp(.*);
    }{stimy_reply($1);}mxg;
    print $_;
    print $insertend;
}
sub preprocessor{
    say "#ifndef STIMY_H";
    say "#include <stimy.h>";
    say "#endif";
}
sub fnothing {};
for (my $i = 0; $i < $me{unicodesize}; $i++){
    for (my $j = 0; $j < $me{brace_indicater}; $j++){
        for (my $k = 0; $k< $me{fundef_indicater}; $k++){
            if($j == 0 && $k == 0){
                    fprepare($i,$j,$k,\&fother_print);
            }else{
                    fprepare($i,$j,$k,\&fnothing);
            }
        }
    }
}

fprepare(lbrace(),blockstart(0),blockend(0),\&fblock_start);
fprepare(lbrace(),blockstart(1),blockend(0),\&fbrace_incre);
fprepare(rbrace(),blockstart(1),blockend(0),\&fbrace_decre);
fprepare(nl(),blockstart(1),blockend(0),\&fsearch_block);
fprepare(semicol(),blockstart(1),blockend(0),\&fstruct_print);

open(INPUT, '<', "$input") or die "Cann't open file: $input. $!";
local $/ = undef;
$me{text} = <INPUT>;
preprocessor();
$me{text_len} = length($me{text});
for ($me{text_index} = 0; $me{text_index} < $me{text_len}; $me{text_index}++) {
    $me{val} = substr($me{text},$me{text_index},1);
    $me{unicode}[ord($me{val})][$me{block_start}][$me{block_end}]();
}
#say Dumper(\%me);
