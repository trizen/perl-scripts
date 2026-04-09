#!/usr/bin/perl

# Lazily generate the positive divisors of a given integer `n`, in descending order.

use 5.036;
use Math::GMPz;
use ntheory 0.74 qw(:all);

prime_set_config(bigint => 'Math::GMPz');

# Binary search: returns first index i such that all arr[0..i-1] <= val
sub bsearch_le ($arr, $val) {
    my ($lo,  $hi)  = (0, scalar @$arr);
    while ($lo < $hi) {
        my $mid = ($lo + $hi) >> 1;
        $arr->[$mid] <= $val ? ($lo = $mid + 1) : ($hi = $mid);
    }
    return $lo;
}

# Max-heap helper: Sifts down to maintain max-heap property
sub sift_down ($heap, $pos) {
    my $n = @$heap;
    while (1) {
        my $max = $pos;
        my $c1  = 2 * $pos + 1;
        my $c2  = $c1 + 1;
        $max = $c1 if $c1 < $n && $heap->[$c1][0] > $heap->[$max][0];
        $max = $c2 if $c2 < $n && $heap->[$c2][0] > $heap->[$max][0];
        last if $max == $pos;
        @{$heap}[$pos, $max] = @{$heap}[$max, $pos];
        $pos = $max;
    }
}

sub heap_push ($heap, $v) {
    my $pos = @$heap;
    push @$heap, $v;
    while ($pos > 0) {
        my $parent = ($pos - 1) >> 1;
        last if $heap->[$parent][0] >= $heap->[$pos][0];
        @{$heap}[$parent, $pos] = @{$heap}[$pos, $parent];
        $pos = $parent;
    }
}

sub heap_pop ($heap) {
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
        push @chains, \@C if @C;
    }

    @chains = sort { @$b <=> @$a } @chains;

    # Distribute chains into two arrays
    my @A = (Math::GMPz->new(1));
    my @B = (Math::GMPz->new(1));

    for my $C (@chains) {
        my $ref = (@A < @B) ? \@A : \@B;
        @$ref = map {
            my $x = $_;
            map { $x * $_ } @$C
        } @$ref;
    }

    @A = sort { $a <=> $b } @A;
    @B = sort { $a <=> $b } @B;

    my $s = $n;    # maximum divisor
                   #my $s = sqrtint($n);

    # Seed the max-heap
    my @h;
    for my $i (0 .. $#A) {
        my $lim = $s / $A[$i];              # Largest B[j] such that A[i] * B[j] <= n
        my $j   = bsearch_le(\@B, $lim);
        next unless $j > 0;
        push @h, [$A[$i] * $B[$j - 1], $i, $j - 1];
    }

    # Heapify using O(n) bottom-up approach
    sift_down(\@h, $_) for reverse(0 .. ((@h >> 1) - 1));

    # Build all divisors as products of one divisor from @A and one from @B,
    # then merge the row-wise sequences in descending order with a max-heap.
    while (@h) {
        my ($k, $i, $j) = @{heap_pop(\@h)};

        $callback->($k);

        # Push the next divisor combination into the heap
        if ($j > 0) {
            heap_push(\@h, [$A[$i] * $B[$j - 1], $i, $j - 1]);
        }
    }

    return;
}

lazy_divisors(5040, sub($d) { say $d });
