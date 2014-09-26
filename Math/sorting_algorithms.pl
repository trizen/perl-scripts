#!/usr/bin/perl

use 5.016;
use List::Util qw(min max shuffle);

############################################
# For performance comparisons, execute:
############################################
##    perl -d:NYTProf sorting_algorithms.pl
##    nytprofhtml --open -m
############################################

{
    # LAZY SORT
    sub lazysort {
        my (@A) = @_;

        my $end = $#A;

        while (1) {
            my $swaped;
            for (my $i = 0 ; $i < $end ; $i++) {
                if ($A[$i] > $A[$i + 1]) {
                    @A[$i + 1, $i] = @A[$i, $i + 1];
                    $swaped //= 1;
                    $i++;
                }
            }
            $swaped || return \@A;
        }
    }
}

{
    # QUICK SORT
    sub quick_sort {
        my (@a) = @_;
        @a < 2 ? @a : do {
            my $p = pop @a;
            __SUB__->(grep $_ < $p, @a), $p, __SUB__->(grep $_ >= $p, @a);
          }
    }
}

{
    # QUICK SORT (with partition)
    sub _partition {
        my ($array, $first, $last) = @_;
        my $i     = $first;
        my $j     = $last - 1;
        my $pivot = $array->[$last];
      SCAN: {
            do {
                # $first <= $i <= $j <= $last - 1
                # Point 1.
                # Move $i as far as possible.
                while ($array->[$i] <= $pivot) {
                    $i++;
                    last SCAN if $j < $i;
                }

                # Move $j as far as possible.
                while ($array->[$j] >= $pivot) {
                    $j--;
                    last SCAN if $j < $i;
                }

                # $i and $j did not cross over, so swap a low and a high value.
                @$array[$j, $i] = @$array[$i, $j];
            } while (--$j >= ++$i);
        }

        # $first - 1 <= $j < $i <= $last
        # Point 2.
        # Swap the pivot with the first larger element (if there is one)
        if ($i < $last) {
            @$array[$last, $i] = @$array[$i, $last];
            ++$i;
        }

        # Point 3.
        return ($i, $j);    # The new bounds exclude the middle.
    }

    sub _quicksort_recurse {
        my ($array, $first, $last) = @_;
        if ($last > $first) {
            my ($first_of_last, $last_of_first) = _partition($array, $first, $last);
            __SUB__->($array, $first,         $last_of_first);
            __SUB__->($array, $first_of_last, $last);
        }
    }

    sub _quicksort_iterate {
        my ($array, $first, $last) = @_;
        my @stack = ($first, $last);
        do {
            if ($last > $first) {
                my ($last_of_first, $first_of_last) = _partition $array, $first, $last;

                # Larger first.
                if ($first_of_last - $first > $last - $last_of_first) {
                    push @stack, $first, $first_of_last;
                    $first = $last_of_first;
                }
                else {
                    push @stack, $last_of_first, $last;
                    $last = $first_of_last;
                }
            }
            else {
                ($first, $last) = splice @stack, -2, 2;    # Double pop.
            }
        } while @stack;
    }

    sub quick_sort2 {
        my @arr = @_;

        # The recursive version is bad with BIG lists
        # because the function call stack gets REALLY deep.
        _quicksort_recurse(\@arr, 0, $#arr);
    }

    sub quick_sort3 {
        my @arr = @_;
        _quicksort_iterate(\@arr, 0, $#arr);
    }

}

{
    # BUBBLE SORT
    sub bubble_sort {
        for my $i (0 .. $#_) {
            for my $j ($i + 1 .. $#_) {
                $_[$j] < $_[$i] && do {
                    @_[$i, $j] = @_[$j, $i];
                };
            }
        }
    }
}

{
    # BUBBLE SORT SMART
    sub bubblesmart {
        my @array = @_;
        my $start = 0;         # The start index of the bubbling scan.
        my $i     = $#array;
        while (1) {
            my $new_start;     # The new start index of the bubbling scan.
            my $new_end = 0;   # The new end index of the bubbling scan.
            for (my $j = $start || 1 ; $j <= $i ; $j++) {
                if ($array[$j - 1] > $array[$j]) {
                    @array[$j, $j - 1] = @array[$j - 1, $j];
                    $new_end = $j - 1;
                    $new_start = $j - 1 unless defined $new_start;
                }
            }
            last unless defined $new_start;    # No swaps: we're done.
            $i     = $new_end;
            $start = $new_start;
        }
    }
}

{
    # COCKTAIL SORT
    sub cocktailSort {                         #( A : list of sortable items ) defined as:
        my @A       = @_;
        my $swapped = 1;
        while ($swapped == 1) {
            $swapped = 0;
            for (my $i = 0 ; $i < ($#A - 1) ; $i += 1) {

                if ($A[$i] > $A[$i + 1]) {     # test whether the two
                                               # elements are in the wrong
                                               # order
                    ($A[$i + 1], $A[$i]) = ($A[$i], $A[$i + 1]);    # let the two elements
                                                                    # change places
                    $swapped = 1;
                }
            }
            if ($swapped == 0) {

                # we can exit the outer loop here if no swaps occurred.
            }
            else {
                $swapped = 0;
                for (my $i = ($#A - 1) ; $i > 0 ; $i -= 1) {

                    if ($A[$i] > $A[$i + 1]) {
                        ($A[$i + 1], $A[$i]) = ($A[$i], $A[$i + 1]);
                        $swapped = 1;
                    }
                }
            }

            #  if no elements have been swapped,
            #  then the list is sorted
        }
        return (@A);
    }
}

{
    # COMB SORT
    sub combSort {
        my @arr   = @_;
        my $gap   = @arr;
        my $swaps = 1;
        while ($gap > 1 or $swaps) {
            $gap /= 1.25 if $gap > 1;
            $swaps = 0;
            foreach my $i (0 .. $#arr - $gap) {
                if ($arr[$i] > $arr[$i + $gap]) {
                    @arr[$i, $i + $gap] = @arr[$i + $gap, $i];
                    $swaps = 1;
                }
            }
        }
        return @arr;
    }
}

{
    # GNOME SORT
    sub gnome_sort {
        my @a = @_;

        my $size = scalar(@a);
        my $i    = 1;
        my $j    = 2;
        while ($i < $size) {
            if ($a[$i - 1] <= $a[$i]) {
                $i = $j;
                $j++;
            }
            else {
                @a[$i, $i - 1] = @a[$i - 1, $i];
                $i--;
                if ($i == 0) {
                    $i = $j;
                    $j++;
                }
            }
        }
        return @a;
    }
}

{
    # HEAP SORT
    sub heap_sort {
        my (@list) = @_;
        my $count = scalar @list;
        _heapify($count, \@list);

        my $end = $count - 1;
        while ($end > 0) {
            @list[0, $end] = @list[$end, 0];
            _sift_down(0, $end - 1, \@list);
            --$end;
        }
    }

    sub _heapify {
        my ($count, $list) = @_;
        my $start = ($count - 2) / 2;
        while ($start >= 0) {
            _sift_down($start, $count - 1, $list);
            --$start;
        }
    }

    sub _sift_down {
        my ($start, $end, $list) = @_;

        my $root = $start;
        while ($root * 2 + 1 <= $end) {
            my $child = $root * 2 + 1;
            ++$child if $child + 1 <= $end and $$list[$child] < $$list[$child + 1];
            if ($$list[$root] < $$list[$child]) {
                @$list[$root, $child] = @$list[$child, $root];
                $root = $child;
            }
            else {
                return;
            }
        }
    }
}

{
    # HEAP SORT (2)
    sub heap_sort2 {
        use integer;
        my (@array) = @_;
        for (my $index = 1 + @array / 2 ; $index-- ;) {
            _heapify2(\@array, $index);
        }
        for (my $last = @array ; --$last ;) {
            @array[0, $last] = @array[$last, 0];
            _heapify2(\@array, 0, $last);
        }
    }

    sub _heapify2 {
        use integer;
        my ($array, $index, $last) = @_;
        $last = @$array unless defined $last;
        my $swap = $index;
        my $high = $index * 2 + 1;
        for (my $try = $index * 2 ; $try < $last and $try <= $high ; ++$try) {
            $swap = $try if $$array[$try] > $$array[$swap];
        }
        unless ($swap == $index) {

            # The heap is in disorder: must reshuffle.
            @{$array}[$swap, $index] = @{$array}[$index, $swap];
            __SUB__->($array, $swap, $last);
        }
    }
}

{
    # MERGE SORT (simple)
    sub merge_sort {
        my @x = @_;
        return @x if @x < 2;
        my $m = int @x / 2;
        my @a = __SUB__->(@x[0 .. $m - 1]);
        my @b = __SUB__->(@x[$m .. $#x]);
        for (@x) {
            $_ =
                !@a            ? shift @b
              : !@b            ? shift @a
              : $a[0] <= $b[0] ? shift @a
              :                  shift @b;
        }
        @x;
    }
}

{
    # MERGE SORT (recursive + iterative)
    {
        my @work;    # A global work array.

        sub _merge {
            my ($array, $first, $middle, $last) = @_;
            my $n = $last - $first + 1;

            # Initialize work with relevant elements from the array.
            for (my $i = $first, my $j = 0 ; $i <= $last ;) {
                $work[$j++] = $array->[$i++];
            }

            # Now do the actual merge. Proceed through the work array
            # and copy the elements in order back to the original array
            # $i is the index for the merge result, $j is the index in
            # first half of the working copy, $k the index in the second half.
            $middle = int(($first + $last) / 2) if $middle > $last;
            my $n1 = $middle - $first + 1;    # The size of the 1st half.
            for (my $i = $first, my $j = 0, my $k = $n1 ; $i <= $last ; $i++) {
                $array->[$i] =
                    $j < $n1 && ($k == $n || $work[$j] < $work[$k])
                  ? $work[$j++]
                  : $work[$k++];
            }
        }
    }

    sub _mergesort_recurse {
        my ($array, $first, $last) = @_;
        if ($last > $first) {
            my $middle = int(($last + $first) / 2);
            __SUB__->($array, $first,      $middle);
            __SUB__->($array, $middle + 1, $last);
            _merge($array, $first, $middle, $last);
        }
    }

    sub merge_sort2 {
        my @array = @_;
        _mergesort_recurse(\@array, 0, $#array);
    }

    {

        sub merge_sort3 {
            my @array = @_;
            my $N     = @array;
            my $Nt2   = $N * 2;    # N times 2.
            my $Nm1   = $N - 1;    # N minus 1.
            for (my $size = 2 ; $size < $Nt2 ; $size *= 2) {
                for (my $first = 0 ; $first < $N ; $first += $size) {
                    my $last = $first + $size - 1;
                    _merge(\@array, $first, int(($first + $last) / 2), $last < $N ? $last : $Nm1);
                }
            }
        }
    }
}

{
    # SHELL SORT
    sub shell_sort {
        my (@a, $h, $i, $j, $k) = @_;
        for ($h = @a ; $h = int $h / 2 ;) {
            for $i ($h .. $#a) {
                $k = $a[$i];
                for ($j = $i ; $j >= $h and $k < $a[$j - $h] ; $j -= $h) {
                    $a[$j] = $a[$j - $h];
                }
                $a[$j] = $k;
            }
        }
        @a;
    }
}

{
    # SHELL SORT (2)
    sub shell_sort2 {
        my @array = @_;
        my $i;    # The initial index for the bubbling scan.
        my $j;    # The running index for the bubbling scan.
        my $shell = (2 << log(scalar @array) / log(2)) - 1;
        do {
            $shell = int(($shell - 1) / 2);
            for ($i = $shell ; $i < @array ; $i++) {
                for ($j = $i - $shell ; $j >= 0 && $array[$j] > $array[$j + $shell] ; $j -= $shell) {
                    @array[$j, $j + $shell] = @array[$j + $shell, $j];
                }
            }
        } while $shell > 1;
    }
}

{
    # SELECTION SORT
    sub selection_sort {
        my @a = @_;
        foreach my $i (0 .. $#a - 1) {
            my $min = $i + 1;
            $a[$_] < $a[$min] and $min = $_ foreach ($min .. $#a);
            @a[$i, $min] = @a[$min, $i] if $a[$i] > $a[$min];
        }
        return @a;
    }
}

{
    # SELECTION SORT (2)
    sub selection_sort2 {
        my @array = @_;
        my $i;    # The starting index of a minimum-finding scan.
        my $j;    # The running index of a minimum-finding scan.
        for ($i = 0 ; $i < $#array ; $i++) {
            my $m = $i;            # The index of the minimum element.
            my $x = $array[$m];    # The minimum value.
            for ($j = $i + 1 ; $j < @array ; $j++) {
                ($m, $x) = ($j, $array[$j])    # Update minimum.
                  if $array[$j] < $x;
            }

            # Swap if needed.
            @array[$m, $i] = @array[$i, $m] unless $m == $i;
        }
    }
}

{
    # INSERTION SORT
    sub insertion_sort {
        my (@list) = @_;
        foreach my $i (1 .. $#list) {
            my $j = $i;
            my $k = $list[$i];
            while ($j > 0 and $k < $list[$j - 1]) {
                $list[$j] = $list[$j - 1];
                --$j;
            }
            $list[$j] = $k;
        }
        return @list;
    }
}

{
    # INSERTION SORT (2)
    sub insertion_sort2 {
        my @array = @_;
        my $i;    # The initial index for the minimum element.
        my $j;    # The running index for the minimum-finding scan.
        for ($i = 0 ; $i < $#array ; $i++) {
            my $m = $i;            # The final index for the minimum element.
            my $x = $array[$m];    # The minimum value.
            for ($j = $i + 1 ; $j < @array ; $j++) {
                ($m, $x) = ($j, $array[$j])    # Update minimum.
                  if $array[$j] < $x;
            }

            # The double-splice simply moves the $m-th element to be
            # the $i-th element. Note: splice is O(N), not O(1).
            # As far as the time complexity of the algorithm is concerned
            # it makes no difference whether we do the block movement
            # using the preceding loop or using splice(). Still, splice()
            # is faster than moving the block element by element.
            splice @array, $i, 0, splice @array, $m, 1 if $m > $i;
        }
    }
}

{
    # STRAND SORT
    sub _strand_merge {
        my ($x, $y) = @_;
        my @out;
        while (@$x and @$y) {
            my $cmp = $$x[-1] <=> $$y[-1];
            if    ($cmp == 1)  { unshift @out, pop @$x }
            elsif ($cmp == -1) { unshift @out, pop @$y }
            else               { splice @out, 0, 0, pop @$x, pop @$y }
        }
        return @$x, @$y, @out;
    }

    sub _strand {
        my $x = shift;
        my @out = shift @$x // return;
        if (@$x) {
            for (-@$x .. -1) {
                if ($x->[$_] >= $out[-1]) {
                    push @out, splice @$x, $_, 1;
                }
            }
        }
        return @out;
    }

    sub strand_sort {
        my @x = @_;
        my @out;
        while (my @strand = _strand(\@x)) {
            @out = _strand_merge(\@out, \@strand);
        }
        @out;
    }
}

{
    # NIGHT SORT
    sub night_sort {
        my (@arr) = @_;

        my $max = 0;
        my $min = 0;

        my @indices = $max;

        my $swaped;
        foreach my $i (1 .. $#arr) {
            my $cmp = $arr[$i - 1] <=> $arr[$i];

            push @indices,
                $cmp == -1 ? $indices[-1] + 1
              : $cmp == 1 ? do { $swaped //= 1; $indices[-1] - 1 }
              :             $indices[-1];

            $min = $indices[-1] if $indices[-1] < $min;
            $max = $indices[-1] if $indices[-1] > $max;
        }
        unless ($swaped) {
            return @arr;
        }

        my @fetch;
        for my $i ($min .. $max) {
            for my $j (0 .. $#indices) {
                if ($indices[$j] == $i) {
                    push @fetch, $j;
                }
            }
        }
        __SUB__->(@arr[@fetch]);
    }
}

{
    # MORNING SORT
    sub morning_sort {
        my (@arr) = @_;
        @arr < 2 ? @arr : do {
            my $p = splice(@arr, int rand @arr, 1);
            __SUB__->(grep $_ <= $p, @arr), $p, __SUB__->(grep $_ > $p, @arr);
          }
    }
}

{
    # AFTERNOON SORT
    sub afternoon_sort {
        my (@arr) = @_;

        my @new;
        for (@arr) {
            push @{$new[int(log($_ + 1) * (10**(1 + int(log($_ + 1) / log(10)))))]}, $_;
        }

        map { defined($_) ? @{$_} : () } @new;
    }
}

{
    # SAC SORT
    sub sac_sort {
        my (@arr, @sac) = @_;

        @arr > 1 || return @arr;

        for (@arr) {
            my $i = 0;
            for (; $i <= $#sac ; ++$i) {
                last if $sac[$i] > $_;
            }
            splice @sac, $i, 0, $_;
        }

        @sac;
    }
}

{
    # SAC SORT SMART
    sub sac_sort_smart {
        my (@arr, @sac) = @_;

        @arr > 1 || return @arr;

        my $c1 = 0;
        my $c2 = 1;
        my $j  = 0;

        for (@arr) {
            if ($c1 < $c2) {
                my $i = 0;
                for (; $i <= $#sac ; ++$i) {
                    last if $sac[$i] > $_;
                    ++$c1;
                }
                splice @sac, $i, 0, $_;
            }
            else {
                my $i = $j;
                for (; $i > 0 ; --$i) {
                    last if $sac[$i - 1] < $_;
                    ++$c2;
                }
                splice @sac, $i, 0, $_;
            }
            ++$j;
        }

        @sac;
    }
}

{
    # COUNTING SORT
    sub counting_sort {
        my ($a, $min, $max) = @_;

        my @cnt = (0) x ($max - $min + 1);
        $cnt[$_ - $min]++ foreach @$a;

        my $i = $min;
        @$a = map { ($i++) x $_ } @cnt;
    }
}

{
    # BEADSORT
    sub beadsort {
        my @data = @_;

        my @columns;
        my @rows;

        for my $datum (@data) {
            for my $column (0 .. $datum - 1) {
                ++$rows[$columns[$column]++];
            }

        }

        return reverse @rows;
    }
}

{
    # PANCAKE
    sub pancake {
        my @x = @_;
        for my $idx (0 .. $#x - 1) {
            my $min = $idx;
            $x[$min] > $x[$_] and $min = $_ for $idx + 1 .. $#x;

            next if $x[$min] == $x[$idx];

            @x[$min .. $#x] = reverse @x[$min .. $#x] if $x[$min] != $x[-1];
            @x[$idx .. $#x] = reverse @x[$idx .. $#x];
        }
        @x;
    }
}

{
    # BINSERTION SORT
    sub _binary_search {
        my ($array_ref, $value, $left, $right, $middle) = @_;

        $array_ref->[$middle = int(($right + $left) / 2)] > $value
          ? ($right = $middle - 1)
          : ($left = $middle + 1)
          while ($left <= $right);

        ++$middle while ($array_ref->[$middle] < $value);

        $middle;
    }

    sub binsertion_sort {
        my (@list) = @_;

        foreach my $i (1 .. $#list) {
            if ((my $k = $list[$i]) < $list[$i - 1]) {
                splice(@list, $i, 1);
                splice(@list, _binary_search(\@list, $k, 0, $i - 1), 0, $k);
            }
        }

        return @list;
    }
}

##########################################################

# Random
my @arr = map { int(rand($_) + rand(500)) } 0 .. 500;

# Reversed
#my @arr = reverse(0..500);

# Sorted
#my @arr = (0..500);

##########################################################

afternoon_sort(map $_, @arr);
#beadsort(map $_, @arr);        # pretty slow
binsertion_sort(map $_, @arr);
bubble_sort(map $_, @arr);
bubblesmart(map $_, @arr);
cocktailSort(map $_, @arr);
combSort(map $_, @arr);
counting_sort([map $_, @arr], min(@arr), max(@arr));
gnome_sort(map $_, @arr);
heap_sort(map $_, @arr);
heap_sort2(map $_, @arr);
insertion_sort(map $_, @arr);
insertion_sort2(map $_, @arr);
lazysort(map $_, @arr);
merge_sort(map $_, @arr);
merge_sort2(map $_, @arr);
merge_sort3(map $_, @arr);
morning_sort(map $_, @arr);
#night_sort(map $_, @arr);       # too sleepy
pancake(map $_, @arr);
quick_sort(map $_, @arr);
quick_sort2(map $_, @arr);
quick_sort3(map $_, @arr);
sac_sort(map $_, @arr);
sac_sort_smart(map $_, @arr);
selection_sort(map $_, @arr);
selection_sort2(map $_, @arr);
shell_sort(map $_, @arr);
shell_sort2(map $_, @arr);
strand_sort(map $_, @arr);
