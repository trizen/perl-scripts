#!/usr/bin/perl

# Generate all sets of integers >= 2 whose product equals n.

# See also:
#   https://oeis.org/A001055 -- The multiplicative partition function
#   https://oeis.org/A162247 -- Irregular triangle in which row n lists all factorizations of n

use 5.036;
use ntheory 0.74 qw(:all);

sub multiplicative_partitions($n, $max_part = $n) {

    my @results;
    my @divs = divisors($n);

    shift(@divs);    # remove divisor '1'

    my $end = $#divs;
    my @path;

    sub ($target, $min_idx) {

        if ($target == 1) {
            push @results, [@path];
            return;
        }

        for my $i ($min_idx .. $end) {
            my $d = $divs[$i];

            # Prune branch if the divisor exceeds the remaining target
            last if $d > $target;
            last if $d > $max_part;

            if ($target % $d == 0) {
                push @path, $d;
                __SUB__->(divint($target, $d), $i);
                pop @path;
            }
        }
    }->($n, 0);

    @results = sort { @$a <=> @$b } @results;

    return @results;
}

# --- Execution and Output ---
my $n            = shift(@ARGV) // 48;
my $max_part     = shift(@ARGV) // $n;
my @combinations = multiplicative_partitions($n, $max_part);

# Format and print the output
my @formatted;
for my $combo (@combinations) {
    push @formatted, "[" . join(", ", @$combo) . "]";
}

print "For n = $n, we have:\n" . join("\n", @formatted) . "\n";

__END__
For n = 48, we have:
[48]
[2, 24]
[3, 16]
[4, 12]
[6, 8]
[2, 2, 12]
[2, 3, 8]
[2, 4, 6]
[3, 4, 4]
[2, 2, 2, 6]
[2, 2, 3, 4]
[2, 2, 2, 2, 3]
