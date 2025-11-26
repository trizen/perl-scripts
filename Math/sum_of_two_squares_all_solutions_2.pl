#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 22 November 2025
# https://github.com/trizen

# A fast algorithm for finding all the non-negative integer solutions to the equation:
#   a^2 + b^2 = n
# for any given positive integer `n` for which such a solution exists.

# Example:
#   99025 = 41^2 + 312^2 = 48^2 + 311^2 = 95^2 + 300^2 = 104^2 + 297^2 = 183^2 + 256^2 = 220^2 + 225^2

# This algorithm is efficient when the factorization of `n` can be computed.

# Blog post:
#   https://trizenx.blogspot.com/2017/10/representing-integers-as-sum-of-two.html

# See also:
#   https://oeis.org/A001481

use 5.036;
use Math::GMPz qw();
use ntheory    qw(factor_exp sqrtmod powint);

# Find a solution to x^2 + y^2 = p, for prime numbers `p` congruent to 1 mod 4.
sub primitive_sum_of_two_squares ($p) {

    if ($p == 2) {
        return (1, 1);
    }

    my $s = Math::GMPz->new(sqrtmod(-1, $p) || return);
    my $q = $p;

    while ($s * $s > $p) {
        ($s, $q) = ($q % $s, $s);
    }

    return ($s, $q % $s);
}

# Multiply two representations (a,b) and (c,d),
# return all distinct sign/ordering variations.
sub combine_pairs($A, $B, $C, $D) {
#<<<
    return (
        [$A * $C - $B * $D, $A * $D + $B * $C],
        [$A * $C + $B * $D, $A * $D - $B * $C],
    );
#>>>
}

# Multiply two *sets* of representations
sub multiply_sets($A, $B) {
    my %seen;
    my @new;
    for my $p (@$A) {
        for my $q (@$B) {
            for my $r (combine_pairs(@$p, @$q)) {
                my ($x, $y) = @$r;

                $x = -$x if ($x < 0);
                $y = -$y if ($y < 0);

                if ($x > $y) {
                    ($x, $y) = ($y, $x);
                }

                my $key = "$x,$y";
                next if $seen{$key}++;
                push @new, [$x, $y];
            }
        }
    }
    return @new;
}

sub sum_of_two_squares_solutions($n) {

    $n < 0  and return;
    $n == 0 and return [0, 0];

    my @factors = factor_exp($n);

    # Start with representation of 1
    my @reps = ([0, 1]);    # (0^2 + 1^2 = 1)

    # Handle primes p ≡ 3 (mod 4) with even exponent: they contribute as a perfect square factor s^2.
    # Multiply each (x,y) by s where s = product p^{e/2} over such primes.
    my $square_scale = Math::GMPz->new(1);

    foreach my $pp (@factors) {
        my ($p, $k) = @$pp;

        # Handle primes 3 mod 4
        if ($p % 4 == 3) {
            if ($k % 2 != 0) {
                return;    # no solutions
            }

            # p^{2t} contributes factor (p^t)^2 which is a square; doesn't change reps aside from scaling
            # We multiply by p^{k/2} as a scaling factor on both coordinates.
            $square_scale *= powint($p, ($k >> 1));
            next;
        }

        # Representation of p = x^2 + y^2
        my ($x, $y) = primitive_sum_of_two_squares($p);

        # Use binary exponentiation to get representations for p^k
        my @acc   = ([0, 1]);
        my @base  = ([$x, $y]);
        my $exp_k = $k;

        while ($exp_k > 0) {
            if ($exp_k & 1) {
                @acc = multiply_sets(\@acc, \@base);
            }
            @base = multiply_sets(\@base, \@base);
            $exp_k >>= 1;
        }
        @reps = multiply_sets(\@reps, \@acc);
    }

    if ($square_scale != 1) {
        @reps = map { [$_->[0] * $square_scale, $_->[1] * $square_scale] } @reps;
    }

    # Sort final reps
    @reps = sort { $a->[0] <=> $b->[0] } map {
        [sort { $a <=> $b } @$_]
    } @reps;

    return @reps;
}

# Run some tests

use Test::More tests => 8;

is_deeply([sum_of_two_squares_solutions(2025)],   [[0, 45],  [27,  36]],);
is_deeply([sum_of_two_squares_solutions(164025)], [[0, 405], [243, 324]]);
is_deeply([sum_of_two_squares_solutions(99025)],  [[41, 312], [48, 311], [95, 300], [104, 297], [183, 256], [220, 225]]);

is_deeply(
          [grep { my @arr = sum_of_two_squares_solutions($_); @arr > 0 } -10 .. 160],
          [0,   1,   2,   4,   5,   8,   9,   10,  13,  16,  17,  18,  20,  25,  26,  29,  32,  34,  36,  37,  40,  41,
           45,  49,  50,  52,  53,  58,  61,  64,  65,  68,  72,  73,  74,  80,  81,  82,  85,  89,  90,  97,  98,  100,
           101, 104, 106, 109, 113, 116, 117, 121, 122, 125, 128, 130, 136, 137, 144, 145, 146, 148, 149, 153, 157, 160
          ]
         );

