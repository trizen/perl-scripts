#!/usr/bin/perl

# Author: Trizen
# Date: 05 May 2023
# https://github.com/trizen

# A basic implementation of the UNIX `compress` tool, creating a .Z compressed file, using LZW compression.

# This implementation reads from STDIN and outputs to STDOUT:
#   perl compress.pl < input.txt > output.Z

# See also:
#   https://youtube.com/watch?v=1cJL9Va80Pk
#   https://en.wikipedia.org/wiki/Lempel%E2%80%93Ziv%E2%80%93Welch

use 5.036;

use constant {
              BUFFER_SIZE     => 8 * 512,         # must be a multiple of 8
              MAGIC_SIGNATURE => "\x1f\x9d\x90",
             };

sub compress ($in_fh, $out_fh) {

    binmode($in_fh,  ':raw');
    binmode($out_fh, ':raw');

    print {$out_fh} MAGIC_SIGNATURE;

    my $dict_size  = 256;
    my %dictionary = (map { (chr($_), $_) } 0 .. $dict_size - 1);

    ++$dict_size;    # 256 is the 'RESET' marker

    my $num_bits = 9;
    my $max_bits = 16;

    my $max_bits_size = (1 << $num_bits);
    my $max_dict_size = (1 << $max_bits);

    my $bitstream      = '';
    my $bitstream_size = 0;

    my sub output_index ($symbol) {

        $bitstream .= reverse(sprintf('%0*b', $num_bits, $dictionary{$symbol}));
        $bitstream_size += $num_bits;

        if ($bitstream_size % BUFFER_SIZE == 0) {
            print {$out_fh} pack("b*", $bitstream);
            $bitstream      = '';
            $bitstream_size = 0;
        }
    }

    my $w = '';

    while (defined(my $c = getc($in_fh))) {
        my $wc = $w . $c;
        if (exists($dictionary{$wc})) {
            $w = $wc;
        }
        else {
            output_index($w);
            if ($dict_size < $max_dict_size) {
                $dictionary{$wc} = $dict_size++;
                if ($dict_size > $max_bits_size) {
                    ++$num_bits;
                    $max_bits_size <<= 1;
                }
            }
            $w = $c;
        }
    }

    if ($w ne '') {
        output_index($w);
    }

    if ($bitstream ne '') {
        print {$out_fh} pack('b*', $bitstream);
    }

    return 1;
}

compress(\*STDIN, \*STDOUT);
