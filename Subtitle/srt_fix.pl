#!/usr/bin/perl

# Fix subtitles translated with Google Translate

use strict;
use warnings;

use Tie::File;

my $filename = shift(@ARGV);

tie my @lines, 'Tie::File', $filename
  or die "Can't tie into file `$filename': $!";

for (@lines) {
    s/(?<!-)->/-->/g;
    /\h-->\h/
      ? do {
        s/[0-9]{2}\K:\h+(?=[0-9]{2})/:/g;
      }
      : do {
        s{</\K\h+}{}g;
        s{color\K\h*=\h*#\h*(?=[[:xdigit:]]{6})}{=#}g;
      };
}
