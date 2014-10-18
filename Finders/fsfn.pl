#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 June 2013
# Improved: 18 October 2014
# http://github.com/trizen

# Find files which have exactly or *ALMOST*
# exactly the same name in a given path.

use 5.014;
use strict;
use warnings;

use File::Find qw(find);
use Encode qw(decode_utf8);
use List::Util qw(first);
use Getopt::Long qw(GetOptions);

my @dirs = grep { -d } @ARGV;
die <<"HELP" if !@dirs;
usage: $0 [options] /my/path [...]

Options:
        -f  --first!        : keep only the first file from each group
        -l  --last!         : keep only the last file from each group
        -w  --words=s,s     : group individually files which contain this words
        -r  --round-up!     : round up the percentange (default: off)
        -p  --percentage=i  : mark the files as similar if they are at least i% the same

Example:
    $0 --percentage=75 ~/Pictures
HELP

my @words;

my $first      = 0;     # bool
my $last       = 0;     # bool
my $round_up   = 0;     # bool
my $percentage = 50;    # int

GetOptions(
           'f|first!'       => \$first,
           'l|last!'        => \$last,
           'w|words=s{1,}'  => \@words,
           'r|round-up!'    => \$round_up,
           'p|percentage=i' => \$percentage,
          )
  or die("Error in command line arguments");

sub compare_strings ($$) {
    my ($name1, $name2) = @_;

    return 0 if $name1 eq $name2;

    if (length($name1) > length($name2)) {
        ($name2, $name1) = ($name1, $name2);
    }

    my $len1 = length($name1);
    my $len2 = length($name2);

    my $min =
      $round_up
      ? int($percentage / 100 + $len2 / (100 / $percentage))
      : int($len2 / (100 / $percentage));

    return -1 if $min > $len1;

    my $diff = $len1 - $min;
    foreach my $i (0 .. $diff) {
        foreach my $j ($i .. $diff) {
            if (index($name2, substr($name1, $i, $min + $j - $i)) != -1) {
                return 0;
            }
        }
    }

    return 1;
}

sub find_duplicated_files (&@) {
    my $code = shift;

    my %files;
    find {
        wanted => sub {
            !(-d) && push @{$files{"key"}},    # to group files by size, change the "key" to '-s _' (unquoted)
              {
                name      => do { join(' ', split(' ', lc(decode_utf8($_) =~ s{\.\w+\z}{}r))) },
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

                if (compare_strings($files->[$i]{name}, $files->[$j]{name}) == 0) {
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
