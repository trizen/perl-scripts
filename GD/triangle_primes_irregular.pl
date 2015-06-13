#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 April 2015
# http://github.com/trizen

# A number triangle, with the primes highlighted in blue

## Veritical lines are represented by:
# n^2 - 2n + 2
# n^2 - n + 1
# n^2
# n^2 + n - 1
# n^2 + 2n - 2
# ...

## Horizontal lines are represented by:
# 1
# n + 1
# 2n + 3
# 3n + 7
# 4n + 13
# 5n + 21
# 6n + 31
# 7n + 43
# ...

use 5.010;
use strict;
use warnings;

use GD::Simple;
use ntheory qw(is_prime);

my $rows = shift(@ARGV) // 2000;    # duration: about 12 seconds
my $white = 1;

# create a new image
my $img = GD::Simple->new($rows, $rows);
$img->fgcolor('white');

foreach my $i (0 .. $rows - 1) {
    $img->moveTo(0, $i);
    foreach my $j ($i .. $rows - 1) {
        my $num = $i * $j + 1;

        #printf "%3d%s", $num, ' ';
        if (is_prime($num)) {
            if ($white) {
                $img->fgcolor('blue');
                $white = 0;
            }
        }
        elsif (not $white) {
            $img->fgcolor('white');
            $white = 1;
        }

        $img->line(1);
    }

    #print "\n";
}

open my $fh, '>:raw', 'triangle_primes_irregular.png';
print $fh $img->png;
close $fh;

__END__
  1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1   1
  2   3   4   5   6   7   8   9  10  11  12  13  14  15  16  17  18  19  20
  5   7   9  11  13  15  17  19  21  23  25  27  29  31  33  35  37  39
 10  13  16  19  22  25  28  31  34  37  40  43  46  49  52  55  58
 17  21  25  29  33  37  41  45  49  53  57  61  65  69  73  77
 26  31  36  41  46  51  56  61  66  71  76  81  86  91  96
 37  43  49  55  61  67  73  79  85  91  97 103 109 115
 50  57  64  71  78  85  92  99 106 113 120 127 134
 65  73  81  89  97 105 113 121 129 137 145 153
 82  91 100 109 118 127 136 145 154 163 172
101 111 121 131 141 151 161 171 181 191
122 133 144 155 166 177 188 199 210
145 157 169 181 193 205 217 229
170 183 196 209 222 235 248
197 211 225 239 253 267
226 241 256 271 286
257 273 289 305
290 307 324
325 343
362
