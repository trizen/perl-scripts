#!/usr/bin/perl

# Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 20 April 2012
# https://github.com/trizen

# Perl locate - a pretty efficient file locater

use 5.010;
use strict;

use Getopt::Std qw(getopts);
use File::Find qw(find);
use File::Spec::Functions qw(rel2abs);

my $DB_FILE = 'plocate.db';

sub usage {
    print <<"HELP";
usage: $0 [options] [dirs]

options:
        -g  : generate a $DB_FILE file
        -i  : insensitive match
        -h  : show this message

example: $0 -g /my/dir
         $0 /tmp/(work|shop).doc
HELP
    exit 0;
}

@ARGV or do { warn "$0: no pattern to search for specified\n"; exit 1 };

my %opt;
getopts('gih', \%opt);

$opt{h} && usage();

if ($opt{g}) {
    open my $DB_FH, '>', $DB_FILE or die "$0: Can't open $DB_FILE: $!";
    say {$DB_FH} q{<<'__END_OF_THE_DATABASE__';};

    find {
        no_chdir => 1,
        wanted   => sub {
            say {$DB_FH} rel2abs($_);
        },
    } => @ARGV ? grep { -d } @ARGV : q{.};

    say {$DB_FH} q{__END_OF_THE_DATABASE__};
    close $DB_FH;

    exit 0;
}

-e $DB_FILE or usage();

my $files = do $DB_FILE;
study $files;

foreach my $re (@ARGV) {
    $re = $opt{i} ? qr{$re}i : qr{$re};
    while ($files =~ /^.*?$re.*/gmp) {
        say ${^MATCH};
    }
}
