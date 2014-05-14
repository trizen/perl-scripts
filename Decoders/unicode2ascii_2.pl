#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 29 April 2012
# http://trizen.googlecode.com

# Substitute Unicode characters with ASCII characters in files

# WARNING! No backup files are created!

use 5.010;
use strict;
use warnings;

use File::Find qw(find);
use File::Slurp qw(read_file);
use Text::Unidecode qw(unidecode);

if ((my @dirs = grep { -d } @ARGV)) {
    find {
          no_chdir => 1,
          wanted   => sub { push @ARGV, $_ if -f }
         } => @dirs;
}

foreach my $file (grep { -T } @ARGV) {

    open my $fh, '<:utf8', $file or die $!;
    my $content = read_file($fh);
    $content = unidecode($content);

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

    open my $out_fh, '>', $file or do { warn "Can't open $file for write: $!"; next };
    print $out_fh $content;
    close $out_fh;
}
