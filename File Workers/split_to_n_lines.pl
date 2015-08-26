#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Website: https://github.com/trizen

# Split a text file into sub files of 'n' lines each other

use strict;
use warnings;

use Getopt::Std qw(getopts);
use File::Spec::Functions qw(catfile);

my %opts;
getopts('l:', \%opts);

my $lines_n = $opts{l} ? int($opts{l}) : 100;

if (not @ARGV) {
    die "Usage: $0 -l [i] <files>\n";
}

sub print_to_file {
    my ($array_ref, $foldername, $num) = @_;
    open(my $out_fh, '>', catfile($foldername, "$num.txt")) or return;
    print $out_fh @{$array_ref};
    close $out_fh;
    return 1;
}

foreach my $filename (@ARGV) {

    -f $filename or do {
        warn "$0: skipping '$filename': is not a file\n";
        next;
    };

    my $foldername = $filename;
    if (not $foldername =~ s/\.\w{1,5}$//) {
        $foldername .= '_files';
    }

    if (-d $foldername) {
        warn "$0: directory '${foldername}' already exists...\n";
        next;
    }
    else {
        mkdir $foldername or do {
            warn "$0: Can't create directory '${foldername}': $!\n";
            next;
        };
    }

    open my $fh, '<', $filename or do {
        warn "$0: Can't open file '${filename}' for read: $!\n";
        next;
    };

    my @lines;
    my $num = 0;
    while (defined(my $line = <$fh>)) {

        push @lines, $line;

        if (@lines == $lines_n or eof $fh) {
            print_to_file(\@lines, $foldername, ++$num);
            undef @lines;
        }
    }
    close $fh;
}
