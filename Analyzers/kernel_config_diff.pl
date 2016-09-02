#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 16 March 2013
# https://github.com/trizen

# List activated options from config_2, which are
# not activated in config_1, or have different values.

# Will print them in CSV format.

use 5.010;
use strict;
use autodie;
use warnings;

use Text::CSV qw();

$#ARGV == 1 or die <<"USAGE";
usage: $0 [config_1] [config_2]
USAGE

my ($config_1, $config_2) = @ARGV;

sub parse_option {
    my ($line) = @_;

    if ($line =~ /^(CONFIG_\w+)=(.*)$/) {
        return $1, $2;
    }
    elsif ($line =~ /^# (CONFIG_\w+) is not set$/) {
        return $1, undef;
    }
    elsif ($line =~ /^\W*CONFIG_\w/) {
        die "ERROR: Can't parse line: $line\n";
    }

    return;
}

my %table;
{
    open my $fh, '<', $config_1;
    while (<$fh>) {

        my ($name, $value) = parse_option($_);
        $name // next;

        $table{$name} = $value;
    }
}

{
    my $csv = Text::CSV->new({binary => 1, eol => "\n"})
      or die "Cannot use CSV: " . Text::CSV->error_diag();

    $csv->print(\*STDOUT, ["OPTION NAME", $config_1, $config_2]);

    open my $fh, '<', $config_2;
    while (<$fh>) {

        my ($name, $value) = parse_option($_);
        $name // next;

        if (defined $value) {
            if (not defined $table{$name}) {
                $csv->print(\*STDOUT, [$name, (exists $table{$name} ? "is not set" : "-"), $value]);
            }
            else {
                if ($table{$name} ne $value) {
                    $csv->print(\*STDOUT, [$name, $table{$name}, $value]);
                }
            }
        }

    }
}
