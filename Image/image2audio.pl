#!/usr/bin/perl

# Convert an image to an audio spectrogram.

# Algorithm from:
#   https://github.com/alexadam/img-encode/blob/master/v1-python/imgencode.py

# The spectrogram can be viewed in a program, like Audacity.

# Inspired by the hidden message in the movie "Leave the world behind":
#   https://www.reddit.com/r/MrRobot/comments/18hnn3q/minor_spoiler_leave_the_world_behind_hidden/

use 5.036;
use Imager;
use Audio::Wav;
use List::Util   qw(min max);
use Getopt::Long qw(GetOptions);

my $max_width  = 300;    # resize images greater than this
my $max_height = 300;    # resize images greater than this

my $sample_rate    = 44100;
my $bits_sample    = 16;
my $duration       = 1;                   # in seconds
my $frequency_band = $sample_rate / 2;    # in Hz
my $channels       = 1;

my $output_wav = 'output.wav';

sub help ($code) {
    print <<"EOT";
usage: $0 [options] [images]

options:
    -o  --output=s   : output audio file (default: $output_wav)
    -d  --duration=i : duration in seconds per image (default: $duration)
    -f  --freq=i     : frequency band in Hz (default: $frequency_band)
    -b  --bits=i     : bits sample (default: $bits_sample)
    -s  --sample=i   : sample rate (default: $sample_rate)
    -c  --channels=i : number of channels (default: $channels)
EOT

    exit($code);
}

GetOptions(
           'o|output=s'      => \$output_wav,
           'd|duration=f'    => \$duration,
           'f|frequency=i'   => \$frequency_band,
           'b|bits-sample=i' => \$bits_sample,
           's|sample-rate=i' => \$sample_rate,
           'c|channels=i'    => \$channels,
           'h|help'          => sub { help(0) },
          )
  or die("Error in command line arguments");

sub range_map ($value, $in_min, $in_max, $out_min, $out_max) {
    ($value - $in_min) * ($out_max - $out_min) / ($in_max - $in_min) + $out_min;
}

sub image2spectrogram ($input_file, $write) {

    say "\n:: Processing: $input_file";

    my $img = Imager->new(file => $input_file)
      or die "Can't open file <<$input_file>> for reading: $!";

    my $width  = $img->getwidth;
    my $height = $img->getheight;

    if ($width > $max_width) {
        $img = $img->scale(xpixels => $max_width, qtype => 'mixing');
        ($width, $height) = ($img->getwidth, $img->getheight);
    }

    if ($height > $max_height) {
        $img = $img->scale(ypixels => $max_height, qtype => 'mixing');
        ($width, $height) = ($img->getwidth, $img->getheight);
    }

    if ($width != $height) {
        my $min_size = min($width, $height);
        $width  = int($duration * $min_size);
        $height = $min_size;
        say "-> Resizing the image to: $width x $height";
        $img = $img->scale(xpixels => $width, ypixels => $height, qtype => 'mixing', type => 'nonprop');
    }

    my @data;
    my $maxFreq = 0;

    my $numSamples      = int($sample_rate * $duration);
    my $samplesPerPixel = $numSamples / $width;

    my $C = $frequency_band / $height;

    my @img;
    foreach my $y (0 .. $height - 1) {
        my @line = $img->getscanline(y => $y);
        foreach my $pixel (@line) {
            my ($R, $G, $B) = $pixel->rgba;
            ## push @{$img[$y]}, ((($R + $G + $B) / 3) * 100 / 255)**2;
            ## push @{$img[$y]}, ((0.5 * max($R, $G, $B) + 0.5 * min($R, $G, $B)) * 100 / 255)**2;
            ## push @{$img[$y]}, (sqrt(0.299 * $R**2 + 0.587 * $G**2 + 0.114 * $B**2) * 100 / 255)**2;
            push @{$img[$y]}, ((0.299 * $R + 0.587 * $G + 0.114 * $B) * 100 / 255)**2;
        }
    }

    say "-> Converting the pixels to spectrogram frequencies";

    my $tau = 2 * atan2(0, -1);

    foreach my $x (0 .. $numSamples - 1) {

        my $rez     = 0;
        my $pixel_x = int($x / $samplesPerPixel);

        foreach my $y (0 .. $height - 1) {
            my $volume = $img[$y][$pixel_x] || next;
            my $freq   = sprintf('%.0f', $C * ($height - $y + 1));
            $rez += sprintf('%.0f', $volume * cos($freq * $tau * $x / $sample_rate));
        }

        push @data, $rez;

        if (abs($rez) > $maxFreq) {
            $maxFreq = abs($rez);
        }
    }

    say "-> Maximum frequency: $maxFreq";

    my $max_no = 2**($bits_sample - 1) - 1;

    #my $min = min(@data);
    #my $max = max(@data);

    my $min = -$maxFreq;
    my $max = $maxFreq;

    foreach my $val (@data) {
        ## $write->write(sprintf('%.0f', $max_no * $val / $maxFreq));
        $write->write(range_map($val, $min, $max, -$max_no, $max_no));
    }

    return 1;
}

@ARGV || help(2);

my $details = {
               'bits_sample' => $bits_sample,
               'sample_rate' => $sample_rate,
               'channels'    => $channels,
              };

my $wav   = Audio::Wav->new;
my $write = $wav->write($output_wav, $details);

foreach my $input_img (@ARGV) {
    image2spectrogram($input_img, $write);
}

$write->finish();
