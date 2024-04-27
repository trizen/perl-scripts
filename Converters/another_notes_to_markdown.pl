#!/usr/bin/perl

# Author: Trizen
# Date: 27 April 2024
# https://github.com/trizen

# Convert JSON data from the Android app "Another notes" to Markdown format.

# See also:
#   https://github.com/maltaisn/another-notes-app

use 5.036;
use JSON          qw(from_json);
use File::Slurper qw(read_text);

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $json_file = $ARGV[0] // die "usage: $0 [input.json]\n";

my $json  = read_text($json_file);
my $notes = from_json($json)->{notes} // die "Invalid input file";

sub markdown_escape($str) {
    $str =~ s/([-*_`\\()\[\]#])/\\$1/gr;
}

foreach my $key (1 .. 1e6) {
    if (exists $notes->{$key}) {

        my $note = $notes->{$key};

        my $title   = markdown_escape($note->{title});
        my $content = markdown_escape(unpack('A*', $note->{content}));

        if ($title !~ /\S/) {
            $title = '...';
        }

        say "# $title\n";

        if ($note->{type} == 0) {
            say(($content =~ s/\R/\n\n/gr), "\n");
        }
        elsif ($note->{type} == 1) {

            my $meta    = from_json($note->{metadata});
            my @list    = split(/\R/, $content);
            my $checked = $meta->{checked};

            foreach my $i (0 .. $#list) {
                say "- [", ($checked->[$i] ? 'x' : ' '), "] $list[$i]\n";
            }
        }
        else {
            warn "Unknown note type: $note->{type}\n";
        }
    }
}
