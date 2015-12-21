#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 21 December 2015
# Website: https://github.com/trizen

# A very basic parser and a Perl code generator.

use 5.010;
use strict;
use warnings;

#
## The parser
#

sub parse_expr {
    local *_ = $_[0];

    # Whitespace
    /\G\s+/gc;

    # Number
    if (/\G([-+]?[0-9]+(?:\.[0-9]+)?)\b/gc) {
        return bless {value => $1}, 'Number';
    }

    # Variable declaration
    if (/\Gvar\b/gc) {
        /\G\s+(\w+)/gc || die "expected a variable name after `var`";
        return bless {name => $1}, 'Variable';
    }

    # Identifier
    if (/\G(\w+)/gc) {
        return bless {name => $1}, 'Identifier';
    }

    # Nested expression
    if (/\G\(/gc) {
        return parse($_[0]);
    }

    return;
}

sub parse {
    local *_ = $_[0];

    my %ast;
    while (1) {
        /\G\s+/gc;

        # Prefix operator
        if (/\Gsay\b/gc) {
            my $arg = parse_expr($_[0]);
            push @{$ast{main}}, {self => bless({expr => {self => $arg}}, 'Say')};
        }

        # Expression
        my $expr = parse_expr($_[0]);
        if (defined $expr) {
            push @{$ast{main}}, {self => $expr};

            # Binary operator
            while (m{\G\s*([-\^+*/=])}gc) {
                my $op = $1;

                # Expression
                my $arg = parse_expr($_[0]);
                push @{$ast{main}[-1]{call}}, {op => $op, arg => {self => $arg}};
            }

            next;
        }

        # End of nested expression
        if (/\G\)/gc) {
            return \%ast;
        }

        # End of code
        if (/\G\z/gc) {
            return \%ast;
        }

        die "Syntax error at -->", substr($_, pos($_), 10) . "\n",;
    }

    return \%ast;
}

#
## The code generator
#

sub generate_expr {
    my ($expr) = @_;

    my $code = '';
    my $obj  = $expr->{self};

    my $ref = ref($obj);
    if ($ref eq 'HASH') {
        $code = '(' . generate($obj) . ')';
    }
    elsif ($ref eq 'Number') {
        $code = $obj->{value};
    }
    elsif ($ref eq 'Variable') {
        $code = 'my $' . $obj->{name};
    }
    elsif ($ref eq 'Identifier') {
        $code = '$' . $obj->{name};
    }
    elsif ($ref eq 'Say') {
        $code = 'print(' . generate_expr($obj->{expr}) . ', "\n")';
    }

    # Check for a call operator
    if (exists $expr->{call}) {
        foreach my $call (@{$expr->{call}}) {
            if (exists $call->{op}) {
                my $op = $call->{op};
                $code .= ' ';
                if ($op eq '^') {
                    $code .= '**';
                }
                else {
                    $code .= $op;
                }
                $code .= ' ';
            }
            if (exists $call->{arg}) {
                $code .= generate_expr($call->{arg});
            }
        }
    }

    return $code;
}

sub generate {
    my ($ast) = @_;

    my @statements;
    foreach my $statement (@{$ast->{main}}) {
        push @statements, generate_expr($statement);
    }

    return join(";\n", @statements);
}

#
## Example
#

my $code = <<'EOT';
var x = 42
var y = (81 / 3)
say (x^2 * (3+y) - 1)
EOT

my $ast = parse(\$code);    # parses the code and returns the AST
eval {
    require Data::Dump;
    Data::Dump::pp($ast);    # displays the AST (if Data::Dump is installed)
};

say generate($ast);          # generates code from the AST and prints it
