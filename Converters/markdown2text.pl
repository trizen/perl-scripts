#!/usr/bin/perl

# Author: Trizen
# Date: 19 November 2023
# https://github.com/trizen

# Convert Markdown to text (UTF-8).

# # Using the following tool:
#   md2html -- for converting Markdown to HTML (provided by md4c)

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use HTML::TreeBuilder 5 qw(-weak);
use HTML::FormatText    qw();
use Getopt::Long        qw(GetOptions);
use File::Temp          qw(tempfile);
use Encode              qw(encode_utf8 decode_utf8);

binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');

my $md2html = "md2html";    # path to the `md2html` tool

sub read_input ($source) {

    if (ref($source) eq 'GLOB') {
        my $content = do {
            local $/;
            <$source>;
        };
        return $content;
    }

    my $content = do {
        open my $fh, '<:utf8', $source
          or die "Can't open file <<$source>> for reading: $!";
        local $/;
        <$fh>;
    };

    return $content;
}

sub html2text ($html, $formatter) {

    my $tree = HTML::TreeBuilder->new();
    $tree->parse($html);
    $tree->eof();
    $tree->elementify();    # just for safety

    my $text = $formatter->format($tree);

    return $text;
}

my $left_margin  = 0;
my $right_margin = 80;

sub usage ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [input.md]

    -lm  --left=i   : the column of the left margin. (default: $left_margin)
    -rm  --right=i  : the column of the right margin. (default: $right_margin)
EOT

    exit($exit_code);
}

GetOptions(
           "lm|left=i"  => \$left_margin,
           "rm|right=i" => \$right_margin,
           "h|help"     => sub { usage(0) },
          )
  or do {
    warn("Error in command line arguments\n");
    usage(1);
  };

my $stdin_on_tty = -t STDIN;

if (not $stdin_on_tty) {    # assume input provided via STDIN
    ## ok
}
else {
    @ARGV || do {
        warn "\nerror: no input file provided!\n\n";
        usage(2);
    };
}

my $formatter = HTML::FormatText->new(leftmargin  => $left_margin,
                                      rightmargin => $right_margin,);

my $markdown = read_input($stdin_on_tty ? $ARGV[0] : \*STDIN);
$markdown // die "error: unable to read Markdown content";

my ($md_fh, $md_file) = tempfile();
print $md_fh encode_utf8($markdown);
close $md_fh;

my $html = decode_utf8(scalar `\Q$md2html\E --github \Q$md_file\E`);

unlink($md_file);

my $text = html2text($html, $formatter);
$text // die "error: unable to extract text";

print $text;
