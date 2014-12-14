#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# Date: 14 December 2014
# License: GPLv3
# Website: https://github.com/trizen

# Extract text and scheleton from a srt file
# translate the text into another language
# and join back the text with the srt scheleton.

use 5.010;
use strict;
use autodie;
use warnings;

use Getopt::Std qw(getopts);
use Text::Reflow qw(reflow_string);
use File::BOM qw(get_encoding_from_filehandle);

sub usage {
    my ($code) = @_;
    print <<"EOF";
usage: $0 [options] [input file]

options:
    -j  : join text with template
    -t  : name of the template file

example:
    $0 -t file.t file.srt > file.text
    $0 -t file.t file.text > new_file.srt
EOF

    exit($code // 0);
}

sub disassemble {
    my ($srt_file, $template_file) = @_;

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

            print reflow_string($text, maximum => 1024, optimum => 1024);
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

sub assemble {
    my ($text_file, $template_file) = @_;

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
        my $text = reflow_string($text, optimum => [25 .. 30], maximum => 36);
        printf($format, unpack('A*', $text));
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
