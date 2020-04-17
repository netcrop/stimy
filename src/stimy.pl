#!/usr/sbin/env /usr/sbin/perl
use PERLVERSION;
use strict;
use warnings;
#  no warnings 'uninitialized';
use Data::Dumper;
my $equal = '=';
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
my $nl = "\n";
my $indent = $space x 4;
my $insertbegin = $lbrace . $nl . $indent . 'stimy_demand();';
my $insertend = $nl . $indent . 'stimy_reply();' . $nl . $rbrace;
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
    num_parent => 0,
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
# End of bracket-block.
sub frbrace {
    say $log "frbrace:$me{num_brace}";
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
    $me{brace_index} = $me{input_index};
    $me{brace_len} = $me{brace_index};
}
sub flparent {
    return if($me{num_brace} < 1);
    say $log "flparent:$me{num_parent} i:$me{input_index}";
    $me{parent_index} = $me{input_index} if($me{num_parent} == 0);
    $me{num_parent}++;
}
# End of one statement-block.
sub frparent {
    return if($me{num_brace} < 1);
    say $log "frparent:$me{num_parent}";
    fparenthesis() if(--$me{num_parent} == 0);
}
sub freplace {
    say $log "freplace: $me{replacement}";
    $me{replaced_len} = length($me{replaced});
    substr($me{input},$me{replaced_index},$me{replaced_len},$me{replacement});
    $me{increment} = length($me{replacement}) - $me{replaced_len};
    $me{input_index} += $me{increment};
    $me{input_len} += $me{increment};
    $me{brace_len} += $me{increment};
}
sub fparenthesis {
    say $log "fparenthesis:"; 
    for(my $i = $me{input_index} + 1; $i < $me{input_len}; $i++){
        $_ = substr($me{input},$i,1);
        return if(m;$equal;);
        if(m;$nonsp;){
            fstatement();
            return;    
        }
    }
}
sub fstatement {
    say $log "fstatement:";
    $_ = substr($me{input},$me{brace_len},$me{parent_index} - $me{brace_len});
    s{
        ($anyword$sp)$
    }{
        $me{replaced} = "$1" || return;
        if( $me{replaced} !~ $keyword){
            $me{replaced} .= substr($me{input},$me{parent_index},
                $me{input_index} - $me{parent_index} + 1);
            $me{replacement} = "stimy_condition($me{replaced})";
            $me{replaced_index} = $me{brace_len} + $-[0];
            freplace();
        }
    }sexg;
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
    print "$me{preinput}$me{input}";
    close $log;
}
openfile();
run();
#say Dumper(\%me);
