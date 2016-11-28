#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 March 2012
# https://github.com/trizen

# Expand a string to its absolute values

use strict;
use warnings;
use Data::Dumper;

sub absolute_string ($) {
    my @chunks = grep { defined && length } split(/([{}])|,/, shift);

    my (@output, @root);
    foreach my $i (0 .. $#chunks) {
        if (defined $chunks[$i + 1] and $chunks[$i + 1] eq '{') {
            push @root, $chunks[$i];
        }
        elsif ($chunks[$i] ne '{' and $chunks[$i] ne '}') {
            push @output, join('', @root, $chunks[$i]);
        }
        if (defined $chunks[$i + 1] and $chunks[$i + 1] eq '}') {
            pop @root;
        }
    }

    return @output;
}

foreach my $x (
               'perl-{gnome2-wnck,gtk2-{imageview,unique},x11-protocol,image-exiftool}',
               'perl-{proc-{simple,processtable},net-{dbus,dropbox-api},goo-canvas}',
               'perl-{sort-naturally,json,json-xs,xml-simple,www-mechanize,locale-gettext}',
               'perl-{file-{which,basedir,copy-recursive},pathtools,path-class},mplayer'
  ) {
    print Dumper [absolute_string $x];
}
