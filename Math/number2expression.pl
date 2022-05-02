#!/usr/bin/perl

# Author: Trizen
# Date: 02 May 2022
# https://github.com/trizen

# Compress a number into a polynomial expression in a given base.

use 5.020;
use strict;
use warnings;

use Math::Sidef qw(Polynomial Number sum);
use Math::AnyNum qw(:overload digits);
use Getopt::Long qw(GetOptions);

use ntheory qw(vecsum);
use experimental qw(signatures);

sub run_length ($arr, $max_len = 1e9) {

    @$arr || return;

    my @result     = ([$arr->[0], 1]);
    my $prev_value = $arr->[0];

    foreach my $i (1 .. $#{$arr}) {

        my $curr_value = $arr->[$i];

        if ($curr_value == $prev_value) {
            ++$result[-1][1];
        }
        else {
            push(@result, [$curr_value, 1]);

            # Stop early when there are too many entries
            if (scalar(@result) > $max_len) {
                return @result;
            }
        }

        $prev_value = $curr_value;
    }

    return @result;
}

sub number2runLength ($n, $base = 10, $max_len = 1e9) {
    my @D = ($base < 2147483647) ? ntheory::todigits($n, $base) : reverse(digits($n, $base));
    my $t = scalar(@D);
    my @R = run_length(\@D, $max_len);
    return \@R;
}

sub number2expr ($R, $base = 10) {

    my $t = vecsum(map { $_->[1] } @$R);

    my @terms;

    foreach my $pair (@$R) {
        my ($d, $l) = @$pair;
        $t -= $l;
        push @terms,
          (
            ($l == 1)
            ? Polynomial($t => $d)
            : Polynomial($l)->sub(1)->div($base - 1)->mul(Polynomial($t => $d))
          );
    }

    my $str = sum(@terms)->to_s;
    ## $str =~ s/x/$base/g;
    return $str;
}

sub number2expr_alt ($R, $base = 10) {

    my $t = vecsum(map { $_->[1] } @$R);

    my @terms;

    foreach my $pair (@$R) {
        my ($d, $l) = @$pair;
        $t -= $l;
        push @terms, Polynomial($l)->sub(1)->mul(Polynomial($t => $d));
    }

    my $sum = sum(@terms);

    my $str = $sum->to_s;
    if ($base != 2) {
        $str = "($str)/" . ($base - 1);
    }

    ## $str =~ s/x/$base/g;
    return $str;
}

sub compress_number ($n, $from = 2, $upto = 100, $integer_coeff = 0) {

    my $min_runLength = [];
    my $min_base      = 0;
    my $min_len       = 1e9;

    foreach my $base ($from .. $upto) {

        my $R = number2runLength($n, $base, $min_len);

        if (scalar(@$R) < $min_len) {
            $min_len       = scalar(@$R);
            $min_base      = $base;
            $min_runLength = $R;
            last if ($min_len == 1);
        }
    }

    my $min_expr     = '';
    my $min_expr_len = 1e9;

    foreach my $base ($min_base) {
        my @list;

        push(@list, number2expr($min_runLength, $base)) if !$integer_coeff;
        push(@list, number2expr_alt($min_runLength, $base));

        foreach my $expr (@list) {

            if (length($expr) < $min_expr_len) {
                $min_expr     = $expr;
                $min_expr_len = length($expr);
            }
        }
    }

    $min_expr =~ s/x/$min_base/gr;
}

sub help {
    print <<"EOT";
usage: $0 [options] [integer]

options:

    -f  --from=i     : first base to check
    -t  --to=i       : last base to check
    -i  --int!       : prefer integer coefficients
    -b  --base=i     : use only this specific base

example:

    perl number2expr.pl 123123123
    perl number2expr.pl -i -b=1000 123123123
    perl number2expr.pl -from=900 -to=1200 123123123
    perl number2expr.pl -i -from=900 -to=1200 123123123
EOT

    exit 0;
}

my $base          = undef;
my $from          = 2;
my $upto          = 1000;
my $integer_coeff = 0;

GetOptions(
           'b|base=i' => \$base,
           'from=i'   => \$from,
           'to=i'     => \$upto,
           'i|int!'   => \$integer_coeff,
           'h|help'   => \&help,
          )
  or die("Error in command line arguments\n");

foreach my $n (@ARGV) {

    if (defined($base)) {
        if ($integer_coeff) {
            say number2expr_alt(number2runLength($n, $base), $base);
        }
        else {
            say number2expr(number2runLength($n, $base), $base);
        }
        next;
    }

    say compress_number($n, $from, $upto, $integer_coeff);
}

if (!@ARGV) {

#<<<
    my @tests = (
        [0b100000100000111111101, 2],
        [(7**911 - 4 * (7**455) - 1), 7],
        [11113338888999999999, 10],
    );
#>>>

    foreach my $pair (@tests) {
        my ($n, $b) = @$pair;
        say("base $b: ", number2expr(number2runLength($n, $b), $b));
        say("base $b: ", number2expr_alt(number2runLength($n, $b), $b));
        say '';
    }
}

__END__
base 2: x^20 + x^14 + x^9 - x^2 + 1
base 2: x^21 - x^20 + x^15 - x^14 + x^9 - x^2 + x - 1

base 7: x^911 - x^456 + 3*x^455 - 1
base 7: (6*x^911 - 4*x^456 + 4*x^455 - 6)/6

base 10: 1/9*x^20 + 2/9*x^16 + 5/9*x^13 + 1/9*x^9 - 1
base 10: (x^20 + 2*x^16 + 5*x^13 + x^9 - 9)/9
