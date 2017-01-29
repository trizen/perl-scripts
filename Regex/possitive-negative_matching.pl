#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 30 May 2013
# https://github.com/trizen

# Returns true in a positive check
# if a string doesn't matches a regex.

my $string = 'This is a TOP 10 string.';

if ($string =~ m{^(?(?{/top/i})(?!))}) {
    print "Doesn't contains the 'top' word.\n";
}
else {
    print "Contains the 'top' word.\n";
}
