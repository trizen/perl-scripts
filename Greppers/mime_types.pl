#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 10 January 2014
# http://trizenx.blogspot.com
# List the available categories and mime-types from .desktop files

# usage: perl mime_types.pl [Category]

use 5.016;
use strict;
use warnings;

my %opt;
if (@ARGV) {
    require Getopt::Std;
    Getopt::Std::getopts('hj', \%opt);
}

sub help {
    print <<"EOF";
usage: $0 [options] [Category]

options:
        -j  : join the results with a semicolon (;)
        -h  : print this message and exit

example:
        perl $0              # displays the available categories
        perl $0 Audio        # displays the Audio mime-types
        perl $0 -j Video     # displays the Video mime-types joined in one line
EOF
    exit;
}

help() if $opt{h};

my @desktop_files = grep { /\.desktop\z/ }
                    glob('/usr/share/applications/*');

my %table;
foreach my $file (@desktop_files) {
    sysopen(my $fh, $file, 0) || next;
    sysread($fh, (my $content), -s $file);

    if ((my $p = index($content, "\n[",
        (my $i = index($content, '[Desktop Entry]') + 2**4))) != -1) {
        $content = substr($content, $i, $p - $i);
    }

    my @cats  = $content =~ /^Categories=(.+)/m ? split(/;/, $1) : ();
    my @types = $content =~ /^MimeType=(.+)/m   ? split(/;/, $1) : ();

    foreach my $cat (@cats) {
        @{$table{$cat}}{@types} = ();
    }
}

{
    {
        local $\ = $opt{j} ? ';' : "\n";
        if (@ARGV && exists $table{$ARGV[0]}) {
            foreach my $type (sort keys %{$table{$ARGV[0]}}) {
                print $type;
            }
        }
        else {
            foreach my $category (sort { fc($a) cmp fc($b) } keys %table) {
                print $category;
            }
        }
    }

    $opt{j} && print "\n";
}
