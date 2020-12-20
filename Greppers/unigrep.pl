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
use Getopt::Std qw(getopts);

my %opt;
getopts('i', \%opt);

my $param = shift(@ARGV) // '';
my $regex = ($opt{i} ? qr/$param/oi : qr/$param/o);

my $uniregex = do {
    my $t = decode_utf8($param);
    $opt{i} ? qr/$t/io : qr/$t/o;
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
