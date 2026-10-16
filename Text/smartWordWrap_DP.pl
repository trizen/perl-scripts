#!/usr/bin/perl

# Smart word wrap algorithm with minimum raggedness (O(N^2) non-recursive)
# See: https://en.wikipedia.org/wiki/Word_wrap#Minimum_raggedness

use 5.016;
use strict;
use warnings;

package Smart::Word::Wrap {

    sub new {
        my (undef, %args) = @_;

        my %opt = (
                   width => 6,
                   text  => '',
                  );

        foreach my $key (keys %args) {
            if (exists $opt{$key}) {
                $opt{$key} = delete $args{$key};
            }
            else {
                local $" = ', ';
                die "ERROR: invalid key-option '$key' (expected one of {@{[keys %opt]}})";
            }
        }

        bless \%opt, __PACKAGE__;
    }

    # Main smart wrap function using Dynamic Programming (O(N^2) time, O(N) space)
    sub smart_wrap {
        my ($self, %opt) = @_;

        if (%opt) {
            $self = $self->new(%{$self}, %opt);
        }

        my $width = $self->{width};
        my @raw_words =
          ref($self->{text}) eq 'ARRAY'
          ? @{$self->{text}}
          : split(' ', $self->{text});

        return '' unless @raw_words;

        # Handle words longer than width by splitting them
        my @words;
        foreach my $word (@raw_words) {
            if (length($word) > $width) {
                push @words, unpack("(A$width)*", $word);
            }
            else {
                push @words, $word;
            }
        }

        my $n      = scalar(@words);
        my @dp     = (0) x ($n + 1);
        my @parent = (0) x ($n + 1);
        my @len    = map { length($_) } @words;

        # Fill DP table from right to left (backwards)
        for (my $i = $n - 1 ; $i >= 0 ; $i--) {
            my $min_cost;
            my $best_j   = $i;
            my $line_len = $len[$i];

            for (my $j = $i ; $j < $n ; $j++) {
                if ($j > $i) {
                    $line_len += 1 + $len[$j];    # Add 1 for the space between words
                }

                if ($line_len > $width) {
                    last;                         # Exceeds line width, no need to pack more words on this line
                }

                my $cost = ($width - $line_len)**2 + $dp[$j + 1];

                if (!defined($min_cost) || $cost < $min_cost) {
                    $min_cost = $cost;
                    $best_j   = $j;
                }
            }

            $dp[$i]     = defined($min_cost) ? $min_cost : 0;
            $parent[$i] = $best_j;
        }

        # Reconstruct optimal lines using parent pointers
        my @lines;
        my $curr = 0;
        while ($curr < $n) {
            my $next = $parent[$curr];
            push @lines, join(' ', @words[$curr .. $next]);
            $curr = $next + 1;
        }

        join("\n", @lines);
    }
}

#
## Usage example
#

my $text = 'As shown in the above phases (or steps), the algorithm does many useless transformations';

my $obj = Smart::Word::Wrap->new(width => 20);

say "=>>> SMART WRAP:";
say $obj->smart_wrap(text => $text);

say "\n=>>> GREEDY WRAP (Text::Wrap):";
require Text::Wrap;
$Text::Wrap::columns = $obj->{width};
$Text::Wrap::columns += 1;
say Text::Wrap::wrap('', '', $text);

say "\n", '-' x 80, "\n";

say "=>>> SMART WRAP:";
$text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
say $obj->smart_wrap(text => $text);

say "\n=>>> GREEDY WRAP (Text::Wrap):";
say Text::Wrap::wrap('', '', $text);

