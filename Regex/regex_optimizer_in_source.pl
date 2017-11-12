#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 November 2017
# https://github.com/trizen

# Optimize regular expressions in a given Perl source code, using Perl::Tokenizer and Regexp::Optimizer.

# Example:
#   qr/foobar|fooxar|foozap$/im  -> qr/foo(?:[bx]ar|zap$)/im
#    m/foobar|fooxar|foozap$/gci ->   /foo(?:[bx]ar|zap$)/cgi

# Regexes which (potentially) include variable interpolation, are ignored.

# The input source code must be UTF-8 encoded.

use utf8;
use 5.018;
use warnings;

use open IO => ':encoding(UTF-8)', ':std';

use Regexp::Optimizer;
use Data::Dump qw(pp);
use Perl::Tokenizer qw(perl_tokens);
use Encode qw(decode_utf8 encode_utf8);

# usage: perl script.pl < source.pl
my $code = join('', <>);

my $regexp_optimizer = Regexp::Optimizer->new;

perl_tokens {
    my ($name, $i, $j) = @_;

    if (   $name eq 'match_regex'
        or $name eq 'compiled_regex') {

        my $str = substr($code, $i, $j - $i);

        my @flags;

        if ($name eq 'match_regex') {

            $str =~ s/^m//;
            $str = 'qr' . $str;

            if ($str =~ s/^.*\Kg([a-z]*)\z/$1/s) {
                push @flags, 'g';
            }

            if ($str =~ s/^.*\Kc([a-z]*)\z/$1/s) {
                push @flags, 'c';
            }
        }

        my $eval_code = join(
                             ';',
                             'my $str = qq{' . quotemeta(encode_utf8($str)) . '}',    # quoted string
                             'die if $str =~ /[\$\@][{\\w]/',                         # skip regexes with interpolation
                             '$str = eval $str',                                      # evaluate string
                             'die if $@',                                             # check the status of eval()
                             '$str',                                                  # regex ref
                            );

        my $raw_str = eval($eval_code);

        if (defined($raw_str) and !$@) {

            my $regex_str = eval { decode_utf8(pp($regexp_optimizer->optimize($raw_str))) };

            if (defined($regex_str)) {

                my ($delim_beg, $delim_end);

                if ($regex_str =~ /^qr(.)\(\?\^([a-z]+):(.*)\)(.)\z/s) {
                    ($delim_beg, $regex_str, $delim_end) = ($1, $3, $4);
                    push @flags, split(//, $2);
                }

#<<<
                $regex_str = join('',
                    $delim_beg, $regex_str, $delim_end,
                        (sort { $a cmp $b } grep { $_ ne 'u' } @flags)
                );
#>>>

                if ($name eq 'match_regex') {
                    $regex_str = 'm' . $regex_str if ($regex_str !~ m{^/});
                }
                else {
                    $regex_str = 'qr' . $regex_str;
                }

                print $regex_str;
                return;
            }
        }
    }

    print substr($code, $i, $j - $i);
} $code;
