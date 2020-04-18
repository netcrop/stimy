#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
no warnings 'uninitialized';
use Data::Dumper;
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
my $insertbegin = $lbrace . $nl . $indent . 'stimy_demand();';
my $insertend = $nl . $indent . 'stimy_reply();' . $nl . $rbrace;
my $ignoreword ='(?:__typeof__)';
my $assignmentop = '(?:=|\+=|\-=|\*=|/=|\%=|\<\<=|\>\>=|\&=|\^=|\|=)';
my $anyword = '(?:[a-zA-Z_][0-9a-zA-Z_\-]*)';
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
    brace_len => 0,
    parent_index => 0,
    tmp => ' ',
    replacement => ' ',
    logfile => '/tmp/stimy.txt',
    infile => $ARGV[0],
    i => 0,
    unicodesize => 256,
    brace_indicater => 2,
    column => 0,
    num_brace => 0,
    preinput => "#ifndef STIMY_H\n#include <stimy.h>\n#endif\n",
);
my %column = (0 => 0,1 => 1);
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
# 0, ascii character. 1, column indicator. 2, function pointer.  
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
    say $log "flbrace:$me{num_brace}";
    return if(++$me{num_brace} > 1);
    $me{brace_index} = $me{input_index};   
    return if(flookbehind());
    $me{replaced} = $lbrace;
    $me{replacement} = $insertbegin;
    $me{replaced_index} =$me{input_index}; 
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
    $me{brace_index} = $me{input_index};
    $me{brace_len} = $me{brace_index};
}
sub flookahead {
    for(my $i = $me{input_index} + 1; $i < $me{input_len}; $i++){
        $_ = substr($me{input},$i,1);
        return 1 if(m;$nonsp;);
        return 0 if(m;$nl;);
    }
}
sub return_statement {
    say $log "return_statement:";
    $me{replaced_index} = $me{brace_index} + 1;
    $_ = substr($me{input},$me{replaced_index},$me{input_index} - $me{replaced_index});
    $me{replaced} = $_;
    s{
        return$sp([^;]*)$semicol
    }{
        "stimy_reply($1);";
    }mexg;
    $me{replacement} = $_;
    freplace();
}
sub freplace {
#    say $log "freplace: $me{replaced} WITH $me{replacement}";
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
    $me{brace_len} += $me{increment};
}
# End of bracket-block.
sub frbrace {
    say $log "frbrace:$me{num_brace}";
    return if(--$me{num_brace} >0);
    return_statement();
    return if(flookahead());
    $me{replaced} = $rbrace;
    $me{replacement} = $insertend;
    $me{replaced_index} = $me{input_index}; 
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
    $me{brace_index} = $me{input_index};
    $me{brace_len} = $me{brace_index};
}
sub flparent {
    return if($me{num_brace} < 1);
    $path[++$me{pi}] = $me{input_index};
    say $log "flparent:$me{pi} i:$me{input_index}";
}
# End of one statement-block.
sub frparent {
    return if($me{num_brace} < 1);
    say $log "frparent:$me{pi} i:$me{input_index}";
    fparentlookahead();
    $path[$me{pi}--] = undef;
}
sub fparentlookbehind {
    say $log "fparentlookbehind:"; 
    $_ = substr($me{input},$me{brace_len},$path[$me{pi}] - $me{brace_len});
    s{
        $wordsep($anyword$sp)$
    }{
        "$1" || return;
        $me{replaced} = "$1";
        return if($me{replaced} =~ $keyword );
        $me{replaced} .= substr($me{input},$path[$me{pi}],
            $me{input_index} - $path[$me{pi}]);
        $me{replacement} = "stimy_condition($me{replaced})";
        $me{replaced_index} = $me{brace_len} + $-[1];
        freplace();
    }sex;
}
sub fparentlookahead {
    say $log "fparentlookahead:"; 
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
    $me{input_len} = length($me{input});
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
sub postrun {
    print "$me{preinput}$me{input}";
    close $log;
}
openfile();
run();
postrun();
#say Dumper(\%me);
