#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 16 August 2019
# https://github.com/trizen

# A simple program that can solve the "Visual Memory Test" from Human Benchmark.
# https://www.humanbenchmark.com/tests/memory

# The program uses the `maim` and `swarp` tools to control the mouse.

# See also:
#   https://github.com/naelstrof/maim
#   https://tools.suckless.org/x/swarp/

# The current highest level reached by this program is 38.

use 5.020;
use strict;
use warnings;

use GD qw();
use Time::HiRes qw(sleep);
use experimental qw(signatures);

GD::Image->trueColor(1);

sub avg {
    ($_[0] + $_[1] + $_[2]) / 3;
}

sub img2ascii ($image) {

    my $size = 1920;

    my $img = GD::Image->new($image) // return;
    my ($width, $height) = $img->getBounds;

    if ($size != 0) {
        my $scale_width  = $size;
        my $scale_height = int($height / ($width / ($size / 2)));

        my $resized = GD::Image->new($scale_width, $scale_height);
        $resized->copyResampled($img, 0, 0, 0, 0, $scale_width, $scale_height, $width, $height);

        ($width, $height) = ($scale_width, $scale_height);
        $img = $resized;
    }

    my $avg = 0;
    my @averages;

    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            my $index = $img->getPixel($x, $y);
            push @averages, avg($img->rgb($index));
            $avg += $averages[-1] / $width / $height;
        }
    }

    unpack("(A$width)*", join('', map { $_ < $avg ? 1 : 0 } @averages));
}

sub solve (@lines) {

    my $width_offset  = 760;
    my $height_offset = 130;

    @lines = @lines[$height_offset - 1 .. 320];

    while (@lines and $lines[0] =~ /^1+\z/) {
        shift @lines;
        ++$height_offset;
    }

    @lines = map { substr($_, $width_offset, 385) } @lines;

    my $square_height = 0;

    foreach my $i (0 .. $#lines) {
        if ($lines[$i] =~ /0/) {
            ++$square_height;
        }

        if ($square_height > 0 and $lines[$i] !~ /0/) {
            last;
        }
    }

    if ($square_height == 0) {
        warn "Can't determine square height...";
        return;
    }

    my $left_index   = 0;
    my $square_width = 0;

  OUTER: foreach my $i (0 .. 100) {
        foreach my $line (@lines) {
            if (substr($line, $i, 1) eq '0') {
                $left_index = $i;
                $line =~ /^1*(0+)/;
                $square_width = length($1);
                last OUTER;
            }
        }
    }

    if ($square_width == 0) {
        warn "Can't determine square width...";
        return;
    }

    say "Left index: $left_index";
    say "Square width: $square_width";
    say "Square height: $square_height";

    my @grid;
    my $size = int(length($lines[0]) / $square_width);

    if ($size < 3) {
        warn "Can't determine the size of the grid...";
        return;
    }

    if ($size > 20) {
        warn "Incorrect size of the grid...";
        return;
    }

    my $width_gap  = 10;
    my $height_gap = 4;

    if ($size >= 6) {
        $width_gap  = 9;
        $height_gap = 3;
    }

    if ($size >= 8) {
        $width_gap = 8;
    }

    if ($size >= 10) {
        $width_gap = 5;
    }

    if ($size >= 11) {
        $width_gap  = 4;
        $height_gap = 2;
    }

    say "Size: $size x $size";

    foreach my $i (0 .. $size - 1) {
        foreach my $j (0 .. $size - 1) {
            my @square;
            foreach my $line (
                 @lines[$square_height * $i + $height_gap * $i .. $square_height * $i + $height_gap * $i + $square_height - 1])
            {
                push @square, substr($line, $square_width * $j + $width_gap * $j, $square_width);
            }
            $grid[$i][$j] = \@square;
        }
    }

    my @matrix;

    foreach my $i (0 .. $#grid) {
        my $row = $grid[$i];
        foreach my $j (0 .. $#$row) {
            my $square = $row->[$j];

            my %freq = ('0' => 0, '1' => 0);
            ++$freq{$_} for split(//, join('', @$square));
            $matrix[$i][$j] = ($freq{'0'} > $freq{'1'}) ? 1 : 0;
        }
    }

    say "@$_" for @matrix;

    foreach my $i (0 .. $#matrix) {
        foreach my $j (0 .. $#{$matrix[0]}) {
            if ($matrix[$i][$j]) {

                my $x = int($width_offset + $square_width * $j + $square_width / 2 + $width_gap * $j);
                my $y = int(2 * $height_offset + $square_height * 2 * $i + $square_height / 2 + 2 * $height_gap * $i);

                #say "Changing pointer to ($x, $y)";
                system("swarp", $x, $y);

                #say "Clicking square...";
                system("xdotool", "click", "1");
            }
        }
    }
}

if (@ARGV) {
    solve(img2ascii($ARGV[0]));
    exit;
}

while (1) {
    print "Press <ENTER> to take screenshot: ";
    my $prompt = <STDIN>;
    my $sshot  = `maim --geometry '1920x700+0+0' --format=jpg /dev/stdout`;
    my @lines  = img2ascii($sshot);
    sleep 1;
    solve(@lines);
    system("swarp",   1700,    800);
    system("xdotool", "click", "1");
}
