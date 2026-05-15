#!/usr/bin/perl

# Generate Combinations with Replacement (also known as multisets) of size `n`, with maximum value `k` and maximum sum `max_sum`.

use 5.036;

sub multisets ($n, $k, $max_sum) {
    my @result;
    my @path;

    sub ($pos, $max_val, $sum) {

        if ($pos == $n) {
            push @result, [@path];
            return;
        }

        for my $v (1 .. $max_val) {
            last if ($sum + $v > $max_sum);
            push @path, $v;
            __SUB__->($pos + 1, $v, $sum + $v);
            pop @path;
        }
    }->(0, $k, 0);

    return @result;
}

# Print results
my ($n, $k, $max_sum) = (3, 4, 8);
my @perms = multisets($n, $k, $max_sum);
for my $perm (@perms) {
    print "[" . join(", ", @$perm) . "]\n";
}

__END__
[1, 1, 1]
[2, 1, 1]
[2, 2, 1]
[2, 2, 2]
[3, 1, 1]
[3, 2, 1]
[3, 2, 2]
[3, 3, 1]
[3, 3, 2]
[4, 1, 1]
[4, 2, 1]
[4, 2, 2]
[4, 3, 1]
