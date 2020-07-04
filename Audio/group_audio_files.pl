#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 11 August 2019
# https://github.com/trizen

# Group MP3 files in directories based on their artist name.

# Example:
#   Foo - abc.mp3
#   Foo - xyz.mp3

# Both files will be moved in a new directory named "Foo".
# The directory "Foo" is created in the current working directory from which the script is executed.

use 5.016;
use strict;
use warnings;

binmode(STDOUT, ':utf8');

use Encode qw(decode_utf8);
use Text::Unidecode qw(unidecode);

use File::Find qw(find);
use File::Copy qw(move);
use File::Basename qw(basename);
use File::Spec::Functions qw(catdir catfile curdir);

use List::Util qw(sum);
use List::UtilsBy qw(max_by);

my $file_formats = qr{\.(?:mp3|mp4|webm|mkv)\z}i;    # file formats
my (@files) = grep { -e $_ } @ARGV;

my @mp3_files;

find(\&wanted_files, @files);

sub wanted_files {
    my $file = $File::Find::name;
    push @mp3_files, $file if ($file =~ $file_formats);
}

my %groups;

foreach my $filename (@mp3_files) {

    my $basename = decode_utf8(basename($filename));

    my $artist;
    if ($basename =~ /^[\d\s.-]*(.+?) -/) {
        $artist = $1;
    }
    elsif ($basename =~ /^[\d\s.-]*(.+?)-/) {
        $artist = $1;
    }
    else {
        next;
    }

    # Remove extra whitespace
    $artist = join(' ', split(' ', $artist));

    # Unidecode key and remove whitespace
    my $key = join('', split(' ', unidecode(CORE::fc($artist))));

    $key =~ s/[[:punct:]]+//g;    # remove any punctuation characters
    $key =~ s/\d+//g;             # remove any digits

    if ($key eq '' or $artist eq '') {
        next;
    }

    push @{$groups{$key}{files}},
      {
        filepath => $filename,
        basename => $basename,
      };

    ++$groups{$key}{artists}{$artist};
}

while (my ($key, $group) = each %groups) {

    my $files   = $group->{files};
    my $artists = $group->{artists};

    sum(values %$artists) > 1 or next;    # ignore single files

    my $common_name = max_by { $artists->{$_} } sort { $a cmp $b } keys %$artists;

    foreach my $file (@{$files}) {

        my $group_dir = catdir(curdir(), $common_name);

        if (not -e $group_dir) {
            mkdir($group_dir) || do {
                warn "[!] Can't create directory `$group_dir`: $!\n";
                next;
            };
        }

        if (not -d $group_dir) {
            warn "[!] Not a directory: $group_dir\n";
            next;
        }

        my $target = catfile($group_dir, $file->{basename});

        if (not -e $target) {
            say "[*] Moving file `$file->{basename}` into `$common_name` directory...";
            move($file->{filepath}, $target) || warn "[!] Failed to move: $!\n";
        }
    }
}
