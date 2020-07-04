#!/usr/bin/perl

use utf8;
use 5.014;
use strict;
use warnings;

use open ':std' => 'utf8';

use Scalar::Util qw(looks_like_number);
use Lingua::RO::Numbers qw(ro_to_number number_to_ro);

require Term::ReadLine;
my $term = Term::ReadLine->new($0);

while (1) {
    my $num = $term->readline("Introduceți un număr: ");
    say +(looks_like_number($num) ? number_to_ro($num) : ro_to_number($num)) // next;
}
