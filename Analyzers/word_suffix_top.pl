#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 05 April 2015
# http://github.com/trizen

# Word suffix top

use 5.014;
use autodie;
use warnings;

use Text::Unidecode qw(unidecode);

my %top;
my $file = shift() // die "usage: $0 file [suffix len]\n";
my $i    = shift() // 3;
my $total = 0;

{
    open my $fh, '<:utf8', $file;
    while (<$fh>) {
        s/[_\W]+\z//;
        if (/(\w{$i})\z/) {
            ++$top{lc(unidecode($1))};
            ++$total;
        }
    }
    close $fh;
}

my $lonely = 0;
foreach my $key (sort { $top{$b} <=> $top{$a} or $a cmp $b } keys %top) {
    printf("%s%10s%10.02f%%\n", $key, $top{$key}, $top{$key} / $total * 100);
    ++$lonely if ($top{$key} == 1);
}

printf "\n** Unique suffixes: %.02f%%\n", $lonely / $total * 100;
