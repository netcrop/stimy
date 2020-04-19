#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
no warnings 'uninitialized';
# use Data::Dumper;
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
my $anyword = '(?:[a-zA-Z][0-9a-zA-Z_\-]*)';
my $keyword = '(?:return|if|while|for|switch)';
my $otherword = '(?!return|if|[a-zA-Z_][0-9a-zA-Z_\-]*)';
my $arguments='(?:[[:alnum:]]|[\_\,\%\\\&\-\(\>\.\*\"\:\[\]]|\s*)+';
my $lparent = '(';
my $rparent = ')';
my $rparentnosemicol = '\)(?!\;)';
my $begin = '^';
my $end = '\$';
my @path = ();
my %me = (
    pi => -1,
    tmp => ' ',
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
sub fnothing { ; }
# Decision table arguments: 0, ASCII character. 1, function pointer.  
sub hash{
    $me{unicode}[$_[0]] = $_[1];
}
sub flookbehind {
    for(my $i = $me{input_index} - 1; $i >= 0; $i--){
        $_ = substr($me{input},$i,1);
        return 0 if(m;[${rparent}];);
        return 1 if(m;$nonsp;);
    }
}
sub flbrace {
    debug("flbrace:$me{num_brace}");
    return if(++$me{num_brace} > 1);
    return if(flookbehind());
    $me{replaced} = $lbrace;
    $me{replacement} = $insertbegin;
    $me{replaced_index} =$me{input_index}; 
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
}
sub flookahead {
    for(my $i = $me{input_index} + 1; $i < $me{input_len}; $i++){
        $_ = substr($me{input},$i,1);
        return 1 if(m;$nonsp;);
        return 0 if(m;$nl;);
    }
}
sub freplace {
    debug("freplace: $me{replaced} WITH $me{replacement}");
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
}
# End of bracket-block.
sub frbrace {
    debug("frbrace:$me{num_brace}");
    return if(--$me{num_brace} >0);
    return if(flookahead());
    $me{replaced} = $rbrace;
    $me{replacement} = $insertend;
    $me{replaced_index} = $me{input_index}; 
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
}
sub flparent {
    return if($me{num_brace} < 1);
    $path[++$me{pi}] = $me{input_index};
    debug("flparent:$me{pi} i:$me{input_index}");
}
# End of one statement-block.
sub frparent {
    return if($me{num_brace} < 1);
    $_ = substr($me{input},$me{input_index},1);
    debug("frparent:$me{pi} i:$me{input_index}: $_");
    fparentlookahead();
    $path[$me{pi}--] = undef;
}
# Find function names
sub fparentlookbehind {
    debug("fparentlookbehind:"); 
    for(my $i = $path[$me{pi}] - 1; $i >= 0; $i--){
        $_ = substr($me{input},$i,1);
        if(m;$nl;){
            $me{tmp} = $i + 1;
            $i = -1;
        }
    }
    $_ = substr($me{input},$me{tmp},$path[$me{pi}] - $me{tmp});
    s{
        $wordsep($anyword$sp)$
    }{
        "$1" || return;
        $me{replaced} = "$1";
        return if($me{replaced} =~ $keyword );
        $me{replaced} .= substr($me{input},$path[$me{pi}],
            $me{input_index} - $path[$me{pi}]);
        $me{replacement} = "stimy_echo($1,$me{replaced})";
        $me{replaced_index} = $me{tmp} + $-[1];
        freplace();
    }sex;
}
# Ignore all assignment operators.
sub fparentlookahead {
    debug("fparentlookahead:"); 
    for(my $i = $me{input_index} + 1; $i < $me{input_len} - 3; $i++){
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
    s{
      ((['"]) (?: \. | .)*? \2) | # skip quoted strings
       /\* .*? \*/ |  # delete C comments
       // [^\n\r]*   # delete C++ comments
     }{
         $1 || ' '   # change comments to a single space
    }sexg;    # ignore white space, treat as single line
    $me{input} = $_;
    $me{input_len} = length($me{input});
}
sub postrun {
    $_ = $me{input};
    s{
        return$sp([^;]*)$semicol
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
