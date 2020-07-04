#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15th October 2013
# http://trizenx.blogspot.com
# http://trizenx.blogspot.ro/2013/11/smart-word-wrap.html
# Email: <echo dHJpemVueEBnbWFpbC5jb20K | base64 -d>

# Smart word wrap algorithm
# See: http://en.wikipedia.org/wiki/Word_wrap#Minimum_raggedness

use 5.010;
use strict;
use warnings;

use experimental qw(signatures);

# This is the ugliest method! It, recursively,
# prepares the words for the combine() function.
sub prepare_words ($words, $width, $callback, $depth = 0) {

    my @root;
    my $len = 0;
    my $i   = -1;

    my $limit = $#{$words};
    while (++$i <= $limit) {
        $len += (my $word_len = length($words->[$i]));

        if ($len > $width) {
            if ($word_len > $width) {
                $len -= $word_len;
                splice(@$words, $i, 1, unpack("(A$width)*", $words->[$i]));
                $limit = $#{$words};
                --$i;
                next;
            }
            last;
        }

#<<<
        push @root, [
            join(' ', @{$words}[0 .. $i]),
            prepare_words([@{$words}[$i + 1 .. $limit]], $width, $callback, $depth + 1),
        ];
#>>>

        if ($depth == 0) {
            $callback->($root[0]);
            @root = ();
        }

        last if (++$len > $width);
    }

    \@root;
}

# This function combines the
# the parents with the children.
sub combine ($path, $callback, $root = []) {
    my $key = shift(@$path);
    foreach my $value (@$path) {
        push @$root, $key;
        if (@$value) {
            foreach my $item (@$value) {
                combine($item, $callback, $root);
            }
        }
        else {
            $callback->($root);
        }
        pop @$root;
    }
}

# This is the main function of the algorithm
# which calls all the other functions and
# returns the best possible wrapped string.
sub smart_wrap ($text, $width) {

    my @words = (
                 ref($text) eq 'ARRAY'
                 ? @{$text}
                 : split(' ', $text)
                );

    my %best = (
                score => 'inf',
                value => [],
               );

    prepare_words(
        \@words,
        $width,
        sub ($path) {
            combine(
                $path,
                sub ($combination) {
                    my $score = 0;
                    foreach my $line (@{$combination}[0 .. $#{$combination} - 1]) {
                        $score += ($width - length($line))**2;
                    }
                    if ($score < $best{score}) {
                        $best{score} = $score;
                        $best{value} = [@$combination];
                    }
                }
            );
        }
    );

    join("\n", @{$best{value}});
}

#
## Usage examples
#

my $text = 'aaa bb cc ddddd';
say smart_wrap($text, 6);

say '-' x 80;

$text = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
say smart_wrap($text, 20);

say '-' x 80;

$text = "Lorem ipsum dolor ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ amet, consectetur adipiscing elit.";
say smart_wrap($text, 20);

say '-' x 80;

$text = 'As shown in the above phases (or steps), the algorithm does many useless transformations';
say smart_wrap($text, 20);

say '-' x 80;

$text = 'Will Perl6 also be pre-installed on future Mac/Linux operating systems? ... I can\'t predict the success of the project';
say smart_wrap($text, 20);

say '-' x 80;

say smart_wrap(['a' .. 'n'], 5);
