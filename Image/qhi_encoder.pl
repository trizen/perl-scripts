#!/usr/bin/perl

# Variation of the QOI encoder, combined with Huffman coding.

# QHIf = Quite Huffman Image format. :)

# See also:
#   https://qoiformat.org/
#   https://github.com/phoboslab/qoi

use 5.020;
use warnings;

use Imager;
use experimental qw(signatures);

# produce encode and decode dictionary from a tree
sub walk ($node, $code, $h, $rev_h) {

    my $c = $node->[0] // return ($h, $rev_h);
    if (ref $c) { walk($c->[$_], $code . $_, $h, $rev_h) for ('0', '1') }
    else        { $h->{$c} = $code; $rev_h->{$code} = $c }

    return ($h, $rev_h);
}

# make a tree, and return resulting dictionaries
sub mktree ($bytes) {
    my (%freq, @nodes);

    ++$freq{$_} for @$bytes;
    @nodes = map { [$_, $freq{$_}] } sort { $a <=> $b } keys %freq;

    do {    # poor man's priority queue
        @nodes = sort { $a->[1] <=> $b->[1] } @nodes;
        my ($x, $y) = splice(@nodes, 0, 2);
        if (defined($x) and defined($y)) {
            push @nodes, [[$x, $y], $x->[1] + $y->[1]];
        }
    } while (@nodes > 1);

    walk($nodes[0], '', {}, {});
}

sub huffman_encode ($bytes, $dict) {
    my $enc = '';
    for (@$bytes) {
        $enc .= $dict->{$_} // die "bad char: $_";
    }
    return $enc;
}

sub qhi_encoder ($img, $out_fh) {

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

    my @header = unpack('C*', 'qhif');

    push @header, unpack('C4', pack('N', $width));
    push @header, unpack('C4', pack('N', $height));

    push @header, $channels;
    push @header, $colorspace;

    my @bytes;

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

    my @footer;
    push(@footer, (0x00) x 7);
    push(@footer, 0x01);

    my ($h, $rev_h) = mktree(\@bytes);
    my $enc   = huffman_encode(\@bytes, $h);

    my $dict  = '';
    my $codes = '';

    foreach my $i (0 .. 255) {
        my $c = $h->{$i} // '';
        $codes .= $c;
        $dict  .= chr(length($c));
    }

    # Header
    print $out_fh pack('C*', @header);

    # Huffman dictionary + data
    print $out_fh $dict;
    print $out_fh pack("B*", $codes);
    print $out_fh pack("N",  length($enc));
    print $out_fh pack("B*", $enc);

    # Footer
    print $out_fh pack('C*', @footer);
}

@ARGV || do {
    say STDERR "usage: $0 [input.png] [output.qhi]";
    exit(2);
};

my $in_file  = $ARGV[0];
my $out_file = $ARGV[1] // "$in_file.qhi";

my $img = 'Imager'->new(file => $in_file);

open(my $out_fh, '>:raw', $out_file)
  or die "Can't open file <<$out_file>> for writing: $!";

qhi_encoder($img, $out_fh);
