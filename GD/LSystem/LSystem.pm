#!/usr/bin/perl

# Written by jreed@itis.com, adapted by John Cristy.
# Later adopted and improved by Daniel "Trizen" Șuteu.

package LSystem {

    use 5.010;
    use strict;
    use warnings;

    use Turtle;
    use Image::Magick;

    sub new {
        my ($class, $imagesize, $changes, $polychanges) = @_;

        my %opt = (
                   turtle      => Turtle->new($imagesize, $imagesize, 0, 1),
                   changes     => $changes,
                   stemchanges => $changes,
                   polychanges => $polychanges,
                  );

        bless \%opt, $class;
    }

    sub translate {
        my ($self, $letter) = @_;

        my %table = (
            'S' => sub {    # Step forward
                $self->{turtle}->forward($self->{changes}->{distance}, $self->{changes}->{motionsub});
            },
            'T' => sub {    # Step forward
                $self->{turtle}->forward($self->{changes}->{distance}, $self->{changes}->{motionsub});
            },
            '-' => sub { $self->{turtle}->turn(-$self->{changes}->{dtheta}); },                    # counter-clockwise
            '+' => sub { $self->{turtle}->turn($self->{changes}->{dtheta}); },                     # Turn clockwise
            'M' => sub { $self->{turtle}->mirror(); },                                             # Mirror
            '[' => sub { push(@{$self->{statestack}}, [$self->{turtle}->state()]); },              # Begin branch
            ']' => sub { $self->{turtle}->setstate(@{pop(@{$self->{statestack}})}); },             # End branch
            '{' => sub { $self->{turtle}{poly} = []; $self->{changes} = $self->{polychanges} },    # Begin polygon
            '}' => sub {                                                                           # End polygon
                $self->{turtle}->draw(
                                      primitive => 'Polygon',
                                      points    => join(' ', @{$self->{turtle}{poly}}),
                                      fill      => 'light green'
                                     );
                $self->{changes} = $self->{stemchanges};
            },
        );

        if (exists $table{$letter}) {
            $table{$letter}->();
        }
    }

    sub turtle {
        my ($self) = @_;
        $self->{turtle};
    }

    sub execute {
        my ($self, $string, $repetitions, $filename, %rule) = @_;

        for (1 .. $repetitions) {
            $string =~ s{(.)}{$rule{$1} // $1}eg;
        }

        foreach my $command (split(//, $string)) {
            $self->translate($command);
        }
        $self->{turtle}->save_as($filename);
    }
}

1;
