#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 June 2012
# https://github.com/trizen

# Find files which have exactly or *ALMOST*
# exactly the same name in a given path.

# Improved version here:
#   https://github.com/trizen/perl-scripts/blob/master/Finders/fsfn.pl

use 5.014;
use strict;
use warnings;

use File::Find qw(find);
use Getopt::Std qw(getopts);

my @dirs = grep { -d } @ARGV;
die <<"HELP" if !@dirs;
usage: $0 [options] /my/path [...]

Options:
        -f  : keep only the first file
        -l  : keep only the last file

HELP

my %opts;
if (@ARGV) {
    getopts("fl", \%opts);
}

sub compare_strings ($$) {
    my ($name1, $name2) = @_;

    return 0 if $name1 eq $name2;

    if (length($name1) > length($name2)) {
        ($name2, $name1) = ($name1, $name2);
    }

    my $len1 = length($name1);
    my $len2 = length($name2);

    my $min = int(0.5 + $len2 / 2);
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

sub find_similar_filenames (&@) {
    my $code = shift;

    my %files;
    find {
        wanted => sub {
            !(-d) && push @{$files{"key"}}, # to group files by size, change the "key" to '-s _' (unquoted)
              {
                name => do { utf8::decode($_); lc(s{\.\w+\z}{}r) },
                real_name => $File::Find::name,
              };
          }
         } => @_;

    foreach my $files (values %files) {

        next if $#{$files} < 1;

        my %dups;
        foreach my $i (0 .. $#{$files} - 1) {
            for (my $j = $i + 1 ; $j <= $#{$files} ; $j++) {
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
    find_similar_filenames {

        say @_, "-" x 80 if @_;

        foreach my $i (
                         $opts{f} ? (1 .. $#_)
                       : $opts{l} ? (0 .. $#_ - 1)
                       :            ()
          ) {
            unlink $_[$i] or warn "[error]: Can't delete: $!\n";
        }
    }
    @dirs;
}
