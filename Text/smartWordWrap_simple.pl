#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15th October 2013
# http://trizenx.blogspot.com
# Email: <echo dHJpemVueEBnbWFpbC5jb20K | base64 -d>

# Smart word wrap algorithm
# See: http://en.wikipedia.org/wiki/Word_wrap#Minimum_raggedness

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

    # This is the ugliest function! It, recursively,
    # prepares the words for the combine() function.
    sub prepare_words {
        my ($self, @array) = @_;

        my @root;
        my $len = 0;

        for (my $i = 0 ; $i <= $#array ; $i++) {
            $len += (my $wordLen = length($array[$i]));

            if ($len > $self->{width}) {
                if ($wordLen > $self->{width}) {
                    $len -= $wordLen;
                    splice(@array, $i, 1, unpack "(A$self->{width})*", $array[$i]);
                    $i--, next;
                }
                last;
            }

            push @root, {"@array[0 .. $i]" => __SUB__->($self, @array[$i + 1 .. $#{array}])};
            last if ++$len >= $self->{width};
        }

        @root ? \@root : undef;
    }

    # This function combines the
    # the parents with the children.
    sub combine {
        my ($root, $hash) = @_;

        my @row;
        while (my ($key, $value) = each %{$hash}) {
            push @{$root}, $key;

            if (ref $value eq 'ARRAY') {
                foreach my $item (@{$value}) {
                    push @row, __SUB__->($root, $item);
                }
            }
            else {
                @row = [@{$root}];
            }

            pop @{$root};
        }

        @row;
    }

    # This function finds the best
    # combination available and returns it.
    sub find_best {
        my ($self, @arrays) = @_;

        my %best = (
                    score => 'inf',
                    value => [],
                   );

        foreach my $array_ref (@arrays) {

            my $score = 0;
            foreach my $string (@{$array_ref}) {
                $score += ($self->{width} - length($string))**2;
            }

            if ($score < $best{score}) {
                $best{score} = $score;
                $best{value} = $array_ref;
            }
        }

        @{$best{value}};
    }

    # This is the main function of the algorithm
    # which calls all the other functions and
    # returns the best possible wrapped string.
    sub smart_wrap {
        my ($self, %opt) = @_;

        if (%opt) {
            $self = $self->new(%{$self}, %opt);
        }

        my @words =
          ref($self->{text}) eq 'ARRAY'
          ? @{$self->{text}}
          : split(' ', $self->{text});

        join "\n", $self->find_best(map { combine([], $_) } @{$self->prepare_words(@words)});
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
