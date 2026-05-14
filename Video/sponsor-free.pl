#!/usr/bin/env perl

# SponsorBlock CLI for YouTube Videos
# Marks or removes sponsored segments using FFmpeg.

# Dependencies:
#   ffmpeg
#   URI
#   IO::Socket::SSL

# Inspired by:
#   https://github.com/faissaloo/SponSkrub

use 5.036;

use URI;
use HTTP::Tiny;
use Getopt::Long qw(:config no_ignore_case bundling);
use JSON::PP     qw(decode_json encode_json);
use Digest::SHA  qw(sha256_hex);
use File::Temp   qw(tempfile);

# ==============================================================================
# Configuration & CLI Parsing
# ==============================================================================

my $appname = 'sponsor-free';
my $version = '0.01';

my %cfg = (
           action     => 'cut',                        # 'cut' or 'chapter'
           categories => 'sponsor',                    # comma-separated
           api_url    => 'https://sponsor.ajay.app',
           direct     => 0,                            # Use direct videoID lookup instead of hash
           proxy      => $ENV{HTTP_PROXY} // '',
           keep_date  => 0,
           tolerance  => 1,                            # tolerance in seconds for video duration (local vs server)
          );

my $remove_all = 0;

my @available_categories = qw(
  sponsor intro outro interaction selfpromo music_offtopic
);

GetOptions(
           'h|help'         => sub { show_help(0) },
           'v|version'      => sub { show_version() },
           'a|action=s'     => \$cfg{action},
           'c|categories=s' => \$cfg{categories},
           'all'            => \$remove_all,
           'api-url=s'      => \$cfg{api_url},
           'direct'         => \$cfg{direct},
           'proxy=s'        => \$cfg{proxy},
           'tolerance=f'    => \$cfg{tolerance},
           'keep-date'      => \$cfg{keep_date},
          )
  or show_help(1);

if ($remove_all) {
    $cfg{categories} = join(',', @available_categories);
}

my ($video_id, $input_file, $output_file) = @ARGV;

show_help(1)
  unless ($video_id && $input_file && $output_file);

die "Invalid action: $cfg{action}\n" unless $cfg{action} =~ /^(cut|chapter)$/;

# ==============================================================================
# Main Execution
# ==============================================================================

my $duration = extract_duration($input_file);
my $bitrate  = extract_bitrate($input_file);

die "Could not determine video duration. Is FFmpeg installed?\n" unless $duration;

say "Fetching SponsorBlock data...";
my @categories = split(',', $cfg{categories});
my @sponsors   = fetch_sponsor_data($video_id, \@categories, $duration);

unless (@sponsors) {
    say "No matching segments found. Nothing to do.";
    exit 0;
}

say "Found " . scalar(@sponsors) . " segment(s).";

my @chapters = get_existing_chapters($input_file, $duration);
my @merged   = merge_segments(\@sponsors, \@chapters);

if ($cfg{action} eq 'chapter') {
    say "Injecting chapters...";
    my $meta = build_ffmpeg_metadata(@merged);
    run_ffmpeg_metadata_pass($input_file, $output_file, $meta);
}
else {    # cut
    say "Removing segments...";
    my @keep = grep { $_->{type} eq 'content' } @merged;
    my $meta = build_ffmpeg_metadata(recalculate_kept_chapters(@keep));

    my $streams = extract_streams($input_file);
    my $has_vid = $streams =~ /video/;
    my $has_aud = $streams =~ /audio/;

    run_ffmpeg_cut_pass($input_file, $output_file, \@keep, $has_vid, $has_aud, $meta);
}

if ($cfg{keep_date}) {
    my @s = stat($input_file);
    utime($s[8], $s[9], $output_file);
}

say "Success! Output saved to: $output_file";
exit 0;

# ==============================================================================
# API Client
# ==============================================================================

