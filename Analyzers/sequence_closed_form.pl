#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 15 April 2016
# Website: https://github.com/trizen

# Analyze a sequence of numbers and find a closed-form expression.

# WARNING: This program is under heavy development.

use 5.010;
use strict;
use warnings;

package Sequence::ClosedForm {

    use Math::BigNum qw(Inf);

    sub new {
        my ($class, %opt) = @_;
        bless \%opt, $class;
    }

    sub sub_n {
        my $n = 0;
        sub {
            $_[0] - ++$n;
        };
    }

    sub add_n {
        my $n = 0;
        sub {
            $_[0] + ++$n;
        };
    }

    sub mul_n {
        my $n = 1;
        sub {
            $_[0] * ++$n;
        };
    }

    sub div_n {
        my $n = 1;
        sub {
            $_[0] / ++$n;
        };
    }

    sub sub_constant {
        my (undef, $c) = @_;
        sub {
            $_[0] - $c;
        };
    }

    sub div_constant {
        my (undef, $c) = @_;
        sub {
            $_[0] / $c;
        };
    }

    sub add_constant {
        my (undef, $c) = @_;
        sub {
            $_[0] + $c;
        };
    }

    sub add_all {
        my $sum = 0;
        sub {
            $sum += $_[0];
            $sum;
        };
    }

    sub mul_all {
        my $prod = 1;
        sub {
            $prod *= $_[0];
            $prod;
        };
    }

    sub sub_consecutive {
        my $prev;
        sub {
            my ($term) = @_;
            if (defined($prev)) {
                $term = $term - $prev;
            }
            $prev = $_[0];
            $term;
        };
    }

    sub add_consecutive {
        my $prev;
        sub {
            my ($term) = @_;
            if (defined($prev)) {
                $term = $term + $prev;
            }
            $prev = $_[0];
            $term;
        };
    }

    sub div_consecutive {
        my $prev;
        sub {
            my ($term) = @_;
            if (defined($prev)) {
                $term = $term / $prev;
            }
            $prev = $_[0];
            $term;
        };
    }

    sub find_closed_form {
        my ($self, $seq) = @_;

        my %data = (
            diff_min => Inf,
            diff_max => -Inf,
            diff_avg => 0,

            ratio_min => Inf,
            ratio_max => -Inf,
            ratio_avg => 0,

            min => Inf,
            max => -Inf,
                   );

        my $count = @$seq - 1;
        return if $count <= 0;

        my $prev;
        foreach my $term (@{$seq}) {

            if ($term < $data{min}) {
                $data{min} = $term;
            }

            if ($term > $data{max}) {
                $data{max} = $term;
            }

            if (defined $prev) {
                my $diff = $term - $prev;

                if ($diff < $data{diff_min}) {
                    $data{diff_min} = $diff;
                }

                if ($diff > $data{diff_max}) {
                    $data{diff_max} = $diff;
                }

                $data{diff_avg} += $diff / $count;

                my $ratio = $term / $prev;

                if ($ratio < $data{ratio_min}) {
                    $data{ratio_min} = $ratio;
                }

                if ($ratio > $data{ratio_max}) {
                    $data{ratio_max} = $ratio;
                }

                $data{ratio_avg} += $ratio;

            }

            $prev = $term;
        }

        $data{ratio_avg} /= $count;

        my @closed_forms;

        if ($data{diff_avg} == $data{diff_max} and $data{diff_max} == $data{diff_min}) {
            my $min = ($data{min} - $data{diff_min})->round(-20);
            push @closed_forms,
              scalar {
                      factor => $data{diff_min},
                      offset => $min,
                      type   => 'arithmetic',
                     };
        }

        if ($data{ratio_avg} == $data{ratio_max} and $data{ratio_max} == $data{ratio_min}) {
            my $factor = $data{min} / $data{ratio_min};
            push @closed_forms,
              scalar {
                      factor => $factor,
                      base   => $data{ratio_min},
                      type   => 'geometric',
                     };
        }

        #foreach my $key (sort keys %data) {
        #    printf("%9s => %s\n", $key, $data{$key});
        #}
        #print "\n";

        return @closed_forms;
    }
}

use Math::BigNum;
use List::Util qw(first);

my $seq       = Sequence::ClosedForm->new();
my @constants = (1 .. 5);                      #, #exp(1), atan2(0, -'inf'));

my @rules = (

    #['sub_consecutive', 'add_n'], # 'add_n'],
    #['add_constant', 'sub_consecutive'],
    ['sub_constant', 'sub_consecutive'],
    ['sub_constant', 'div_constant'],
    ['sub_constant'],

    #['add_constant', 'div_consecutive'],
    ['sub_constant', 'add_n',],
    ['sub_constant', 'div_consecutive', 'sub_constant'],

    #['sub_constant'],
    #['sub_constant', 'div_consecutive',],
    ['sub_constant', 'div_consecutive'],

    #['div_consecutive', 'sub_constant'],

    # ['sub_constant', 'sub_consecutive'],

    #['sub_constant'],
    #['add_n', 'div_consecutive',],
    #['div_consecutive',],
);

