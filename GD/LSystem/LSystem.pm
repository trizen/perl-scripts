#!/usr/bin/perl

# Written by jreed@itis.com, adapted by John Cristy.
# Later adopted and improved by Daniel "Trizen" Șuteu.

# Defined rules:
#   +     Turn clockwise
#   -     Turn counter-clockwise
#   :     Mirror
#   [     Begin branch
#   ]     End branch

# Any upper case letter draws a line.
# Any lower case letter is a no-op.

package LSystem {

    use 5.010;
    use strict;
    use warnings;

    use lib qw(.);
    use Turtle;
    use Image::Magick;
    use Math::Trig qw(deg2rad);

    sub new {
        my ($class, %opt) = @_;

        my %state = (
                     theta => deg2rad($opt{angle} // 90),
                     scale => $opt{scale} // 1,
                     xoff  => $opt{xoff}  // 0,
                     yoff  => $opt{yoff}  // 0,
                     len   => $opt{len}   // 5,
                     color => $opt{color} // 'black',
                     turtle => Turtle->new($opt{width} // 1000, $opt{height} // 1000, deg2rad($opt{turn} // 0), 1),
                    );

        bless \%state, $class;
    }

    sub translate {
        my ($self, $letter) = @_;

        my %table = (
                     '+' => sub { $self->{turtle}->turn($self->{theta}); },                        # Turn clockwise
                     '-' => sub { $self->{turtle}->turn(-$self->{theta}); },                       # Turn counter-clockwise
                     ':' => sub { $self->{turtle}->mirror(); },                                    # Mirror
                     '[' => sub { push(@{$self->{statestack}}, [$self->{turtle}->state()]); },     # Begin branch
                     ']' => sub { $self->{turtle}->setstate(@{pop(@{$self->{statestack}})}); },    # End branch
                    );

        if (exists $table{$letter}) {
            $table{$letter}->();
        }
        elsif ($letter =~ /^[[:upper:]]\z/) {
            $self->{turtle}->forward($self->{len}, $self);
        }
    }

    sub turtle {
        my ($self) = @_;
        $self->{turtle};
    }

    sub execute {
        my ($self, $string, $repetitions, $filename, %rules) = @_;

        for (1 .. $repetitions) {
            $string =~ s{(.)}{$rules{$1} // $1}eg;
        }

        foreach my $command (split(//, $string)) {
            $self->translate($command);
        }
        $self->{turtle}->save_as($filename);
    }
}

1;
