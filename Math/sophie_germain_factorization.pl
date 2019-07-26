#!?usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 26 July 2019
# https://github.com/trizen

# A simple factorization method, based on Sophie Germain's identity:
#   x^4 + 4y^4 = (x^2 + 2xy + 2y^2) * (x^2 - 2xy + 2y^2)

# This method is also effective for numbers of the form: n^4 + 4^(2k+1).

# See also:
#   https://oeis.org/A227855 -- Numbers of the form x^4 + 4*y^4.
#   https://www.quora.com/What-is-Sophie-Germains-Identity

use 5.020;
use strict;
use warnings;

use Math::GMPz;
use ntheory qw(:all);
use experimental qw(signatures);

sub sophie_germain_factorization ($n, $verbose = 0) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz->new("$n");
    }

    my $f = sub ($A, $B) {
        my @factors;

        foreach my $f ($A**2 + 2 * $B**2 - 2 * $A * $B, $A**2 + 2 * $B**2 + 2 * $A * $B,) {
            my $g = Math::GMPz->new(gcd($f, $n));

            if ($g > 1 and $g < $n) {
                while ($n % $g == 0) {
                    $n /= $g;
                    push @factors, $g;
                }
            }
        }

        @factors;
    };

    my $orig = $n;
    my @sophie_params;

    # Try to find n = x^4 + 4*y^4, for x or y small.
    foreach my $r1 (map { Math::GMPz->new($_) } 2 .. logint($n, 2)) {

        {
            my $x  = 4 * $r1**4;
            my $dx = $n - $x;

            if ($dx >= 1 and is_power($dx, 4, \my $r2)) {
                $r2 = Math::GMPz->new($r2);
                say "[*] Sophie Germain special form detected: $r2^4 + 4*$r1^4" if $verbose;
                push @sophie_params, [$r2, $r1];
            }

        }

        {
            my $y  = $r1**4;
            my $dy = $n - $y;

            if ($dy >= 4 and ($dy % 4 == 0) and is_power($dy / 4, 4, \my $r2)) {
                $r2 = Math::GMPz->new($r2);
                say "[*] Sophie Germain special form detected: $r1^4 + 4*$r2^4" if $verbose;
                push @sophie_params, [$r1, $r2];
            }
        }
    }

    {    # Try to find n = x^4 + 4*y^4 for x,y close to floor(n/5)^(1/4).
        my $k = Math::GMPz->new(rootint($n / 5, 4));

        for my $j (0 .. 1000) {

            my $r1 = $k + $j;

            {
                my $x  = 4 * $r1**4;
                my $dx = $n - $x;

                if ($dx >= 1 and is_power($dx, 4, \my $r2)) {
                    $r2 = Math::GMPz->new($r2);
                    say "[*] Sophie Germain special form detected: $r2^4 + 4*$r1^4" if $verbose;
                    push @sophie_params, [$r2, $r1];
                }
            }

            {
                my $y  = $r1**4;
                my $dy = $n - $y;

                if ($dy >= 4 and ($dy % 4 == 0) and is_power($dy / 4, 4, \my $r2)) {
                    $r2 = Math::GMPz->new($r2);
                    say "[*] Sophie Germain special form detected: $r1^4 + 4*$r2^4" if $verbose;
                    push @sophie_params, [$r1, $r2];
                }
            }
        }
    }

    my @factors;

    foreach my $args (@sophie_params) {
        push @factors, $f->(@$args);
    }

    push @factors, $orig / vecprod(@factors);
    return sort { $a <=> $b } @factors;
}

if (@ARGV) {
    say join ', ', sophie_germain_factorization($ARGV[0], 1);
    exit;
}

say join ' * ', sophie_germain_factorization(powint(43,        4) + 4 * powint(372485613, 4));
say join ' * ', sophie_germain_factorization(powint(372485613, 4) + 4 * powint(97,        4));
say join ' * ', sophie_germain_factorization(powint(372485613, 4) + 4 * powint(372485629, 4));
say join ' * ', sophie_germain_factorization(powint(372485629, 4) + 4 * powint(372485511, 4));

say '';

say join ' * ', sophie_germain_factorization(powint(4, 117) + powint(53,  4));
say join ' * ', sophie_germain_factorization(powint(4, 213) + powint(240, 4));
say join ' * ', sophie_germain_factorization(powint(4, 251) + powint(251, 4));

__END__
277491031750210669 * 277491095817736105
138745459629795665 * 138745604154213509
138745543811525897 * 693727695218548205
138745455904945045 * 693727455337830721

166153499473114453560556010453601017 * 166153499473114514665395754616490745
13164036458569648337239753460419861813422875717854660184319779072 * 13164036458569648337239753460497746266300898132282617629258080512
3618502788666131106986593281521497099061968496512379043906292883903830095385 * 3618502788666131106986593281521497141767405545090156208559806116590740633113
