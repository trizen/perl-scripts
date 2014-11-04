#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 June 2013
# Improved: 18 October 2014
# Latest edit on: 04 November 2014
# http://github.com/trizen

# Find files which have exactly or *ALMOST* exactly
# the same name in a given path (using Levenshtein distance).

use 5.014;
use strict;
use warnings;

use File::Find qw(find);
use List::Util qw(first min max);
use Encode qw(decode_utf8);
use Getopt::Long qw(GetOptions);

sub help {
    my ($code) = @_;

    print <<"HELP";
usage: $0 [options] /my/path [...]

Options:
        -f  --first!        : keep only the first file from each group
        -l  --last!         : keep only the last file from each group
        -w  --words=s,s     : group individually files which contain this words
        -i  --insensitive   : make all words case-insensitive
        -s  --size!         : group files by size (default: off)
        -p  --percentage=i  : mark the files as similar based on this percent
        -r  --round-up!     : round up the percentange (default: off)

Example:
    $0 --percentage=75 ~/Pictures

WARNING:
    Options '-f' and '-l' will, permanently, delete your files!
HELP

    exit($code // 0);
}

my @words;

my $first         = 0;     # bool
my $last          = 0;     # bool
my $round_up      = 0;     # bool
my $group_by_size = 0;     # bool
my $insensitive   = 0;     # bool
my $percentage    = 50;    # int

GetOptions(
           'f|first!'       => \$first,
           'l|last!'        => \$last,
           'w|words=s{1,}'  => \@words,
           'r|round-up!'    => \$round_up,
           'i|insensitive!' => \$insensitive,
           'p|percentage=i' => \$percentage,
           's|size!'        => \$group_by_size,
           'h|help'         => \&help,
          )
  or die("Error in command line arguments");

@words = map { $insensitive ? qr/$_/i : qr/$_/ } (@words, '.');

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

    ($d[-1][-1] // $min) <= $diff ? 0 : 1;
}

sub find_duplicated_files (&@) {
    my $code = shift;

    my %files;
    find {
        wanted => sub {
            (-f)
              && push @{$files{$group_by_size ? (-s _) : 'key'}}, {
                name => [split //, join(' ', split(' ', lc(decode_utf8($_) =~ s{\.\w{1,5}\z}{}r)))],    # \
                real_name => $File::Find::name,
                                                                  };
          }
         } => @_;

    foreach my $files (values %files) {

        next if $#{$files} < 1;

        my %dups;
        foreach my $i (0 .. $#{$files} - 1) {
            for (my $j = $i + 1 ; $j <= $#{$files} ; $j++) {

                if (defined(my $word1 = first { $files->[$i]{real_name} =~ $_ } @words)) {
                    if (defined(my $word2 = first { $files->[$j]{real_name} =~ $_ } @words)) {
                        next if $word1 ne $word2;
                    }
                }

                if (lev_cmp($files->[$i]{name}, $files->[$j]{name}) == 0) {
                    push @{$dups{$files->[$i]{real_name}}}, ${splice @{$files}, $j--, 1}{real_name};
                }
            }
        }

        while (my ($fparent, $fdups) = each %dups) {
            $code->(sort $fparent, @{$fdups});
        }
    }

    return 1;
}

{
    (my @dirs = grep { -d } @ARGV) || help(1);
    local $, = "\n";
    find_duplicated_files {

        say @_, "-" x 80 if @_;

        foreach my $i (
                         $first ? (1 .. $#_)
                       : $last  ? (0 .. $#_ - 1)
                       :          ()
          ) {
            unlink $_[$i] or warn "[error]: Can't delete: $!\n";
        }
    }
    @dirs;
}
