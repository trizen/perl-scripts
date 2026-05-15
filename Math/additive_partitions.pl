#!/usr/bin/perl

# Generate all additive partitions of a given number.
# With support for specifying the largest value in a partition.

use 5.036;

sub partitions ($n, $max_part = $n) {
    my @results;

    sub ($n, $max_part, $current) {

        if ($n == 0) {
            push @results, [@$current];
            return;
        }

        my $upper = ($n < $max_part ? $n : $max_part);

        for my $part (1 .. $upper) {
            push @$current, $part;
            __SUB__->($n - $part, $part, $current);
            pop @$current;    # backtrack
        }
    }->($n, $max_part, []);

    return @results;
}

my $n          = shift(@ARGV) // 5;
my $max_part   = shift(@ARGV) // $n;
my @partitions = partitions($n, $max_part);
my $count      = scalar @partitions;

printf "Additive partitions of %d  (%d total):\n", $n, $count;
printf "  [%s]\n", join(', ', @$_) for @partitions;

__END__
Additive partitions of 5  (7 total):
  [1, 1, 1, 1, 1]
  [2, 1, 1, 1]
  [2, 2, 1]
  [3, 1, 1]
  [3, 2]
  [4, 1]
  [5]
