#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 April 2015
# Website: https://github.com/trizen

# Extract markdown code from each task for a given programming language.

use utf8;
use 5.014;
use strict;
use autodie;
use warnings;

use Text::Tabs qw(expand);
use Encode qw(decode_utf8);
use Getopt::Long qw(GetOptions);
use File::Path qw(make_path);
use LWP::UserAgent::Cached qw();
use URI::Escape qw(uri_unescape);
use HTML::Entities qw(decode_entities);
use File::Spec::Functions qw(catfile catdir);

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

sub escape_markdown {
    my ($t) = @_;
    $t =~ s{([*_`])}{\\$1}g;
    return $t;
}

sub escape_lang {
    $_[0] =~ s/\s/_/gr;    # replace whitespace with underscores
}

sub _ulist {
    $_[0] =~ s{<li>(.*?)</li>}{* $1\n}gsr;
}

sub _olist {
    my $i = 1;
    $_[0] =~ s{<li>(.*?)</li>}{$i++ . '. ' . "$1\n"}egsr;
}

sub tags_to_markdown {
    my ($t, $escape) = @_;

    my $out = '';
    until ($t =~ /\G\z/gc) {
        if ($t =~ m{\G<br\h*/\h*>}gc) {
            $out .= "\n";
        }
        elsif ($t =~ m{\G<b>(.*?)</b>}gcs) {
            $out .= "**" . tags_to_markdown($1, 1) . "**";
        }
        elsif ($t =~ m{\G<i>(.*?)</i>}gcs) {
            $out .= "*" . tags_to_markdown($1, 1) . "*";
        }
        elsif ($t =~ m{\G<code>(.*?)</code>}gcs) {
            $out .= "`$1`";
        }
        elsif ($t =~ m{\G<tt>(.*?)</tt>}gcs) {
            $out .= "`" . decode_entities($1) . "`";
        }
        elsif ($t =~ m{\G<a\b.*? href="(.*?)".*?>(.*?)</a>}gcs) {
            my ($url, $label) = ($1, $2);

            if ($url =~ m{^/}) {
                $url = 'https://rosettacode.org' . $url;
            }

            $label = tags_to_markdown($label);
            $out .= "[$label]($url)";
        }
        elsif ($t =~ m{\G(<img\b.*? src="/mw/.*?".*?/>)}gc) {
            my $html = $1;
            $html =~ s{ src="\K/mw/}{https://rosettacode.org/mw/};
            $html =~ s{ srcset=".*?"}{};
            $out .= $html;
        }
        elsif ($t =~ m{\G<span><span class="mwe-math-mathml-inline mwe-math-mathml-a11y"}gc) {
            $t =~ m{\G.*?</span>}gsc;
            if ($t =~
                m{\G<meta class="mwe-math-fallback-image-inline".*? url\(&#39;(/mw/index\.php\?(?:.*?))&#39;\).*?/></span>}gc)
            {
                $out .= '![image](https://rosettacode.org' . decode_entities($1) . ')';
            }
            else {
                warn "[!] Failed to parse math meta class!\n";
            }
        }
        elsif ($t =~ m{\G<ul>(.*?)</ul>}gcs) {
            $out .= _ulist(tags_to_markdown($1, 1));
        }
        elsif ($t =~ m{\G<ol>(.*?)</ol>}gcs) {
            $out .= _olist(tags_to_markdown($1, 1));
        }
        elsif ($t =~ /\G([^<]+)/gc) {
            $out .= $escape ? escape_markdown($1) : $1;
        }
        elsif ($t =~ /\G(.)/gcs) {
            $out .= $escape ? escape_markdown($1) : $1;
        }
    }

    return $out;
}

sub strip_tags {
    $_[0] =~ s/<.*?>//gsr;    # remove HTML tags
}

sub strip_space {
    unpack('A*', $_[0] =~ s/^\s+//r);    # remove leading and trailing whitespace
}

sub extract_tasks {
    my ($content, $lang) = @_;

    my $i = index($content, qq{<h2>Pages in category "$lang"</h2>});

    if ($i == -1) {
        warn "[!] Can't find any tasks for language: <$lang>!\n";
        return;
    }

    my $tasks_content = substr($content, $i);

    my @tasks;
    while ($tasks_content =~ m{<a href="/wiki/(.+?)" title=".+?">(.+?)</a></li>}g) {
        my ($task, $label) = ($1, $2);

        last if $task eq 'Special:Categories';

        push @tasks,
          {
            name  => decode_utf8(uri_unescape($task)),
            title => $label,
          };
    }

    return \@tasks;
}

sub extract_lang {
    my ($content, $lang) = @_;

    my $header = sub {
        qq{<span class="mw-headline" id="$_[0]">};
    };

    my $i = index($content, $header->($lang));

    # Try with the language escaped
    if ($i == -1) {
        $i = index($content, $header->(escape_lang($lang)));
    }

    # Give up
    if ($i == -1) {
        warn "[!] Can't find language: <$lang>\n";
        return;
    }

    my $j = index($content, '<h2>', $i);

    if ($j == -1) {
        state $x = 0;
        if (++$x <= 3) {
            warn "[!] Is `$lang` the last language in the list?!\n";
        }
        $j = index($content, '<div class="printfooter">', $i);
    }

    if ($j == -1) {
        state $x = 0;
        if (++$x <= 3) {
            warn "[!] Position `j` will point at the end of the page...\n";
        }
        $j = length($content);
    }

    $i = index($content, '</h2>', $i);

    if ($i == -1) {
        warn "[!] Can't find the end of the header!\n";
        return;
    }

    $i += 5;    # past the end of the header

    my $part = strip_space(substr($content, $i, $j - $i));

    # remove <script> tags
    $part =~ s{<script\b.+?</script>}{}gsi;

    # replace [email protected] with 'email@example.com'
    $part =~ s{<a class="__cf_email__".+?</a>}{email\@example.com}gsi;

    my @data;
    until ($part =~ /\G\z/gc) {
        if ($part =~ m{\G<pre class="(.+?) highlighted_source">(.+)</pre>}gc) {
            push @data,
              {
                code => {
                         lang => $1,
                         data => $2,
                        }
              };
        }
        elsif ($part =~ m{\G<p>(.*?)</p>}sgc) {
            push @data,
              {
                text => {
                         tag  => 'p',
                         data => $1,
                        },
              };
        }
        elsif ($part =~ m{\G<pre>(.*?)</pre>}sgc) {
            push @data,
              {
                text => {
                         tag  => 'pre',
                         data => $1,
                        }
              };
        }
        elsif ($part =~ m{\G(.)}sgc) {
            @data && exists($data[-1]{unknown})
              ? ($data[-1]{unknown}{data} .= $1)
              : (push @data, {unknown => {data => $1}});
        }
    }

    return \@data;
}

sub to_html {
    my ($lang_data) = @_;

    my $text = '';
    foreach my $item (@{$lang_data}) {
        if (exists $item->{text}) {
            $text .= qq{<$item->{text}{tag}>$item->{text}{data}</$item->{text}{tag}>};
        }
        elsif (exists $item->{code}) {
            $text .= qq{<pre class="lang $item->{code}{lang}">$item->{code}{data}</pre>};
        }
    }

    return $text;
}

sub to_markdown {
    my ($lang_data) = @_;

    my $text = '';
    foreach my $item (@{$lang_data}) {
        if (exists $item->{text}) {

            my $data = $item->{text}{data};
            my $tag  = $item->{text}{tag};

            if ($tag eq 'p') {
                my $t = tags_to_markdown(strip_space($data), 1);
                $text .= "\n\n" . $t . "\n\n";
            }
            elsif ($tag eq 'pre') {
                my $t = decode_entities($data);
                $t =~ s/^(?:\R)+//;
                $t =~ s/(?:\R)+\z//;
                $t = join("\n", expand(split(/\R/, $t)));
                $text .= "\n#### Output:\n";
                $text .= "```\n$t\n```\n";
            }
        }
        elsif (exists $item->{code}) {
            my $code = decode_entities(strip_tags(tags_to_markdown($item->{code}{data})));
            my $lang = $item->{code}{lang};
            $code =~ s/\[(\w+)\]\(https?:.*?\)/$1/g;
            $text .= "```$lang\n$code\n```\n";
        }
    }

    return strip_space($text);
}

sub write_to_file {
    my ($base_dir, $name, $markdown, $overwrite) = @_;

    # Remove parenthesis
    $name =~ tr/()//d;

    # Substitute bad characters
    #$name =~ tr{-A-Za-z0-9[]'*_/À-ÿ}{_}c;
    $name =~ s{[^\pL\pN\[\]'*/\-]+}{ }g;

    # Replace multiple spaces with a single underscore
    $name = join('_', split(' ', $name));

    my $char = uc(substr($name, 0, 1));
    my $dir = catdir($base_dir, $char);

    # Remove directory paths from name (if any)
    if ($name =~ s{^(.*)/}{}) {
        my $dirname = $1;
        $dir = catdir($dir, map { $_ eq 'Sorting_Algorithms' ? 'Sorting_algorithms' : $_ } split(/\//, $dirname));
    }

    # Create directory if it doesn't exists
    if (not -d $dir) {
        make_path($dir) or do {
            warn "[!] Can't create path `$dir`: $!\n";
            return;
        };
    }

    my $file = catfile($dir, "$name.md");

    if (not $overwrite) {
        return 1 if -e $file;    # Don't overwrite existent files
    }

    say "** Creating file: $file";
    open(my $fh, '>:encoding(UTF-8)', $file) or do {
        warn "[!] Can't create file `$file`: $!";
        return;
    };
    print {$fh} $markdown;
    close $fh;
}

#
## MAIN
#

my $cache_dir = 'cache';
my $lang      = 'Sidef';
my $overwrite = 0;

my $base_dir = 'programming_tasks';
my $main_url = 'https://rosettacode.org';

sub usage {
    print <<"EOT";
usage: $0 [options]

options:
    --lang=s        : the programming language name (default: $lang)
    --base_dir=s    : where to save the files (default: $base_dir)
    --overwrite!    : overwrite existent files (default: $overwrite)

    --cache-dir=s   : cache directory (default: $cache_dir)
    --main-url=s    : main URL (default: $main_url)

    --help          : print this message and exit

example:
    $0 --lang=Perl --base_dir=perl_tasks
EOT

    exit;
}

GetOptions(
           'cache-dir=s'  => \$cache_dir,
           'L|language=s' => \$lang,
           'base-dir=s'   => \$base_dir,
           'main-url=s'   => \$main_url,
           'overwrite!'   => \$overwrite,
           'help'         => \&usage,
          )
  or die "[!] Error in command line arguments!";

if (not -d $cache_dir) {
    mkdir($cache_dir);
}

my $lwp = LWP::UserAgent::Cached->new(
    timeout       => 60,
    show_progress => 1,
    agent         => '',
    cache_dir     => $cache_dir,

    nocache_if => sub {
        my ($response) = @_;
        my $code = $response->code;
        return 1 if ($code >= 500);                               # do not cache any bad response
        return 1 if ($code == 401);                               # don't cache an unauthorized response
        return 1 if ($response->{_request}{_method} ne 'GET');    # cache only GET requests
        return;
    },
);

my $lwp_uc = LWP::UserAgent->new(
                                 show_progress => 1,
                                 agent         => '',
                                 timeout       => 60,
                                );

my $start_url = $main_url . '/wiki/' . escape_lang($lang);
my $req       = $lwp_uc->get($start_url);
$req->is_success || die $req->status_line;

my $content = $req->decoded_content;
my $tasks = extract_tasks($content, $lang);

foreach my $task (@{$tasks}) {

    my $name  = $task->{name};
    my $title = $task->{title};
    my $url   = "$main_url/wiki/$name";

    my $req = $lwp->get($url);

    if ($req->is_success) {

        my $content = $req->decoded_content;
        my $lang_data = extract_lang($content, $lang) // do { $lwp->uncache; next };

        my $header   = "[1]: $url\n\n" . "# [$title][1]\n\n";
        my $markdown = $header . to_markdown($lang_data);

        write_to_file($base_dir, $name, $markdown, $overwrite);
    }
    else {
        warn "[" . $req->status_line . "] Can't fetch: $url\n";
    }
}
