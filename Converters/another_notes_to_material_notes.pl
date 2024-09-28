#!/usr/bin/perl

# Author: Trizen
# Date: 27 April 2024
# Edit: 28 September 2024
# https://github.com/trizen

# Convert JSON data from the Android app "Another notes" to "Material Notes".

# See also:
#   https://github.com/maltaisn/another-notes-app
#   https://github.com/maelchiotti/LocalMaterialNotes

use 5.036;

use JSON          qw(to_json from_json);
use File::Slurper qw(read_text);

binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $json_file = $ARGV[0] // die "usage: $0 [input.json]\n";

my $json  = read_text($json_file);
my $notes = from_json($json)->{notes} // die "Invalid input file";

my %new_notes = (
                 encrypted => JSON::false,
                 notes     => [],
                 version   => "1.6.0",
                );

foreach my $key (1 .. 1e6) {
    if (exists $notes->{$key}) {

        my $note = $notes->{$key};

        my $title   = $note->{title};
        my $content = $note->{content};

        my %new_note = (
                        title        => $title // '',
                        pinned       => JSON::false,
                        deleted      => JSON::false,
                        created_time => ($note->{added}    =~ s{Z\z}{}r),
                        edited_time  => ($note->{modified} =~ s{Z\z}{}r),
                       );

        if ($note->{type} == 0) {    # text
            $new_note{content} = to_json([{insert => $content}]);
        }
        elsif ($note->{type} == 1) {    # checklist

            my $meta    = from_json($note->{metadata});
            my @list    = split(/\R/, $content);
            my $checked = $meta->{checked};

            my @new_checklist;

            foreach my $i (0 .. $#list) {
                push @new_checklist, {insert => $list[$i]};
                push @new_checklist,
                  {
                    attributes => {
                                   block   => "cl",
                                   checked => $checked->[$i] ? JSON::true : JSON::false,
                                  },
                    insert => "\n",
                  };
            }

            $new_note{content} = to_json(\@new_checklist);
        }
        else {
            warn "Unknown note type: $note->{type}\n";
        }

        push @{$new_notes{notes}}, \%new_note;
    }
}

say to_json(\%new_notes);
