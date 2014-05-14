#!/usr/bin/perl

# Sudoku solver
# Coded by Edmund von der Burg
# http://ecclestoad.co.uk/
# Improved by Trizen
# http://trizen.go.ro
# Latest edit on: 25 July 2011

use integer;
use strict;

sub usage {
    print "usage: $0 sudoku_file.txt\n";
    exit;
}

usage if grep { /^-+(?:h|help|usage|\?)$/ } @ARGV;

my $opened_file = 0;

if (@ARGV) {
    $opened_file = 1 if sysopen FILE, shift @ARGV, 0;
}

my $sudoku =
"53..247..
..2...8..
1..7.39.2
..8.72.49
.2.98..7.
79.....8.
.4..3.5.6
96..1.3..
.5.69..1."
  unless $opened_file;

my $file;

if ($opened_file) {
    my $i = 0;
    while (defined($_ = <FILE>)) {
        next if /^$/;
        $file .= $_;
        ++$i;
        last if $i == 9;
    }
}
else {
    my $ref = \$sudoku;

    open my $fh, '<', $ref;
    my $i = 0;
    while (defined($_ = <$fh>)) {
        next if /^$/;
        ++$i;
        $file .= $_;
        last if $i == 9;
    }
    close $fh;
}

close FILE if $opened_file;

$file =~ s/\n//g;
$file =~ s/[^1-9]/0/g;

my (@A) = split(//, $file, 0);

sub R {
    foreach my $i ( 0 .. 80 ) {
        next if $A[$i];
        my (%t) = map( {
                $_ / 9 == $i / 9
                  || $_ % 9 == $i % 9
                  || $_ / 27 == $i / 27
                  && $_ % 9 / 3 == $i % 9 / 3 ? $A[$_] : 0,
                1;
        } 0 .. 80 );
        &R( $A[$i] = $_ ) foreach ( grep { not $t{$_} } 1 .. 9 );
        return $A[$i] = 0;
    }
    &print_sudoku;
}
R;

sub print_sudoku {
    my $sudoku = join(' ', @A);
    $sudoku =~ s/([1-9 ]{17}) /$1\n/g;
    $sudoku =~ s/([1-9 ]{5}) /$1 | /g;
    my (@sudoku) = split(/\n/, $sudoku, 0);
    my $n = 0;
    foreach $_ (@sudoku) {
        print ' ', '-' x 23, "\n" if $n =~ /^(?:0|3|6|9)$/;
        print '| ', $_, " |\n";
        ++$n;
    }
    print ' ', '-' x 23, "\n";
    exit 0;
}
