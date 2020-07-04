#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 April 2014
# http://trizenx.blogspot.com

# Inspired from: Cosmos.A.Space.Time.Odyssey.S01E01
#                            by Neil deGrasse Tyson

use 5.010;
use strict;
use warnings;

use Term::ReadLine;

# Here is the definition of the cosmic year
my @cosmic_year = [(13.798 + [+0.037, -0.037]->[rand 2]) * 10**9, 'years'];

push @cosmic_year, [$cosmic_year[-1][0] / 12,         'months'];
push @cosmic_year, [$cosmic_year[-1][0] / 30.4368499, 'days'];
push @cosmic_year, [$cosmic_year[-1][0] / 24,         'hours'];
push @cosmic_year, [$cosmic_year[-1][0] / 60,         'minutes'];
push @cosmic_year, [$cosmic_year[-1][0] / 60,         'seconds'];
push @cosmic_year, [$cosmic_year[-1][0] / 1000,       'milliseconds'];

print <<'EOF';
This program will scale the age of the universe to a normal year.

You can insert any number you want, and the program will map it
into this cosmic year to have a feeling how long ago it was,
compared to the age of the universe.

EOF

sub output {
    my ($value, $type) = @_;
    printf "\n=> In the cosmic scale, that happened about %.2f %s ago!\n\n", $value, $type;
}

BLOCK: {
    my $term  = Term::ReadLine->new('Cosmic Calendar');
    my $value = eval $term->readline("How long ago? (any expression, in years): ");

    foreach my $bit (@cosmic_year) {
        $value >= $bit->[0]
            && output($value / $bit->[0], $bit->[1])
            && redo BLOCK;
    }

    warn "\n[!] Your value `$value' is too small, compared to the Cosmic Calendar!\n\n";
    redo;
}
