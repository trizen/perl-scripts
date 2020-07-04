#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 18 May 2019
# https://github.com/trizen

# A new integer factorization method, using the modular Lucas U sequence.

# It uses the smallest divisor `d` of `p - kronecker(P*P - 4*Q, n)`, such that `U_d(P,Q) = 0 (mod p)`.

# By selecting a small bound B, we compute `k = lcm(1..B)`, hoping that `k` is a
# multiple of `d`, then `gcd(U_k(P,Q) (mod n), n)` in a non-trivial factor of `n`.

# This method is similar in flavor to Pollard's p-1 and Williams's p+1 methods.

use 5.020;
use warnings;

use experimental qw(signatures);

use Math::AnyNum qw(:overload irand gcd prod);
use Math::Prime::Util::GMP qw(lucas_sequence logint consecutive_integer_lcm random_nbit_prime);

sub lucas_factorization ($n, $B = logint($n, 2)**2, $a = 1, $b = 10) {

    my $L = consecutive_integer_lcm($B);

    foreach my $P ($a .. $b) {    # P > 0, P < n

        my $Q = irand(-$n, $n - 1);    # Q < n
        my $D = ($P * $P - 4 * $Q);    # D != 0

        $D || next;

        my $F = eval { (lucas_sequence($n, $P, $Q, $L))[0] } // next;
        my $g = gcd($F, $n);

        if ($g > 1 and $g < $n) {
            return $g;
        }
    }

    return 1;
}

say lucas_factorization(257221 * 470783,               700);     #=> 470783           (p+1 is  700-smooth)
say lucas_factorization(333732865481 * 1632480277613,  3000);    #=> 333732865481     (p-1 is 3000-smooth)
say lucas_factorization(1124075136413 * 3556516507813, 4000);    #=> 1124075136413    (p+1 is 4000-smooth)
say lucas_factorization(6555457852399 * 7864885571993, 700);     #=> 6555457852399    (p-1 is  700-smooth)
say lucas_factorization(7553377229 * 588103349,        800);     #=> 7553377229       (p+1 is  800-smooth)

say "\n=> More factorizations:";

foreach my $k (10 .. 50) {

    my $n = prod(map { random_nbit_prime($k) } 1 .. 2);
    my $B = int(log($n) * exp(sqrt(log($n) * log(log($n))) / 2));
    my $p = lucas_factorization($n, $B);

    if ($p > 1) {
        printf("%s = %s * %s\n", $n, $p, $n / $p);
    }
}

__END__
544553 = 631 * 863
1676989 = 1301 * 1289
40928003 = 7159 * 5717
152309891 = 14557 * 10463
2300268811 = 64627 * 35593
11952132373 = 108079 * 110587
88750630231 = 289253 * 306827
405912740881 = 560089 * 724729
2327770162243 = 1690309 * 1377127
12499479778633 = 4032971 * 3099323
52190728874299 = 6665017 * 7830547
169450380817337 = 14835001 * 11422337
413120763604271 = 17965499 * 22995229
1991077071146719 = 36803257 * 54100567
7717232903949787 = 92283913 * 83624899
36847896737907319 = 181428361 * 203098879
638608157008243187 = 698497087 * 914260301
3416003128355302301 = 1773283703 * 1926371467
8189756908298548657 = 3749794309 * 2184054973
38364912094936082309 = 5629836997 * 6814568897
114226553742226158113 = 10915936417 * 10464201089
670007250188746144573 = 30739321757 * 21796422689
7304335218402627970339 = 84180973361 * 86769431699
157099299692502309409753 = 432342208787 * 363367944419
2303492941061419264300001 = 1191794882419 * 1932793113179
14246977176399484087089437 = 4078455141589 * 3493228853033
54462337363308569263306589 = 7154666227601 * 7612142290189
187314575021720258442926711 = 11541166852097 * 16230124511863
2109644814216084799800489451 = 49099874983879 * 42966398894269
10333250426104069265111817281 = 97051714715701 * 106471590495581
42849869010641243828199370319 = 173690504530247 * 246702426977977
