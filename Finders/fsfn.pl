#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 June 2013
# Improved: 18 October 2014
# Latest edit on: 18 October 2015
# Website: https://github.com/trizen

# Find files which have exactly or *ALMOST* exactly
# the same name in a given path (+Levenshtein distance).

# Review:
#    http://trizenx.blogspot.com/2013/06/finding-similar-file-names.html

# To move files into another directory, please see:
#    https://github.com/trizen/perl-scripts/blob/master/File%20Workers/file-mover.pl

use 5.014;
use strict;
use warnings;

use File::Find qw(find);
use List::Util qw(first min max);
use Encode qw(decode_utf8);
use Getopt::Long qw(GetOptions :config no_ignore_case);

sub help {
    my ($code) = @_;

    print <<"HELP";
usage: $0 [options] /my/path [...]

Options:
        -f  --first!         : keep only the first file from each group
        -l  --last!          : keep only the last file from each group
        -g  --groups=[s]     : group individually files which contain this words
        -G  --nogroups=[s]   : group together files which contain this words
        -c  --contains=[s]   : ignore files which doesn't contain this words
        -C  --nocontains=[s] : ignore files which contain this words
        -i  --insensitive    : make all words case-insensitive
        -s  --size!          : group files by size (default: off)
        -p  --percentage=f   : mark the files as similar based on this percent
        -r  --round-up!      : round up the percentange (default: off)
        -L  --levenshtein    : use the Levenshtein distance alogorithm
        -J  --jaro           : use the Jaro distance algorithm

Usage example:
    $0 --percentage=75 ~/Music

NOTE:
    The values for -c, -C, -g and -G are regular expressions.
    Each of the above options can be specified more than once.

WARNING:
    Options '-f' and '-l' will, permanently, delete your files!
HELP

    exit($code);
}

my @groups;
my @no_groups;

my @contains;
my @no_contains;

my $first         = 0;    # bool
my $last          = 0;    # bool
my $round_up      = 0;    # bool
my $group_by_size = 0;    # bool
my $insensitive   = 0;    # bool
my $levenshtein   = 0;    # bool
my $jaro_distance = 0;    # bool
my $percentage;           # float

GetOptions(
           'f|first!'       => \$first,
           'l|last!'        => \$last,
           'g|groups=s'     => \@groups,
           'G|nogroups=s'   => \@no_groups,
           'c|contains=s'   => \@contains,
           'C|nocontains=s' => \@no_contains,
           'r|round-up!'    => \$round_up,
           'i|insensitive!' => \$insensitive,
           'p|percentage=f' => \$percentage,
           'L|levenshtein!' => \$levenshtein,
           'J|jaro!'        => \$jaro_distance,
           's|size!'        => \$group_by_size,
           'h|help'         => sub { help(0) },
          )
  or die("Error in command line arguments");

@groups      = map { $insensitive ? qr/$_/i : qr/$_/ } (@groups, '.');
@no_groups   = map { $insensitive ? qr/$_/i : qr/$_/ } @no_groups;
@contains    = map { $insensitive ? qr/$_/i : qr/$_/ } @contains;
@no_contains = map { $insensitive ? qr/$_/i : qr/$_/ } @no_contains;

# Determine what algorithm to use for comparison
my $algorithm = $levenshtein ? \&lev_cmp : $jaro_distance ? \&jaro_cmp : \&index_cmp;

# Default percentage
$percentage //= $jaro_distance ? 70 : 50;

sub index_cmp ($$) {
    my ($name1, $name2) = @_;

    return 0 if $name1 eq $name2;

    my ($len1, $len2) = (length($name1), length($name2));
    if ($len1 > $len2) {
        ($name2, $len2, $name1, $len1) = ($name1, $len1, $name2, $len2);
    }

    my $min =
      $round_up
      ? int($percentage / 100 + $len2 * $percentage / 100)
      : int($len2 * $percentage / 100);

    return -1 if $min > $len1;

    my $diff = $len1 - $min;
    foreach my $i (0 .. $diff) {
        foreach my $j ($i .. $diff) {
            if (index($name2, substr($name1, $i, $min + $j - $i)) != -1) {
                return 0;
            }
        }
    }

    return -1;
}

