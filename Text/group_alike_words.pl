#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 July 2014
# Website: http://github.com/trizen

# Group in distinct paragraphs all the words that look pretty much the same to one another

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';

use POSIX qw(ceil);
use Getopt::Std qw(getopts);
use List::Util qw(first min);

my %opt = (d => 2);

sub usage {
    my ($code) = @_;

    print <<"USAGE";
usage: $0 [options] [input file]

options:
        -d int  : the maximum distance between two words (default: $opt{d})
        -m      : merge similar groups into one larger group
        -k      : allow a word to exist in more than one group

        -h      : print this message and exit

example:
        $0 -d 1 input.txt > output.txt
USAGE

    exit($code // 0);
}

getopts('d:kmh', \%opt);
$opt{h} && usage();

# Levenshtein's distance function (optimized for speed)
sub leven {
    my ($s, $t) = @_;

    my @d = ([0 .. @$t], map { [$_] } 1 .. @$s);

    foreach my $i (0 .. $#{$s}) {
        foreach my $j (0 .. $#{$t}) {
            $d[$i + 1][$j + 1] =
              $s->[$i] eq $t->[$j]
                ? $d[$i][$j]
                : 1 + min($d[$i][$j + 1], $d[$i + 1][$j], $d[$i][$j]);
        }
    }

    $d[-1][-1];
}

# When no file has been provided, throw an error
@ARGV || usage(2);

# Iterate over the argument-files
foreach my $file (@ARGV) {

    my @words = do {
        my %w;
        open my $fh, '<', $file or do {
            warn "Can't open file '$file': $!";
            next;
        };
        @w{map { unpack('A*') } <$fh>} = ();
        map { [split //] } sort keys %w;
    };

    my %table;
    for (my $i = 0 ; $i <= $#words - 1 ; $i++) {

        printf STDERR "[%*d of %d] Processing...\r", ceil(log(scalar @words) / log(10)), $i, scalar(@words);

        my %h1;
        @h1{@{$words[$i]}} = ();

        for (my $j = $i + 1 ; $j <= $#words ; $j++) {

            # If the lengths of the words differ by more than $opt{d}
            if (abs(@{$words[$i]} - @{$words[$j]}) > $opt{d}) {
                next;    # then there is no need to compute the distance
            }

            my %h2;
            @h2{@{$words[$j]}} = ();

            # One more check before calling the very
            # expensive Levenshtein's distance function
            my $diff = 0;
            foreach my $key (keys %h1) {
                exists $h2{$key} or do {
                    last if ++$diff > $opt{d};
                };
            }

            next if $diff > $opt{d};

            # Compute the Levenshtein distance
            if (leven($words[$i], $words[$j]) <= $opt{d}) {
                if (not exists $table{$i}) {
                    $table{$i} = [join('', @{$words[$i]})];
                }
                push @{$table{$i}}, join('', @{$words[$j]});
                splice(@words, $j--, 1) if (not $opt{k} and not $opt{m});
            }
        }
    }

    # Clear the process line
    print STDERR "                             \r";

    # Output the results
    if ($opt{m}) {    # merge the groups
        my @values = values %table;
        for (my $i = 0 ; $i <= $#values ; $i++) {
            foreach my $val (@{$values[$i]}) {
                for (my $j = $i + 1 ; $j <= $#values ; $j++) {
                    if (defined(first { $val eq $_ } @{$values[$j]})) {
                        push @{$values[$i]}, @{$values[$j]};
                        splice(@values, $j--, 1);
                        last;
                    }
                }
            }

            my %w;
            @w{@{$values[$i]}} = ();
            say for sort keys %w;
            print "\n";
        }
    }
    else {    # simple output
        foreach my $value (values %table) {
            say for @{$value};
            print "\n";
        }
    }
}
