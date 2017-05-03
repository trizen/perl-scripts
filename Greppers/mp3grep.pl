#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 22 March 2013
# https://github.com/trizen

# List MP3 files, from a directory, that matches some
# specified tags, such as: artist, genre, title, etc...

use 5.010;
use strict;
use warnings;
use re 'eval';

use MP3::Tag;
use File::Find qw(find);
use Getopt::Long qw(GetOptions);

my $version = 0.01;

my @tags = qw(
  album
  artist
  comment
  genre
  song
  title
  track
  year
  );

sub usage {
    print <<"HELP";
usage: $0 [options] [dirs]

options: @{[
        join("\n\t", '', map{
            sprintf "--%-10s: get MP3s that matches the $_ tag", "$_=s"
        } @tags)
        ]}

** Each option accepts a regular expression as an argument.
** Regular expressions will match in case insensitive mode.
** When more than one option is specified, the result is printed only
   if it matches all the options specified.

Example: $0 --artist="^(?:SOAD|System of a down)\$" /home/user/Music
HELP

    exit;
}

sub version {
    print "mp3grep $version\n";
    exit;
}

@ARGV || usage();

my %opt;
GetOptions(
           (map { ; "$_=s" => \$opt{$_} } @tags),
           'help|?'  => \&usage,
           'version' => \&version,
          )
  || exit 1;

sub check_file {
    if (/\.mp3\z/i && -f && !-z _) {
        my $filename = $_;

        my $mp3inf   = MP3::Tag->new($filename);
        my $info_ref = $mp3inf->autoinfo();

        my $match;
        foreach my $tag (@tags) {
            if (defined $opt{$tag} && defined $info_ref->{$tag}) {
                if ($info_ref->{$tag} =~ /$opt{$tag}/i) {
                    $match //= $filename;
                    next;
                }
                return;
            }
        }

        $match // return;
        say $match;
    }
}

my @files = grep {
    (-d) || (-f _) || do { warn "[!] Not a file or directory: $_\n"; 0 }
} @ARGV;

@files || exit 1;

find {
      no_chdir => 1,
      wanted   => \&check_file,
     } => @files;
