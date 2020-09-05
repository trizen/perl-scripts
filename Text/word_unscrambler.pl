#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 05 September 2020
# https://github.com/trizen

# Find words in a given scrambled word, using a dictionary.

use 5.020;
use strict;
use warnings;

use open IO => ':utf8', ':std';

use Term::ReadLine;
use List::Util qw(min uniq);
use Algorithm::Combinatorics qw(combinations);
use experimental qw(signatures);
use Encode qw(decode_utf8);

my $dict_file = '/usr/share/dict/words';

my $unidecode        = 0;    # plain ASCII transliterations of Unicode text
my $group_by_length  = 1;    # group words by length
my $case_insensitive = 0;    # case-insensitive mode

my $min_length = 3;          # minimum number of letters a word must have
my $max_length = 0;          # maximum number of letters a word must have (0 for no limit)

sub normalize_word ($word) {

    if ($unidecode) {        # Unicode to ASCII
        require Text::Unidecode;
        $word = Text::Unidecode::unidecode($word);
    }

    if ($case_insensitive) {
        $word = CORE::fc($word);
    }

    return $word;
}

sub create_optimized_dictionary ($file) {

    open my $fh, '<:utf8', $file
      or die "Can't open file <<$file>> for reading: $!";

    my %dict;

    while (defined(my $line = <$fh>)) {

        $line =~ s{/\w+}{};

        my @words = split(' ', $line);

        foreach my $word (@words) {

            # Ignore too short words
            if ($min_length > 0 and length($word) < $min_length) {
                next;
            }

            # Ignore too long words
            if ($max_length > 0 and length($word) > $max_length) {
                next;
            }

            $word = normalize_word($word);

            # Add the word into the hash table
            push(@{$dict{join('', sort split(//, $word))}}, $word);
        }
    }

    close $fh;
    return \%dict;    # return dictionary
}

sub find_unscrambled_words ($word, $dict) {

    $word = normalize_word($word);

    my @found;
    my @chars = sort split(//, $word);    # split word into characters

    foreach my $k (($min_length || 1) .. min($max_length || scalar(@chars), scalar(@chars))) {

        # Create combination of words of k characters
        my $iter = combinations(\@chars, $k);

        while (my $arr = $iter->next) {

            my $unscrambled = join('', @$arr);

            # Check each combination if it exists inside the dictionary
            if (exists $dict->{$unscrambled}) {

                # Store the words made from this combination of letters
                push @found, @{$dict->{$unscrambled}};
            }
        }
    }

    return uniq(@found);
}

my $dict = create_optimized_dictionary($dict_file);
my $term = Term::ReadLine->new("Word Unscrambler");

while (1) {

    chomp(my $word = decode_utf8($term->readline("Word: ")));

    my @unscrambled = find_unscrambled_words($word, $dict);

    my %groups;
    foreach my $word (@unscrambled) {
        push @{$groups{length($word)}}, $word;
    }

    say '';
    foreach my $len (sort { $b <=> $a } keys %groups) {

        if ($group_by_length) {
            say join(" ", sort @{$groups{$len}});
        }
        else {
            say for sort @{$groups{$len}};
        }
    }
    say '';
}
