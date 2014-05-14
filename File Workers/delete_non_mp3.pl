#!/usr/bin/perl

use strict;
use warnings;

use File::Find qw(find);

find {
    wanted => sub {
        if (not /\.mp3$/i and -f) {
            print "[DELETING]: $_\n";
            unlink or warn "\t[ERROR]: $!";
        }
    },
    no_chdir => 1,
  } => @ARGV
