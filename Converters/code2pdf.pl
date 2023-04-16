#!/usr/bin/perl

# Author: Trizen
# Date: 30 July 2022
# https://github.com/trizen

# Code to PDF converter, with syntax highlighting, given a summary file.

# Using the following tools:
#   md2html         -- for converting markdown to HTML (provided by md4c)
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

my $md2html      = "md2html";            # path to the `md2html` tool
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

my %language_codes = (

    # Source:
    #   https://support.codebasehq.com/articles/tips-tricks/syntax-highlighting-in-markdown

    Cucumber     => ['.feature'],
    abap         => ['.abap'],
    ada          => ['.adb',      '.ads', '.ada'],
    ahk          => ['.ahk',      '.ahkl'],
    apacheconf   => ['.htaccess', 'apache.conf', 'apache2.conf'],
    applescript  => ['.applescript'],
    as           => ['.as'],
    as3          => ['.as'],
    asy          => ['.asy'],
    bash         => ['.sh',  '.ksh', '.bash', '.ebuild', '.eclass'],
    bat          => ['.bat', '.cmd'],
    befunge      => ['.befunge'],
    blitzmax     => ['.bmx'],
    boo          => ['.boo'],
    brainfuck    => ['.bf',    '.b'],
    c            => ['.c',     '.h'],
    cfm          => ['.cfm',   '.cfml', '.cfc'],
    cheetah      => ['.tmpl',  '.spt'],
    cl           => ['.cl',    '.lisp', '.el'],
    clojure      => ['.clj',   '.cljs'],
    cmake        => ['.cmake', 'CMakeLists.txt'],
    coffeescript => ['.coffee'],
    console      => ['.sh-session'],
    control      => ['control'],
    cpp          => ['.cpp', '.hpp', '.c++', '.h++', '.cc', '.hh', '.cxx', '.hxx', '.pde'],
    csharp       => ['.cs'],
    css          => ['.css'],
    cython       => ['.pyx', '.pxd', '.pxi'],
    d            => ['.d',   '.di'],
    delphi       => ['.pas'],
    diff         => ['.diff',   '.patch'],
    dpatch       => ['.dpatch', '.darcspatch'],
    duel         => ['.duel',   '.jbst'],
    dylan        => ['.dylan',  '.dyl'],
    erb          => ['.erb'],
    erl          => ['.erl-sh'],
    erlang       => ['.erl', '.hrl'],
    evoque       => ['.evoque'],
    factor       => ['.factor'],
    felix        => ['.flx', '.flxh'],
    fortran      => ['.f',   '.f90'],
    gas          => ['.s',   '.S'],
    genshi       => ['.kid'],
    glsl         => ['.vert', '.frag', '.geo'],
    gnuplot      => ['.plot', '.plt'],
    go           => ['.go'],
    groff        => ['.1', '.2', '.3', '.4', '.5', '.6', '.7', '.man'],
    haml         => ['.haml'],
    haskell      => ['.hs'],
    html         => ['.html', '.htm', '.xhtml', '.xslt'],
    hx           => ['.hx'],
    hybris       => ['.hy',  '.hyb'],
    ini          => ['.ini', '.cfg'],
    io           => ['.io'],
    ioke         => ['.ik'],
    irc          => ['.weechatlog'],
    jade         => ['.jade'],
    java         => ['.java'],
    js           => ['.js'],
    jsp          => ['.jsp'],
    lhs          => ['.lhs'],
    llvm         => ['.ll'],
    logtalk      => ['.lgt'],
    lua          => ['.lua', '.wlua'],
    make         => ['.mak', 'Makefile', 'makefile', 'Makefile.', 'GNUmakefile'],
    mako         => ['.mao'],
    maql         => ['.maql'],
    mason        => ['.mhtml', '.mc', '.mi', 'autohandler', 'dhandler'],
    markdown     => ['.md'],
    modelica     => ['.mo'],
    modula2      => ['.def', '.mod'],
    moocode      => ['.moo'],
    mupad        => ['.mu'],
    mxml         => ['.mxml'],
    myghty       => ['.myt', 'autodelegate'],
    nasm         => ['.asm', '.ASM'],
    newspeak     => ['.ns2'],
    objdump      => ['.objdump'],
    objectivec   => ['.m'],
    objectivej   => ['.j'],
    ocaml        => ['.ml', '.mli', '.mll', '.mly'],
    ooc          => ['.ooc'],
    perl         => ['.pl',     '.PL',   '.perl', '.PERL', '.pm', '.pod', '.POD', '.t', '.cgi', '.fcgi'],
    php          => ['.php',    '.php3', '.php4', '.php5'],
    postscript   => ['.ps',     '.eps'],
    pot          => ['.pot',    '.po'],
    pov          => ['.pov',    '.inc'],
    prolog       => ['.prolog', '.pro'],
    properties   => ['.properties'],
    protobuf     => ['.proto'],
    py3tb        => ['.py3tb'],
    pytb         => ['.pytb'],
    python       => ['.py', '.pyw', '.sc', 'SConstruct', 'SConscript', '.tac'],
    ruby         => ['.rb', '.rbw', 'Rakefile', '.rake', '.gemspec', '.rbx', '.duby'],
    rconsole     => ['.Rout'],
    rebol        => ['.r', '.r3'],
    redcode      => ['.cw'],
    rhtml        => ['.rhtml'],
    rst          => ['.rst', '.rest'],
    sass         => ['.sass'],
    scala        => ['.scala'],
    scaml        => ['.scaml'],
    scheme       => ['.scm'],
    scss         => ['.scss'],
    smalltalk    => ['.st'],
    smarty       => ['.tpl'],
    sourceslist  => ['sources.list'],
    splus        => ['.S', '.R'],
    sql          => ['.sql'],
    sqlite3      => ['.sqlite3-console'],
    squidconf    => ['squid.conf'],
    ssp          => ['.ssp'],
    tcl          => ['.tcl'],
    tcsh         => ['.tcsh', '.csh'],
    tex          => ['.tex',  '.aux', '.toc'],
    text         => ['.txt'],
    v            => ['.v',    '.sv'],
    vala         => ['.vala', '.vapi'],
    vbnet        => ['.vb',   '.bas'],
    velocity     => ['.vm',   '.fhtml'],
    vim          => ['.vim',  '.vimrc'],
    xml          => ['.xml',  '.xsl', '.rss', '.xslt', '.xsd', '.wsdl'],
    xquery       => ['.xqy',  '.xquery'],
    xslt         => ['.xsl',  '.xslt'],
    yaml         => ['.yaml', '.yml'],
    julia        => ['.jl'],
                     );

sub determine_language_code {
    my ($file) = @_;

    my @found_codes;

    foreach my $lang_code (keys %language_codes) {
        foreach my $ext (@{$language_codes{$lang_code}}) {
            if (substr($file, -length($ext)) eq $ext) {
                push @found_codes, $lang_code;
            }
        }
    }

    if (scalar(@found_codes) == 1) {
        return $found_codes[0];
    }

    if (scalar(@found_codes) > 1) {
        warn ":: Ambiguous file extension for <<$file>>: it could be (@found_codes)\n";
        @found_codes = sort(@found_codes);    # be deterministic
        return $found_codes[0];
    }

    return $lang;
}

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

                        if (-d $file) {
                            $markdown_content .= ("#" x $depth) . ' ' . $x->content->[0] . "\n\n";
                            next;
                        }

                        if (not -T $file) {
                            warn ":: Ignoring binary file <<$file>>...\n";
                            next;
                        }

                        if (open(my $fh, '<:utf8', $file)) {
                            my $lang_code = determine_language_code($file);
                            $markdown_content .= ("#" x $depth) . ' ' . $x->content->[0] . "\n\n";
                            $markdown_content .= "```$lang_code\n";
                            $markdown_content .= do {
                                local $/;
                                <$fh>;
                            };
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
