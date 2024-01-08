#!/usr/bin/perl

# The elliptic-curve factorization method (ECM), due to Hendrik Lenstra, with B2 stage. (GMPz implementation)

# Code translated from the SymPy file "ntheory/ecm.py".

package Point {

    use 5.020;
    use warnings;
    use Math::GMPz   qw();
    use experimental qw(signatures);

    sub new {
        my ($class, $x_cord, $z_cord, $a_24, $mod) = @_;
        bless {
               x_cord => $x_cord,
               z_cord => $z_cord,
               a_24   => $a_24,
               mod    => $mod,
              }, $class;
    }

    state $t1 = Math::GMPz::Rmpz_init();
    state $t2 = Math::GMPz::Rmpz_init();
    state $u  = Math::GMPz::Rmpz_init();
    state $v  = Math::GMPz::Rmpz_init();

    sub add ($self, $Q, $diff, $new_x_cord = undef, $new_z_cord = undef) {

        Math::GMPz::Rmpz_sub($u, $self->{x_cord}, $self->{z_cord});
        Math::GMPz::Rmpz_add($t2, $Q->{x_cord}, $Q->{z_cord});
        Math::GMPz::Rmpz_mul($u, $u, $t2);
        Math::GMPz::Rmpz_mod($u, $u, $self->{mod});

        Math::GMPz::Rmpz_add($v, $self->{x_cord}, $self->{z_cord});
        Math::GMPz::Rmpz_sub($t2, $Q->{x_cord}, $Q->{z_cord});
        Math::GMPz::Rmpz_mul($v, $v, $t2);
        Math::GMPz::Rmpz_mod($v, $v, $self->{mod});

        Math::GMPz::Rmpz_add($t1, $u, $v);
        Math::GMPz::Rmpz_sub($t2, $u, $v);

        $new_x_cord //= Math::GMPz::Rmpz_init();
        $new_z_cord //= Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mul($new_x_cord, $t1,         $t1);
        Math::GMPz::Rmpz_mul($new_x_cord, $new_x_cord, $diff->{z_cord});
        Math::GMPz::Rmpz_mod($new_x_cord, $new_x_cord, $self->{mod});

        Math::GMPz::Rmpz_mul($new_z_cord, $t2,         $t2);
        Math::GMPz::Rmpz_mul($new_z_cord, $new_z_cord, $diff->{x_cord});
        Math::GMPz::Rmpz_mod($new_z_cord, $new_z_cord, $self->{mod});

        return Point->new($new_x_cord, $new_z_cord, $self->{a_24}, $self->{mod});
    }

    sub double ($self, $new_x_cord = undef, $new_z_cord = undef) {

        Math::GMPz::Rmpz_add($u, $self->{x_cord}, $self->{z_cord});
        Math::GMPz::Rmpz_powm_ui($u, $u, 2, $self->{mod});

        Math::GMPz::Rmpz_sub($v, $self->{x_cord}, $self->{z_cord});
        Math::GMPz::Rmpz_powm_ui($v, $v, 2, $self->{mod});

        Math::GMPz::Rmpz_sub($t1, $u, $v);

        $new_x_cord //= Math::GMPz::Rmpz_init();
        $new_z_cord //= Math::GMPz::Rmpz_init();

        Math::GMPz::Rmpz_mul($new_x_cord, $u, $v);
        Math::GMPz::Rmpz_mod($new_x_cord, $new_x_cord, $self->{mod});

        Math::GMPz::Rmpz_mul($t2, $self->{a_24}, $t1);
        Math::GMPz::Rmpz_add($t2, $t2, $v);
        Math::GMPz::Rmpz_mod($t2, $t2, $self->{mod});
        Math::GMPz::Rmpz_mul($new_z_cord, $t1, $t2);
        Math::GMPz::Rmpz_mod($new_z_cord, $new_z_cord, $self->{mod});

        return Point->new($new_x_cord, $new_z_cord, $self->{a_24}, $self->{mod});
    }

    sub mont_ladder ($self, $k) {

        my $Q = $self;
        my $R = $self->double();

        if (ref($k) ne 'Math::GMPz') {
            $k = Math::GMPz::Rmpz_init_set_str("$k", 10);
        }

        my $new_x_cord_1 = Math::GMPz::Rmpz_init();
        my $new_x_cord_2 = Math::GMPz::Rmpz_init();
        my $new_z_cord_1 = Math::GMPz::Rmpz_init();
        my $new_z_cord_2 = Math::GMPz::Rmpz_init();

        foreach my $i (split(//, substr(Math::GMPz::Rmpz_get_str($k, 2), 1))) {
            if ($i eq '1') {
                $Q = $R->add($Q, $self, $new_x_cord_1, $new_z_cord_1);
                $R = $R->double($new_x_cord_2, $new_z_cord_2);
            }
            else {
                $R = $Q->add($R, $self, $new_x_cord_2, $new_z_cord_2);
                $Q = $Q->double($new_x_cord_1, $new_z_cord_1);
            }
        }

        return $Q;
    }
}

use 5.020;
use warnings;
use experimental qw(signatures);

use Math::GMPz             qw();
use List::Util             qw(uniq min);
use Math::Prime::Util::GMP qw(:all);

sub ecm_one_factor ($n, $B1 = 10_000, $B2 = 100_000, $max_curves = 200, $seed = undef) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz::Rmpz_init_set_str("$n", 10);
    }

    if (($B1 % 2 == 1) or ($B2 % 2 == 1)) {
        die "The Bounds should be even integers";
    }

    is_prime($n) && return $n;

    my $D = min(sqrtint($B2), ($B1 >> 1) - 1);
    my $k = Math::GMPz::Rmpz_init_set_str(consecutive_integer_lcm($B1), 10);

    my @S;
    my @beta = map { Math::GMPz::Rmpz_init() } 1 .. $D;
    my @xz   = map { [Math::GMPz::Rmpz_init(), Math::GMPz::Rmpz_init()] } 1 .. $D;

    my @deltas_list;

    my $r_min  = $B1 + 2 * $D;
    my $r_max  = $B2 + 2 * $D;
    my $r_step = 4 * $D;

    for (my $r = $r_min ; $r <= $r_max ; $r += $r_step) {
        my @deltas;
        foreach my $q (sieve_primes($r - 2 * $D, $r + 2 * $D)) {
            push @deltas, ((abs($q - $r) - 1) >> 1);
        }
        push @deltas_list, [uniq(@deltas)];
    }

    state $u     = Math::GMPz::Rmpz_init();
    state $v     = Math::GMPz::Rmpz_init();
    state $u_3   = Math::GMPz::Rmpz_init();
    state $sigma = Math::GMPz::Rmpz_init();
    state $t     = Math::GMPz::Rmpz_init();
    state $t1    = Math::GMPz::Rmpz_init();
    state $t2    = Math::GMPz::Rmpz_init();
    state $inv   = Math::GMPz::Rmpz_init();
    state $a24   = Math::GMPz::Rmpz_init();
    state $v_3   = Math::GMPz::Rmpz_init();
    state $alpha = Math::GMPz::Rmpz_init();
    state $g     = Math::GMPz::Rmpz_init();

    my $state = Math::GMPz::zgmp_randinit_default();

    if (defined($seed)) {
        Math::GMPz::zgmp_randseed_ui($state, $seed);
    }

    for (1 .. $max_curves) {

        # Suyama's parametrization
        Math::GMPz::Rmpz_sub_ui($sigma, $n, 7);
        Math::GMPz::Rmpz_urandomm($sigma, $state, $sigma, 1);
        Math::GMPz::Rmpz_add_ui($sigma, $sigma, 6);

        Math::GMPz::Rmpz_mul($u, $sigma, $sigma);
        Math::GMPz::Rmpz_sub_ui($u, $u, 5);
        Math::GMPz::Rmpz_mod($u, $u, $n);

        Math::GMPz::Rmpz_mul_2exp($v, $sigma, 2);
        Math::GMPz::Rmpz_mod($v, $v, $n);

        Math::GMPz::Rmpz_powm_ui($u_3, $u, 3, $n);

        Math::GMPz::Rmpz_mul($t, $u_3, $v);
        Math::GMPz::Rmpz_mul_2exp($t, $t, 4);
        Math::GMPz::Rmpz_mod($t, $t, $n);

        Math::GMPz::Rmpz_invert($inv, $t, $n) || return do {
            Math::GMPz::Rmpz_lcm($g, $u_3, $v);
            Math::GMPz::Rmpz_gcd($g, $g, $n);
            return Math::GMPz::Rmpz_init_set($g);
        };

        Math::GMPz::Rmpz_sub($a24, $v, $u);
        Math::GMPz::Rmpz_powm_ui($a24, $a24, 3, $n);

        Math::GMPz::Rmpz_mul_ui($t, $u, 3);
        Math::GMPz::Rmpz_add($t, $t, $v);
        Math::GMPz::Rmpz_mul($a24, $a24, $t);
        Math::GMPz::Rmpz_mod($a24, $a24, $n);
        Math::GMPz::Rmpz_mul($a24, $a24, $inv);
        Math::GMPz::Rmpz_mod($a24, $a24, $n);

        Math::GMPz::Rmpz_powm_ui($v_3, $v, 3, $n);

        my $Q = Point->new($u_3, $v_3, $a24, $n);
        $Q = $Q->mont_ladder($k);
        Math::GMPz::Rmpz_gcd($g, $Q->{z_cord}, $n);

        # Stage 1 factor
        if ($g > 1 and $g < $n) {
            return Math::GMPz::Rmpz_init_set($g);
        }

        # Stage 1 failure. Q.z = 0, Try another curve
        elsif ($g == $n) {
            next;
        }

        # Stage 2 - Improved Standard Continuation
        $S[0] = $Q;
        my $Q2 = $Q->double($xz[0][0], $xz[0][1]);
        $S[1] = $Q2->add($Q, $Q, $xz[1][0], $xz[1][1]);

        foreach my $d (0 .. 1) {
            Math::GMPz::Rmpz_mul($beta[$d], $S[$d]->{x_cord}, $S[$d]->{z_cord});
            Math::GMPz::Rmpz_mod($beta[$d], $beta[$d], $n);
        }

        foreach my $d (2 .. $D - 1) {
            $S[$d] = $S[$d - 1]->add($Q2, $S[$d - 2], $xz[$d][0], $xz[$d][1]);
            Math::GMPz::Rmpz_mul($beta[$d], $S[$d]->{x_cord}, $S[$d]->{z_cord});
            Math::GMPz::Rmpz_mod($beta[$d], $beta[$d], $n);
        }

        Math::GMPz::Rmpz_set_ui($t, 1);

        my $W = $Q->mont_ladder(4 * $D);
        my $T = $Q->mont_ladder($B1 - 2 * $D);
        my $R = $Q->mont_ladder($B1 + 2 * $D);

        foreach my $deltas (@deltas_list) {

            Math::GMPz::Rmpz_mul($alpha, $R->{x_cord}, $R->{z_cord});
            Math::GMPz::Rmpz_mod($alpha, $alpha, $n);

            foreach my $delta (@$deltas) {
                Math::GMPz::Rmpz_sub($t1, $R->{x_cord}, $S[$delta]->{x_cord});
                Math::GMPz::Rmpz_add($t2, $R->{z_cord}, $S[$delta]->{z_cord});
                Math::GMPz::Rmpz_mul($t1, $t1, $t2);
                Math::GMPz::Rmpz_mod($t1, $t1, $n);
                Math::GMPz::Rmpz_sub($t1, $t1, $alpha);
                Math::GMPz::Rmpz_add($t1, $t1, $beta[$delta]);
                Math::GMPz::Rmpz_mul($t, $t, $t1);
                Math::GMPz::Rmpz_mod($t, $t, $n);
            }

            # Swap
            ($T, $R) = ($R, $R->add($W, $T));
        }

        Math::GMPz::Rmpz_gcd($g, $t, $n);

        # Stage 2 Factor found
        if ($g > 1 and $g < $n) {
            return Math::GMPz::Rmpz_init_set($g);
        }
    }

    # ECM failed, Increase the bounds
    die "Increase the bounds";
}

