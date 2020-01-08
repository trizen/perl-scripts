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

sub pocklington_pratt_primality_proving ($n, $lim = 2**64) {

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
  pocklington_pratt_primality_proving(115792089237316195423570985008687907853269984665640564039457584007913129603823);

__END__
:: Proving primality of: 1202684276868524221513588244947
a = 346396580104425418965575454682 ; p = 2
a = 395385292850838170128328828116 ; p = 3
a = 560648981353249253078437405876 ; p = 192697
a = 494703015287234994679974119746 ; p = 5829139
a = 306457770974323789423503072510 ; p = 59483944987587859

:: Proving primality of: 3201964079152361724098258636758155557
a = 1356115518279653627564352210970159943 ; p = 2
a = 2457916028227754146876991447098503864 ; p = 13
a = 11728301593361244989156925656983410 ; p = 51199
a = 2108054294077847671434547666614921115 ; p = 1202684276868524221513588244947

:: Proving primality of: 2848630210554880446022254608450222949126931851754251657020267
a = 1209988187472090611751147313669268320351528758910368461329491 ; p = 2
a = 2300573356420091000839516595493416230415669494600279441813823 ; p = 7
a = 2255070062675661569997567047423251088740948129004746039001652 ; p = 71
a = 1700776819424249129400987278064417150296142232503378309546959 ; p = 397
a = 1557663127914051170819266186415060024746272157947950396848254 ; p = 22483
a = 1529304355972906129963007304614010762285079880618804024992958 ; p = 100274029791527
a = 1359380483007119191612142919174796446436066905484471515166032 ; p = 3201964079152361724098258636758155557

:: Proving primality of: 57896044618658097711785492504343953926634992332820282019728792003956564801911
a = 57400691074692315475639863020768426880305244856451980889960538168345429022524 ; p = 2
a = 25820275722126461008372188295587408543429765560766435733697174460356575227321 ; p = 5
a = 27298126184613458024322898773516636407461062104891054863568660611145831927443 ; p = 19
a = 7100354002561105328600593201175960102344714262592146066784856909856617007329 ; p = 106969315701167
a = 18941027101040193108179225001169566407134428948824247293492332749705988365235 ; p = 2848630210554880446022254608450222949126931851754251657020267

:: Proving primality of: 115792089237316195423570985008687907853269984665640564039457584007913129603823
a = 113522921208063424748606312287587727138037143611024280238876731030118912160215 ; p = 2
a = 2309014289093855479517407977261240733911340029895025970257499692025785552300 ; p = 57896044618658097711785492504343953926634992332820282019728792003956564801911
Is prime: 1
