#!/usr/bin/perl

# Factorize a given number, using the `YAFU` tool, and parse the output into an array of `Math::GMPz` objects.

# See also:
#   https://sourceforge.net/projects/yafu/

use 5.020;
use strict;
use warnings;
use Math::GMPz;

use experimental qw(signatures);
use File::Spec::Functions qw(rel2abs curdir tmpdir);

sub yafu_factor ($n) {

    $n = Math::GMPz->new($n);    # validate the number

    my $dir = rel2abs(curdir());

    chdir(tmpdir());
    my $output = qx(yafu 'factor($n)');
    chdir($dir);

    my @factors;

    while ($output =~ /^P\d+ = (\d+)/mg) {
        push @factors, Math::GMPz->new($1);
    }

    return sort { $a <=> $b } @factors;
}

my $n = shift() || die "usage: $0 [n]\n";

my @factors = yafu_factor($n);
say "$n = [", join(', ', @factors), ']';
