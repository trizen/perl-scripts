#!/usr/bin/perl

# Lazily generate the divisors of a given number, in ascending order, by using a Min-Heap.

use 5.036;
use Math::GMPz;
use ntheory 0.74 qw(:all);

prime_set_config(bigint => 'Math::GMPz');

# Generates and sorts divisors for a specific partition of prime factors
sub _gen_divs ($factors, $one) {
    my @res = ($one);
    foreach my $f (@$factors) {
        my ($p, $e) = @$f;
        my @next_res = @res;
        my $p_pow    = $one * $p;
        for my $i (1 .. $e) {
            push @next_res, map { $_ * $p_pow } @res;
            $p_pow = $p_pow * $p if $i < $e;
        }
        @res = @next_res;
    }

    # Numerically sort the partial divisors
    return [sort { $a <=> $b } @res];
}

# Sift down a heap element to maintain Min-Heap property
sub _sift_down ($h, $idx) {
    my $len  = scalar @$h;
    my $item = $h->[$idx];
    my $val  = $item->[0];

    while (1) {
        my $left = 2 * $idx + 1;
        last if $left >= $len;
        my $right     = $left + 1;
        my $min_child = $left;

        if ($right < $len && $h->[$right][0] < $h->[$left][0]) {
            $min_child = $right;
        }
        last if $val <= $h->[$min_child][0];

        $h->[$idx] = $h->[$min_child];
        $idx = $min_child;
    }
    $h->[$idx] = $item;
}

# Helper: Push a new item into the Min-Heap
sub _push_heap ($h, $item) {
    push @$h, $item;
    my $idx = $#$h;
    my $val = $item->[0];

    while ($idx > 0) {
        my $parent = int(($idx - 1) / 2);
        last if $h->[$parent][0] <= $val;
        $h->[$idx] = $h->[$parent];
        $idx = $parent;
    }
    $h->[$idx] = $item;
}

sub divisors_lazy ($n, $callback) {

    return if $n < 1;
    my $one = Math::GMPz->new(1);

    # 1. Factorize N using Math::Prime::Util
    my @pe = factor_exp($n);

    # 2. Partition factors to balance the number of divisors in A and B
    # Sort factors by their exponent+1 descending to pack the largest first
    @pe = sort { $b->[1] <=> $a->[1] } @pe;

    my (@partA, @partB);
    my ($divA,  $divB) = (1, 1);

    foreach my $f (@pe) {
        if ($divA <= $divB) {
            push @partA, $f;
            $divA *= ($f->[1] + 1);
        }
        else {
            push @partB, $f;
            $divB *= ($f->[1] + 1);
        }
    }

    # 3. Generate the two small sorted arrays of partial divisors
    my $A = _gen_divs(\@partA, $one);
    my $B = _gen_divs(\@partB, $one);

    # 4. Priority Queue (Min-Heap) for lazy sorted cross-multiplication
    # Elements in the heap are array references: [ product_value, index_A, index_B ]
    my @heap = ([$A->[0] * $B->[0], 0, 0]);

    while (@heap) {

        my $curr = $heap[0];
        my $val  = $curr->[0];
        my $i    = $curr->[1];
        my $j    = $curr->[2];

        # Trigger the callback for the absolute smallest next divisor
        $callback->($val);

        # Determine possible next steps in the A x B matrix
        my $has_next_j = ($j + 1 < @$B);
        my $has_next_i = ($j == 0 && $i + 1 < @$A);

        if ($has_next_j && $has_next_i) {

            # Add the new row starter into the heap
            _push_heap(\@heap, [$A->[$i + 1] * $B->[0], $i + 1, 0]);

            $curr->[0] = $A->[$i] * $B->[$j + 1];
            $curr->[2] = $j + 1;
            _sift_down(\@heap, 0);
        }
        elsif ($has_next_j) {

            # Reuse root
            $curr->[0] = $A->[$i] * $B->[$j + 1];
            $curr->[2] = $j + 1;
            _sift_down(\@heap, 0);
        }
        elsif ($has_next_i) {

            # Reuse root
            $curr->[0] = $A->[$i + 1] * $B->[0];
            $curr->[1] = $i + 1;
            _sift_down(\@heap, 0);
        }
        else {
            # Exhausted this path, pop from heap entirely
            my $last = pop @heap;
            if (@heap) {
                $heap[0] = $last;
                _sift_down(\@heap, 0);
            }
        }
    }
}

divisors_lazy(5040, sub ($d) { say $d });
