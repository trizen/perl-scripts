#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 December 2014
# Website: http://github.com/trizen

# Find the minimum sentence(s) that satisfies a regular expression
# See also: http://www.perlmonks.org/?node_id=284513

# WARNING: this script is just an idea in development

# usage: perl regex_to_strings.pl [regexp]

use utf8;
use 5.010;
use strict;
use warnings;

use Regexp::Parser;
use Data::Dump qw(pp);

binmode(STDOUT, ':utf8');

{
    no warnings 'redefine';
    *Regexp::Parser::anyof_class::new = sub {
        my ($class, $rx, $type, $neg, $how) = @_;
        my $self = bless {
                          rx     => $rx,
                          flags  => $rx->{flags}[-1],
                          family => 'anyof_class',
                         }, $class;

        if (ref $type) {
            $self->{data} = $type;
        }
        else {
            $self->{type} = $type;
            $self->{data} = 'POSIX';
            $self->{neg}  = $neg;
            $self->{how}  = ${$how};    # bug-fix
        }

        return $self;
    };
}

my $regex = shift() // 'ab(c[12]|d(n|p)o)\w{3}[.?!]{4}';
my $parser = Regexp::Parser->new($regex);

my %conv = (
            alnum  => 'a',
            nalnum => '#',
            digit  => '1',
            ndigit => '+',
            space  => ' ',
            nspace => '.',
           );

my @stack;
my @strings = [];
my $ref     = \@strings;

my $iter = $parser->walker;

my $min        = 1;
my $last_depth = 0;
while (my ($node, $depth) = $iter->()) {

    my $family = $node->family;
    my $type   = $node->type;

    if ($depth < $last_depth) {
        $min = 1;
        say "MIN CHANGED";
    }

    if ($family eq 'quant') {
        $min = $node->min;
        say "MIN == $min";
    }

    pp $family, $type, $node->qr;    # for debug

    if ($type =~ /^(?:close\d|tail)/) {
        $ref = pop @stack;
    }
    elsif (exists $conv{$type}) {
        push @{$ref->[-1]}, $conv{$type} x $min;
    }
    elsif ($family eq 'open' or $type eq 'group' or $type eq 'suspend') {
        push @stack, $ref;
        push @{$ref->[-1]}, [];
        $ref = $ref->[-1][-1];
        push @{$ref}, [];
    }
    elsif ($type eq 'branch') {
        $#{$ref->[-1]} == -1 or push @{$ref}, [];
    }
    elsif ($type eq 'exact' or $type eq 'exactf') {
        push @{$ref->[-1]}, $node->data x $min;
    }
    elsif ($type eq 'anyof' and $min > 0) {
        my $regex = $node->qr;
        foreach my $c (0 .. 1000000) {
            if (chr($c) =~ /$regex/) {
                push @{$ref->[-1]}, chr($c) x $min;
                last;
            }
        }
    }

    $last_depth = $depth;
}

use Data::Dump qw(pp);
pp @strings;

# TODO: join the @strings into real $strings
