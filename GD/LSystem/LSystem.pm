#!/usr/bin/perl

# Translation of: https://github.com/shiffman/The-Nature-of-Code-Examples/blob/master/chp08_fractals/NOC_8_09_LSystem/LSystem.pde

package LSystem {

    use 5.014;
    use warnings;

    sub new {
        my (undef, $axiom, $ruleset) = @_;

        (ref($axiom) eq '' and ref($ruleset) eq 'ARRAY')
          or die "usage: " . __PACKAGE__ . '->new($axiom, \@ruleset)';

        my @ruleset;
        foreach my $rule (@{$ruleset}) {
            while (my ($key, $value) = each %{$rule}) {
                push @ruleset, [$key, ref($value) eq 'ARRAY' ? $value : [split(//, $value)]];
            }
        }

        bless {
               ruleset => \@ruleset,
               seq     => defined($axiom) ? [split(//, $axiom)] : [],
              },
          __PACKAGE__;
    }

    sub generate {
        my ($self) = @_;

        my @nextgen;
        foreach my $i (0 .. $#{$self->{seq}}) {
            my $curr    = $self->{seq}[$i];
            my $replace = [$curr];
            foreach my $j (0 .. $#{$self->{ruleset}}) {
                my $key = $self->{ruleset}[$j][0];
                if ($key eq $curr) {
                    $replace = $self->{ruleset}[$j][1];
                    last;
                }
            }
            push @nextgen, @{$replace};
        }
        $self->{seq} = \@nextgen;
    }

    sub seq {
        my ($self) = @_;
        $self->{seq};
    }
};

1
