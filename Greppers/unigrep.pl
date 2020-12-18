#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 18 December 2020
# https://github.com/trizen

# A unidecode grep-like program.

# In addition to normal grepping, it also converts input to ASCII and checks the given regex.

# usage:
#   perl unigrep.pl [regex] [input]
#   find . | perl unigrep.pl [regex]

use 5.010;
use strict;
use warnings;

use Encode qw(decode_utf8);
use Text::Unidecode qw(unidecode);

my $param = shift(@ARGV);
my $regex = qr/$param/o;

my $uniregex = do {
    my $t = decode_utf8($param);
    qr/$t/o;
};

while (<>) {

    my $orig   = $_;
    my $line   = decode_utf8($_);
    my $unidec = unidecode(decode_utf8($_));

    if (   $orig =~ $regex
        or $line   =~ $uniregex
        or $unidec =~ $regex
        or $unidec =~ $uniregex) {
        print $orig;
    }
}
