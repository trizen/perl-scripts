#!/usr/bin/perl

# Author: Trizen
# Date: 29 July 2022
# Edit: 05 January 2024
# https://github.com/trizen

# Markdown to PDF converter, with syntax highlighting.

# Using the following tools:
#   md2html     -- for converting Markdown to HTML (provided by md4c)
#   highlight   -- for syntax highlighting
#   wkhtmltopdf -- for converting HTML to PDF

use 5.010;
use strict;
use warnings;

use open IO => ':utf8', ':std';

use HTML::TreeBuilder 5 ('-weak');
use HTML::Entities qw(encode_entities);

use IPC::Run3    qw(run3);
use File::Temp   qw(tempfile);
use Encode       qw(decode_utf8 encode_utf8);
use Getopt::Long qw(GetOptions);

my $md2html = "md2html";    # path to the `md2html` tool

my $syntax_lang = 'text';
my $style       = 'github';
my $title       = 'Document';
my $page_size   = 'A3';
my $mathjax     = 0;            # true to use MathJax.js
my $js_delay    = 3000;         # in ms
my $keep_html   = 0;

sub usage {
    my ($exit_code) = @_;
    $exit_code //= 0;

    print <<"EOT";
usage: $0 [options] [input.md] [output.pdf]

options:

    --style=s    : style theme for `highlight` (default: $style)
    --title=s    : title of the PDF file (default: $title)
    --size=s     : set paper size to: A4, Letter, etc. (default: $page_size)
    --lang=s     : default syntax highlighting language (default: $syntax_lang)
    --mathjax!   : enable support for Tex expressions (default: $mathjax)
    --js-delay=i : JavaScript delay in ms (with --mathjax) (default: $js_delay)
    --html!      : keep the intermediary HTML file (default: $keep_html)

EOT

    exit($exit_code);
}

