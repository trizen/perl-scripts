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
    #say length($buffer);

    print "\n";

    my $i    = 0;
    my @data = "";
    foreach my $char (split(//, $buffer)) {

        my $step = 20;             # a lower value means greater precision
        my $ord  = ord($char);
        my $mod  = $ord % $step;

        if ($mod > ($step / 2)) {
            $ord += ($step - $mod);
        }
        else {
            $ord -= $mod;
        }

        if ($ord >= 127) {
            $ord %= 127;
        }

        if ($ord <= 32) {
            $ord += 32;
        }

        if ($ord == ord('-')) {    # '-' is for the background noise
            if ($data[-1] ne '') {
                ++$#data;
                $data[-1] = '';
            }
            next;
        }

        $data[-1] .= chr $ord;
    }

    my @sen;
    foreach my $seq (@data) {
        my $len = length($seq);
        if ((my $i = $len - ($len % 2)) > 0) {
            push @sen, 'x' x $i;
        }
    }

    print "@sen\n";

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

__DATA__
xxxx xxxxxxx xxxx xxxxxx xx xxxxxx xxx xxxxxx xxx xxxxxx xxx xxxxxx xxxx xxxxx xxx xxxxx xxx xxxxx xxxxxx xxxxx xxxxxxxx xxxxxx xxxxxxx x xxxx xxxxxxxx xxxx xx xxxxxxxx xxx xxx xx xxxxxxxxxxx x x xx xx x xxxxxxx x x x xx x xxxxxxxx x x xx xxxxxxx x x xxx xxxxxx xxx xx x xxxxx xxx x xxxxxx x xx x xxxxxxx xx xxxxxxxx xx xxxx xx xxxxxx xx xxxxxx x xxxxx x xx
16384
xxxxx xxxxxx x xxxxxxxxx xxxxxxxx xxxxx xxxxx xxxxx xxxx xx xxxxxxxx xxxxxx x xxxxxxx xx x xxxxxx xxxx xxxxxx xxxxx xxxxxxxx xxx x xxxxxxxx ! xx xxxx x x x xx xxxxxx x xx xxxxxxxx xxx xx xxx x xxxxx xxx xxxxx xx x xx xxxxxx xxx x xxxxxx xxx x x xxxxxxxx x xxxxxxxxx xxxxx x xxxxxx xxxxx x xxxxxxxxxx x xxxxx xxxx
16384
xxxx xx xxxxxx xxxxxx xxxxxxxx xxxxxxxx xxxxxxx xxxxxx xxxxx xxx xxxxx xxxxx xxxxxxx xxxx xxxxx xxxxxxxxx xxx xxxx xxxxxxxx xxxx xxxx xxx xxx xxx xxx xxx x x xxxx x xxxx xxxxx xx xxx xx xx xxxxx x xxxx xxxxxxx x xxxxx xxxxxx xxxx xx
16384
xxxxx xxxxx x xxxxx xxx xxxxx x xxxx xxxxxx xxxxxx xxxxxx x xxxxx xxxx xxxxxx xxxxxx xxxx xxxxxxx xxx xxx x xxxx xxxx x x xxx x x x xx x xxxx xxxxx xxxxxx x xxxxxx xxxx xxxxx xxx xxx xxxxxx xx xxxxx xxxxxxxx xxxxxxx x x xxxxxxx xxxxxx xx xxxxxx x xxxxx x x xxxxxx xxxxxx xxxxx
16384
xxxxxxx xxxxxxx x xxxxx xxxxx x x xxxxxxx xxxxxxxxx xxxxxxx xxxxxxxxxxxx xxxxxxxxxx x xxxxxxxxxx xxxxxxx xxxxxxxxx xxxxxxxx x xxxxxx xxxxxxxxx xxxxxxx xxxxxxxx xxxxxxxxx xxxxxxxxxx x xxxxxxx xxxxxxxxxx xxxx x xxxxxx xx xxxxxxx xxx xxxxxx x xxxxxxxxx x x xxxxxxxxx xxxxxxxx x xxxxxxxx xxxxxx x x xxxx xxxxxx xxx xxxxxxxx xxxxxxxxxx x xx xxx x xx xxxxxxxx xxx xx xxx xxxxxxx x xx xx xxxxx xxx xx x xxxxxx x x xxxxxxxxxx xxxxxxxx xxxxxxxx xxxxxx xxxxxx xxx xxxxxxxxxxx
16384
xxx xxxxx xxxxxxx xxxxx xxxxxx xx xxxxxxxxx xxxx xxxxxxxxxx x x xxxxxx x xxxxxxxxxxxx x x xxxxxxxxxx xx xxxxxxxxxxx xxx x xxxxxxxx xxxxxxxx xxxxxxxx xxxxxxxxx xxxxx xxxxxxx xxxxxxxxxxx xxxxxxxx xxxxx xxxx xxxxxxxxx xxxxxxxx x xxxxxx x xxxxxxx xxxxxxx x x xxxxxxxx xxx xxxx xxxxxx xxxxxx x xxxxxx x xxxxxx x xxxxxx xxx xxxxxx x xxxxx xxx xxxxxxx xxxxxxx
16384
xxxxx xx xxxx xxxxxx xx xxxxxx x xxxxxx xxx xxxxx x xxxxx xxx xxxxxx xxxxx xxxxxx xxxxx xxx xxxxxxx x x xxxxxxx xxx x xxx xxxxxxx xxxx xxxxxxxxxxx xx xx xxxxxx x xxx xxxxx xxxx xxxxxxx xxx x xxxxxx xx xxxxx xxxxxxxx xx xxxxxx xx xxxxx x x xx xxx
16384
xxxxx xxxxxx xxxx xxxxxxx xxxx x xxxxxx xx xxxxx xxx xxxxxx xx xxxxx xx xxxxxx x xxxxx xxxxx xxxx xxx xxxx xxxxx x xx xxxxxxx xxxxxx xxx xxxxxx xxxx xxxxxxx xxx xxxxxxxxx xxx xx xxxxxxx xxx x xxxxxxx xxxx xx x xxxxxxx xxx x xx xxxxxxx xxxx x xxxxxx xxx xx xxxxxxx xxxx x x xxxxxxxx xxx xxxxxxx xxxx xxxxxxx x xxxxxx xxxx xxxxx
16384
xxxx xxxxx xxxxxxx xxxxxxx xxxxx xxxxx xxxx xxxx xxxxx xxxx xxxx xxxxx xxxxx xxxxxx xxxxxx xx x xxx xxxxxx x x xx xxxxxxxx x x x xxxxxxx xxx x xxxxxxxxx xx x x xxxxxx x xxxxxxx xxx x xxxxxx xx xx xxxxxxxx xxx x xxxxx x xxxxxxx xxxx xx xxxxx x xxxxxxxx x x xx
16384
xxxxxx x xx xxxxxx xxxxxx x xxxx xxxxx xxx xxxx xxx x xxxxxxx xxxxxx xxxxxxxx xxxxxxxxxxxx xxxxxx xxxxxx xxxxxxx xxxxxxx xxxxxxxxx xx xx xxxxxxxx xxxxxxx xxxxxxxx xxxxxxxx xxxxx xxxxxx x xx xxxxx xxxxxx x x xxxx x x xxxxx xx x xxxx xx xxxx xxx xxxxx xxx xxx
16384
xxx xx xxxxxx xx xxxxxx x xxxxxx xxxxx xxxxx x xxxxxx xxxxxxx xxxxxx xxxxx x x xxxxx x xxxx x xx x xx x xxxxxxx x xxxxxx x xx x xxxx xx x xx xxxxx xx x xxxx xx x xxxx x xx x xxxx xxx xxxxx xxxx xxxxxxx xxx xxxxxxxxx xxxxxxxxx xxxx
16384
xxxxx xxxxxxxx xxxx xxxxxx xxxxxxx xx xxxxx xxxx xxxx xxxxxxx xxxxx xxx xxxx xxxxxxx xxxxxxxx xxxx xxxxxx xx xxxxxxxxx xxxxxxx x xxxxxxxx x xx xxxxxxx x xxxxxxxxxxx xxxxxx xxxxxx x x xxxxxx xx xxxxxx xx xxxxx x xxxx xx xx xxxxx xxx xxxxxx xxxx xxxxx xxxx xx xxxx x
16384
x xxxxx xxxxxx x xxxxxxxx xxxx xxxxxx xx xxxx xxxxxx xxx xxxxx xxxx xx xx xxxx xxxxxxxxxx xxxx x x x xxxxxxxxxx xxxx x xxx xxxxx xxx xxxxxxx xx x xxxxxxx xx xxxxxxx xxxxxx x xxxxxxxx xxxxxxx xxxxxx xxxxxxx x xxxxx xxxxx xxx xxxxx xx xxxxx xx xxxx x xxxx xxxxx xxxxx xxxxxxxxxxx xxxxxxxxxxxxx xxxxx xxxxx