sub make_constant_obj {
    my ($method) = @_;

    my %cache;

    my %state = (
        i    => 0,
        done => 0,

        code => sub {
            my ($self, $n) = @_;
            my $i = $self->{i} - 1;
            my $sub = ($cache{$i} //= $seq->$method($constants[$i]));
            $sub->($n);
        }
    );

    bless \%state, 'Sequence::Constant';
}

sub generate_actions {
    map { /_constant\z/ ? [$_, make_constant_obj($_)] : [$_, $seq->$_] } @_;
}

my @numbers = (map { Math::BigNum->new($_) } 1 .. 9);

#my @seq = map { 3**$_ + 2} @numbers;
#my @seq = map { 3 * $_  } @numbers;
#my @seq = map { $_ * ($_ + 1) / 2 + 1 } @numbers;
my @seq = map { $_->fac + 2 } @numbers;

say "\nseq: @seq\n";

my %closed_forms = (
    sub_consecutive => sub {
        my ($n, $data) = @_;

        #"($data->{factor}*$n + $data->{offset})*($data->{factor}*$n + $data->{offset} + 1)/2";
        #"($n * ($n+1) / 2)";

        $data->{type} eq 'arithmetic'
          ? "($n * ($n+1) / 2)"
          : "($data->{base}**$n)";
    },
    add_n => sub {
        my ($n, $data) = @_;

        #"(2 * ($n) / $data->{factor})";
        #"($n / (2 * $data->{factor}))";
        #"($n - 1)";

        "($n * " . ($data->{factor} - 1) . " / $data->{factor})";
    },
    div_consecutive => sub {
        my ($n) = @_;
        "($n!)";
    },
    add_constant => sub {
        my ($n, $data, $const) = @_;

        $data->{type} eq 'arithmetic'
          ? "($data->{factor}*($n-$constants[$const->{i}-1+$data->{offset}]))"
          : die "geometric sequences are not supported, yet!";    # TODO: implement it
    },
    sub_constant => sub {
        my ($n, $data, $const) = @_;
        $data->{type} eq 'arithmetic'
          ? "($data->{factor}*($n+$constants[$const->{i}-1]+$data->{offset}))"
          : "($constants[$const->{i}-1] + $n)";                   # wrong
    },
    div_constant => sub {
        my ($n, $data, $const) = @_;
        $data->{type} eq 'geometric'
          ? "($constants[$const->{i}-1] * $data->{factor} * $data->{base}**$n)"
          : "($data->{factor} * $n)";                             # wrong
    },
);

sub fill_closed_form {
    my ($cf, $actions) = @_;

    my $result = 'n';
    foreach my $action (reverse @$actions) {
        my ($name, $obj) = @$action;

        #$report .= "name: $name" . (ref($obj) eq 'Sequence::Constant' ? (' (' . $constants[$obj->{i}-1] . ')') : '') . "\n";
        if (not exists($closed_forms{$name})) {
            warn "No closed-form for rule: $name\n";
            next;
        }
        $result = $closed_forms{$name}($result, $cf, $obj);
    }

    $result;

    #"$result / $cf->{factor} + $cf->{offset}";
}

say '-' x 80;

my %seen;

RULE: foreach my $rule (@rules) {
    my @actions   = generate_actions(@$rule);
    my @const_pos = grep { $rule->[$_] =~ /_constant\z/ } 0 .. $#{$rule};
    my $has_const = !!@const_pos;

  WHILE: while (1) {

        foreach my $group (grep { $_->[0] !~ /_constant\z/ } @actions) {
            my $method = $group->[0];
            $group->[1] = $seq->$method;
        }

        my @sequence;

        my $stop = $has_const;
        foreach my $pos (@const_pos) {
            my $constant = $actions[$pos][1];

            if ($constant->{done}) {
                if ($constant->{i} >= $#constants) {
                    $constant->{i} = 0;
                }
                else {
                    $constant->{i}++;
                }
            }
            else {
                if ($constant->{i} >= $#constants) {
                    $constant->{i}    = 0;
                    $constant->{done} = 1;
                }
                else {
                    $constant->{i}++;
                }

                $stop = 0;
                last;
            }
        }

        last if $stop;

        foreach my $term (@seq) {
            my $result = $term;

            foreach my $group (@actions) {
                my $action = $group->[1];
                if (ref($action) eq 'Sequence::Constant') {
                    $result = $action->{code}($action, $result);
                }
                else {
                    $result = $action->($result);
                }
            }

            next WHILE if ($result <= 0 or not $result->is_real);
            push @sequence, $result;
        }

        if ($sequence[0] >= $sequence[1]) {
            $has_const || last;
            next;
        }

        next if $seen{join(';', map { $_->as_rat } @sequence)}++;

        say "try: @sequence";
        my @closed_forms = $seq->find_closed_form(\@sequence);

        if (@closed_forms) {
            say "new: @sequence\n";
            foreach my $cf (@closed_forms) {
                if ($cf->{type} eq 'geometric') {
                    say "type: $cf->{type}";
                    say "base: $cf->{base}";
                    say "fact: $cf->{factor}";
                }
                elsif ($cf->{type} eq 'arithmetic') {
                    say "type: $cf->{type}";
                    say "fact: $cf->{factor}";
                    say "offs: $cf->{offset}";
                }
                foreach my $action (@actions) {
                    my ($name, $obj) = @$action;
                    say "name: $name" . (ref($obj) eq 'Sequence::Constant' ? " (constant: $constants[$obj->{i}-1])" : '');
                }
                my $filled = fill_closed_form($cf, \@actions);
                say "\n=> Possible closed-form: $filled";
            }
            say '-' x 80;
        }

        $has_const || last;
    }
}