# Params from:
#   https://www.rieselprime.de/ziki/Elliptic_curve_method

my @ECM_PARAMS = (

    # d      B1     curves
    [10, 360,        7],
    [15, 2000,       25],
    [20, 11000,      90],
    [25, 50000,      300],
    [30, 250000,     700],
    [35, 1000000,    1800],
    [40, 3000000,    5100],
    [45, 11000000,   10600],
    [50, 43000000,   19300],
    [55, 110000000,  49000],
    [60, 260000000,  124000],
    [65, 850000000,  210000],
    [70, 2900000000, 340000],
                 );

sub ecm ($n, $B1 = undef, $B2 = undef, $max_curves = undef, $seed = undef) {

    if (ref($n) ne 'Math::GMPz') {
        $n = Math::GMPz::Rmpz_init_set_str("$n", 10);
    }

    $n <= 1 and die "n must be greater than 1";

    if (!defined($B1)) {
        foreach my $row (@ECM_PARAMS) {
            my ($d, $B1, $curves) = @$row;
            ## say ":: Trying to find a prime factor with $d digits using B1 = $B1 with $curves curves";
            my @f = eval { __SUB__->($n, $B1, $B1 * 20, $curves, $seed) };
            return @f if !$@;
        }
    }

    state $primorial = primorial(100_000);

    my @factors;
    my $g = gcd($n, $primorial);

    if ($g > 1) {
        $n = Math::GMPz::Rmpz_init_set($n);    # copy
        push @factors, factor($g);
        my $t = Math::GMPz::Rmpz_init();
        foreach my $p (@factors) {
            Math::GMPz::Rmpz_set_ui($t, $p);
            Math::GMPz::Rmpz_remove($n, $n, $t);
        }
    }

    while ($n > 1) {
        my $factor = eval { ecm_one_factor($n, $B1, $B2, $max_curves, $seed) };

        if ($@) {
            die "Failed to factor $n: $@";
        }

        push @factors, $factor;
        $n = Math::GMPz::Rmpz_init_set($n);
        Math::GMPz::Rmpz_remove($n, $n, $factor);
    }

    @factors = uniq(@factors);

    my @final_factors;
    foreach my $factor (@factors) {
        if (is_prime($factor)) {
            push @final_factors, $factor;
        }
        else {
            push @final_factors, __SUB__->($factor, $B1, $B2, $max_curves);
        }
    }

    return sort { $a <=> $b } @final_factors;
}

