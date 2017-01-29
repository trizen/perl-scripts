#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# Date: 14 December 2014
# Edit: 14 December 2016
# License: GPLv3
# https://github.com/trizen

# Extract the text and the skeleton from a SRT file.

# The text can be translated into another language, then
# joined back with the SRT skeleton into a new SRT file.

use utf8;
use 5.010;
use strict;
use autodie;
use warnings;

use experimental qw(signatures);

use Getopt::Std qw(getopts);
use File::BOM qw(get_encoding_from_filehandle);

sub usage {
    my ($code) = @_;
    require File::Basename;
    my $main = File::Basename::basename($0);
    print <<"EOF";
usage: $main [options] [input file]

options:
    -j  : join text with template
    -t  : name of the template file

example:
    $main -t file.t file.srt > file.text
    $main -t file.t file.text > new_file.srt
EOF

    exit($code // 0);
}

sub prepare_words ($words, $width, $callback, $depth = 0) {

    my @root;
    my $len = 0;
    my $i   = -1;

    my $limit = $#{$words};
    while (++$i <= $limit) {
        $len += (my $word_len = length($words->[$i]));

        if ($len > $width) {
            if ($word_len > $width) {
                $len -= $word_len;
                splice(@$words, $i, 1, unpack("(A$width)*", $words->[$i]));
                $limit = $#{$words};
                --$i;
                next;
            }
            last;
        }

#<<<
        push @root, [
            join(' ', @{$words}[0 .. $i]),
            prepare_words([@{$words}[$i + 1 .. $limit]], $width, $callback, $depth + 1),
        ];
#>>>

        if ($depth == 0) {
            $callback->($root[0]);
            @root = ();
        }

        last if (++$len > $width);
    }

    \@root;
}

sub combine ($path, $callback, $root = []) {
    my $key = shift(@$path);
    foreach my $value (@$path) {
        push @$root, $key;
        if (@$value) {
            foreach my $item (@$value) {
                combine($item, $callback, $root);
            }
        }
        else {
            $callback->($root);
        }
        pop @$root;
    }
}

sub smart_wrap ($text, $width) {

    my @words = (
                 ref($text) eq 'ARRAY'
                 ? @{$text}
                 : split(' ', $text)
                );

    my %best = (
                score => 'inf',
                value => [],
               );

    prepare_words(
        \@words,
        $width,
        sub ($path) {
            combine(
                $path,
                sub ($combination) {
                    my $score = 0;
                    foreach my $line (@$combination) {
                        $score += ($width - length($line))**2;
                        return if $score >= $best{score};
                    }
                    $best{score} = $score;
                    $best{value} = [@$combination];
                }
            );
        }
    );

    join("\n", @{$best{value}});
}

sub disassemble ($srt_file, $template_file) {

    open(my $srt_fh,  '<:crlf', $srt_file);
    open(my $tmpl_fh, '>',      $template_file);

    my $enc = get_encoding_from_filehandle($srt_fh);

    if (defined($enc) and $enc ne '') {
        binmode($srt_fh, ":encoding($enc)");
        binmode(STDOUT,  ":encoding($enc)");
    }

    local $/ = "";    # paragraph mode
    while (defined(my $para = <$srt_fh>)) {
        if (
            $para =~ /^
        (?<i>[0-9]+)\h*\R

        (?<from>[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})
                     \h*-->\h*
        (?<to>[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})\h*\R

        (?<text>.+)/sx
          ) {
            print {$tmpl_fh} "$+{i}\n$+{from} --> $+{to}\n%s\n\n";

            my $text = $+{text};
            $text =~ s/<.*?>//gs;    # remove HTML tags
                                     # (consider this a bug)

            print join(' ', split(' ', $text)), "\n\n";
        }
        else {
            die "[ERROR] Invalid paragraph:
{{->>BEGIN<<-}}
$para
{{->>END<<-}}\n";
        }
    }

    close $srt_fh;
    close $tmpl_fh;
}

sub assemble ($text_file, $template_file) {

    open my $txt_fh,  '<:crlf', $text_file;
    open my $tmpl_fh, '<:crlf', $template_file;

    my $enc = get_encoding_from_filehandle($txt_fh)
      || get_encoding_from_filehandle($tmpl_fh);

    if (defined($enc) and $enc ne '') {
        binmode($txt_fh,  ":encoding($enc)");
        binmode($tmpl_fh, ":encoding($enc)");
        binmode(STDOUT,   ":encoding($enc)");
    }

    local $/ = "";
    while (defined(my $text = <$txt_fh>)) {
        my $format = <$tmpl_fh> // die "Unexpected error: template file is shorter than text!";

        $text =~ s/[?!.)\]"']\K\h+([-‒―—]+)(?=\h)/\n$1/g;
        $text = join("\n", map { length($_) <= 45 ? $_ : smart_wrap($_, 45) } split(/\R/, $text));

        printf($format, $text);
    }

    close $txt_fh;
    close $tmpl_fh;
}

my %opt;
getopts('jt:h', \%opt);

my $input_file    = shift(@ARGV) // usage(1);
my $template_file = $opt{t}      // ($input_file =~ s/\.\w{1,5}\z//r . '.template');

$opt{j} || ($input_file !~ /\.srt\z/)
  ? assemble($input_file, $template_file)
  : disassemble($input_file, $template_file);
