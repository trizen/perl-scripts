#!/usr/bin/perl

# Implementation of the QOI encoder.

# See also:
#   https://qoiformat.org/
#   https://github.com/phoboslab/qoi
#   https://yewtu.be/watch?v=EFUYNoFRHQI

use 5.020;
use warnings;

use Imager;
use experimental qw(signatures);

sub qoi_encoder ($img) {

    use constant {
                  QOI_OP_RGB  => 0b1111_1110,
                  QOI_OP_RGBA => 0b1111_1111,
                  QOI_OP_DIFF => 0b01_000_000,
                  QOI_OP_RUN  => 0b11_000_000,
                  QOI_OP_LUMA => 0b10_000_000,
                 };

    my $width      = $img->getwidth;
    my $height     = $img->getheight;
    my $channels   = $img->getchannels;
    my $colorspace = 0;

    say "[$width, $height, $channels, $colorspace]";

    my @bytes = unpack('C*', 'qoif');

    push @bytes, unpack('C4', pack('N', $width));
    push @bytes, unpack('C4', pack('N', $height));

    push @bytes, $channels;
    push @bytes, $colorspace;

    my $run     = 0;
    my @px      = (0, 0, 0, 255);
    my @prev_px = @px;

    my @colors = (map { [0, 0, 0, 0] } 1 .. 64);

    foreach my $y (0 .. $height - 1) {

        my @line     = unpack('C*', scalar $img->getscanline(y => $y));
        my $line_len = scalar(@line);

        for (my $i = 0 ; $i < $line_len ; $i += 4) {
            @px = splice(@line, 0, 4);

            if (    $px[0] == $prev_px[0]
                and $px[1] == $prev_px[1]
                and $px[2] == $prev_px[2]
                and $px[3] == $prev_px[3]) {

                if (++$run == 62) {
                    push @bytes, QOI_OP_RUN | ($run - 1);
                    $run = 0;
                }
            }
            else {

                if ($run > 0) {
                    push @bytes, (QOI_OP_RUN | ($run - 1));
                    $run = 0;
                }

                my $hash     = ($px[0] * 3 + $px[1] * 5 + $px[2] * 7 + $px[3] * 11) % 64;
                my $index_px = $colors[$hash];

                if (    $px[0] == $index_px->[0]
                    and $px[1] == $index_px->[1]
                    and $px[2] == $index_px->[2]
                    and $px[3] == $index_px->[3]) {    # OP INDEX
                    push @bytes, $hash;
                }
                else {

                    $colors[$hash] = [@px];

                    if ($px[3] == $prev_px[3]) {

                        my $vr = $px[0] - $prev_px[0];
                        my $vg = $px[1] - $prev_px[1];
                        my $vb = $px[2] - $prev_px[2];

                        my $vg_r = $vr - $vg;
                        my $vg_b = $vb - $vg;

                        if (    $vr > -3
                            and $vr < 2
                            and $vg > -3
                            and $vg < 2
                            and $vb > -3
                            and $vb < 2) {
                            push(@bytes, QOI_OP_DIFF | (($vr + 2) << 4) | (($vg + 2) << 2) | ($vb + 2));
                        }
                        elsif (    $vg_r > -9
                               and $vg_r < 8
                               and $vg > -33
                               and $vg < 32
                               and $vg_b > -9
                               and $vg_b < 8) {
                            push(@bytes, QOI_OP_LUMA | ($vg + 32));
                            push(@bytes, (($vg_r + 8) << 4) | ($vg_b + 8));
                        }
                        else {
                            push(@bytes, QOI_OP_RGB, $px[0], $px[1], $px[2]);
                        }
                    }
                    else {
                        push(@bytes, QOI_OP_RGBA, $px[0], $px[1], $px[2], $px[3]);
                    }
                }
            }

            @prev_px = @px;
        }
    }

    if ($run > 0) {
        push(@bytes, 0b11_00_00_00 | ($run - 1));
    }

    push(@bytes, (0x00) x 7);
    push(@bytes, 0x01);

    return \@bytes;
}

@ARGV || do {
    say STDERR "usage: $0 [input.png] [output.qoi]";
    exit(2);
};

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1] // "$in_file.qoi";

my $img = 'Imager'->new(file => $in_file)
    or die "Can't read image: $in_file";

my $bytes = qoi_encoder($img);

open(my $fh, '>:raw', $out_file)
  or die "Can't open file <<$out_file>> for writing: $!";

print $fh pack('C*', @$bytes);
close $fh;
