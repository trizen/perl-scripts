#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 March 2012
# https://github.com/trizen

# Count Character Frequency in a file

use 5.010;
use strict;
use warnings;
use open IO => ':utf8', ':std';

my %table;
my %memoize;

my %white_spaces = (
                    ord("\r") => q{\r},
                    ord("\n") => q{\n},
                    ord("\f") => q{\f},
                    ord("\t") => q{\t},
                    ord(" ")  => q{' '},
                   );

my $file = shift // $0;

open my $fh, '<', $file or die "Unable to open $file: $!";
while (defined(my $char = getc $fh)) {
    ++$table{
        $memoize{$char} // do {
            $memoize{$char} = ord $char;
          }
      };
}
close $fh;

$= = 80;
format STDOUT_TOP =
CHR             ORD            USED
-----------------------------------
.

my $key;

format STDOUT =
@>>         @>>>>>>         @>>>>>>
$white_spaces{$key} // chr $key, $key, $table{$key}
.

foreach $key (sort { $table{$b} <=> $table{$a} } keys %table) {
    write;
}

say "\nUnique characters used: ", scalar keys %table;
