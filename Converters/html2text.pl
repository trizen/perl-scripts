#!/usr/bin/perl

# Author: Trizen
# Date: 08 January 2022
# https://github.com/trizen

# Convert HTML to text (UTF-8), given either an HTML file, or an URL.

# Dependencies:
#   perl-html-tree
#   perl-html-formatter
#   perl-libwww                 (optional: when given URLs)
#   perl-lwp-protocol-https     (optional: when given https:// URLs)

# See also:
#   https://github.com/grobian/html2text

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

use HTML::TreeBuilder 5 qw(-weak);
use HTML::FormatText qw();
use Getopt::Long qw(GetOptions);

binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');

sub extract_html ($source) {

    if ($source =~ m{^https?://}) {

        require LWP::UserAgent;
        my $lwp = LWP::UserAgent->new(
                                     env_proxy => 1,
                                     timeout   => 15,
                                     agent => "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0",
                                     cookie_jar => {},
                                     ssl_opts   => {verify_hostname => 0},
        );

        my $resp = $lwp->get($source);
        $resp->is_success or return;

        my $html = $resp->decoded_content;
        return $html;
    }

    if (ref($source) eq 'GLOB') {
        my $html = do {
            local $/;
            <$source>;
        };
        return $html;
    }

    my $html = do {
        open my $fh, '<:utf8', $source
          or die "Can't open file <<$source>> for reading: $!";
        local $/;
        <$fh>;
    };

    return $html;
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

sub help ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [URL or HTML file]

    -lm  --left=i   : the column of the left margin. (default: $left_margin)
    -rm  --right=i  : the column of the right margin. (default: $right_margin)
EOT

    exit($exit_code);
}

GetOptions(
           "lm|left=i"  => \$left_margin,
           "rm|right=i" => \$right_margin,
           "h|help"     => sub { help(0) }
          )
  or do {
    warn("Error in command line arguments\n");
    help(1);
  };

my $stdin_on_tty = -t STDIN;

if (not $stdin_on_tty) {    # assume input provided via STDIN
    ## ok
}
else {
    @ARGV || do {
        warn "\nerror: no URL or HTML file provided!\n\n";
        help(2);
    };
}

my $formatter = HTML::FormatText->new(leftmargin  => $left_margin,
                                      rightmargin => $right_margin,);

my $html = extract_html($stdin_on_tty ? $ARGV[0] : \*STDIN);
$html // die "error: unable to extract HTML content";

my $text = html2text($html, $formatter);
$text // die "error: unable to extract text";

say $text;
