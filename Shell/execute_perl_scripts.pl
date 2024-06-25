#!/usr/bin/perl

# Author: Trizen
# Date: 25 June 2024
# https://github.com/trizen

# Execute a given list of Perl scripts given as command-line arguments.

use 5.036;

use File::Basename qw(basename);
use Getopt::Long   qw(GetOptions);

my $arg   = undef;
my $regex = undef;

sub usage($exit_code = 0) {
    print <<"EOT";
usage: $0 [options] [Perl scripts]

options:

    --regex=s : execute scripts matching a given regex (default: None)
    --arg=s   : an argument to be passed to each script (default: None)
    --help    : print this message and exit

examples:

    perl $0 --arg=42 *.pl
    perl $0 --arg=42 --regex='^\\w+\.pl\\z'

EOT

    exit($exit_code);
}

GetOptions(
           'arg=s'   => \$arg,
           'regex=s' => \$regex,
           'h|help'  => sub { usage(0) },
          )
  or die("Error in command line arguments\n");

my @files = @ARGV;

if (defined($regex)) {
    my $re = qr{$regex};
    foreach my $file (glob("*")) {
        if (basename($file) =~ $re) {
            push @files, $file;
        }
    }
}

@files || usage(2);

foreach my $script (@files) {

    if (not -f $script) {
        warn "[!] Not a file: $script\n. Skipping...";
    }

    warn ":: Executing: $script\n";
    system($^X, $script, (defined($arg) ? $arg : ()));
    $? == 0 or die "[!] Stopping... Exit code: $?\n";
}
