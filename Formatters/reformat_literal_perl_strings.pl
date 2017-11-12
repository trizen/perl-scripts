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

use Symbol qw(gensym);
use Data::Dump qw(pp);
use IPC::Open3 qw(open3);
use Perl::Tokenizer qw(perl_tokens);
use Encode qw(encode_utf8 decode_utf8);

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
                             'binmode STDOUT, ":utf8"',                             # encode as UTF-8
                             'my $str = quotemeta(qq{' . quotemeta($str) . '})',    # escaped string
                             'die if $str =~ /\\\\[\$\@]/',                         # skip strings with interpolation
                             '$str =~ s/\\\\(.)/$1/gs',                             # unescape string
                             '$str = eval $str',                                    # evaluate string
                             'die if $@',                                           # check the status of evaluation
                             'print $str',                                          # print the string
                            );

        my $in  = gensym();
        my $out = gensym();
        my $err = gensym();

        if (open3($in, $out, $err, $^X, '-Mutf8', '-Mstrict', '-e', encode_utf8($eval_code))) {
            my $err_msg = join('', <$err>);

            if ($err_msg eq '') {
                my $raw_str = decode_utf8(join('', <$out>));
                print scalar pp($raw_str);
                return;
            }
        }
    }

    print substr($code, $i, $j - $i);
} $code;
