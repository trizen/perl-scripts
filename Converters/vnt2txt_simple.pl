#!/usr/bin/perl

# Author: Trizen
# License: GPLv3
# Date: 08 May 2013
# http://trizen.googlecode.com

# Convert a .vnt file to a plain text file and set the right modification time.

use strict;
use warnings;

use Date::Parse;
use File::Slurper qw(read_text write_text);

my $source = shift() // die "usage: $0 [vnt file]\n";

read_text($source) =~ /^BODY.*?:(.*?)\R^DCREATED:(\S+)\R^LAST-MODIFIED:(\S+)/ms;

write_text((my $tfile =
      join('-', unpack("A4A2A2", $2))   .
'.' . join(".", unpack("x9A2A2A2", $2)) . '.txt'), $1);

utime time(), str2time($3), $tfile, $source;
