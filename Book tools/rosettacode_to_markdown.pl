#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 April 2015
# Edit: 09 December 2023
# Website: https://github.com/trizen

# Extract markdown code from each task for a given programming language.

use utf8;
use 5.020;
use strict;
use autodie;
use warnings;

use experimental qw(signatures);

use Text::Tabs             qw(expand);
use Encode                 qw(decode_utf8);
use Getopt::Long           qw(GetOptions);
use File::Path             qw(make_path);
use LWP::UserAgent::Cached qw();
use URI::Escape            qw(uri_unescape uri_escape);
use HTML::Entities         qw(decode_entities);
use File::Spec::Functions  qw(catfile catdir);

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

sub escape_markdown ($t) {
    $t =~ s{([*_`])}{\\$1}g;
    return $t;
}

sub escape_lang ($s) {
    $s =~ s/\s/_/gr;    # replace whitespace with underscores
}

sub _ulist ($s) {
    $s =~ s{<li>(.*?)</li>}{* $1\n}gsr;
}

sub _olist ($s) {
    my $i = 1;
    $s =~ s{<li>(.*?)</li>}{$i++ . '. ' . "$1\n"}egsr;
}

sub tags_to_markdown ($t, $escape = 0) {

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
            $out .= "`" . decode_entities($1) . "`";
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
            if ($t =~ m{\G<meta class="mwe-math-fallback-image-inline".*? url\(&#39;(/mw/index\.php\?(?:.*?))&#39;\).*?/></span>}gc) {
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

sub strip_tags ($s) {
    $s =~ s/<.*?>//gsr;    # remove HTML tags
}

sub strip_space ($s) {
    unpack('A*', $s =~ s/^\s+//r);    # remove leading and trailing whitespace
}

sub extract_tasks ($content, $lang) {

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

sub extract_all_tasks ($main_url, $path_url, $lang) {

    my $lwp_uc = LWP::UserAgent->new(
                                     show_progress => 1,
                                     agent         => '',
                                     timeout       => 60,
                                    );

    my $tasks_url = $main_url . $path_url;
    my $resp      = $lwp_uc->get($tasks_url);
    $resp->is_success || die $resp->status_line;

    my $content = $resp->decoded_content;
    my $tasks   = extract_tasks($content, $lang);

    my @all_tasks = @$tasks;

    if ($content =~ m{<a href="([^"]+)" title="[^"]+">next page</a>}) {
        push @all_tasks, __SUB__->($main_url, $1, $lang);
    }

    return @all_tasks;
}

sub extract_lang ($content, $lang, $lang_alias = $lang) {

    my $header = sub {
        qq{<span class="mw-headline" id="$_[0]">};
    };

    my $i = index($content, $header->($lang));

    # Try with the language escaped
    if ($i == -1) {
        $i = index($content, $header->(escape_lang($lang)));
    }

    # Try with the language alias
    if ($i == -1) {
        $i = index($content, $header->($lang_alias));
    }

    # Try with the language alias escaped
    if ($i == -1) {
        $i = index($content, $header->(escape_lang($lang_alias)));
    }

    # Give up
    if ($i == -1) {
        warn "[!] Can't find language: <$lang>\n";
        return;
    }

    my $j = index($content, '<h2>', $i);

    if ($j == -1) {
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

    # replace [email protected] with 'email@example.net'
    $part =~ s{<a class="__cf_email__".+?</a>}{email\@example.net}gsi;

    my @data;
    until ($part =~ /\G\z/gc) {
        if ($part =~ m{\G<pre class="(.+?) highlighted_source">(.+)</pre>}gc) {    # old way
            push @data,
              {
                code => {
                         lang => $1,
                         data => $2,
                        }
              };
        }
        elsif ($part =~ m{\G<div class="[^"]*mw-highlight-lang-(\S+)[^"]*" dir="ltr"><pre>(.*?)</pre>}sgc) {    # new way
            push @data,
              {
                code => {
                         lang => $1,
                         data => $2,
                        }
              };
        }
        elsif ($part =~ m{\G<h([1-4])>(.*?)</h[1-4]>}sgc) {
            push @data,
              {
                header => {
                           n    => $1,
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
        elsif ($part =~ m{\G<pre\b[^>]*>(.*?)</pre>}sgc) {
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

sub to_html ($lang_data) {

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

sub to_markdown ($lang_data) {

    my $text = '';
    foreach my $item (@{$lang_data}) {

        if (exists $item->{header}) {

            my $n    = $item->{header}{n};
            my $data = $item->{header}{data};

            my $t = strip_tags(tags_to_markdown(strip_space($data), 1));
            $t =~ s/\[\[edit\].*//s;
            $text .= "\n\n" . ('#' x $n) . ' ' . $t . "\n\n";
        }
        elsif (exists $item->{text}) {

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
                if ($text !~ /Output:/) {
                    $text .= "\n#### Output:";
                }
                $text .= "\n```\n$t\n```\n";
            }
        }
        elsif (exists $item->{code}) {
            my $code = decode_entities(strip_tags(tags_to_markdown($item->{code}{data})));
            my $lang = $item->{code}{lang};
            $code =~ s/\[(\w+)\]\(https?:.*?\)/$1/g;
            $code =~ s{(?:\R)+\z}{};
            $text .= "```$lang\n$code\n```\n";
        }
    }

    return strip_space($text);
}

sub write_to_file ($base_dir, $name, $markdown, $overwrite = 0) {

    # Remove parenthesis
    $name =~ tr/()//d;

    # Substitute bad characters
    #$name =~ tr{-A-Za-z0-9[]'*_/À-ÿ}{_}c;
    $name =~ s{[^\pL\pN\[\]'*/\-]+}{ }g;

    # Replace multiple spaces with a single underscore
    $name = join('_', split(' ', $name));

    my $char = uc(substr($name, 0, 1));
    my $dir  = catdir($base_dir, $char);

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

my $cache_dir  = 'cache';
my $lang       = 'Sidef';
my $lang_alias = undef;
my $overwrite  = 0;

my $base_dir = 'programming_tasks';
my $main_url = 'https://rosettacode.org';

sub usage {
    print <<"EOT";
usage: $0 [options]

options:
    --lang=s        : the programming language name (default: $lang)
    --base-dir=s    : where to save the files (default: $base_dir)
    --overwrite!    : overwrite existent files (default: $overwrite)

    --cache-dir=s   : cache directory (default: $cache_dir)
    --main-url=s    : main URL (default: $main_url)

    --help          : print this message and exit

example:
    $0 --lang=Perl --base-dir=perl_tasks
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
        return 1 if ($code >= 300);                           # do not cache any bad response
        return 1 if ($code == 401);                           # don't cache an unauthorized response
        return 1 if ($response->request->method ne 'GET');    # cache only GET requests
        return;
    },
);

{
    my $accepted_encodings = HTTP::Message::decodable();
    $lwp->default_header('Accept-Encoding' => $accepted_encodings);

    require LWP::ConnCache;
    my $cache = LWP::ConnCache->new;
    $cache->total_capacity(undef);    # no limit
    $lwp->conn_cache($cache);
}

my @tasks = extract_all_tasks($main_url, '/wiki/' . escape_lang($lang), $lang);

sub my_uri_escape ($path) {
    $path =~ s/([?'+])/uri_escape($1)/egr;
}

foreach my $task (@tasks) {

    my $name  = $task->{name};
    my $title = $task->{title};
    my $url   = "$main_url/wiki/" . my_uri_escape($name);

    my $resp = $lwp->get($url);

    if ($resp->is_success) {

        my $content   = $resp->decoded_content;
        my $lang_data = extract_lang($content, $lang, $lang_alias) // do { $lwp->uncache; next };

        my $header   = "[1]: $url\n\n" . "# [$title][1]\n\n";
        my $markdown = $header . to_markdown($lang_data) . "\n";

        write_to_file($base_dir, $name, $markdown, $overwrite);
    }
    else {
        warn "[" . $resp->status_line . "] Can't fetch: $url\n";
    }
}
