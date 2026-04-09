#!/usr/bin/perl

# Lazily generate the positive divisors of a given integer `n`, in ascending order.

use 5.036;
use Math::GMPz;
use ntheory 0.74 qw(:all);

prime_set_config(bigint => 'Math::GMPz');

sub sift_down($heap, $pos) {

    my $n = @$heap;
    while (1) {

        my $min = $pos;
        my $c1  = 2 * $pos + 1;
        my $c2  = $c1 + 1;

        $min = $c1 if $c1 < $n && $heap->[$c1][0] < $heap->[$min][0];
        $min = $c2 if $c2 < $n && $heap->[$c2][0] < $heap->[$min][0];

        last if $min == $pos;
        @{$heap}[$pos, $min] = @{$heap}[$min, $pos];
        $pos = $min;
    }
}

sub heap_push($heap, $v) {

    my $pos = @$heap;
    push @$heap, $v;

    while ($pos > 0) {
        my $parent = ($pos - 1) >> 1;
        last if $heap->[$parent][0] <= $heap->[$pos][0];
        @{$heap}[$parent, $pos] = @{$heap}[$pos, $parent];
        $pos = $parent;
    }
}

sub heap_pop($heap) {
    return pop @$heap if @$heap <= 1;
    my $top = $heap->[0];
    $heap->[0] = pop @$heap;
    sift_down($heap, 0);
    return $top;
}

sub lazy_divisors ($n, $callback) {

    # Build factor chains from the prime factorisation of f
    my @chains;
    for my $pe (factor_exp($n)) {
        my ($p, $v) = @$pe;
        my @C = map { powint($p, $_) } 0 .. $v;
        push @chains, \@C;
    }

    @chains = sort { @$b <=> @$a } @chains;

    # Distribute chains into two arrays
    my @A = (Math::GMPz->new(1));
    my @B = (Math::GMPz->new(1));

    for my $C (@chains) {
        my $ref = (@A < @B) ? \@A : \@B;
        my @new;
        for my $x (@$ref) {
            for my $c (@$C) {
                push @new, $x * $c;
            }
        }
        @$ref = @new;
    }

    @A = sort { $a <=> $b } @A;
    @B = sort { $a <=> $b } @B;

    my @h;

    # Seed each row with its smallest product
    for my $i (0 .. $#A) {
        push @h, [$A[$i] * $B[0], $i, 0];
    }

    sift_down(\@h, $_) for reverse(0 .. ((@h >> 1) - 1));

    my $end_B = $#B;

    while (@h) {
        my ($k, $i, $j) = @{heap_pop(\@h)};

        $callback->($k);

        # Advance to the next larger product in the same row
        if ($j < $end_B) {
            heap_push(\@h, [$A[$i] * $B[$j + 1], $i, $j + 1]);
        }
    }

    return;
}

lazy_divisors(5040, sub($d) { say $d });