sub fetch_sponsor_data ($vid, $cats, $duration) {
    my $http      = HTTP::Tiny->new(proxy => $cfg{proxy} || undef, timeout => 30);
    my $cats_json = encode_json($cats);

    my $url = URI->new("$cfg{api_url}/api/skipSegments");

    if ($cfg{direct}) {
        $url->query_form(videoID    => $vid,
                         categories => $cats_json);
    }
    else {
        my $hash = substr(sha256_hex($vid), 0, 4);    # 4-char prefix is standard for privacy API
        $url->path($url->path . '/' . $hash);
        $url->query_form(categories => $cats_json);
    }

    my $res = $http->get($url);
    return () if $res->{status} == 404;               # No segments
    die "API Error $res->{status}: $res->{reason}\n" unless $res->{success};

    my $data = decode_json($res->{content});

    # If using privacy API, filter the returned list by the exact videoID
    $data = [map { $_->{segments}->@* } grep { $_->{videoID} eq $vid } @$data] unless $cfg{direct};

    foreach my $segment (@$data) {
        if (abs($segment->{videoDuration} - $duration) > $cfg{tolerance}) {
            warn "The input does not match the video duration!\n";
            return ();
        }
    }

    return map {
        ;
        {
         start => sprintf('%.6f', $_->{segment}[0]),
         end   => sprintf('%.6f', $_->{segment}[1]),
         title => $_->{category},
         type  => 'sponsor',
        }
    } $data->@*;
}

# ==============================================================================
# Timeline Mathematics
# ==============================================================================

