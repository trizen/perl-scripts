#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 30 May 2020
# https://github.com/trizen

# Automatically determine the mime type of files and add the corresponding file extensions.

# Usage:
#   perl script.pl [dir]

use 5.020;
use autodie;
use warnings;

use List::Util qw(any);
use File::Find qw(find);
use File::MimeInfo::Magic qw(mimetype extensions);
use File::Basename qw(dirname basename);
use File::Spec::Functions qw(curdir catfile);

my $dir = $ARGV[0] // curdir();

find(
    {
     no_chdir => 1,
     wanted   => sub {

         return 1 if not -f $_;

         my $dirname    = dirname($_);
         my $basename   = basename($_);
         my @extensions = extensions(mimetype($_));

         return 1 if not @extensions;

         if (any { defined($_) and $basename =~ /\.\Q$_\E\z/ } @extensions) {
             return 1;    # already has extension -- skip
         }

         my $ext     = $extensions[0] // return 1;
         my $newfile = catfile($dirname, $basename . '.' . $ext);

         if (-e $newfile) {
             say ":: $newfile already exists...";
         }
         else {
             say ":: Renaming: $_ -> $newfile";
             rename($_, $newfile);
         }
     },
    } => $dir
);
