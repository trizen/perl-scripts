#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 April 2012
# https://github.com/trizen

# Substitute Unicode characters with ASCII characters in text files

# WARNING! No backup files are created!

use 5.010;
use strict;
use warnings;

use File::Find qw(find);
use Text::Unidecode qw(unidecode);
use File::Slurper qw(read_text write_text);

if ((my @dirs = grep { -d } @ARGV)) {
    find {
          no_chdir => 1,
          wanted   => sub { push @ARGV, $_ if -f }
         } => @dirs;
}

foreach my $file (grep { -T } @ARGV) {

    my $content = unidecode(read_text($file, 'utf8'));

=some substitutions
    study $content;
    $content =~ s/^_{3,} _{3,}$//gm;
    $content =~ s/^(\S)\1*$//gm;
    $content =~ s/^-{2,}\s+\d+\s*$//gm;
    $content =~ s/[^\t\n [:^cntrl:]]+//g;
    $content =~ s/"{2,}/"/g;
    $content =~ s/'{2,}/'/g;
    $content =~ s/\n{3,}/\n\n/g;
    $content =~ s/,,/ /g;
    $content =~ s/^\s+//;
    1 while $content =~ s/\n(.+)\n{2,}(.+)\n{2,}/\n$1\n$2\n/;
=cut

    write_text($file, $content);
}
