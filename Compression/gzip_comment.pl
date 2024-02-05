#!/usr/bin/perl

# Author: Trizen
# Date: 21 January 2024
# https://github.com/trizen

# Add and extract a GZIP comment, given a ".gz" file.

# References:
#   Data Compression (Summer 2023) - Lecture 11 - DEFLATE (gzip)
#   https://youtube.com/watch?v=SJPvNi4HrWQ
#
#   GZIP file format specification version 4.3
#   https://datatracker.ietf.org/doc/html/rfc1952

use 5.036;
use Getopt::Std  qw(getopts);
use MIME::Base64 qw(encode_base64 decode_base64);

use constant {
              CHUNK_SIZE => 0xffff,    # 2^16 - 1
             };

getopts('ebho:', \my %opts);

sub usage ($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [input.gz] [comment.txt]"

options:

    -o  : output file
    -e  : extract comment
    -b  : base64 encoding / decoding of the comment
    -h  : print this message and exit

example:

    # Add comment to "input.gz" from "file.txt" (base64-encoded)
    perl $0 -o output.gz -b input.gz file.txt

    # Extract comment from "input.gz" (base64-decoded)
    perl $0 -o comment.txt -eb input.gz

EOT
    exit $exit_code;
}

sub read_null_terminated ($in_fh) {
    my $string = '';
    while (1) {
        my $c = getc($in_fh) // die "Invalid gzip data";
        last if $c eq "\0";
        $string .= $c;
    }
    return $string;
}

sub extract_comment ($input_gz, $output_file) {

    open my $in_fh, '<:raw', $input_gz
      or die "Can't open file <<$input_gz>> for reading: $!";

    my $MAGIC = getc($in_fh) . getc($in_fh);

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        die "Not a Gzip file: $input_gz\n";
    }

    my $CM     = getc($in_fh);                             # 0x08 = DEFLATE
    my $FLAGS  = getc($in_fh);                             # flags
    my $MTIME  = join('', map { getc($in_fh) } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh);                             # extra flags
    my $OS     = getc($in_fh);                             # 0x03 = Unix

    my $has_filename = 0;

    if ((ord($FLAGS) & 0b0000_1000) != 0) {
        say STDERR "Has filename.";
        $has_filename = 1;
    }

    if ((ord($FLAGS) & 0b0001_0000) != 0) {
        say STDERR "Has comment.";
    }
    else {
        die "No comment was found.\n";
    }

    if ($has_filename) {
        read_null_terminated($in_fh);    # filename
    }

    my $comment = read_null_terminated($in_fh);

    my $out_fh;
    if (defined($output_file)) {
        open $out_fh, '>:raw', $output_file
          or die "Can't open file <<$output_file>> for writing: $!";
    }
    else {
        $out_fh = \*STDOUT;
    }

    if ($opts{b}) {
        $comment = decode_base64($comment);
    }

    print $out_fh $comment;
}

sub add_comment ($input_gz, $comment_file, $output_gz) {

    if (!defined($output_gz)) {
        if ($input_gz =~ /\.tar\.gz\z/) {
            $output_gz = "output.tar.gz";
        }
        elsif ($input_gz =~ /\.tgz\z/) {
            $output_gz = "output.tgz";
        }
        else {
            $output_gz = "output.gz";
        }
    }

    if (-e $output_gz) {
        die "Output file <<$output_gz>> already exists!\n";
    }

    open my $in_fh, '<:raw', $input_gz
      or die "Can't open file <<$input_gz>> for reading: $!";

    open my $comment_fh, '<:raw', $comment_file
      or die "Can't open file <<$comment_file>> for reading: $!";

    my $MAGIC = getc($in_fh) . getc($in_fh);

    if ($MAGIC ne pack('C*', 0x1f, 0x8b)) {
        die "Not a Gzip file: $input_gz\n";
    }

    my $CM     = getc($in_fh);                             # 0x08 = DEFLATE
    my $FLAGS  = getc($in_fh);                             # flags
    my $MTIME  = join('', map { getc($in_fh) } 1 .. 4);    # modification time
    my $XFLAGS = getc($in_fh);                             # extra flags
    my $OS     = getc($in_fh);                             # 0x03 = Unix

    open my $out_fh, '>:raw', $output_gz
      or die "Can't open file <<$output_gz>> for writing: $!";

    print $out_fh $MAGIC, $CM, chr(ord($FLAGS) | 0b0001_0000), $MTIME, $XFLAGS, $OS;

    my $has_filename = 0;
    my $has_comment  = 0;

    if ((ord($FLAGS) & 0b0000_1000) != 0) {
        say STDERR "Has filename.";
        $has_filename = 1;
    }
    else {
        say STDERR "Has no filename.";
    }

    if ((ord($FLAGS) & 0b0001_0000) != 0) {
        say STDERR "Has comment.";
        $has_comment = 1;
    }
    else {
        say STDERR "Has no existing comment.";
    }

    if ($has_filename) {
        my $filename = read_null_terminated($in_fh);    # filename
        print $out_fh $filename . "\0";
    }

    if ($has_comment) {
        say STDERR "Replacing existing comment.";
        read_null_terminated($in_fh);                   # remove existing comment
    }
    else {
        say STDERR "Adding comment from file.";
    }

    my $comment = do {
        local $/;
        <$comment_fh>;
    };

    if ($opts{b}) {
        $comment = encode_base64($comment);
    }

    print $out_fh $comment;
    print $out_fh "\0";

    # Copy the rest of the gzip file
    while (read($in_fh, (my $chunk), CHUNK_SIZE)) {
        print $out_fh $chunk;
    }

    return 1;
}

if ($opts{h}) {
    usage(0);
}

my $input_gz = shift(@ARGV) // usage(2);

if ($opts{e}) {
    extract_comment($input_gz, $opts{o});
}
else {
    my $comment_file = shift(@ARGV) // usage(2);
    add_comment($input_gz, $comment_file, $opts{o});
}
