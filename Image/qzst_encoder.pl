#!/usr/bin/perl

# Variation of the QOI encoder, combined with Zstandard compression.

# See also:
#   https://qoiformat.org/
#   https://github.com/phoboslab/qoi

use 5.020;
use warnings;

use Imager;
use experimental       qw(signatures);
use IO::Compress::Zstd qw(zstd $ZstdError);

sub qzst_encoder ($img, $out_fh) {

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

    my @header = unpack('C*', 'qzst');

    push @header, unpack('C4', pack('N', $width));
    push @header, unpack('C4', pack('N', $height));

    push @header, $channels;
    push @header, $colorspace;

    my $qoi_data = '';

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
                    $qoi_data .= chr(QOI_OP_RUN | ($run - 1));
                    $run = 0;
                }
            }
            else {

                if ($run > 0) {
                    $qoi_data .= chr(QOI_OP_RUN | ($run - 1));
                    $run = 0;
                }

                my $hash     = ($px[0] * 3 + $px[1] * 5 + $px[2] * 7 + $px[3] * 11) % 64;
                my $index_px = $colors[$hash];

                if (    $px[0] == $index_px->[0]
                    and $px[1] == $index_px->[1]
                    and $px[2] == $index_px->[2]
                    and $px[3] == $index_px->[3]) {    # OP INDEX
                    $qoi_data .= chr($hash);
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
                            $qoi_data .= chr(QOI_OP_DIFF | (($vr + 2) << 4) | (($vg + 2) << 2) | ($vb + 2));
                        }
                        elsif (    $vg_r > -9
                               and $vg_r < 8
                               and $vg > -33
                               and $vg < 32
                               and $vg_b > -9
                               and $vg_b < 8) {
                            $qoi_data .= join('', chr(QOI_OP_LUMA | ($vg + 32)), chr((($vg_r + 8) << 4) | ($vg_b + 8)));
                        }
                        else {
                            $qoi_data .= join('', chr(QOI_OP_RGB), chr($px[0]), chr($px[1]), chr($px[2]));
                        }
                    }
                    else {
                        $qoi_data .= join('', chr(QOI_OP_RGBA), chr($px[0]), chr($px[1]), chr($px[2]), chr($px[3]));
                    }
                }
            }

            @prev_px = @px;
        }
    }

    if ($run > 0) {
        $qoi_data .= chr(0b11_00_00_00 | ($run - 1));
    }

    my @footer;
    push(@footer, (0x00) x 7);
    push(@footer, 0x01);

    # Header
    print $out_fh pack('C*', @header);

    # Compressed data
    zstd(\$qoi_data, \my $zstd_data) or die "zstd failed: $ZstdError\n";
    print $out_fh pack("N", length($zstd_data));
    print $out_fh $zstd_data;

    # Footer
    print $out_fh pack('C*', @footer);
}

@ARGV || do {
    say STDERR "usage: $0 [input.png] [output.qzst]";
    exit(2);
};

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1] // "$in_file.qzst";

my $img = 'Imager'->new(file => $in_file)
  or die "Can't read image: $in_file";

open(my $out_fh, '>:raw', $out_file)
  or die "Can't open file <<$out_file>> for writing: $!";

qzst_encoder($img, $out_fh);
