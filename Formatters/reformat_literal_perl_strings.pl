#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 12 November 2017
# https://github.com/trizen

# Reformat the literal quoted strings in a Perl source code, using Perl::Tokenizer and Data::Dump.

# Example:
#   'foo姓bar' -> "foo\x{59D3}bar"
#   '\'foo\''  -> "'foo'"

# The literal quoted strings (quoted as: q{...}, qq{...}, '...' or "...") will be reformated as "...".

# Strings which (potentially) include variable interpolations, are ignored.

# The input source code must be UTF-8 encoded.

use utf8;
use 5.018;
use warnings;

use open IO => ':encoding(UTF-8)', ':std';

use Data::Dump qw(pp);
use Perl::Tokenizer qw(perl_tokens);

# usage: perl script.pl < source.pl
my $code = join('', <>);

perl_tokens {
    my ($name, $i, $j) = @_;

    if (   $name eq 'single_quoted_string'
        or $name eq 'double_quoted_string'
        or $name eq 'qq_string'
        or $name eq 'q_string') {

        my $str = substr($code, $i, $j - $i);

        my $eval_code = join(
                             ';',
                             'my $str = qq{' . quotemeta($str) . '}',    # quoted string
                             'die if $str =~ tr/@$//',                   # skip strings with interpolation
                             '$str = eval $str',                         # evaluate string
                             'die if $@',                                # check the status of eval()
                             '$str',                                     # string content
                            );

        my $raw_str = eval($eval_code);

        if (defined($raw_str) and !$@) {
            print scalar pp($raw_str);
            return;
        }
    }

    print substr($code, $i, $j - $i);
} $code;
