#!/usr/bin/perl

use 5.010;
use strict;
use autodie;
use warnings;

sub compression {
    my $str = shift;
    die "Sorry, code too long\n" if length($str) >= 1 << 16;
    my @rep;
    my $la = 0;
    while ($la < length $str) {
        my $n = 1;
        my ($tmp, $p);
        $p = 0;
        while (   $la + $n < length $str
               && $n < 255
               && ($tmp = index(substr($str, 0, $la), substr($str, $la, $n), $p)) >= 0) {
            $p = $tmp;
            $n++;
        }

        --$n;
        my $c = substr($str, $la + $n, 1);
        push @rep, [$p, $n, ord $c];
        $la += $n + 1;
    }

    join('', map { pack 'SCC', @$_ } @rep);

}

sub decompression {
    my $str = shift;

    my $ret = '';
    while (length $str) {
        my ($s, $l, $c) = unpack 'SCC', $str;
        $ret .= substr($ret, $s, $l) . chr $c;
        $str = substr($str, 4);
    }

    $ret;
}

my $in  = shift() // die "usage: $0 [input file] [output file]\n";
my $out = shift() // "$in.77";

open my $fh, '<:raw', $in;

my $content = do {
    local $/;
    <$fh>;
};
close $fh;

open my $out_fh, '>:raw', $out;
print {$out_fh} compression($content);
close $out_fh;
