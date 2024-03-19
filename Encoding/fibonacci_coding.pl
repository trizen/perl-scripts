#!/usr/bin/perl

# Author: Trizen
# Date: 19 March 2024
# https://github.com/trizen

# Implementation of the Fibonacci coding method.

# References:
#   Information Retrieval WS 17/18, Lecture 4: Compression, Codes, Entropy
#   https://youtube.com/watch?v=A_F94FV21Ek
#
#   Fibonacci coding
#   https://en.wikipedia.org/wiki/Fibonacci_coding

use 5.036;
use List::Util qw(shuffle);

sub read_bit ($fh, $bitstring) {

    if (($$bitstring // '') eq '') {
        $$bitstring = unpack('b*', getc($fh) // return undef);
    }

    chop($$bitstring);
}

sub fibonacci_coding ($symbols) {

    my $bitstring = '';

    foreach my $n (@$symbols) {
        my ($f1, $f2, $f3) = (0, 1, 1);
        my ($rn, $s, $k) = ($n, '', 2);
        for (; $f3 <= $rn ; ++$k) {
            ($f1, $f2, $f3) = ($f2, $f3, $f2 + $f3);
        }
        foreach my $i (1 .. $k - 2) {
            ($f3, $f2, $f1) = ($f2, $f1, $f2 - $f1);
            if ($f3 <= $rn) {
                $rn -= $f3;
                $s .= '1';
            }
            else {
                $s .= '0';
            }
        }
        $bitstring .= reverse($s) . '1';
    }

    pack('B*', $bitstring);
}

sub bsearch_le ($left, $right, $callback) {

    my ($mid, $cmp);

    for (; ;) {

        $mid = int(($left + $right) / 2);
        $cmp = $callback->($mid) || return $mid;

        if ($cmp < 0) {
            $left = $mid + 1;
            $left > $right and last;
        }
        else {
            $right = $mid - 1;

            if ($left > $right) {
                $mid -= 1;
                last;
            }
        }
    }

    return $mid;
}

{
    my @FIB = (0, 1);

    sub find_fibonacci ($n) {

        if ($n == 1) {
            return (2, 0, 1, 1);
        }

        if ($n >= $FIB[-1]) {
            my ($f1, $f2) = ($FIB[-2], $FIB[-1]);
            while (1) {
                ($f1, $f2) = ($f2, $f1 + $f2);
                push @FIB, $f2;
                last if ($f2 >= $n);
            }
        }

        my $k = bsearch_le(0, $#FIB, sub ($k) { $FIB[$k] <=> $n });
        return ($k, $FIB[$k - 1], $FIB[$k], $FIB[$k + 1]);
    }
}

sub fibonacci_coding_cached ($symbols) {

    my $bitstring = '';

    foreach my $n (@$symbols) {
        my ($rn, $s) = ($n, '');
        my ($k, $f1, $f2, $f3) = find_fibonacci($n);
        foreach my $i (1 .. $k - 1) {
            ($f3, $f2, $f1) = ($f2, $f1, $f2 - $f1);
            if ($f3 <= $rn) {
                $rn -= $f3;
                $s .= '1';
            }
            else {
                $s .= '0';
            }
        }
        $bitstring .= reverse($s) . '1';
    }

    return pack('B*', $bitstring);
}

sub fibonacci_decoding ($str) {

    open my $fh, '<:raw', \$str;

    my @symbols;

    my $enc      = '';
    my $prev_bit = '0';
    my $buffer   = '';

    while (1) {
        my $bit = read_bit($fh, \$buffer) // last;
        if ($bit eq '1' and $prev_bit eq '1') {
            my ($value, $f1, $f2) = (0, 1, 1);
            foreach my $bit (split //, $enc) {
                $value += $f2 if $bit;
                ($f1, $f2) = ($f2, $f1 + $f2);
            }
            push @symbols, $value;
            $enc      = '';
            $prev_bit = '0';
        }
        else {
            $enc .= $bit;
            $prev_bit = $bit;
        }
    }

    return \@symbols;
}

my @integers = shuffle(grep { $_ > 0 } map { int(rand($_)) } 1 .. 1000);
my $str      = fibonacci_coding([@integers]);
my $str2     = fibonacci_coding_cached([@integers]);

say "Encoded length: ", length($str);
say "Rawdata length: ", length(join(' ', @integers));

my $decoded = fibonacci_decoding($str);

$str eq $str2                                or die "Encoding error";
join(' ', @integers) eq join(' ', @$decoded) or die "Decoding error";

__END__
Encoded length: 1428
Rawdata length: 3608
