#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date : 21 February 2013
# https://github.com/trizen

# XPM to Perl data.
# for file in `find /usr/share/pixmaps/ -maxdepth 1`; do perl -X xpm_c_to_perl.pl $file > $(basename $file); done

use strict;
use Data::Dump qw(dump);
$Data::Dump::INDENT = '';

sub parse_xpm_file {
    my ($file) = @_;

    open my $fh, '<', $file
      or die "Can't open file '$file': $!";

    my @data;
    while (<$fh>) {
        if (/^"(.*?)",?\s*(\};\s*)?$/s) {
            push @data, $1;
        }
        else {
            #print STDERR $_;
        }
    }

    close $fh;
    my $dumped = dump \@data;

    # In list context returns the dumped data and the array itself.
    # In scalar context returns only the dumped data
    return wantarray ? ($dumped, \@data) : $dumped;
}

my $xpm_file = shift // die "usage: $0 [xpm_file]\n";
$xpm_file =~ /\.xpm\z/i or die "Not a XPM file: $xpm_file\n";
my $data = parse_xpm_file($xpm_file);
print $data;
