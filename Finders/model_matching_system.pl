#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 June 2015
# Edit: 25 July 2016
# https://github.com/trizen
# Email: <trizenx gmail="com"/>

#
## A very fast complex matching system
#

# It works by creating a nested hash with words stored as paths,
# then it walks this nested hash from path to path, looking for matches.

# It matches in (case|word order|space|punctuation)-insensitive mode.
# The results are sorted to match the input keywords as best as possible.

use 5.010;
use strict;
use warnings;

use List::Util qw(all);

sub split_entry {
    grep { $_ ne '' } split(/\W+/, lc($_[0]));
}

sub update_model {
    my ($model, $entry) = @_;

    foreach my $word (split_entry($entry)) {
        my $ref = $model;
        foreach my $char (split(//, $word)) {
            $ref = $ref->{$char} //= {};
            push @{$ref->{values}}, \$entry;
        }
    }

    return 1;
}

sub find {
    my ($model, $entry) = @_;

    my @tokens = split_entry($entry);

    my (@words, @matches, %analyzed);
    foreach my $word (@tokens) {

        my $ref = $model;
        foreach my $char (split(//, $word)) {
            if (exists $ref->{$char}) {
                $ref = $ref->{$char};
            }
            else {
                $ref = undef;
                last;
            }
        }

        if (defined $ref and exists $ref->{values}) {
            push @words, $word;
            foreach my $match (@{$ref->{values}}) {
                if (not exists $analyzed{$match}) {
                    undef $analyzed{$match};
                    unshift @matches, $$match;
                }
            }
        }
        else {
            @matches = ();    # don't include partial matches
            last;
        }
    }

    foreach my $token (@tokens) {
        @matches = grep { index(lc($_), $token) != -1 } @matches;
    }

    # Sort and return the matches
    map    { $_->[0] }
      sort { $b->[1] <=> $a->[1] }
      map {
        my @parts = split_entry($_);

        my $end_w = $#words;
        my $end_p = $#parts;

        my $min_end = $end_w < $end_p ? $end_w : $end_p;

        my $order_score = 0;
        for (my $i = 0 ; $i <= $min_end ; ++$i) {
            my $word = $words[$i];

            for (my $j = $i ; $j <= $end_p ; ++$j) {
                my $part = $parts[$j];

                my $matched;
                my $continue = 1;
                while ($part eq $word) {
                    $order_score += 1 - 1 / (length($word) + 1)**2;
                    $matched ||= 1;
                    $part = $parts[++$j] // do { $continue = 0; last };
                    $word = $words[++$i] // do { $continue = 0; last };
                }

                if ($matched) {
                    $order_score += 1 - 1 / (length($word) + 1)
                      if ($continue and index($part, $word) == 0);
                    last;
                }
                elsif (index($part, $word) == 0) {
                    $order_score += length($word) / length($part);
                    last;
                }
            }
        }

        my $prefix_score = 0;
        all {
            ($parts[$_] eq $words[$_])
              ? do {
                $prefix_score += 1;
                1;
              }
              : (index($parts[$_], $words[$_]) == 0) ? do {
                $prefix_score += length($words[$_]) / length($parts[$_]);
                0;
              }
              : 0;
        }
        0 .. $min_end;

        ## printf("score('@parts', '@words') = %.4g + %.4g = %.4g\n",
        ##        $order_score, $prefix_score, $order_score + $prefix_score);

        [$_, $order_score + $prefix_score]
      } @matches;
}

#
## Usage example
#

my %model;
while (<DATA>) {
    chomp($_);
    update_model(\%model, $_);
}

sub search {
    my ($str) = @_;
    say "* Results for '$str':";
    use Data::Dump qw(pp);
    say pp([find(\%model, $str)]), "\n";
}

search('I love');
search('love');
search('a love');
search('love a');
search('actually love');
search('Paris love');
search('love Berlin');

__DATA__
My First Lover
A Lot Like Love
Funny Games (2007)
Cinderella Man (2005)
Pulp Fiction (1994)
Don't Say a Word (2001)
Secret Window (2004)
The Lookout (2007)
88 Minutes (2007)
The Mothman Prophecies
Love Actually (2003)
From Paris with Love (2010)
P.S. I Love You (2007)
