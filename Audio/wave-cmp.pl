#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 March 2015
# Website: http://github.com/trizen

# Find similar audio files by comparing their waveforms.

# Review:
#   http://trizenx.blogspot.ro/2015/03/similar-audio-files.html

#
## The waveform is processed block by block:
#  _________________________________________
# |_____|_____|_____|_____|_____|_____|_____|
# |_____|_____|_____|_____|_____|_____|_____|
# |_____|_____|_____|_____|_____|_____|_____|
# |_____|_____|_____|_____|_____|_____|_____|
#
# Each block has a distinct number of white pixels, which are collected
# inside an array and constitute the unique fingerprint of the waveform.
#
# Now, each block value is compared with the corresponding value
# of another fingerprint. If the difference from all blocks is within
# the allowed deviation, then the audio files are marked as similar.
#
# In the end, the similar files are reported to the standard output.

# Requirements:
#   - sox: http://sox.sourceforge.net/
#   - wav2png: https://github.com/beschulz/wav2png

use utf8;
use 5.010;
use strict;
use autodie;
use warnings;

require GD;
GD::Image->trueColor(1);

require GDBM_File;
use List::Util qw(sum);
use Getopt::Long qw(GetOptions);

use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec::Functions qw(catfile catdir);

require Digest::MD5;
my $ctx = Digest::MD5->new;

my $pkgname = 'wave-cmp';
my $version = 0.01;

my $deviation = 5;

my ($width, $height) = (1800, 300);
my ($div_x, $div_y)  = (10,   2);

sub help {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [dirs|files]

=> Waveform generation
    -w  --width=i       : width of the waveform (default: $width)
    -h  --height=i      : height of the waveform (default: $height)

=> Waveform processing
    -x  --x-div=i       : divisions along the X-axis (default: $div_x)
    -y  --y-div=i       : divisions along the Y-axis (default: $div_y)
    -d  --deviation=i   : tolerance deviation value (default: $deviation)

        --help          : print this message and exit
        --version       : print the version number and exit

example:
    $0 --deviation=6 ~/Music

EOT
    exit($code);
}

sub version {
    print "$pkgname $version\n";
    exit 0;
}

GetOptions(
           'w|width=i'     => \$width,
           'h|height=i'    => \$height,
           'x|x-div=i'     => \$div_x,
           'y|y-div=i'     => \$div_y,
           'd|deviation=i' => \$deviation,
           'help'          => sub { help(0) },
           'v|version'     => \&version,
          )
  or die("Error in command line arguments");

my $sq_x = int($width / $div_x);
my $sq_y = int($height / $div_y);

my $limit_x = $width - $sq_x;
my $limit_y = int($height / 2) - $sq_y;    # analyze only the first half

# Source: http://en.wikipedia.org/wiki/Audio_file_format#List_of_formats
my @audio_formats = qw(
  3gp
  act
  aiff
  aac
  amr
  au
  awb
  dct
  dss
  flac
  gsm
  m4a
  m4p
  mp3
  mpc
  ogg oga
  opus
  ra rm
  raw
  sln
  tta
  vox
  wav
  wma
  wv
  );

my $audio_formats_re = do {
    local $" = '|';
    qr/\.(?:@audio_formats)\z/i;
};

my $home_dir =
     $ENV{HOME}
  || $ENV{LOGDIR}
  || (getpwuid($<))[7]
  || `echo -n ~`;

my $xdg_config_home = catdir($home_dir, '.config');

my $cache_dir = catdir($xdg_config_home, $pkgname);
my $cache_db = catfile($cache_dir, 'fp.db');

if (not -d $cache_dir) {
    make_path($cache_dir);
}

tie my %db, 'GDBM_File', $cache_db, &GDBM_File::GDBM_WRCREAT, 0640;

