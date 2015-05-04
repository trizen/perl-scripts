#!?usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 May 2015
# Website: http://github.com/trizen

# A very basic length encoder

use 5.010;
use strict;
use warnings;

use Data::Dump qw(pp);

# produce encode and decode dictionary from a tree
sub walk {
    my ($node, $code, $h) = @_;

    my $c = $node->[0];
    if (ref $c) { walk($c->[$_], $code . $_, $h) for 0, 1 }
    else        { $h->{$c} = $code }

    $h;
}

# make a tree, and return resulting dictionaries
sub mktree {
    my %freq = @_;

    my @nodes = map([$_, $freq{$_}], keys %freq);

    if (@nodes == 1) {
        return {$nodes[0][0] => '0'};
    }

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice @nodes, 0, 2;
        push @nodes, [[$x, $y], $x->[1] + $y->[1]];
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub length_encoder {
    my ($str) = @_;

    my %table;
    my @chars = split(//, $str);

    my $lim = $#chars;

    my %t;
    for (my $i = 0 ; $i < $lim ; $i++) {
        for (my $j = $i + 1 ; $j <= $lim ; $j++) {
            last if $j + ($j - $i) + 1 > $lim;
            my $key = join('', @chars[$i .. $j]);
            if (join('', @chars[$j + 1 .. $j + ($j - $i) + 1]) eq $key) {
                if (not exists $t{$key}) {
                    if (exists $t{substr($key, 0, -1)}) {
                        last;
                    }
                    $t{$key} = length($key);
                }
                else {
                    $t{$key}++;
                }
            }
        }
    }

    my ($dict) = keys(%t) ? mktree(%t) : {};
    my @sorted_tokens =
      sort { length($dict->{$a}) <=> length($dict->{$b}) or $t{$b} <=> $t{$a} or $a cmp $b } keys %t;

    say "Weights: ", pp(\%t);
    say "Sorted: @sorted_tokens";
    say "Bits: ", pp($dict);

    my $regex = do {
        my @tries = map { "(?<token>\Q$_\E)(?<rest>(?:\Q$_\E)*+)" } @sorted_tokens;
        local $" = '|';
        @sorted_tokens ? qr/^(?:@tries|(?<token>.))/s : qr/^(?<token>.)/s;
    };

    my $enc = '';

    while ($str =~ s/$regex//) {
        my $m = $+{token};
        my $r = $+{rest};
        if (defined $r) {
            $enc .= ("[$dict->{$m}x" . (1 + length($r) / length($m)) . "]");
        }
        else {
            $enc .= $m;
        }
    }

    return $enc;
}

foreach my $str (
                 qw(
                 ABABABAB
                 ABABABABAAAAAAAAAAAAAFFFFFFFFFFFFFFFFFFFDDDDDDDDDDDDDDDDDDDDJKLABABVADSABABAB
                 DABDDB DABDDBBDDBA ABBDDD ABRACADABRA TOBEORNOTTOBEORTOBEORNOT
                 )
  ) {

    say "Encoding: $str";
    say "Encoded: ", length_encoder($str);
    say "-" x 80;
}
