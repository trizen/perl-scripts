#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Remove newline characters from the end of files

# WARNING: No backup files are created!

use strict;
use warnings;
use Tie::File;

foreach my $filename (grep { -f } @ARGV) {

    print "** Processing $filename\n";

    tie my @file, 'Tie::File', $filename
        or die "Unable to tie: $!\n";

    pop @file while $file[-1] eq q{};

    untie @file
        or die "Unable to untie: $!\n";

    print "** Done.\n\n";
}