#
#-- execute the sox and wave2png commands and return the waveform PNG data
#
sub generate_waveform {
    my ($file, $output) = @_;
`sox \Q$file\E -q --norm -V0 --multi-threaded -t wav --encoding signed-integer - | wav2png -w $width -h $height -f 000000ff -b ffffff00 -o /dev/stdout /dev/stdin`;
}

#
#-- return the md5 hex digest of the content of a file
#
sub md5_file {
    my ($file) = @_;
    open my $fh, '<:raw', $file;
    $ctx->addfile($fh);
    $ctx->hexdigest;
}

#
#-- take image data as input and return a fingerprint array ref
#
sub generate_fingerprint {
    my ($image_data) = @_;

    state %rgb_cache;    # cache the RGB values of pixels

    my @fingerprint;
    my $image = GD::Image->new($image_data) // return;

    for (my $i = 0 ; $i <= $limit_x ; $i += $sq_x) {
        for (my $j = 0 ; $j <= $limit_y ; $j += $sq_y) {
            my $fill = 0;

            foreach my $x ($i .. $i + $sq_x - 1) {
                foreach my $y ($j .. $j + $sq_y - 1) {
                    my $index = $image->getPixel($x, $y);
                    my $rgb = $rgb_cache{$index} //= [$image->rgb($index)];
                    $fill++ if $rgb->[0] == 255;    # check only the value of red
                }
            }

            push @fingerprint, $fill;
        }
    }

    return \@fingerprint;
}

#
#-- fetch or generate the fingerprint for a given audio file
#
sub fingerprint {
    my ($audio_file) = @_;

    state $local_cache = {};

    return $local_cache->{$audio_file}
      if exists $local_cache->{$audio_file};

    my $md5 = md5_file($audio_file);
    my $key = "$width/$height/$div_x/$div_y/$md5";

    if (not exists $db{$key}) {
        my $image_data  = generate_waveform($audio_file)    // return;
        my $fingerprint = generate_fingerprint($image_data) // return;
        $db{$key} = join(':', @{$fingerprint});
        return ($local_cache->{$audio_file} = $fingerprint);
    }

    $local_cache->{$audio_file} //= [split /:/, $db{$key}];
}

#
#-- compare two fingerprints and return true if they are alike
#
sub alike_fingerprints {
    my ($a1, $a2) = @_;

    foreach my $i (0 .. $#{$a1}) {
        my $value = abs($a1->[$i] - $a2->[$i]) / ($sq_x * $sq_y) * 100;
        return if $value > $deviation;
    }

    return 1;
}

#
#-- compare two audio files and return true if they are alike
#
sub alike_files {
    my ($file1, $file2) = @_;

    my $fp1 = fingerprint($file1) // return;
    my $fp2 = fingerprint($file2) // return;

    alike_fingerprints($fp1, $fp2);
}

#
#-- find and call $code with a group of similar audio files
#
sub find_similar_audio_files {
    my $code = shift;

    my @files;
    find {
        no_chdir => 1,
        wanted   => sub {
            /$audio_formats_re/ || return;
            lstat;
            (-f _) && (not -l _) && push @files, $_;
        }
    } => @_;

    my %groups;
    my %seen;

    my $limit = $#files;

    foreach my $i (0 .. $limit) {
        foreach my $j ($i + 1 .. $limit) {
            next if $seen{$files[$j]};
            if (alike_files($files[$i], $files[$j])) {
                $groups{$i} //= [$files[$i]];
                $seen{$files[$j]}++;
                push @{$groups{$i}}, $files[$j];
            }
        }

        if (exists $groups{$i}) {
            $code->(delete $groups{$i});
        }
    }
}

#
#-- print a group of files followed by an horizontal line
#
sub print_group {
    my ($group) = @_;

    foreach my $file (sort { (lc($a) cmp lc($b)) || ($a cmp $b) } @{$group}) {
        say $file;
    }

    say "-" x 80;
}

@ARGV || help(2);
find_similar_audio_files(\&print_group, @ARGV);
