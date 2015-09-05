#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 March 2015
# Edit: 04 September 2015
# Website: http://github.com/trizen

# Find similar audio files by comparing their waveforms.

# Review:
#   http://trizenx.blogspot.ro/2015/03/similar-audio-files.html

# Requirements:
#   - sox: http://sox.sourceforge.net/
#   - wav2png: https://github.com/beschulz/wav2png

use utf8;
use 5.022;
use strict;
use autodie;
use warnings;

use experimental 'bitwise';

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

my $pkgname = 'wave-cmp2';
my $version = 0.02;

# Mark files as similar based on this percentage
my $percentage = 75;

# The size of the waveform
my ($width, $height) = (1800, 300);

sub help {
    my ($code) = @_;
    print <<"EOT";
usage: $0 [options] [dirs|files]

=> Waveform generation
    -w  --width=i       : width of the waveform (default: $width)
    -h  --height=i      : height of the waveform (default: $height)

=> Waveform processing
    -p  --percentage=i  : minimum percentage of similarity (default: $percentage)

        --help          : print this message and exit
        --version       : print the version number and exit

example:
    $0 --percentage=80 ~/Music

EOT
    exit($code);
}

sub version {
    print "$pkgname $version\n";
    exit 0;
}

GetOptions(
           'w|width=i'      => \$width,
           'h|height=i'     => \$height,
           'p|percentage=i' => \$percentage,
           'help'           => sub { help(0) },
           'v|version'      => \&version,
          )
  or die("Error in command line arguments");

my $size = $width * $height;

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
`sox \Q$file\E -q --norm -V0 --multi-threaded -t wav --encoding signed-integer - | wav2png -w $width -h $height -f ffffffff -b 00000000 -o /dev/stdout /dev/stdin`;
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

#<<<
#
#-- compare two fingerprints and return the similarity percentage
#
sub alike_percentage {
    ((($_[0] ^. $_[1]) =~ tr/\0//) / $size)**2 * 100;
}
#>>>

#
#-- compute the average value of a pixel
#
sub avg {
    ($_[0] + $_[1] + $_[2]) / 3;
}

#
#-- take image data as input and return the fingerprint as string
#
sub generate_fingerprint {
    my ($image_data) = @_;

    my $img = GD::Image->new($image_data) // return;

    my @averages;
    foreach my $y (0 .. $height - 1) {
        foreach my $x (0 .. $width - 1) {
            push @averages, avg($img->rgb($img->getPixel($x, $y)));
        }
    }

    my $avg = sum(@averages) / @averages;
    join('', map { $_ < $avg ? 1 : 0 } @averages);
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
    my $key = "$width/$height/$md5";

    if (not exists $db{$key}) {
        my $image_data  = generate_waveform($audio_file)    // return;
        my $fingerprint = generate_fingerprint($image_data) // return;
        $db{$key} = pack('B*', $fingerprint);
        return ($local_cache->{$audio_file} = $fingerprint);
    }

    $local_cache->{$audio_file} //= unpack('B*', $db{$key});
}

#
#-- find and call $code with a group of similar audio files
#
sub find_similar_audio_files(&@) {
    my $callback = shift;

    my @files;
    find {
        no_chdir => 1,
        wanted   => sub {
            (/$audio_formats_re/o && -f) || return;

            push @files,
              {
                fingerprint => fingerprint($_) // return,
                filename => $_,
              };
          }
         } => @_;

    #
    ## Populate the %alike hash
    #
    my %alike;
    foreach my $i (0 .. $#files - 1) {
        for (my $j = $i + 1 ; $j <= $#files ; $j++) {
            my $p = alike_percentage($files[$i]{fingerprint}, $files[$j]{fingerprint});
            if ($p >= $percentage) {
                $alike{$files[$i]{filename}}{$files[$j]{filename}} = $p;
                $alike{$files[$j]{filename}}{$files[$i]{filename}} = $p;
            }
        }
    }

    #
    ## Group the files
    #
    my @alike;
    foreach my $root (
        map { $_->[0] }
        sort { ($a->[1] <=> $b->[1]) || ($b->[2] <=> $a->[2]) }
        map {
            my $keys = keys(%{$alike{$_}});
            my $avg  = sum(values(%{$alike{$_}})) / $keys;

            [$_, $keys, $avg]
        }
        keys %alike
      ) {
        my @group = keys(%{$alike{$root}});
        if (@group) {
            my $avg = 0;
            $avg += delete($alike{$_}{$root}) for @group;
            push @alike, {score => $avg / @group, files => [$root, @group]};

        }
    }

    #
    ## Callback each group
    #
    my %seen;
    foreach my $group (sort { $b->{score} <=> $a->{score} } @alike) {
        (@{$group->{files}} == grep { $seen{$_}++ } @{$group->{files}}) and next;
        $callback->($group->{score}, $group->{files});
    }

    return 1;
}

@ARGV || help(2);
find_similar_audio_files {
    my ($score, $files) = @_;
    printf("=> Similarity: %.0f%%\n", $score), say join("\n", @{$files});
    say "-" x 80;
}
@ARGV;
