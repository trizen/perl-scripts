#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 04 January 2015
# Website: http://github.com/trizen

#
## Analyze your Perl code and see whether you are or not a true Perl hacker!
#

# More info about this script:
# http://trizenx.blogspot.com/2015/01/perl-code-analyzer.html

use utf8;
use 5.010;
use strict;
use warnings;

use IPC::Open3 qw(open3);
use Encode qw(decode_utf8);
use Getopt::Long qw(GetOptions);
use Algorithm::Diff qw(LCS_length);
use Perl::Tokenizer qw(perl_tokens);

my $strict_level = 1;
my %ignored_types;

sub help {
    my ($code) = @_;
    print <<"HELP";
usage: $0 [options] [file] [...]

options:
    --strict [level]   : sets the strictness level (default: $strict_level)

Valid strict levels:
    >= 1   : ignores strings, PODs, comments, spaces and semicolons
    >= 2   : ignores round parentheses
    >= 3   : ignores here-documents, (q|qq|qw|qx) quoted strings
    >= 4   : ignores hex and binary literal numbers

If level=0, any stricture will be disabled.
HELP
    exit($code // 0);
}

GetOptions('strict=i' => \$strict_level,
           'help|h'   => sub { help(0) },)
  or die("Error in command line arguments\n");

@ARGV || help(2);

if ($strict_level >= 1) {
    @ignored_types{
        qw(
          pod
          data
          comment
          vertical_space
          horizontal_space
          other_space
          semicolon
          double_quoted_string
          single_quoted_string
          )
    } = ();
}

if ($strict_level >= 2) {
    @ignored_types{
        qw(
          parenthesis_open
          parenthesis_close
          )
    } = ();
}

if ($strict_level >= 3) {
    @ignored_types{
        qw(
          heredoc
          heredoc_beg
          q_string
          qq_string
          qw_string
          qx_string
          )
    } = ();
}

if ($strict_level >= 4) {
    @ignored_types{
        qw(
          hex_number
          binary_number
          )
    } = ();
}

sub deparse {
    my ($code) = @_;

    local (*CHLD_IN, *CHLD_OUT, *CHLD_ERR);
    my $pid = open3(\*CHLD_IN, \*CHLD_OUT, \*CHLD_ERR, $^X, '-MO=Deparse', '-T');

    binmode(CHLD_IN, ':utf8');
    print CHLD_IN "$code\n\cD";
    close(CHLD_IN);

    #waitpid($pid, 0);
    my $child_exit_status = $? >> 8;
    if ($child_exit_status != 0) {
        die "B::Deparse failed with code: $child_exit_status\n";
    }

    decode_utf8(
                do { local $/; <CHLD_OUT> }
               );
}

sub get_tokens {
    my ($code) = @_;
    my @tokens;
    perl_tokens {
        my ($token) = @_;
        if (not exists $ignored_types{$token}) {
            push @tokens, $token;
        }
    }
    $code;
    return @tokens;
}

foreach my $script (@ARGV) {

    print STDERR "=> Analyzing: $script\n";

    my $code = do {
        open my $fh, '<:utf8', $script;
        local $/;
        <$fh>;
    };

    my $d_code = eval { deparse($code) };
    $@ && do { warn $@; next };

    my @types   = get_tokens($code);
    my @d_types = get_tokens($d_code);

    if (@types == 0 or @d_types == 0) {
        warn "This script seems to be empty! Skipping...\n";
        next;
    }

    my $len = LCS_length(\@types, \@d_types) - abs(@types - @d_types);
    my $score = (100 - ($len / @types * 100));

    if ($score >= 60) {
        printf("WOW!!! We have here a score of %.2f! This is obfuscation, isn't it?\n", $score);
    }
    elsif ($score >= 40) {
        printf("Outstanding! This code seems to be written by a true legend! Score: %.2f\n", $score);
    }
    elsif ($score >= 20) {
        printf("Amazing! This code is very unique! Score: %.2f\n", $score);
    }
    elsif ($score >= 15) {
        printf("Excellent! This code is written by a true Perl hacker. Score: %.2f\n", $score);
    }
    elsif ($score >= 10) {
        printf("Awesome! This code is written by a Perl expert. Score: %.2f\n", $score);
    }
    elsif ($score >= 5) {
        printf("Just OK! We have a score of %.2f! This is production code, isn't it?\n", $score);
    }
    else {
        printf("What is this? I guess it is some baby Perl code, isn't it? Score: %.2f\n", $score);
    }
}
