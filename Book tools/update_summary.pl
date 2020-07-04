#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 24 April 2015
# Website: https://github.com/trizen

# Add a given directory to a given section in SUMMARY.md (for gitbooks)

use 5.014;
use strict;
use autodie;
use warnings;

use Cwd qw(getcwd);
use File::Basename qw(basename dirname);
use File::Spec::Functions qw(rel2abs);

sub add_section {
    my ($name, $section, $file) = @_;

    my ($before, $middle, $after);
    open my $fh, '<', $file;
    while (defined(my $line = <$fh>)) {
        if ($line =~ /^(\*\h+\Q$name\E)\h*$/ || $line =~ m{^(\*\h+\[\Q$name\E\](?:\(.*\))?)\h*$}) {

            $middle = "$1\n";
            say "** Found section: <<<$1>>>";
            while (defined(my $line = <$fh>)) {
                if ($line =~ /^\S/) {
                    $after = $line;
                }
            }
        }
        else {
            if (defined $after) {
                $after .= $line;
            }
            else {
                $before .= $line;
            }
        }
    }
    close $fh;

    open my $out_fh, '>', $file;
    print {$out_fh} $before . $middle . $section . $after;
    close $out_fh;
}

my $summary_file = 'SUMMARY.md';

my $main_dir     = 'programming_tasks';
my $section_name = 'Programming tasks';

{
    my @root;

    sub make_section {
        my ($name, $dir, $spaces) = @_;

        my $cwd = getcwd();

        chdir $dir;
        my @files = map { {name => $_, path => rel2abs($_)} } glob('*');    # sorting for free
        chdir $cwd;

        my $make_section_url = sub {
            my ($name) = @_;
            join('/', basename($main_dir), @root, $name);
        };

        my %ignored;
        my $section = '';
        foreach my $file (@files) {
            my $title = $file->{name} =~ s/_/ /gr;

            if (-d $file->{path}) {

                if (-e "$file->{path}.md") {
                    my $url_path = $make_section_url->("$file->{name}.md");
                    $section .= (' ' x $spaces) . "* [\u$title]($url_path)\n";
                    $ignored{"$file->{name}.md"}++;    # ignore this file later
                }
                else {
                    $section .= (' ' x $spaces) . "* $title\n";
                }

                push @root, $file->{name};
                $section .= make_section($file->{name}, $file->{path}, $spaces + 4);
            }
            else {
                next if $dir eq $main_dir;
                next if $ignored{$file->{name}};
                my $naked_name  = $file->{name} =~ s/\.md\z//ir;
                my $naked_title = $title =~ s/\.md\z//ir;
                my $url_path    = $make_section_url->($file->{name});
                $section .= (' ' x $spaces) . "* [\u$naked_title]($url_path)\n";
            }
        }

        pop @root;
        return $section;
    }
}

my $section = make_section($section_name, $main_dir, 3);
my $section_content = add_section($section_name, $section, $summary_file);

say "** All done!";
