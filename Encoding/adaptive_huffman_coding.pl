#!/usr/bin/perl

# Implementation of the Adaptive Huffman Coding.

# See also:
#   https://rosettacode.org/wiki/huffman_coding

use 5.036;
use List::Util qw(uniq);

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree_from_freq ($freq) {

    my @nodes = map { [$_, $freq->{$_}] } sort { $a <=> $b } keys %$freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x)) {
            if (defined($y)) {
                push @nodes, [[$x, $y], $x->[1] + $y->[1]];
            }
            else {
                push @nodes, [[$x], $x->[1]];
            }
        }
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub encode ($bytes, $alphabet) {

    my %freq;
    ++$freq{$_} for @$alphabet;

    my @enc;
    foreach my $byte (@$bytes) {
        my ($h, $rev_h) = mktree_from_freq(\%freq);
        ++$freq{$byte};
        push @enc, $h->{$byte};
    }

    return join('', @enc);
}

sub decode ($enc, $alphabet) {

    my @out;
    my $prefix = '';

    my %freq;
    ++$freq{$_} for @$alphabet;

    my ($h, $rev_h) = mktree_from_freq(\%freq);

    foreach my $bit (split(//, $enc)) {
        $prefix .= $bit;
        if (exists $rev_h->{$prefix}) {
            push @out, $rev_h->{$prefix};
            ++$freq{$rev_h->{$prefix}};
            ($h, $rev_h) = mktree_from_freq(\%freq);
            $prefix = '';
        }
    }

    return \@out;
}

my $text     = "this is an example for huffman encoding";
my @bytes    = unpack('C*', $text);
my @alphabet = uniq(@bytes);

my $enc = encode(\@bytes, \@alphabet);
my $dec = decode($enc, \@alphabet);

say $enc;
say pack('C*', @$dec);

__END__
1010000100010111110101010101010001010011011000101100010010010111110001011011111000011100111101111100111010110111011100111100011011100010001101100010011100000100010110001010
this is an example for huffman encoding