sub get_existing_chapters ($file, $duration) {

    my $json_str = ffprobe($file, qw(-show_chapters -print_format json));
    my $data     = decode_json($json_str // '{}');

    my @chaps =
      map {
        ;
        {
         start => $_->{start_time},
         end   => $_->{end_time},
         title => $_->{tags}{title} // 'Chapter',
         type  => 'content',
        }
      } ($data->{chapters} // [])->@*;

    if (!@chaps) {
        @chaps = (
                  {
                   start => 0,
                   end   => $duration,
                   title => 'Content',
                   type  => 'content',
                  }
                 );
    }

    return @chaps;
}

# Flattens overlapping intervals (sponsors override content)
sub merge_segments ($sponsors, $chapters) {
    my @timeline;

    # Convert all events into start/end points
    for my $c ($chapters->@*) {
        push @timeline, {t => $c->{start}, type => 'content_start', title => $c->{title}};
        push @timeline, {t => $c->{end}, type => 'content_end'};
    }
    for my $s ($sponsors->@*) {
        push @timeline, {t => $s->{start}, type => 'sponsor_start', title => $s->{title}};
        push @timeline, {t => $s->{end}, type => 'sponsor_end'};
    }

    @timeline = sort { $a->{t} <=> $b->{t} || $a->{type} cmp $b->{type} } @timeline;

    my @merged;
    my ($cur_time, $cur_title, $sponsor_depth) = (0, 'Content', 0);

    for my $ev (@timeline) {
        if ($ev->{t} > $cur_time) {
            push @merged,
              {
                start => $cur_time,
                end   => $ev->{t},
                title => $sponsor_depth > 0 ? "[Skip] $cur_title" : $cur_title,
                type  => $sponsor_depth > 0 ? 'sponsor'           : 'content'
              };
        }
        $cur_time = $ev->{t};
        $sponsor_depth++          if $ev->{type} eq 'sponsor_start';
        $sponsor_depth--          if $ev->{type} eq 'sponsor_end';
        $cur_title = $ev->{title} if $ev->{type} =~ /start$/;
    }

    # Filter out zero-length segments
    return grep { $_->{end} > $_->{start} } @merged;
}

sub recalculate_kept_chapters (@kept) {
    my ($cur, @out) = (0);
    for my $seg (@kept) {
        my $len = $seg->{end} - $seg->{start};
        push @out, {start => $cur, end => $cur + $len, title => $seg->{title}};
        $cur += $len;
    }
    return @out;
}

# ==============================================================================
# FFmpeg Wrappers
# ==============================================================================

sub ffprobe ($file, @args) {
    chomp(my $out = `ffprobe -loglevel quiet @args \Q$file\E 2>&1`);
    return $? == 0 ? $out : undef;
}

sub extract_bitrate ($file) {
    ffprobe($file, qw(-show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1));
}

sub extract_duration ($file) {
    ffprobe($file, qw(-show_entries format=duration -of default=noprint_wrappers=1:nokey=1));
}

sub extract_streams ($file) {
    ffprobe($file, qw(-show_entries stream=codec_type -print_format default=noprint_wrappers=1:nokey=1));
}

sub run_ffmpeg_metadata_pass ($in, $out, $meta) {
    my $meta_file = create_temp_file($meta);
    my @cmd =
      ('ffmpeg', '-y', '-loglevel', 'warning', '-stats', '-i', $in, '-i', $meta_file, '-map_metadata', '1', '-map_chapters', '1', '-codec', 'copy', $out);
    system(@cmd) == 0 or die "FFmpeg failed.\n";
    unlink $meta_file;
}

sub run_ffmpeg_cut_pass ($in, $out, $clips, $has_v, $has_a, $meta) {
    my $n = scalar $clips->@*;

    my @ts  = sort { $a->{start} <=> $b->{start} } @$clips;
    my @idx = 0 .. $n - 1;

    my $vouts  = join '', map { "[vcopy$_]" } @idx;
    my $aouts  = join '', map { "[acopy$_]" } @idx;
    my $vclips = join '', map { "[vcopy$_] trim=$ts[$_]{start}:$ts[$_]{end},setpts=PTS-STARTPTS[v$_]," } @idx;
    my $aclips = join '', map { "[acopy$_] atrim=$ts[$_]{start}:$ts[$_]{end},asetpts=PTS-STARTPTS[a$_]," } @idx;

    my $filter = '';
    if ($has_a && $has_v) {
        $filter = "[0:v]split=$n$vouts,[0:a]asplit=$n$aouts,${vclips}${aclips}" . join(' ', map { "[v$_] [a$_]" } @idx) . " concat=n=$n:v=1:a=1[v][a]";
    }
    elsif ($has_v) {
        $filter = "[0:v]split=$n$vouts,${vclips}" . join(' ', map { "[v$_]" } @idx) . " concat=n=$n:v=1[v]";
    }
    elsif ($has_a) {
        $filter = "[0:a]asplit=$n$aouts,${aclips}" . join(' ', map { "[a$_]" } @idx) . " concat=n=$n:v=0:a=1[a]";
    }

    my $meta_file = create_temp_file($meta);

    my @cmd = ('ffmpeg', '-y', '-loglevel', 'warning', '-stats', '-i', $in, '-i', $meta_file, '-filter_complex', $filter);
    push @cmd, '-map', '[v]' if $has_v;
    push @cmd, '-map', '[a]' if $has_a;

    if ($has_v) {

        # push @cmd, '-b:v', $bitrate;   # for better quality, let ffmpeg decide
    }
    elsif ($has_a) {
        push @cmd, '-b:a', $bitrate;
    }

    push @cmd, '-map_metadata', '1', '-map_chapters', '1', $out;

    system(@cmd) == 0 or die "FFmpeg failed.\n";
    unlink $meta_file;
}

sub build_ffmpeg_metadata (@chapters) {
    my $meta = ";FFMETADATA1\n";
    for my $ch (@chapters) {
        $meta .= "[CHAPTER]\nTIMEBASE=1/1\nSTART=$ch->{start}\nEND=$ch->{end}\ntitle=$ch->{title}\n";
    }
    return $meta;
}

sub create_temp_file ($content) {
    my ($fh, $file) = tempfile(SUFFIX => '.txt');
    print $fh $content;
    close $fh;
    return $file;
}

sub show_version {
    print "$appname $version\n";
    exit 0;
}

sub show_help ($code) {
    local $" = ",";
    print <<"USAGE";
Usage: $0 [options] <video_id> <input> <output>

Options:
  -a, --action <type>      Action to perform: 'cut' (default) or 'chapter'.
  -c, --categories <list>  Comma-separated categories to target. (default: $cfg{categories})
                           Available: @available_categories
  --all                    Remove all categories
  --tolerance <value>      Tolerance, in seconds, for the duration of the video (default: $cfg{tolerance})
  --direct                 Bypass privacy hash and query API directly via Video ID.
  --proxy <url>            Route requests through a proxy.
  --api-url <url>          Override SponsorBlock API URL.
  --keep-date              Preserve original file modification timestamp.
  -h, --help               Show this help message.
USAGE
    exit $code;
}
