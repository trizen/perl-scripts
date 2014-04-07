#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 07 April 2014
# Website: http://github.com/trizen

# Read raw data from microphone (via ALSA/arecord)

use 5.010;
use strict;
use warnings;

use Time::HiRes qw(sleep);

use constant {
        HW_PARAMS_FILE => '/proc/asound/card0/pcm0c/sub0/hw_params',
};

open(my $pipe_h, '-|', 'arecord', '-t', 'raw', '/dev/stdout') // exit $!;
sleep 0.1;    # /proc can't be instant

sub parse_config {
    my ($file) = @_;

    open my $fh, '<', $file or return;

    my %table;
    while (<$fh>) {
        if (/^([^:]+):\h*(.*\S)/) {
            $table{$1} = $2;
        }
    }

    close $fh;
    return \%table;
}

# Read the hardware parameters file
my $hw_params = parse_config(HW_PARAMS_FILE) // die "can't read config file: $!";

while (read($pipe_h, (my $buffer), $hw_params->{buffer_size})) {

    # Here some interesting stuff needs to be written :)
    say length($buffer);

    ## Recursive self-recording
    ## WARNING: code too awesome to be executed =D
    #open my $fh, '>:raw', '/tmp/x';
    #print $fh $buffer;
    #close $fh;
    #system 'aplay', '/tmp/x';
}

__END__
access: MMAP_INTERLEAVED
format: S32_LE
subformat: STD
channels: 2
rate: 48000 (48000/1)
period_size: 1024
buffer_size: 16384