GetOptions(
           "lang=s"     => \$syntax_lang,
           "style=s"    => \$style,
           "title=s"    => \$title,
           "size=s"     => \$page_size,
           "mathjax!"   => \$mathjax,
           "js-delay=i" => \$js_delay,
           "html!"      => \$keep_html,
           "h|help"     => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my $input_markdown_file = $ARGV[0] // usage(2);
my $output_pdf_file     = $ARGV[1] // ($input_markdown_file . ".pdf");

say ":: Converting Markdown to HTML...";
my $html = `\Q$md2html\E --github \Q$input_markdown_file\E`;

if ($? != 0) {
    die "`$md2html` failed with code: $?";
}

my $tree = HTML::TreeBuilder->new();
$tree->parse($html);
$tree->eof();

#my @nodes = $tree->guts();
my @nodes = $tree->disembowel();

my @highlight = qw(highlight --fragment -t 4 --no-trailing-nl -O html --encoding utf-8);

my ($in_fh,  $tmp_in_file)  = tempfile();
my ($out_fh, $tmp_out_file) = tempfile();

my $html_content = '';

say ":: Syntax highlighting...";

foreach my $entry (@nodes) {

    ref($entry) || next;

    my $code = $entry->as_HTML(undef, undef, {});

    if ($entry->tag eq 'pre') {

        my $t = $entry->content->[0];

        if ($t->tag eq 'code') {

            my $lang = $syntax_lang;

            my $class = $t->attr('class');
            if (defined($class) and $class =~ /^language-(.+)/) {
                $lang = $1;
            }

            if ($lang eq 'text' or $lang eq 'none' or $lang eq '') {    # no need to highlight plaintext
                $html_content .= $code;
                next;
            }

            my $content = $t->content() // next;

            if (ref($content) ne 'ARRAY') {
                warn ":: Unexpected entry: <<$content>>\n";
                next;
            }

            my $str = join(' ', @{$content});
            print $in_fh encode_utf8($str);
            seek($in_fh, 0, 0);

            run3([@highlight, '--syntax', $lang, '--style', $style], $in_fh, $out_fh);

            if ($? != 0) {
                die ":: Can't execute the `highlight` command!";
            }

            $code = "<pre class=hl>" . do {
                seek($out_fh, 0, 0);
                local $/;
                decode_utf8(<$out_fh>);
              }
              . "</pre>";

            seek($in_fh,  0, 0);
            seek($out_fh, 0, 0);

            truncate($in_fh,  0);
            truncate($out_fh, 0);
        }
    }

    $html_content .= $code;
}

$title = encode_entities(decode_utf8($title));

my $final_html = <<"HTML";
<!DOCTYPE html>
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>$title</title>
HTML

if ($mathjax) {

    # Reference: https://stackoverflow.com/questions/34347818/using-mathjax-on-a-github-page
    say ":: Adding MathJax support...";
    $final_html .= <<'HTML';
<script type="text/javascript" charset="utf-8"
src="https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML,
https://vincenttam.github.io/javascripts/MathJaxLocal.js"></script>
HTML
}

my $css = `highlight --print-style -O html --style \Q$style\E --stdout`;

$final_html .= <<'HTML';
<style type="text/css">
/*<![CDATA[*/
<!--
HTML

$final_html .= $css;

$final_html .= do {
    local $/;
    <DATA>;
};

$final_html .= <<'HTML';
-->
/*]]>*/
</style>
HTML

$final_html .= <<'HTML';
</head>
<body class="markdown-body">
HTML

$final_html .= $html_content;

$final_html .= <<'HTML';
</body>
</html>
HTML

my $tmp_html_file = $output_pdf_file . '.html';

do {
    open my $fh, '>:utf8', $tmp_html_file
      or die "Can't create file <<$tmp_html_file>>: $!";
    print $fh $final_html;
    close $fh;
};

say ":: Converting HTML to PDF...";

system(
    qw(wkhtmltopdf
      --quiet
      --enable-smart-shrinking
      --images
      --enable-external-links
      --enable-local-file-access
      --load-error-handling ignore),
    "--page-size",
    $page_size,
    (
     $mathjax
     ? ('--enable-javascript', '--javascript-delay', $js_delay)
     : ()
    ),
    $tmp_html_file,
    $output_pdf_file,
);

unlink($tmp_in_file, $tmp_out_file);
unlink($tmp_html_file) if not $keep_html;

if ($? != 0) {
    die "`wkhtmltopdf` failed with code: $?";
}

say ":: Done!"

__DATA__
/* theme "github.css" from md2pdf */

@font-face {
  font-family: octicons-anchor;
  src: url(data:font/woff;charset=utf-8;base64,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) format('woff');
}

.markdown-body {
  -ms-text-size-adjust: 100%;
  -webkit-text-size-adjust: 100%;
  color: #333;
  overflow: hidden;
  font-family: "Helvetica Neue", Helvetica, "Segoe UI", Arial, freesans, sans-serif;
  font-size: 16px;
  line-height: 1.6;
  word-wrap: break-word;
  /*padding: 3.17cm 2.54cm 2.54cm 2.54cm;*/
  padding: 0;
}

.markdown-body a {
  background: transparent;
}

.markdown-body a:active,
.markdown-body a:hover {
  outline: 0;
}

.markdown-body strong {
  font-weight: bold;
}

.markdown-body h1 {
  font-size: 2em;
  margin: 0.67em 0;
}

.markdown-body img {
  border: 0;
}

.markdown-body hr {
  -moz-box-sizing: content-box;
  box-sizing: content-box;
  height: 0;
}

.markdown-body pre {
  overflow: auto;
}

.markdown-body code,
.markdown-body kbd,
.markdown-body pre {
  font-family: monospace, monospace;
  font-size: 1em;
}

.markdown-body input {
  color: inherit;
  font: inherit;
  margin: 0;
}

.markdown-body html input[disabled] {
  cursor: default;
}

.markdown-body input {
  line-height: normal;
}

.markdown-body input[type="checkbox"] {
  -moz-box-sizing: border-box;
  box-sizing: border-box;
  padding: 0;
}

.markdown-body table {
  border-collapse: collapse;
  border-spacing: 0;
}

.markdown-body td,
.markdown-body th {
  padding: 0;
}

.markdown-body * {
  -moz-box-sizing: border-box;
  box-sizing: border-box;
}

.markdown-body input {
  font: 13px/1.4 Helvetica, arial, freesans, clean, sans-serif, "Segoe UI Emoji", "Segoe UI Symbol";
}

.markdown-body a {
  color: #4183c4;
  text-decoration: none;
}

.markdown-body a:hover,
.markdown-body a:active {
  text-decoration: underline;
}

.markdown-body hr {
  height: 0;
  margin: 15px 0;
  overflow: hidden;
  background: transparent;
  border: 0;
  border-bottom: 1px solid #ddd;
}

.markdown-body hr:before {
  display: table;
  content: "";
}

.markdown-body hr:after {
  display: table;
  clear: both;
  content: "";
}

.markdown-body h1,
.markdown-body h2,
.markdown-body h3,
.markdown-body h4,
.markdown-body h5,
.markdown-body h6 {
  margin-top: 15px;
  margin-bottom: 15px;
  line-height: 1.1;
}

.markdown-body h1 {
  font-size: 30px;
}

.markdown-body h2 {
  font-size: 21px;
}

.markdown-body h3 {
  font-size: 16px;
}

.markdown-body h4 {
  font-size: 14px;
}

.markdown-body h5 {
  font-size: 12px;
}

.markdown-body h6 {
  font-size: 11px;
}

.markdown-body blockquote {
  margin: 0;
}

.markdown-body ul,
.markdown-body ol {
  padding: 0;
  margin-top: 0;
  margin-bottom: 0;
}

.markdown-body ol ol,
.markdown-body ul ol {
  list-style-type: lower-roman;
}

.markdown-body ul ul ol,
.markdown-body ul ol ol,
.markdown-body ol ul ol,
.markdown-body ol ol ol {
  list-style-type: lower-alpha;
}

.markdown-body dd {
  margin-left: 0;
}

.markdown-body code {
  font-family: Consolas, "Liberation Mono", Menlo, Courier, monospace;
  font-size: 12px;
}

.markdown-body pre {
  margin-top: 0;
  margin-bottom: 0;
  font: 12px Consolas, "Liberation Mono", Menlo, Courier, monospace;
}

.markdown-body .octicon {
  font: normal normal 16px octicons-anchor;
  line-height: 1;
  display: inline-block;
  text-decoration: none;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  -webkit-user-select: none;
  -moz-user-select: none;
  -ms-user-select: none;
  user-select: none;
}

.markdown-body .octicon-link:before {
  content: '\f05c';
}

.markdown-body>*:first-child {
  margin-top: 0 !important;
}

.markdown-body>*:last-child {
  margin-bottom: 0 !important;
}

.markdown-body .anchor {
  position: absolute;
  top: 0;
  left: 0;
  display: block;
  padding-right: 6px;
  padding-left: 30px;
  margin-left: -30px;
}

.markdown-body .anchor:focus {
  outline: none;
}

.markdown-body h1,
.markdown-body h2,
.markdown-body h3,
.markdown-body h4,
.markdown-body h5,
.markdown-body h6 {
  position: relative;
  margin-top: 1em;
  margin-bottom: 16px;
  font-weight: bold;
  line-height: 1.4;
}

.markdown-body h1 .octicon-link,
.markdown-body h2 .octicon-link,
.markdown-body h3 .octicon-link,
.markdown-body h4 .octicon-link,
.markdown-body h5 .octicon-link,
.markdown-body h6 .octicon-link {
  display: none;
  color: #000;
  vertical-align: middle;
}

.markdown-body h1:hover .anchor,
.markdown-body h2:hover .anchor,
.markdown-body h3:hover .anchor,
.markdown-body h4:hover .anchor,
.markdown-body h5:hover .anchor,
.markdown-body h6:hover .anchor {
  padding-left: 8px;
  margin-left: -30px;
  text-decoration: none;
}

.markdown-body h1:hover .anchor .octicon-link,
.markdown-body h2:hover .anchor .octicon-link,
.markdown-body h3:hover .anchor .octicon-link,
.markdown-body h4:hover .anchor .octicon-link,
.markdown-body h5:hover .anchor .octicon-link,
.markdown-body h6:hover .anchor .octicon-link {
  display: inline-block;
}

.markdown-body h1 {
  padding-bottom: 0.3em;
  font-size: 2.25em;
  line-height: 1.2;
  border-bottom: 1px solid #eee;
}

.markdown-body h1 .anchor {
  line-height: 1;
}

.markdown-body h2 {
  padding-bottom: 0.3em;
  font-size: 1.75em;
  line-height: 1.225;
  border-bottom: 1px solid #eee;
}

.markdown-body h2 .anchor {
  line-height: 1;
}

.markdown-body h3 {
  font-size: 1.5em;
  line-height: 1.43;
}

.markdown-body h3 .anchor {
  line-height: 1.2;
}

.markdown-body h4 {
  font-size: 1.25em;
}

.markdown-body h4 .anchor {
  line-height: 1.2;
}

.markdown-body h5 {
  font-size: 1em;
}

.markdown-body h5 .anchor {
  line-height: 1.1;
}

.markdown-body h6 {
  font-size: 1em;
  color: #777;
}

.markdown-body h6 .anchor {
  line-height: 1.1;
}

.markdown-body p,
.markdown-body blockquote,
.markdown-body ul,
.markdown-body ol,
.markdown-body dl,
.markdown-body table,
.markdown-body pre {
  margin-top: 0;
  margin-bottom: 16px;
}

.markdown-body hr {
  height: 4px;
  padding: 0;
  margin: 16px 0;
  background-color: #e7e7e7;
  border: 0 none;
}

.markdown-body ul,
.markdown-body ol {
  padding-left: 2em;
}

.markdown-body ul ul,
.markdown-body ul ol,
.markdown-body ol ol,
.markdown-body ol ul {
  margin-top: 0;
  margin-bottom: 0;
}

.markdown-body li>p {
  margin-top: 16px;
}

.markdown-body dl {
  padding: 0;
}

.markdown-body dl dt {
  padding: 0;
  margin-top: 16px;
  font-size: 1em;
  font-style: italic;
  font-weight: bold;
}

.markdown-body dl dd {
  padding: 0 16px;
  margin-bottom: 16px;
}

.markdown-body blockquote {
  padding: 0 15px;
  color: #777;
  border-left: 4px solid #ddd;
}

.markdown-body blockquote>:first-child {
  margin-top: 0;
}

.markdown-body blockquote>:last-child {
  margin-bottom: 0;
}

.markdown-body table {
  display: block;
  width: 100%;
  overflow: auto;
  word-break: normal;
  word-break: keep-all;
}

.markdown-body table th {
  font-weight: bold;
}

.markdown-body table th,
.markdown-body table td {
  padding: 6px 13px;
  border: 1px solid #ddd;
}

.markdown-body table tr {
  background-color: #fff;
  border-top: 1px solid #ccc;
}

.markdown-body table tr:nth-child(2n) {
  background-color: #f8f8f8;
}

.markdown-body img {
  max-width: 100%;
  -moz-box-sizing: border-box;
  box-sizing: border-box;
}

.markdown-body code {
  padding: 0;
  padding-top: 0.2em;
  padding-bottom: 0.2em;
  margin: 0;
  font-size: 85%;
  background-color: rgba(0,0,0,0.04);
  border-radius: 3px;
}

.markdown-body code:before,
.markdown-body code:after {
  letter-spacing: -0.2em;
  content: "\00a0";
}

.markdown-body pre>code {
  padding: 0;
  margin: 0;
  font-size: 100%;
  word-break: normal;
  white-space: pre;
  background: transparent;
  border: 0;
}

.markdown-body .highlight {
  margin-bottom: 16px;
}

.markdown-body .highlight pre,
.markdown-body pre {
  padding: 16px;
  overflow: auto;
  font-size: 85%;
  line-height: 1.45;
  background-color: #f7f7f7;
  border-radius: 3px;
}

.markdown-body .highlight pre {
  margin-bottom: 0;
  word-break: normal;
}

.markdown-body pre {
  word-wrap: normal;
}

.markdown-body pre code {
  display: inline;
  max-width: initial;
  padding: 0;
  margin: 0;
  overflow: initial;
  line-height: inherit;
  word-wrap: normal;
  background-color: transparent;
  border: 0;
}

.markdown-body pre code:before,
.markdown-body pre code:after {
  content: normal;
}

.markdown-body kbd {
  display: inline-block;
  padding: 3px 5px;
  font-size: 11px;
  line-height: 10px;
  color: #555;
  vertical-align: middle;
  background-color: #fcfcfc;
  border: solid 1px #ccc;
  border-bottom-color: #bbb;
  border-radius: 3px;
  box-shadow: inset 0 -1px 0 #bbb;
}

.markdown-body .pl-c {
  color: #969896;
}

.markdown-body .pl-c1,
.markdown-body .pl-mdh,
.markdown-body .pl-mm,
.markdown-body .pl-mp,
.markdown-body .pl-mr,
.markdown-body .pl-s1 .pl-v,
.markdown-body .pl-s3,
.markdown-body .pl-sc,
.markdown-body .pl-sv {
  color: #0086b3;
}

.markdown-body .pl-e,
.markdown-body .pl-en {
  color: #795da3;
}

.markdown-body .pl-s1 .pl-s2,
.markdown-body .pl-smi,
.markdown-body .pl-smp,
.markdown-body .pl-stj,
.markdown-body .pl-vo,
.markdown-body .pl-vpf {
  color: #333;
}

.markdown-body .pl-ent {
  color: #63a35c;
}

.markdown-body .pl-k,
.markdown-body .pl-s,
.markdown-body .pl-st {
  color: #a71d5d;
}

.markdown-body .pl-pds,
.markdown-body .pl-s1,
.markdown-body .pl-s1 .pl-pse .pl-s2,
.markdown-body .pl-sr,
.markdown-body .pl-sr .pl-cce,
.markdown-body .pl-sr .pl-sra,
.markdown-body .pl-sr .pl-sre,
.markdown-body .pl-src {
  color: #df5000;
}

.markdown-body .pl-mo,
.markdown-body .pl-v {
  color: #1d3e81;
}

.markdown-body .pl-id {
  color: #b52a1d;
}

.markdown-body .pl-ii {
  background-color: #b52a1d;
  color: #f8f8f8;
}

.markdown-body .pl-sr .pl-cce {
  color: #63a35c;
  font-weight: bold;
}

.markdown-body .pl-ml {
  color: #693a17;
}

.markdown-body .pl-mh,
.markdown-body .pl-mh .pl-en,
.markdown-body .pl-ms {
  color: #1d3e81;
  font-weight: bold;
}

.markdown-body .pl-mq {
  color: #008080;
}

.markdown-body .pl-mi {
  color: #333;
  font-style: italic;
}

.markdown-body .pl-mb {
  color: #333;
  font-weight: bold;
}

.markdown-body .pl-md,
.markdown-body .pl-mdhf {
  background-color: #ffecec;
  color: #bd2c00;
}

.markdown-body .pl-mdht,
.markdown-body .pl-mi1 {
  background-color: #eaffea;
  color: #55a532;
}

.markdown-body .pl-mdr {
  color: #795da3;
  font-weight: bold;
}

.markdown-body kbd {
  display: inline-block;
  padding: 3px 5px;
  font: 11px Consolas, "Liberation Mono", Menlo, Courier, monospace;
  line-height: 10px;
  color: #555;
  vertical-align: middle;
  background-color: #fcfcfc;
  border: solid 1px #ccc;
  border-bottom-color: #bbb;
  border-radius: 3px;
  box-shadow: inset 0 -1px 0 #bbb;
}

.markdown-body .task-list-item {
  list-style-type: none;
}

.markdown-body .task-list-item+.task-list-item {
  margin-top: 3px;
}

.markdown-body .task-list-item input {
  float: left;
  margin: 0.3em 0 0.25em -1.6em;
  vertical-align: middle;
}

.markdown-body :checked+.radio-label {
  z-index: 1;
  position: relative;
  border-color: #4183c4;
}

.footnotes {
  font-size: 12px;
}

.nobreak {
  page-break-inside: avoid;
}