# Levenshtein's distance function (optimized for speed)
sub lev_cmp ($$) {
    my ($s, $t) = @_;

    my $len1 = @$s;
    my $len2 = @$t;

    my ($min, $max) = $len1 < $len2 ? ($len1, $len2) : ($len2, $len1);

    my $diff =
      $round_up
      ? int($percentage / 100 + $max * (100 - $percentage) / 100)
      : int($max * (100 - $percentage) / 100);

    return -1 if ($max - $min) > $diff;

    my @d = ([0 .. $len2], map { [$_] } 1 .. $len1);
    foreach my $i (1 .. $len1) {
        foreach my $j (1 .. $len2) {
            $d[$i][$j] =
                $$s[$i - 1] eq $$t[$j - 1]
              ? $d[$i - 1][$j - 1]
              : min($d[$i - 1][$j], $d[$i][$j - 1], $d[$i - 1][$j - 1]) + 1;
        }
    }

    ($d[-1][-1] // $min) <= $diff ? 0 : -1;
}

sub jaro_cmp($$) {
    my ($string1, $string2) = @_;

    my $len1 = @{$string1};
    my $len2 = @{$string2};

    ($string1, $len1, $string2, $len2) = ($string2, $len2, $string1, $len1)
      if $len1 > $len2;

    $len1 || return -1;

    my $diff =
      $round_up
      ? int($percentage / 100 + $len2 * (100 - $percentage) / 100)
      : int($len2 * (100 - $percentage) / 100);

    return -1 if ($len2 - $len1) > $diff;

    my $match_window = $len2 > 3 ? int($len2 / 2) - 1 : 0;

    my @string1_matches;
    my @string2_matches;

    my @chars1 = @{$string1};
    my @chars2 = @{$string2};

    foreach my $i (0 .. $#chars1) {

        my $window_start = max(0, $i - $match_window);
        my $window_end = min($i + $match_window + 1, $len2);

        foreach my $j ($window_start .. $window_end - 1) {
            if (not exists($string2_matches[$j]) and $chars1[$i] eq $chars2[$j]) {
                $string1_matches[$i] = $chars1[$i];
                $string2_matches[$j] = $chars2[$j];
                last;
            }
        }
    }

    (@string1_matches = grep { defined } @string1_matches) || return -1;
    @string2_matches = grep { defined } @string2_matches;

    my $transpositions = 0;
    foreach my $i (0 .. $#string1_matches) {
        $string1_matches[$i] eq $string2_matches[$i] or ++$transpositions;
    }

    my $num_matches = @string1_matches;
#<<<
    ((($num_matches / $len1)
    + ($num_matches / $len2)
    + ($num_matches - int($transpositions / 2))
    / $num_matches) / 3 * 100) >= $percentage ? 0 : -1;
#<<<
}

sub find_similar_filenames (&@) {
    my $code = shift;

    my %files;
    find {
        wanted => sub {

            if (@contains) {
                defined(first { $File::Find::name =~ $_ } @contains) || return;
            }
            if (@no_contains) {
                defined(first { $File::Find::name =~ $_ } @no_contains) && return;
            }

            (-f)
              && push @{$files{$group_by_size ? (-s _) : 'key'}}, {
                name => do {
                    my $str = join(' ', split(' ', lc(decode_utf8($_) =~ s{\.\w{1,5}\z}{}r =~ s/[^\pN\pL]+/ /gr)));
                    ($levenshtein || $jaro_distance) ? [$str =~ /\X/g] : $str;
                },
                real_name => $File::Find::name,
                                                                  };
          }
         } => @_;

    foreach my $files (values %files) {

        next if $#{$files} < 1;

        my %dups;
        my @files;
        foreach my $i (0 .. $#{$files} - 1) {
            for (my $j = $i + 1 ; $j <= $#{$files} ; $j++) {

                if (defined(my $word1 = first { $files->[$i]{real_name} =~ $_ } @groups)) {
                    if (defined(my $word2 = first { $files->[$j]{real_name} =~ $_ } @groups)) {
                        next if $word1 ne $word2;
                    }
                }

                if ($algorithm->($files->[$i]{name}, $files->[$j]{name}) == 0) {
                    if (    defined(first { $files->[$i]{real_name} =~ $_ } @no_groups)
                        and defined(first { $files->[$j]{real_name} =~ $_ } @no_groups)) {
                        push @files, $files->[$i]{real_name}, ${splice @{$files}, $j--, 1}{real_name};
                    }
                    else {
                        push @{$dups{$files->[$i]{real_name}}}, ${splice @{$files}, $j--, 1}{real_name};
                    }
                }
            }
        }

        while (my ($fparent, $fdups) = each %dups) {
            $code->(sort $fparent, @{$fdups});
        }

        $code->(
            do {
                my %seen;
                sort grep { !$seen{$_}++ } @files;
              }
        );
    }

    return 1;
}

{
    @ARGV || help(1);
    local $, = "\n";
    find_similar_filenames {

        say @_, "-" x 80 if @_;

        foreach my $i (
                         $first ? (1 .. $#_)
                       : $last  ? (0 .. $#_ - 1)
                       :          ()
          ) {
            unlink $_[$i] or warn "[error]: Can't delete: $!\n";
        }
    }
    @ARGV;
}
