#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 29 July 2016
# Website: https://github.com/trizen

# Analyzes a list of strings and returns those that have a certain prefix

package Search::ByPrefix;

use 5.014;
use strict;
use warnings;

sub new {
    my ($class, %opt) = @_;
    bless {table => $opt{table} // {}}, $class;
}

sub add {
    my ($self, $key, $value) = @_;

    my $ref = $self->{table};
    foreach my $item (@$key) {
        $ref = $ref->{$item} //= {};
        push @{$ref->{values}}, \$value;
    }

    $self;
}

sub search {
    my ($self, $pattern) = @_;

    my $ref = $self->{table};

    foreach my $item (@$pattern) {
        if (exists $ref->{$item}) {
            $ref = $ref->{$item};
        }
        else {
            return;
        }
    }

    map { $$_ } @{$ref->{values}};
}

package main;

use File::Spec::Unix;
my $obj = Search::ByPrefix->new;

sub make_key {
    [File::Spec::Unix->splitdir($_[0])];
}

foreach my $dir (
                 qw(
                 /home/user1/tmp/coverage/test
                 /home/user1/tmp/covert/operator
                 /home/user1/tmp/coven/members
                 /home/user1/tmp2/coven/members
                 /home/user2/tmp2/coven/members
                 )
  ) {
    $obj->add(make_key($dir), $dir);
}

# Finds the common directories
say for $obj->search(make_key('/home/user1/tmp'));
