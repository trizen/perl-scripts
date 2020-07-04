#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 1st December 2014
# License: GPLv3
# https://github.com/trizen

use utf8;
use 5.014;
use strict;
use warnings;

use Encode qw(decode_utf8);
use File::Find qw(find);
use Getopt::Long qw(GetOptions);

binmode(STDOUT, ':utf8');

my $rename         = 0;
my $single_file    = 0;
my $min_percentage = 50;

sub help {
    my ($code) = @_;

    print <<"HELP";
Rename subtitles to match the video files

usage: $0 /my/videos [...]

options:
    -r --rename         : rename the file names (default: $rename)
    -s --single-file    : one video and one subtitle in a dir (default: $single_file)
    -p --percentage=i   : minimum percentage of approximation (default: $min_percentage)

Match subtitles to video names across directories and rename them accordingly.
The match is done heuristically, using an approximation comparison algorithm.

When there are more subtitles and more videos inside a directory, the script
makes decisions based on the filename approximations and rename the file
if they are at least 50% similar. (this percent is customizable)

The script has, also, several special cases for serials (S00E00)
and for single video files with one subtitle in the same directory.

Usage example:
    $0 -s -p=75 ~/Videos

Copyright (C) 2014 Daniel "Trizen" Șuteu <trizenx\@gmail\.com>
License: GPLv3 or later, at your choice. See <http://www.gnu.org/licenses/gpl>
HELP

    exit($code // 0);
}

GetOptions(
           'p|percentage=i' => \$min_percentage,
           'r|rename!'      => \$rename,
           's|single-file!' => \$single_file,
           'h|help'         => sub { help() },
          )
  or die("Error in command line arguments");

my @dirs = grep { -d } @ARGV;
@dirs || help(2);

# Source: http://en.wikipedia.org/wiki/Video_file_format
my @video_formats = qw(
  avi
  mp4
  wmv
  mkv
  webm
  flv
  ogv
  ogg
  drc
  mng
  mov
  qt
  rm
  rmvb
  asf
  m4p
  m4v
  mpg
  mp2
  mpeg
  mpe
  mpv
  m4v
  3gp
  3g2
  mxf
  roq
  nsv
  yuv
  );

# Source: http://en.wikipedia.org/wiki/Subtitle_%28captioning%29#Subtitle_formats
my @subtitle_formats = qw(
  aqt
  gsub
  jss
  sub
  ttxt
  pjs
  psb
  rt
  smi
  stl
  ssf
  srt
  ssa
  ass
  usf
  );

sub acmp {
    my ($name1, $name2, $percentage) = @_;

    my ($len1, $len2) = (length($name1), length($name2));
    if ($len1 > $len2) {
        ($name2, $len2, $name1, $len1) = ($name1, $len1, $name2, $len2);
    }

    return -1
      if (my $min = int($len2 * $percentage / 100)) > $len1;

    my $diff = $len1 - $min;
    foreach my $i (0 .. $diff) {
        foreach my $j ($i .. $diff) {
            if (index($name2, substr($name1, $i, $min + $j - $i)) != -1) {
                return 0;
            }
        }
    }

    return 1;
}

my $videos_re = do {
    local $" = '|';
    qr/\.(?:@video_formats)\z/i;
};

my $subs_re = do {
    local $" = '|';
    qr/\.(?:@subtitle_formats)\z/i;
};

my $serial_re = qr/S([0-9]{2,})E([0-9]{2,})/;

if (not $rename) {

    warn "\n[!] To actually rename the files, execute me with option '-r'.\n\n";

}

my %content;
find {
    no_chdir => 0,
    wanted   => sub {
        if (/$videos_re/) {
            my $name = decode_utf8($_) =~ s/$videos_re//r;
            push @{$content{$File::Find::dir}{videos}{$name}}, decode_utf8($File::Find::name);
        }
        elsif (/$subs_re/) {
            my $name = decode_utf8($_) =~ s/$subs_re//r;
            push @{$content{$File::Find::dir}{subs}{$name}}, decode_utf8($File::Find::name);
        }
    },
} => @dirs;

sub ilc {
    my ($string) = @_;
    $string =~ s/[[:punct:]]+/ /g;
    $string = join(' ', split(' ', $string));
    lc($string);
}

foreach my $dir (sort keys %content) {
    my $subs   = $content{$dir}{subs}   // next;
    my $videos = $content{$dir}{videos} // next;

    # Make a table with scores and rename the subtitles
    # accordingly to each video it belongs (using heuristics)
    my (%table, %seen, %subs_taken);

    my @subs   = sort keys %{$subs};
    my @videos = sort keys %{$videos};

    my %memo;
    foreach my $sub (@subs) {
        foreach my $video (@videos) {
          PERCENT: for (my $i = 100 ; $i >= $min_percentage ; $i--) {

                # Break if subtitle has the same name as video
                # and mark it as already taken.
                if ($sub eq $video) {
                    $subs_taken{$sub}++;
                    last;
                }

                if (acmp($memo{$sub} //= ilc($sub), $memo{$video} //= ilc($video), $i) == 0) {

                    # A subtitle can't be shared with more videos
                    if (exists $seen{$sub}) {
                        foreach my $key (@{$seen{$sub}}) {
                            if (@{$table{$key}}) {
                                if ($i > $table{$key}[-1][1]) {
                                    pop @{$table{$key}};
                                }
                                else {
                                    last PERCENT;
                                }
                            }
                        }
                    }

                    push @{$table{$video}}, [$sub, $i];
                    push @{$seen{$sub}}, $video;
                    last;
                }
            }
        }
    }

    if (@subs == 1 and @videos == 1 and not keys %table) {
        my ($sub, $video) = (@subs, @videos);
        next if $sub eq $video;
        $table{$video} = [[$sub, 0]];
    }

    # Rename the files
    foreach my $video (sort keys %table) {
        @{$table{$video}} || next;
        my ($sub, $percentage) = @{(sort { $b->[1] <=> $a->[1] } @{$table{$video}})[0]};

        next if exists $subs_taken{$sub};

        foreach my $subfile (@{$subs->{$sub}}) {

            # If it is a serial (SxxExx)
            # skip if subtitle contains a serial number
            # that is different from that of the video.
            if ($video =~ /$serial_re/) {
                my ($vs, $ve) = ($1, $2);
                if ($sub =~ /$serial_re/) {
                    my ($ss, $se) = ($1, $2);
                    if ($vs ne $ss or $ve ne $se) {
                        next;
                    }
                }
            }

            my $new_name = $subfile =~ s/\Q$sub\E(?=$subs_re)/$video/r;
            say "** Renaming: $subfile -> $new_name ($percentage%)";

            # Skip file if the current percentage is lower than the minimum percentage
            if ($percentage < $min_percentage) {
                if (@subs == 1 and @videos == 1) {
                    if (not $single_file) {
                        warn "\t[!] I will rename this if you execute me with option '-s'.\n";
                        next;
                    }
                }
                else {    # this will not happen
                    warn "\t[!] Percentage is lower than $min_percentage%. Skipping file...\n";
                    next;
                }
            }

            # Rename the file (if rename is enabled)
            if ($rename) {

                if (-e $new_name) {
                    warn "\t[!] File already exists... Skipping...\n";
                    next;
                }

                rename($subfile, $new_name)
                  || warn "\t[!] Can't rename file: $!\n";
            }
        }
    }
}
