#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 12 June 2015
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

use List::Util qw(first);

sub split_entry {
    ((map { s/^[[:punct:]]+//r =~ s/[[:punct:]]+\z//r } split(' ', $_[0])), split(/\W+/, $_[0]));
}

sub update_model {
    my ($model, $entry) = @_;

    foreach my $word (split_entry(lc($entry))) {
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
    $entry = lc($entry);

    my (@matches, @words);
    foreach my $word (split_entry($entry)) {

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

        if (defined($ref) and exists($ref->{values})) {
            push @words,   $word;
            push @matches, @{$ref->{values}};
        }
        else {
            @matches = ();    # don't include partial matches
            last;
        }
    }

    # Filter matches to make sure they include all words
    @matches = grep {
        my $str = lc(${$_});
        not defined(first { index($str, $_) == -1 } @words);
    } @matches;

    # Sort and return the matches
    my %seen;
    map    { $_->[0] }
      sort { $b->[1] <=> $a->[1] }
      map {
        [${$_},

         do {
             my $str = lc(${$_});

             (    # Calculate a score for each match
                ((($str =~ s/\W+//gr) ^ ($entry =~ s/\W+//gr)) =~ /^[\0]+/ ? $+[0]**2 : 0) +
                  scalar(grep { $str =~ /\b\Q$_\E\b/i } @words)**2 +
                  scalar(grep { $str =~ /\b\Q$_\E/i } @words)
             );
           }
        ]
      } grep { !$seen{$_}++ } @matches;
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
