#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 17 April 2012
# https://github.com/trizen

# Group and list words from a wordlist that have similar ending chars

use strict;
use warnings;

use open IO => ':utf8', ':std';
use Getopt::Long qw(GetOptions);

my $min = 4;
my $max = 15;

my $min_words = 2;
my $max_words = 'inf';

my $unique = 0;

GetOptions(
           'end-min|end_min=i'     => \$min,
           'end-max|end_max=i'     => \$max,
           'group-min|group_min=i' => \$min_words,
           'group-max|group_max=i' => \$max_words,
           'unique!'               => \$unique,
          )
  or die "Error in command-line arguments!";

@ARGV or die <<"HELP";
usage: $0 [options] wordlists

options:
       --end-min=i   : minimum number of similar characters (default: $min)
       --end-max=i   : maximum number of similar characters (default: $max)
       --group-min=i : minimum number of words per group (default: $min_words)
       --group-max=i : maximum number of words per group (default: $max_words)
       --unique!     : don't use the same word in different groups (default: $unique)
HELP

--$min;    # starting with zero

foreach my $file (grep -f, @ARGV) {
    my %table;
    open my $fh, '<', $file or do { warn "$0: can't open file $file: $!"; next };
    while (defined(my $line = <$fh>)) {
        chomp $line;

        next if (my $length = length($line)) <= $min;
        --$length;    # same as $#chars

        my @chars = split //, $line;
        for (my $i = $length - $min ; $i >= 0 ; --$i) {
            push @{$table{join q{}, @chars[$i .. $length]}}, $line;
        }
    }
    close $fh;

    my %data;
    my %seen;
    {
        local $, = "\n";
        local $\ = "\n";
        foreach my $key (
                         map  { $_->[1] }
                         sort { $b->[0] <=> $a->[0] }
                         map  { [scalar @{$table{$_}} => $_] } keys %table
          ) {
            next if length($key) > $max;
            @{$table{$key}} = do {
                my %s;
                grep !$s{$_}++, @{$table{$key}};
            };
            my $items = @{$table{$key}};
            next if $items < $min_words;
            next if $items > $max_words;

            if ($unique) {
                @{$table{$key}} = grep { not exists $seen{$_} } @{$table{$key}};
                @{$table{$key}} or next;
                @seen{@{$table{$key}}} = ();
            }

            #print "\e[1;46m$key\e[0m";
            print "\t\t\t==$key==";
            print @{$table{$key}};
        }
    }
}
