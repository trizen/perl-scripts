#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 January 2017
# https://github.com/trizen

# Checks English words for spelling errors in Perl code.
# It tries to minimize false positives as much as possible.

use 5.014;
use strict;
use warnings;

use Text::Hunspell;
use List::Util qw(max);
use File::Find qw(find);
use Perl::Tokenizer qw(perl_tokens);
use Text::JaroWinkler qw(strcmp95);
use Getopt::Long qw(GetOptions :config no_ignore_case);

binmode(STDOUT, ':utf8');

my $similarity     = 90 / 100;
my $min_word_len   = 6;
my $aggressive     = 0;
my $non_word_split = 0;
my $scan_cats      = 'com,str';

sub help {
    my ($code) = @_;

    my $p = sprintf('%.0f', $similarity * 100);

    print <<"HELP";
usage: $0 [options] [files]

Options:
        -m  --minimum=f     : minimum length for words (default: $min_word_len)
        -p  --percentage=f  : minimum similarity percentage (default: $p)
        -W  --W-split!      : split by non-word characters (default: by space)
        -s  --scan=s        : categories of tokens to scan (default: "$scan_cats")

All the possible categories for --scan are:

    pod     : scan pod sections (including __END__)
    str     : scan strings (including here-documents)
    com     : scan comments
    var     : scan variable names
    sub     : scan subroutine declarations
    bar     : scan barewords (including subroutine/method calls)
    all     : scan all categories

Example:
    $0 --scan=pod,com --percentage=75 /my/script.pl

HELP

    exit($code);
}

my $percentage;

GetOptions(
           'm|minimum=i'    => \$min_word_len,
           'p|percentage=f' => \$percentage,
           's|scan=s'       => \$scan_cats,
           'W|W-split!'     => \$non_word_split,
           'h|help'         => sub { help(0) },
          )
  or die("Error in command line arguments");

my $scan_pod         = $scan_cats =~ /\bpod/;
my $scan_strings     = $scan_cats =~ /\bstr/;
my $scan_comments    = $scan_cats =~ /\bcom/;
my $scan_variables   = $scan_cats =~ /\bvar/;
my $scan_subroutines = $scan_cats =~ /\bsub/;
my $scan_barewords   = $scan_cats =~ /\bbar/;

if ($scan_cats =~ /\ball/) {
    $scan_pod         = 1;
    $scan_strings     = 1;
    $scan_comments    = 1;
    $scan_variables   = 1;
    $scan_subroutines = 1;
    $scan_barewords   = 1;
}

if (    not $scan_pod
    and not $scan_strings
    and not $scan_comments
    and not $scan_variables
    and not $scan_subroutines
    and not $scan_barewords) {
    die "Invalid value for `--scan`: <<$scan_cats>>";
}

if (defined $percentage) {
    $similarity = $percentage / 100;
}

#<<<
my $speller = Text::Hunspell->new(
    "/usr/share/hunspell/en_US.aff",
    "/usr/share/hunspell/en_US.dic",
) or die "Can't create the speller object: $!";
#>>>

@ARGV || help(2);

@ARGV = reverse(@ARGV);

while (@ARGV) {

    my %seen;
    my $file = pop @ARGV;

    if (-d $file) {
        find {
            no_chdir => 1,
            wanted   => sub {
                if (-f($_) and /\.p[lm]\z/) {
                    push @ARGV, $_;
                }
            },
        } => $file;
        next;
    }

    open my $fh, '<:encoding(UTF-8)', $file or next;
    local $SIG{__WARN__} = sub { };
    my $code = eval { local $/; <$fh> } // next;

    say "\n** Scanning: $file";

    perl_tokens {
        my ($token, $i, $j) = @_;

        my $string;

        if ($scan_strings) {
            if ($token eq 'q_string') {
                $string = substr($code, $i + 2, $j - $i - 3);
            }
            elsif (   $token eq 'qq_string'
                   or $token eq 'qw_string') {
                $string = substr($code, $i + 3, $j - $i - 4);
            }
            elsif (   $token eq 'double_quoted_string'
                   or $token eq 'single_quoted_string') {
                $string = substr($code, $i + 1, $j - $i - 2);
            }
            elsif ($token eq 'heredoc') {
                $string = substr($code, $i, $j - $i);
                $string =~ s/.*\K\R.*//s;
            }
        }

        if ($scan_comments) {
            if ($token eq 'comment') {
                $string = substr($code, $i + 1, $j - $i - 1);
            }
        }

        if ($scan_pod) {
            if (   $token eq 'pod'
                or $token eq 'data') {
                $string = substr($code, $i, $j - $i);
            }
        }

        if ($scan_variables) {
            if ($token eq 'var_name') {
                $string = substr($code, $i, $j - $i);
            }
        }

        if ($scan_subroutines) {
            if ($token eq 'sub_name') {
                $string = substr($code, $i, $j - $i);
            }
        }

        if ($scan_barewords) {
            if ($token eq 'bare_word') {
                $string = substr($code, $i, $j - $i);
            }
        }

        if (defined $string) {
            foreach my $word (
                              $non_word_split
                              ? split(/[^\pL]+/, $string)
                              : split(' ',       $string)
              ) {

                if (!$non_word_split) {
                    $word =~ s/^[^\pL]+//;
                    $word =~ s/[^\pL]+\z//;
                }

                $word !~ /^[\pL]+\z/          and next;
                length($word) < $min_word_len and next;
                $seen{$word}++                and next;
                $speller->check($word)        and next;

                my @suggestions = $speller->suggest($word);

                if (    @suggestions
                    and lc($suggestions[0]) ne lc($word)
                    and $suggestions[0] !~ / /) {
                    my $score = strcmp95($suggestions[0], $word, max(length($suggestions[0]), length($word)));

                    if ($score >= $similarity) {
                        printf "[%.2f] %-20s => [%s]\n", $score, $word, join(', ', @suggestions);
                    }
                }
            }
        }
    } $code;
}
