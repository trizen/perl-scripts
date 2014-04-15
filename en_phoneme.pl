#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 15 April 2014
# Website: http://github.com/trizen

# usage: ./en_phoneme.pl [word] [word] [...]

use 5.010;
use strict;
use warnings;

use Lingua::EN::Phoneme;
my $lep = Lingua::EN::Phoneme->new;

sub normalize {
    my $syl = lc($_[0]);
    $syl =~ s/h0\z/x/;
    $syl =~ s/\w\K0\z//;
    $syl =~ s/\w\K1\z//;
    return $syl;
}

foreach my $word (@ARGV) {
    my $p_word = $lep->phoneme($word) // do {
        warn "error: '$word' is not an English word!\n";
        next;
    };
    say join(" ", map { normalize($_) } split(' ', $p_word));
}
