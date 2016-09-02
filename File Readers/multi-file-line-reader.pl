#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 April 2012
# https://github.com/trizen

# If you saw this code on perlmonks.org,
# posted by an Anonymous Monk, that was me.

my (@files) = @ARGV ? @ARGV : ($0, $0);

my @fh;
my $i = 0;

foreach my $file (@files) {
    next unless -f -r $file;
    open $fh[$i++], '<', $file
      or die "Cannot open ${file}: $!";
}

while (1) {
    my @lines;

    foreach my $i (0 .. $#fh) {

        next unless ref $fh[$i] eq 'GLOB';
        push @lines, scalar readline $fh[$i];

        if (eof $fh[$i]) {
            close $fh[$i];
            $fh[$i] = undef;
        }
    }

    last unless @lines;

    foreach my $line (@lines) {
        print $line;
    }
}
