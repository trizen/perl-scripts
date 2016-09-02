#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 October 2012
# Edit: 23 June 2013
# https://github.com/trizen

# Unidecode filename renamer.
# Ex: fișier.mp3 -> fisier.mp3

# Usage: unidec_renamer.pl -r <dirs>

use utf8;
use 5.005;
use strict;
use warnings;

use File::Find qw(find);
use Getopt::Std qw(getopts);
use File::Basename qw(basename);
use Text::Unidecode qw(unidecode);
use File::Spec::Functions qw(catfile catdir splitdir);

my %opts;
getopts('r', \%opts);

my @dirs = grep { -d } @ARGV;
@dirs || die "usage: $0 [-r] <dir>\n";

binmode(STDOUT, ':utf8');

sub rename_file {
    my ($filename, $new_filename) = @_;

    if (not -e $new_filename) {
        rename $filename, $new_filename
          or do { warn "Can't rename: $!\n"; return };
    }
    else {
        warn "'$new_filename' already exists! Skipping...\n";
    }
    return 1;
}

my @dirs_for_rename;
find {
    no_chdir => 1,
    wanted   => sub {
        my $filename = basename($File::Find::name);

        utf8::decode($filename);
        my $new_name = unidecode($filename);

        if ($filename ne $new_name) {
            my $dir = $File::Find::dir;
            utf8::decode($dir);

            print "[", qw(DIR FILE) [-f $_], "] $filename -> $new_name\n";

            my $new_filename = (-f _) ? catfile($dir, $new_name) : do {
                push @dirs_for_rename, [$_, ($dir eq $filename ? $new_name : catdir($dir, $new_name))];
                return;
            };

            if ($opts{r}) {
                rename_file($_ => $new_filename);
            }
        }
    },
} => @dirs;

if ($opts{r}) {
    foreach my $array_ref (
                           map  { $_->[1] }
                           sort { $b->[0] <=> $a->[0] }
                           map  { [scalar(splitdir($_->[0])), $_] } @dirs_for_rename
      ) {
        rename_file($array_ref->[0], $array_ref->[1]);
    }
}
