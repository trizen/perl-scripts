#~ #!/usr/bin/perl

# Author: Trizen
# Date: 30 July 2022
# https://github.com/trizen

# Gitbook to PDF converter, with syntax highlighting.

# Uses the following tools:
#   md2html         -- for converting Markdown to HTML (provided by md4c)
#   markdown2pdf.pl -- for converting Markdown to PDF (with syntax highlighting)

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';
use HTML::TreeBuilder 5 ('-weak');

use Encode       qw(decode_utf8 encode_utf8);
use Getopt::Long qw(GetOptions);
use URI::Escape  qw(uri_unescape);
use Digest::MD5  qw(md5_hex);

my $md2html      = "md2html";            # path to the `md2html` tool
my $markdown2pdf = "markdown2pdf.pl";    # path to the `markdown2pdf.pl` script

my $style     = 'github';
my $title     = 'Document';
my $page_size = "A3";
my $mathjax   = 0;                       # true to use MathJax

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [SUMMARY.md] [output.pdf]

options:

    --style=s   : style theme for `highlight` (default: $style)
    --title=s   : title of the PDF file (default: $title)
    --size=s    : set paper size to: A4, Letter, etc. (default: $page_size)
    --mathjax!  : enable support for Tex expressions (default: $mathjax)

EOT

    exit($exit_code);
}

GetOptions(
           "style=s"  => \$style,
           "title=s"  => \$title,
           "size=s"   => \$page_size,
           "mathjax!" => \$mathjax,
           "h|help"   => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my $input_markdown_file = $ARGV[0] // usage(2);
my $output_pdf_file     = $ARGV[1] // "OUTPUT.pdf";

say ":: Converting <<$input_markdown_file>> to HTML...";
my $html = `\Q$md2html\E \Q$input_markdown_file\E`;

if ($? != 0) {
    die "`$md2html` failed with code: $?";
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
                            $markdown_content .= <$fh>;
                            $markdown_content .= "\n\n";
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

$markdown_content =~ s{^####+ Output:$}{**Output:**}gm;

$markdown_content =~ s{
    \[(\d+)\]:\s*(https?://.+)
    \s*\R\s*
    \#\s*\[(.+?)\]\[\1\]
}{
    my $t = 'a'.md5_hex(encode_utf8($2));
    "[". $t ."]: $2\n\n# [$3][$t]";
}gex;

open my $fh, '>:utf8', $markdown_file
  or die "Can't open file <<$markdown_file>> for writing: $!";

print $fh $markdown_content;
close $fh;

say ":: Converting Markdown to PDF...";
system($markdown2pdf, ($mathjax ? "--mathjax" : ()), "--style", $style, "--title", $title, "--size", $page_size, $markdown_file, $output_pdf_file);

unlink($markdown_file);

if ($? != 0) {
    die "`$markdown2pdf` failed with code: $?";
}
