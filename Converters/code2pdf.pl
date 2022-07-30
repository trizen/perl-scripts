#!/usr/bin/perl

# Author: Trizen
# Date: 30 July 2022
# https://github.com/trizen

# Code to PDF converter, with syntax highlighting, given a summary file.

# Uses the following tools:
#   md2html         -- for converting markdown to HTML
#   markdown2pdf.pl -- for converting markdown to PDF (with syntax highlighting)

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use HTML::TreeBuilder 5 ('-weak');

use Encode       qw(decode_utf8 encode_utf8);
use Getopt::Long qw(GetOptions);
use URI::Escape  qw(uri_unescape);
use Digest::MD5  qw(md5_hex);

my $markdown2pdf = "markdown2pdf.pl";    # path to the `markdown2pdf.pl` script

my $style     = 'github';
my $title     = 'Document';
my $lang      = 'perl';
my $page_size = "A3";

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [SUMMARY.md] [output.pdf]

options:

    --style=s   : style theme for `highlight` (default: $style)
    --title=s   : title of the PDF file (default: $title)
    --lang=s    : language code used for highlighting (default: $lang)
    --size=s    : set paper size to: A4, Letter, etc. (default: $page_size)

EOT

    exit($exit_code);
}

GetOptions(
           "style=s" => \$style,
           "title=s" => \$title,
           "lang=s"  => \$lang,
           "size=s"  => \$page_size,
           "h|help"  => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my $input_markdown_file = $ARGV[0] // usage(2);
my $output_pdf_file     = $ARGV[1] // "OUTPUT.pdf";

say ":: Converting $input_markdown_file to HTML...";
my $html = `md2html $input_markdown_file`;

if ($? != 0) {
    die "`md2html` failed with code: $?";
}

my $tree = HTML::TreeBuilder->new();
$tree->parse($html);
$tree->eof();

#my @nodes = $tree->guts();
my @nodes = $tree->disembowel();

say ":: Reading Markdown files...";
my $markdown_content = '';

sub expand_ul {
    my ($ul, $depth) = @_;

    foreach my $t (@{$ul->content}) {
        if ($t->tag eq 'li') {
            foreach my $x (@{$t->content}) {

                if (!ref($x)) {
                    $markdown_content .= ("#" x $depth) . ' ' . $x . "\n\n";
                    next;
                }

                if ($x->tag eq 'ul') {
                    expand_ul($x, $depth + 1);
                }
                else {
                    if ($x->tag eq 'a') {

                        my $href = $x->attr('href');
                        my $file = decode_utf8(uri_unescape($href));

                        if (not -e $file) {
                            warn ":: File <<$file>> does not exist. Skipping...\n";
                            next;
                        }

                        if (open my $fh, '<:utf8', $file) {
                            local $/;
                            $markdown_content .= ("#" x $depth) . ' ' . $x->content->[0] . "\n\n";
                            $markdown_content .= "```$lang\n";
                            $markdown_content .= <$fh>;
                            if (substr($markdown_content, -1) ne "\n") {
                                $markdown_content .= "\n";
                            }
                            $markdown_content .= "```\n\n";
                        }
                        else {
                            warn ":: Cannot open file <<$file>> for reading: $!\n";
                        }
                    }
                }
            }
        }
    }
}

foreach my $entry (@nodes) {
    if ($entry->tag eq 'ul') {
        expand_ul($entry, 1);
    }
}

my $markdown_file = "$output_pdf_file.md";

open my $fh, '>:utf8', $markdown_file
  or die "Can't open file <<$markdown_file>> for writing: $!";

print $fh $markdown_content;
close $fh;

say ":: Converting Markdown to PDF...";
system($markdown2pdf, "--style", $style, "--title", $title, "--size", $page_size, $markdown_file, $output_pdf_file);

unlink($markdown_file);

if ($? != 0) {
    die "`$markdown2pdf` failed with code: $?";
}
