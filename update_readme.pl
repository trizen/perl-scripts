#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 April 2015
# Website: https://github.com/trizen

# Updated the README.md file by adding new scripts to the summary.

use 5.014;
use strict;
use autodie;
use warnings;

use Cwd qw(getcwd);
use File::Spec qw();
use File::Basename qw(basename dirname);
use URI::Escape qw(uri_escape);

sub add_section {
    my ($section, $file) = @_;

    my ($before, $middle);
    open my $fh, '<', $file;
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^(#+\h*Summary\s*)$/) {
            $middle = "$1\n";
            last;
        }
        else {
            $before .= $line;
        }
    }
    close $fh;

    open my $out_fh, '>', $file;
    print {$out_fh} $before . $middle . $section;
    close $out_fh;
}

my $summary_file = 'README.md';
my $main_dir     = File::Spec->curdir;

{
    my @root;

    sub make_section {
        my ($dir, $spaces) = @_;

        my $cwd = getcwd();

        chdir $dir;
        my @files = map { {name => $_, path => File::Spec->rel2abs($_)} } glob('*');    # sorting for free
        chdir $cwd;

        my $make_section_url = sub {
            my ($name) = @_;
            join('/', basename($main_dir), @root, $name);
        };

        my $section = '';
        foreach my $file (@files) {
            my $title = $file->{name} =~ tr/_/ /r =~ s/ s /'s /gr;

            if ($file->{name} =~ /\.(\w{2,3})\z/) {
                next if $1 !~ /^(?:p[lm])\z/i;
            }

            if (-d $file->{path}) {
                $section .= (' ' x $spaces) . "* $title\n";
                push @root, $file->{name};
                $section .= make_section($file->{path}, $spaces + 4);
            }
            else {
                next if $dir eq $main_dir;
                my $naked_title = $title =~ s/\.pl\z//ri;
                my $url_path    =uri_escape($make_section_url->($file->{name}), ' ');
                $section .= (' ' x $spaces) . "* [\u$naked_title]($url_path)\n";
            }
        }

        pop @root;
        return $section;
    }
}

my $section = make_section($main_dir, 0);
my $section_content = add_section($section, $summary_file);

say "** All done!";
