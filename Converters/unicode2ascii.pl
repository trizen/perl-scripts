#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 29 April 2012
# Edit: 12 March 2023
# https://github.com/trizen

# Substitute Unicode characters with ASCII characters in a stream input.

use 5.010;
use strict;
use warnings;

use Encode qw(decode_utf8);
use Text::Unidecode qw(unidecode);

while (defined(my $line = <>)) {
    print unidecode(decode_utf8($line));
}
