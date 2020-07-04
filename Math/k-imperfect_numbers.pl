#!/usr/bin/perl

# Generate all the k-imperfect numbers less than or equal to n.
# Based on Michel Marcus's algorithm from A328860.

# k-imperfect numbers, are numbers n such that:
#   n = k * Sum_{d|n} d * (-1)^Ω(n/d)

# See also:
#   https://oeis.org/A206369 -- rho function.
#   https://oeis.org/A127724 -- k-imperfect numbers for some k >= 1.
#   https://oeis.org/A127725 -- Numbers that are 2-imperfect.
#   https://oeis.org/A127726 -- Numbers that are 3-imperfect.
#   https://oeis.org/A328860 -- Numbers that are 4-imperfect.

use 5.020;
use warnings;

use ntheory qw(:all);
use List::Util qw(uniq);
use experimental qw(signatures);

sub rho_prime_power ($p, $e) {
    my $x = addint(powint($p, $e + 1), $p >> 1);
    my $y = $p + 1;
    divint($x, $y);
}

sub rho_factors(@F) {
    vecprod(map { rho_prime_power($_->[0], $_->[1]) } @F);
}

sub k_imperfect_numbers ($limit, $A, $B = 1) {

    my @sol;
    my $g = gcd($A, $B);

    $A = divint($A, $g);
    $B = divint($B, $g);

    if ($A == 1) {
        return (1) if ($B == 1);
        return ();
    }

    my @f   = factor_exp($A);
    my $rho = rho_factors(@f);
    my ($p, $n) = @{$f[-1]};

    my $r = rho_prime_power($p, $n);

    for (my $pn = powint($p, $n) ; $pn <= $limit ; $pn = mulint($pn, $p)) {
        foreach my $k (__SUB__->(divint($limit, $pn), mulint($A, $r), mulint($B, $pn))) {
            push @sol, mulint($pn, $k) if (gcd($pn, $k) == 1);
        }
        $r = rho_prime_power($p, ++$n);
    }

    if ($rho == $B) {
        push @sol, $A;
    }

    @sol = grep { $_ <= $limit } @sol;
    @sol = sort { $a <=> $b } @sol;
    uniq(@sol);
}

say join ', ', k_imperfect_numbers(10**15, 2);    # 2-imperfect numbers
say join ', ', k_imperfect_numbers(10**15, 3);    # 3-imperfect numbers

__END__
2, 12, 40, 252, 880, 10880, 75852, 715816960, 62549517598720
6, 120, 126, 2520, 2640, 30240, 32640, 37800, 37926, 55440, 685440, 758520, 831600, 2600640, 5533920, 6917400, 9102240, 10281600, 11377800, 16687440, 152182800, 206317440, 250311600, 475917120, 866829600, 1665709920, 1881532800, 2082137400, 2147450880, 3094761600, 7660224000, 45096468480, 45807022800, 74547345600, 76324550400, 566341372800, 676447027200, 1265637895200, 1401820992000, 1422467373600, 1769199213600, 10463865984000, 13574037012480, 15634517184000, 19954883520000, 22973689670400, 108844858987200, 122332194129600, 123789805977600, 130728955864320, 152151132369600, 187648552796160, 203610555187200
