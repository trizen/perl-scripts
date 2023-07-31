#!/usr/bin/perl

# Author: Trizen
# Date: 11 February 2016
# Edit: 31 July 2023
# https://github.com/trizen

# Arithmetic coding, implemented using big integers.

# See also:
#   https://en.wikipedia.org/wiki/Arithmetic_coding#Arithmetic_coding_as_a_generalized_change_of_radix

use 5.036;
use Math::GMPz;
use List::Util qw(sum);

sub cumulative_freq ($freq) {

    my %cf;
    my $total = 0;
    foreach my $c (sort { $a <=> $b } keys %$freq) {
        $cf{$c} = $total;
        $total += $freq->{$c};
    }

    return %cf;
}

sub ac_encode ($bytes_arr) {

    my @chars = @$bytes_arr;

    # The frequency characters
    my %freq;
    ++$freq{$_} for @chars;

    # Create the cumulative frequency table
    my %cf = cumulative_freq(\%freq);

    # Limit and base
    my $base = Math::GMPz->new(scalar @chars);

    # Lower bound
    my $L = Math::GMPz->new(0);

    # Product of all frequencies
    my $pf = Math::GMPz->new(1);

    # Each term is multiplied by the product of the
    # frequencies of all previously occurring symbols
    foreach my $c (@chars) {
        Math::GMPz::Rmpz_mul($L, $L, $base);
        Math::GMPz::Rmpz_addmul_ui($L, $pf, $cf{$c});
        Math::GMPz::Rmpz_mul_ui($pf, $pf, $freq{$c});
    }

    # Upper bound
    my $U = $L + $pf;

    # Compute the power for left shift
    my $pow = Math::GMPz::Rmpz_sizeinbase($pf, 2) - 1;

    # Set $enc to (U-1) divided by 2^pow
    my $enc = ($U - 1) >> $pow;

    # Remove any divisibility by 2
    if ($enc > 0 and Math::GMPz::Rmpz_even_p($enc)) {
        $pow += Math::GMPz::Rmpz_remove($enc, $enc, Math::GMPz->new(2));
    }

    my $bin = Math::GMPz::Rmpz_get_str($enc, 2);

    return ($bin, $pow, \%freq);
}

sub ac_decode ($bits, $pow2, $freq) {

    # Decode the bits into an integer
    my $enc = Math::GMPz->new($bits, 2);

    $enc <<= $pow2;

    my $base = sum(values %$freq);

    # Create the cumulative frequency table
    my %cf = cumulative_freq($freq);

    # Create the dictionary
    my %dict;
    while (my ($k, $v) = each %cf) {
        $dict{$v} = $k;
    }

    # Fill the gaps in the dictionary
    my $lchar;
    foreach my $i (0 .. $base - 1) {
        if (exists $dict{$i}) {
            $lchar = $dict{$i};
        }
        elsif (defined $lchar) {
            $dict{$i} = $lchar;
        }
    }

    my $div = Math::GMPz::Rmpz_init();

    my @dec;

    # Decode the input number
    for (my $pow = Math::GMPz->new($base)**($base - 1) ;
         Math::GMPz::Rmpz_sgn($pow) > 0 ;
         Math::GMPz::Rmpz_tdiv_q_ui($pow, $pow, $base)) {

        Math::GMPz::Rmpz_tdiv_q($div, $enc, $pow);

        my $c  = $dict{$div};
        my $fv = $freq->{$c};
        my $cv = $cf{$c};

        Math::GMPz::Rmpz_submul_ui($enc, $pow, $cv);
        Math::GMPz::Rmpz_tdiv_q_ui($enc, $enc, $fv);

        push @dec, $c;
    }

    return \@dec;
}

#
## Run some tests
#
foreach my $str (
        'this is a message for you to encode and to decode correctly!',
        join('', 'a' .. 'z', 0 .. 9, 'A' .. 'Z', 0 .. 9),
        qw(DABDDB DABDDBBDDBA ABBDDD ABRACADABRA CoMpReSSeD Sidef Trizen google TOBEORNOTTOBEORTOBEORNOT),
        'In a positional numeral system the radix, or base, is numerically equal to a number of different symbols '
        . 'used to express the number. For example, in the decimal system the number of symbols is 10, namely 0, 1, 2, '
        . '3, 4, 5, 6, 7, 8, and 9. The radix is used to express any finite integer in a presumed multiplier in polynomial '
        . 'form. For example, the number 457 is actually 4×102 + 5×101 + 7×100, where base 10 is presumed but not shown explicitly.'
  ) {

    my @bytes = unpack('C*', $str);
    my ($enc, $len, $freq) = ac_encode(\@bytes);

    my $dec_bytes = ac_decode($enc, $len, $freq);
    my $dec       = pack('C*', @$dec_bytes);

    say "Encoded:  $enc";
    say "Decoded:  $dec";

    if ($str ne $dec) {
        die "\tHowever that is incorrect!";
    }

    say "-" x 80;
}
