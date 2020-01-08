#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 January 2020
# https://github.com/trizen

# Prove the primality of a number, using the Pocklington primality test recursively.

# See also:
#   https://en.wikipedia.org/wiki/Pocklington_primality_test
#   https://en.wikipedia.org/wiki/Primality_certificate
#   http://mathworld.wolfram.com/PrattCertificate.html

use 5.020;
use strict;
use warnings;
use experimental qw(signatures);

use List::Util qw(uniq);
use ntheory qw(is_prime is_prob_prime primes);
use Math::AnyNum qw(:overload isqrt prod is_coprime irand powmod primorial gcd);
use Math::Prime::Util::GMP qw(ecm_factor is_strong_pseudoprime);

my $primorial = primorial(10**6);

sub trial_factor ($n) {

    my @f;
    my $g = gcd($primorial, $n);

    if ($g > 1) {
        my @primes = ntheory::factor($g);
        foreach my $p (@primes) {
            while ($n % $p == 0) {
                push @f, $p;
                $n /= $p;
            }
        }
    }

    $n > 1 and push(@f, $n);
    return @f;
}

sub pocklington_pratt_primality_test ($n, $lim = 2**64) {

    if ($n <= $lim or $n <= 2) {
        return is_prime($n);    # fast deterministic test for small n
    }

    is_prob_prime($n) || return 0;

    if (ref($n) ne 'Math::AnyNum') {
        $n = Math::AnyNum->new("$n");
    }

    my $d = $n - 1;
    my @f = trial_factor($d);
    my $B = pop @f;

    if (__SUB__->($B, $lim)) {
        push @f, $B;
        $B = 1;
    }

    for (; ;) {
        my $A = prod(@f);

        if ($A > $B and is_coprime($A, $B)) {

            say "\n:: Proving primality of: $n";

            foreach my $p (uniq(@f)) {
                for (; ;) {
                    my $a = irand(2, $d);
                    is_strong_pseudoprime($n, $a) || return 0;
                    if (is_coprime(powmod($a, $d / $p, $n) - 1, $n)) {
                        say "a = $a ; p = $p";
                        last;
                    }
                }
            }

            return 1;
        }

        my @ecm_factors = map { Math::AnyNum->new($_) } ecm_factor($B);

        foreach my $p (@ecm_factors) {
            if (__SUB__->($p, $lim)) {
                while ($B % $p == 0) {
                    $B /= $p;
                    $A *= $p;
                    push @f, $p;
                }
            }
            if ($A > $B) {
                say ":: Stopping early with A = $A and B = $B" if ($B > 1);
                last;
            }
        }
    }
}

say "Is prime: ",
  pocklington_pratt_primality_test(115792089237316195423570985008687907853269984665640564039457584007913129603823);

__END__
ECM: 22483
ECM: 192697
ECM: 5829139 59483944987587859

:: Proving primality of: 1202684276868524221513588244947
a = 824659741493608067322001296391 ; p = 2
a = 1022498653912984875575760149307 ; p = 3
a = 1112121982665922579866638136705 ; p = 192697
a = 137814990526010612216861667924 ; p = 5829139
a = 687404560259305393436098989961 ; p = 59483944987587859
ECM: 51199 1202684276868524221513588244947

:: Proving primality of: 3201964079152361724098258636758155557
a = 1735202724155715231675932061909004519 ; p = 2
a = 1017306163754423031218134136967053698 ; p = 13
a = 1806295190887934822312389687562949765 ; p = 51199
a = 1940954729913215797425123604240218898 ; p = 1202684276868524221513588244947
ECM: 100274029791527 3201964079152361724098258636758155557

:: Proving primality of: 2848630210554880446022254608450222949126931851754251657020267
a = 876509090672599285589511461938611672183248393667689101021939 ; p = 2
a = 1741377658963169486319054527199584394147635606009531538905208 ; p = 7
a = 1407759779304682793530720121494750238872767474110459509784585 ; p = 71
a = 1292432511266622380791896470232492058013196666318195516716270 ; p = 397
a = 921425335514018469277938018479416084194112657968399168345826 ; p = 22483
a = 1005006049163802715705725459646726990765258119458352357634361 ; p = 100274029791527
a = 951012779900250941440463976376893440871595032505469432056039 ; p = 3201964079152361724098258636758155557
ECM: 106969315701167 2848630210554880446022254608450222949126931851754251657020267

:: Proving primality of: 57896044618658097711785492504343953926634992332820282019728792003956564801911
a = 9011027398170526921698385033355478246228034811012818414210433997348022041626 ; p = 2
a = 18186621172197914616941046557266597550086691782247168585267221112869491753758 ; p = 5
a = 6394424410600480010837184585149123530391477019087790997481193531898188458675 ; p = 19
a = 13773688246968141489730150084932560321869518880521726264730329460376985698054 ; p = 106969315701167
a = 10660711510136249254894061538242258262017795355680899368081230374186133287026 ; p = 2848630210554880446022254608450222949126931851754251657020267

:: Proving primality of: 115792089237316195423570985008687907853269984665640564039457584007913129603823
a = 4958636727926862755054625745935311762883597579020694115885512999360698577553 ; p = 2
a = 97729064523374442956591697551115275134430159015075032825212111129287707022210 ; p = 57896044618658097711785492504343953926634992332820282019728792003956564801911
Is prime: 1
