#!/usr/bin/perl

# Given a positive integer `n`, this algorithm finds all the numbers k
# such that sigma(k) = n, where `sigma(k)` is the sum of divisors of `k`.

# Based on "invphi.gp" code by Max Alekseyev.

# See also:
#   https://home.gwu.edu/~maxal/gpscripts/

use utf8;
use 5.020;
use strict;
use warnings;

use Math::Prime::Util::GMP qw(:all);
use List::Util qw(uniq);
use experimental qw(signatures);

binmode(STDOUT, ':utf8');

sub inverse_sigma {
    my ($n) = @_;

    my %cache;
    my %factor_cache;
    my %divisor_cache;

    my $results = sub ($n, $m) {

        return [1] if ($n == 1);

        my $key = "$n $m";
        if (exists $cache{$key}) {
            return $cache{$key};
        }

        my (@R, @D);
        $divisor_cache{$n} //= [divisors($n)];

        foreach my $d (@{$divisor_cache{$n}}) {
            if ($d >= $m) {

                push @D, $d;

                $factor_cache{$d} //= do {
                    my %factors;
                    @factors{factor(subint($D[-1], 1))} = ();
                    [keys %factors];
                };
            }
        }

        foreach my $d (@D) {
            foreach my $p (@{$factor_cache{$d}}) {

                my $r = addint(mulint($d, subint($p, 1)), 1);
                my $k = valuation($r, $p) - 1;
                next if ($k < 1);

                my $s = powint($p, $k + 1);
                next if ("$r" ne "$s");
                my $z = powint($p, $k);

                my $u   = divint($n, $d);
                my $arr = __SUB__->($u, $d);

                foreach my $v (@$arr) {
                    if (modint($v, $p) != 0) {
                        push @R, mulint($v, $z);
                    }
                }
            }
        }

        $cache{$key} = \@R;
    }->($n, 3);

    sort { $a <=> $b } uniq(@$results);
}

my %tests = (
     6 => 6187272, 10 => 196602,  11 => 8105688, 16 => 2031554,
    25 => 1355816, 31 => 8880128, 80 => 11532,   97 => 5488,
);

while (my ($n, $k) = each %tests) {
    my @inverse = inverse_sigma($k);
    say "σ−¹($k) = [@inverse]";
    if (gcd(@inverse) != $n) {
        die "Error for k = $k";
    }
}

use Test::More;
plan tests => 4;

is(join(' ', inverse_sigma(42)), join(' ', 20, 26, 41));
is(join(' ', inverse_sigma(7688)), join(' ', 2800, 2928, 4575, 7687));
is(join(' ', inverse_sigma("110680464442257309690")), "46116860184273879040");
is(join(' ', inverse_sigma("9325257382230393314439814176")), "3535399776779654608221686964 4302950338161146561477374638 4637009852153025247015401018 4661529533007908774933879778 4884658628787348878992283572 5187814889839710566412258045 5311639278156872382400698772 5326520187917077557965023252 5328493035801953244119300732 5495240957385767488866317781 6208298641832871739558373002 6411114450283395403677372213 6417519160023938256228496989 6454455748546107757077838269 6799666841209661791779031135 6938435552254756930386764875 6992294299511863162400845113 7215972974344947207602237095 8501184728947212952861568533 8546137477181166087378779593 9130981186767260120388984667 9214242413394317203553625829 9323102747899933426890262757 9325091641128050246166715829 9325201015147968294835238387");

__END__
σ−¹(6187272) = [2855646 2651676]
σ−¹(196602) = [105650 81920]
σ−¹(8105688) = [4953454 4947723]
σ−¹(2031554) = [845200 999424]
σ−¹(8880128) = [6389751 7527079]
σ−¹(5488) = [3783 2716]
σ−¹(11532) = [4880 4400]
σ−¹(1355816) = [457500 390000 811875 624700]
