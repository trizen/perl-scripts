#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 23 July 2015
# http://github.com/trizen

# Find files which have almost the same content (at least, mathematically).

#
## WARNING! For strict duplicates, use the 'fdf' script:
#   https://github.com/trizen/perl-scripts/blob/master/Finders/fdf
#

use 5.014;
use strict;
use warnings;

use Math::BigInt (try => 'GMP');

use File::Find qw(find);
use Getopt::Long qw(GetOptions);

sub help {
    my ($code) = @_;

    print <<"HELP";
usage: $0 [options] /my/path [...]

Options:
    -w  --whitespaces! : remove whitespaces (default: false)
    -u  --unique!      : don't include a file in more groups (default: false)
    -h  --help         : print this message and exit

Example:
    $0 -w ~/Documents

HELP

    exit($code // 0);
}

my $strip_spaces = 0;    # bool
my $unique       = 0;    # bool

GetOptions(
           'w|whitespaces!' => \$strip_spaces,
           'u|unique!'      => \$unique,
           'h|help'         => \&help,
          )
  or die("Error in command line arguments");

sub hash ($) {
    my ($str) = @_;

    $strip_spaces
      and $str =~ s/\s+//g;

    state $ten = Math::BigInt->new(10);

    my $hash1 = Math::BigInt->new(0);
    my $pow   = Math::BigInt->new(1);

    state $chars = {};
    my @chars = map { $chars->{$_} //= Math::BigInt->new($_) } unpack("C*", $str);

    foreach my $char (@chars) {
        $hash1->badd($pow->copy->bmul($char));
        $pow->bmul($ten);
    }

    return $hash1;
}

sub hash_file ($) {
    my ($file) = @_;
    open my $fh, '<:raw', $file;
    hash(
         do { local $/; <$fh> }
        );
}

sub alike_hashes ($$) {
    my ($h1, $h2) = @_;

    my $pow = abs($h1->copy->blog(10) - $h2->copy->blog(10));

    my $ratio = ($h2 > $h1 ? ($h2 / $h1) : ($h1 / $h2));
    my $limit = 10**$pow;

    $ratio == $limit;
}

sub find_similar_files (&@) {
    my $code = shift;

    my @files;
    find {
        wanted => sub {
            (-f)
              && push @files,
              {
                hash => hash_file($File::Find::name),
                name => $File::Find::name,
              };
        }
    } => @_;

    my %dups;
    foreach my $i (0 .. $#files - 1) {
        for (my $j = $i + 1 ; $j <= $#files ; $j++) {
            if (alike_hashes($files[$i]{hash}, $files[$j]{hash})) {
                push @{$dups{$files[$i]{name}}},
                  (
                    $unique
                    ? ${splice @files, $j--, 1}{name}
                    : $files[$j]{name}
                  );
            }
        }
    }

    while (my ($fparent, $fdups) = each %dups) {
        $code->(sort $fparent, @{$fdups});
    }

    return 1;
}

{
    @ARGV || help(1);
    local $, = "\n";
    find_similar_files {
        say @_, "-" x 80 if @_;
    }
    @ARGV;
}
