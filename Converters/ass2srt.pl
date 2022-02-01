#!/usr/bin/perl

# Author: Trizen
# Date: 01 February 2022
# https://github.com/trizen

# Convert ASS/SSA subtitles to SRT.

# See also:
#   http://matroska.sourceforge.net/technical/specs/subtitles/ssa.html
#   https://moodub.free.fr/video/ass-specs.doc

use 5.020;
use strict;
use warnings;

use experimental qw(signatures);

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

sub parse_ASS_subtitle ($file) {

    open my $fh, '<:utf8', $file
      or die "Can't open file <<$file>> for reading: $!";

    my %sections;
    my $section = '';

    while (my $line = <$fh>) {
        if ($line =~ m{^\[(.*?)\]\s*\z}) {
            $section = $1;
        }
        else {
            push @{$sections{$section}}, $line;
        }
    }

    close $fh;

    my $events = $sections{"Events"} // die "No <<Events>> section found.";
    my $format = shift(@$events);

    my @fields;

    if ($format =~ m{^Format: (.+)}) {
        @fields = split(/\s*,\s*/, $1);
    }
    else {
        die "Can't find the <<Format>> line";
    }

    my @dialogues;

    foreach my $event (@$events) {
        if ($event =~ /^Dialogue: (.+)/) {
            my @values = split(/\s*,\s*/, $1, scalar(@fields));

            my %dialogue;
            @dialogue{@fields} = @values;

            push @dialogues, \%dialogue;
        }
        else {
            warn "Ignoring line: $event";
        }
    }

    return @dialogues;
}

sub ASS_time_to_sec ($time) {
    my ($hours, $min, $sec, $milisec) = split(/[:.]/, $time, 4);
    ($hours * 3600 + $min * 60 + $sec + $milisec / 10**length($milisec));
}

sub sec_to_SRT_time ($sec) {
    $sec = sprintf('%.3f', $sec);
    sprintf('%02d:%02d:%02d,%03d', int($sec / 3600) % 24, int($sec / 60) % 60, $sec % 60, substr($sec, -3));
}

sub reformat_text ($text) {

    $text =~ s{\{\\i0\}}{</i>}g;
    $text =~ s{\{\\b0\}}{</b>}g;

    $text =~ s{\{\\i\d+\}}{<i>}g;
    $text =~ s{\{\\b\d+\}}{<b>}g;

    # Strip unknown style codes
    $text =~ s{\{\\\w.*?\}}{}g;

    # Replace \N and \n with a newline
    $text =~ s{\\N}{\n}g;
    $text =~ s{\\n}{\n}g;

    $text;
}

sub reformat_time ($time) {
    sec_to_SRT_time(ASS_time_to_sec($time));
}

sub ASS2SRT ($file) {

    my @dialogues = parse_ASS_subtitle($file);

    my $count = 1;
    my @srt_data;

    foreach my $entry (@dialogues) {

        my $srt_entry = join("\n",
                             $count++,
                             join(' --> ', reformat_time($entry->{Start}), reformat_time($entry->{End})),
                             reformat_text($entry->{Text}),
                            );

        push @srt_data, $srt_entry;
    }

    join("\n\n", @srt_data) . "\n\n";
}

sub usage ($exit_code = 0) {
    print <<"EOT";
usage: $^X $0 [input.ass] [output.srt]
EOT
    exit($exit_code);
}

my $input_file = shift(@ARGV) // usage(2);
my $srt_data   = ASS2SRT($input_file);

my $output_file = shift(@ARGV);

if (defined($output_file)) {
    open my $fh, '>:utf8', $output_file
      or die "Can't open file <<$output_file>> for writing: $!";
    print $fh $srt_data;
    close $fh;
}
else {
    print $srt_data;
}