# Support for numbers provided as command-line arguments
if (@ARGV) {
    foreach my $n (@ARGV) {
        say "rad($n) = ", join ' * ', ecm($n);
    }
    exit;
}

say join ' * ', ecm('314159265358979323');                #=> 317213509 * 990371647
say join ' * ', ecm('14304849576137459');                 #=> 16100431 * 888476189
say join ' * ', ecm('9804659461513846513');               #=> 4641991 * 2112166839943
say join ' * ', ecm('25645121643901801');                 #=> 5394769 * 4753701529
say join ' * ', ecm('17177619065692036843');              #=> 2957613037 * 5807933239
say join ' * ', ecm('195905123644566489241411490581');    #=> 259719190596553 * 754295911652077

say join ' * ', ecm(Math::GMPz->new(2)**64 + 1);          #=> 274177 * 67280421310721
say join ' * ', ecm(Math::GMPz->new(2)**128 - 1);         #=> 3 * 5 * 17 * 257 * 641 * 65537 * 274177 * 6700417 * 67280421310721
say join ' * ', ecm(Math::GMPz->new(2)**128 + 1);         #=> 59649589127497217 * 5704689200685129054721

# Run some tests when no argument is provided
foreach my $n (map { Math::GMPz->new(urandomb($_)) + 2 } 2 .. 100) {
    say "rad($n) = ", join(' * ', map { is_prime($_) ? $_ : "$_ (composite)" } ecm($n));
}
