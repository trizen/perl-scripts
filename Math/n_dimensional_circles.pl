#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 November 2015
# Website: https://github.com/trizen

# The area of a circle in n-dimensions:
#   pi * d^n / (2*n)
#   pi * r^n * 2^(n-1) / n

# The circumference of a circle in n-dimensions:
#   pi * d^(n-1)
#   pi * r^(n-1) * 2^(n-1)

use 5.010;
use strict;
use warnings;

use Text::ASCIITable;

my @d_areas;
my @r_areas;

my @d_circumferences;
my @r_circumferences;

for my $i (1 .. 9) {
    push @d_areas, sprintf("pi * d^%d / %s", $i, 2 * $i);
    push @r_areas, sprintf("pi * r^%d * %d/%d", $i, 2**($i - 1), $i);
    push @d_circumferences, sprintf("pi * d^%d", $i - 1);
    push @r_circumferences, sprintf("pi * r^%d * %d", $i - 1, 2**($i - 1));
}

my $table = Text::ASCIITable->new;
$table->setCols('Dimension', 'Volume (d)', 'Volume (r)', 'Perimeter (d)', 'Perimeter (r)');

foreach my $i (0 .. $#d_areas) {
    $table->addRow($i + 1, $d_areas[$i], $r_areas[$i], $d_circumferences[$i], $r_circumferences[$i]);
}

print $table;

__END__
.-------------------------------------------------------------------------------.
| Dimension | Volume (d)    | Volume (r)       | Perimeter (d) | Perimeter (r)  |
+-----------+---------------+------------------+---------------+----------------+
|         1 | pi * d^1 / 2  | pi * r^1 * 1/1   | pi * d^0      | pi * r^0 * 1   |
|         2 | pi * d^2 / 4  | pi * r^2 * 2/2   | pi * d^1      | pi * r^1 * 2   |
|         3 | pi * d^3 / 6  | pi * r^3 * 4/3   | pi * d^2      | pi * r^2 * 4   |
|         4 | pi * d^4 / 8  | pi * r^4 * 8/4   | pi * d^3      | pi * r^3 * 8   |
|         5 | pi * d^5 / 10 | pi * r^5 * 16/5  | pi * d^4      | pi * r^4 * 16  |
|         6 | pi * d^6 / 12 | pi * r^6 * 32/6  | pi * d^5      | pi * r^5 * 32  |
|         7 | pi * d^7 / 14 | pi * r^7 * 64/7  | pi * d^6      | pi * r^6 * 64  |
|         8 | pi * d^8 / 16 | pi * r^8 * 128/8 | pi * d^7      | pi * r^7 * 128 |
|         9 | pi * d^9 / 18 | pi * r^9 * 256/9 | pi * d^8      | pi * r^8 * 256 |
'-----------+---------------+------------------+---------------+----------------'
