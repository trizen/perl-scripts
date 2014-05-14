#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 15 March 2012

# Find perl scripts in a directory and its subdirectories

use 5.010;
use File::Find qw(find);

my @dirs = grep { -d } @ARGV or die "usage: $0 [dirs]\n";

find {
    wanted => sub {
        if (/\.p[lm]$/i) { say }
        elsif (-T and open my $fh, '<', $_) {
            my $head = <$fh> || return;
            if ($head =~ m{^\s*#\s*!.*\bperl\d*\b}) { say }
        }
    },
    no_chdir => 1
}, @dirs
