
#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 13 January 2016
# http://github.com/trizen

# Finds files which have almost the same content, using the Levenshtein distance.

#
## WARNING! For strict duplicates, use the 'fdf' script:
#   https://github.com/trizen/perl-scripts/blob/master/Finders/fdf
#

use 5.010;
use strict;
use warnings;

use Fcntl qw(O_RDONLY);
use File::Find qw(find);
use Getopt::Long qw(GetOptions);
use Text::LevenshteinXS qw(distance);
use Number::Bytes::Human qw(parse_bytes);

my $unique    = 0;
my $threshold = 70;
my $max_size  = '100KB';

sub help {
    my ($code) = @_;

    print <<"HELP";
usage: $0 [options] [/dir/a] [/dir/b] [...]

options:
    -s  --size=s      : maximum file size (default: $max_size)
    -u  --unique!     : don't include a file in more groups (default: false)
    -t  --threshold=f : threshold percentage (default: $threshold)

Example:
    perl $0 ~/Documents

HELP

    exit($code // 0);
}

GetOptions(
           's|size=s'      => \$max_size,
           'u|unique!'     => \$unique,
           't|threshold=f' => \$threshold,
           'h|help'        => \&help,
          )
  or die("Error in command line arguments");

@ARGV || help();
$max_size = parse_bytes($max_size);

sub look_similar {
    my ($f1, $f2) = @_;

    sysopen my $fh1, $f1, O_RDONLY or return;
    sysopen my $fh2, $f2, O_RDONLY or return;

    my $s1 = (-s $f1) || (-s $fh1);
    my $s2 = (-s $f2) || (-s $fh2);

    my ($min, $max) = $s1 < $s2 ? ($s1, $s2) : ($s2, $s1);

    my $diff = int($max * (100 - $threshold) / 100);
    ($max - $min) > $diff and return;

    sysread($fh1, (my $c1), $s1) || return;
    sysread($fh2, (my $c2), $s2) || return;

    distance($c1, $c2) <= $diff;
}

sub find_similar_files (&@) {
    my $code = shift;

    my %files;
    find {
        no_chdir => 1,
        wanted   => sub {
            lstat;
            (-f _) && (not -l _) && do {
                my $size = -s _;
                if ($size <= $max_size) {

                    # TODO: better grouping
                    push @{$files{int log $size}}, $File::Find::name;
                }
            };
        }
    } => @_;

    foreach my $key (sort { $a <=> $b } keys %files) {

        next if $#{$files{$key}} < 1;
        my @files = @{$files{$key}};

        my %dups;
        foreach my $i (0 .. $#files - 1) {
            for (my $j = $i + 1 ; $j <= $#files ; $j++) {
                if (look_similar($files[$i], $files[$j])) {
                    push @{$dups{$files[$i]}},
                      (
                        $unique
                        ? splice(@files, $j--, 1)
                        : $files[$j]
                      );
                }
            }
        }

        while (my ($fparent, $fdups) = each %dups) {
            $code->(sort $fparent, @{$fdups});
        }
    }

    return 1;
}

{
    local $, = "\n";
    find_similar_files {
        say @_, "-" x 80 if @_;
    }
    @ARGV;
}