is_deeply(
          [sum_of_two_squares_solutions(1777574759925022720)],
          [[110080512, 1328705024],
           [146744832, 1325156864],
           [151045632, 1324673536],
           [243249664, 1310879232],
           [347689472, 1287123456],
           [402252288, 1271128576],
           [463025664, 1250272768],
           [490100224, 1239909888],
           [494122496, 1238312448],
           [591927808, 1194653184],
           [673967616, 1150366208],
           [697867776, 1136026112],
           [722402816, 1120584192],
           [775551488, 1084478976],
           [885287424, 996915712],
           [912489984, 972078592]
          ]
         );

do {
    use bigint try => 'GMP';
    is_deeply(
              [sum_of_two_squares_solutions(Math::GMPz->new("11392163240756069707031250"))],
              [[39309472125,   3374998963875],
               [216763660575,  3368260197225],
               [477329304375,  3341305130625],
               [729359177085,  3295481517405],
               [735019741071,  3294223614297],
               [907262616645,  3251005657515],
               [982736803125,  3228992353125],
               [1151205969375, 3172835964375],
               [1224793301193, 3145162095999],
               [1393801568775, 3074000720175],
               [1622919634875, 2959441687125],
               [1847545189875, 2824666354125],
               [1993551800625, 2723584854375],
               [2056446956025, 2676413487825],
               [2194367046795, 2564549961435],
               [2198769707673, 2560776252111],
               [2386646521875, 2386646521875]
              ]
             );

    is_deeply([sum_of_two_squares_solutions(2**128 + 1)], [[1, 18446744073709551616], [8479443857936402504, 16382350221535464479]]);

    is_deeply(
              [sum_of_two_squares_solutions(13**18 * 5**7)],
              [[75291211970,   2963091274585],
               [100083884615,  2962357487570],
               [124869548830,  2961416259815],
               [149646468985,  2960267657230],
               [154416779750,  2960022656375],
               [179181003625,  2958626849750],
               [203932680250,  2957023863625],
               [228670076375,  2955213810250],
               [253391459750,  2953196816375],
               [258150241063,  2952784638466],
               [282850264814,  2950521038023],
               [307530481817,  2948050825694],
               [332189163826,  2945374174457],
               [356824584103,  2942491271746],
               [481345955350,  2924702504425],
               [505803171575,  2920572173350],
               [530224968650,  2916237327575],
               [554609636425,  2911698270650],
               [578955467350,  2906955320425],
               [583639307225,  2906018552450],
               [607936593550,  2901032879225],
               [632191308775,  2895844059550],
               [656401754450,  2890452456775],
               [680566235225,  2884858448450],
               [802350873038,  2853386013959],
               [826200069721,  2846571993278],
               [849991411282,  2839558639801],
               [873723231719,  2832346444642],
               [897393869198,  2824935912839],
               [901945120375,  2823486084250],
               [925540625750,  2815839700375],
               [949071319625,  2807996135750],
               [972535554250,  2799955939625],
               [977046452345,  2798385051790],
               [1000429281410, 2790111094745],
               [1023742054855, 2781641758610],
               [1046983140190, 2772977636455],
               [1070150909945, 2764119334990],
               [1186462080890, 2716226499895],
               [1209150070505, 2706203018090],
               [1231753388710, 2695990032905],
               [1254270452695, 2685588259510],
               [1276699685690, 2674998426295],
               [1281008818375, 2672937536750],
               [1303331253250, 2662124398375],
               [1325562421625, 2651124843250],
               [1347700766750, 2639939641625],
               [1369744738375, 2628569576750],
               [1373978929622, 2626358804329],
               [1395908335991, 2614769317862],
               [1417739993098, 2602996730711],
               [1439472372169, 2591041867258],
               [1461103951382, 2578905564649],
               [1569204922025, 2514592328950],
               [1590192225050, 2501373094025],
               [1611068173975, 2487978699050],
               [1631831306950, 2474410081975],
               [1652480170025, 2460668192950],
               [1656443419150, 2458002007175],
               [1676954116825, 2444054737150],
               [1697347384850, 2429936320825],
               [1717621795175, 2415647746850],
               [1838087734327, 2325298292486],
               [1857481600234, 2309835659287],
               [1876745394953, 2294211278554],
               [1895877769526, 2278426244393],
               [1899547017625, 2275368057250],
               [1918520912750, 2259392877625],
               [1937360462375, 2243259482750],
               [1956064347250, 2226969002375],
               [1974631257625, 2210522577250],
               [1978190975930, 2207337566135],
               [1996592834665, 2190706671530],
               [2014854880870, 2173922371465],
               [2032975835735, 2156985841270],
               [2050954430330, 2139898266935]
              ]
             );
};

my @nums = (@ARGV ? (map { Math::GMPz->new($_) } @ARGV) : (map { int rand(~0) } 1 .. 20));

foreach my $n (@nums) {
    (my @solutions = sum_of_two_squares_solutions($n)) || next;

    say "$n = " . join(' = ', map { "$_->[0]^2 + $_->[1]^2" } @solutions);

    # Verify solutions
    foreach my $solution (@solutions) {
        if ($n != $solution->[0]**2 + $solution->[1]**2) {
            die "error for $n: (@$solution)\n";
        }
    }
}
