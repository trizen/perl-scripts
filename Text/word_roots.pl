#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11th September 2014
# http://github.com/trizen

# Find the minimum word derivations for a list of words

use 5.016;
use strict;
use warnings;

no warnings 'recursion';

sub make_tree {
    my ($fh) = @_;

    my %table;
    while (defined(my $word = unpack('A*', scalar(<$fh>) // last))) {
        my $ref = \%table;
        foreach my $char (split //, $word) {
            $ref = $ref->{$char} //= {};
        }
        undef $ref->{$word};
    }

    return \%table;
}

sub traverse(&$) {
    my ($code, $hash) = @_;

    foreach my $key (my @keys = sort keys %{$hash}) {
        __SUB__->($code, $hash->{$key});

        if ($#keys > 0) {

            my $count = 0;
            my $ref = my $val = delete $hash->{$key};

            while (my ($key) = each %{$ref}) {
                $ref = $val = $ref->{$key // last} // ($code->(substr($key, 0, length($key) - $count)), last);
                ++$count;
            }
        }
    }
}

traverse { say shift } make_tree(@ARGV ? \*ARGV : \*DATA);

__END__
deodorant
decor
decadere
plecare
placere
plecat
jaguar
