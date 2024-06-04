#!/usr/bin/perl

# Convert Android Notepad Free backup notes to text files.

use utf8;
use 5.014;
use autodie;
use warnings;

use JSON                  qw(from_json);
use File::Slurper         qw(read_text write_text);
use File::Spec::Functions qw(catfile updir);
use File::Compare         qw();

my $output_dir = 'Text files';
my $meta_json  = from_json(read_text('notes_meta_data.json'));

if (not -d $output_dir) {
    mkdir($output_dir);
}

OUTER: foreach my $note (@{$meta_json->{notes}}) {

    my $title        = $note->{title};
    my $file         = $note->{file};
    my $lastEditDate = $note->{lastEditDate};

    $title =~ s{/}{÷}g;    # replace '/' with '÷'

    my $input_file  = catfile(updir, $file);
    my $content     = read_text($input_file);
    my $output_file = catfile($output_dir, $title . '.txt');

    for (my $k = 1 ; (-f $output_file) ; ++$k) {
        if (File::Compare::compare($input_file, $output_file) == 0) {
            say "File `$output_file` already exists... Skipping...";
            next OUTER;    # files are equal
        }
        else {
            $output_file = catfile($output_dir, $title . '_' . $k . '.txt');
        }
    }

    say "Creating: `$output_file`...";
    write_text($output_file, $content);
    utime($lastEditDate, $lastEditDate, $output_file);
}
