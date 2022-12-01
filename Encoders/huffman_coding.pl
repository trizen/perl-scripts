#!/usr/bin/perl

# https://rosettacode.org/wiki/Huffman_coding#Perl

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0];
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for (0, 1) }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree ($bytes) {
    my (%freq, @nodes);

    $freq{$_}++ for @$bytes;
    @nodes = map { [$_, $freq{$_}] } keys %freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        push @nodes, [[$x, $y], $x->[1] + $y->[1]];
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub encode ($bytes, $dict) {
    join('', map { $dict->{$_} // die("bad char $_") } @$bytes);
}

sub decode ($str, $dict) {
    my ($seg, @out) = ("");

    # append to current segment until it's in the dictionary
    foreach my $bit (split('', $str)) {
        $seg .= $bit;
        my $x = $dict->{$seg} // next;
        push @out, $x;
        $seg = '';
    }

    die "bad code" if length($seg);
    return \@out;
}

my $txt   = 'this is an example for huffman encoding';
my @bytes = unpack('C*', $txt);
my ($h, $rev_h) = mktree(\@bytes);
for (keys %$h) { printf("%3d: %s\n", $_, $h->{$_}) }

my $enc = encode(\@bytes, $h);
say $enc;

my $dec = decode($enc, $rev_h);
say pack('C*', @$dec);
