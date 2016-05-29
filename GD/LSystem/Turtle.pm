package Turtle {

    use 5.010;
    use strict;
    use warnings;

    # Written by jreed@itis.com, adapted by John Cristy.
    # Later adopted and improved by Daniel "Trizen" Șuteu.

    sub new {
        my $class = shift;

        my %opt;
        @opt{qw(x y theta mirror)} = @_;

        # Create the main image
        my $im = Image::Magick->new(size => $opt{x} . 'x' . $opt{y});
        $im->ReadImage('canvas:white');

        $opt{im} = $im;
        bless \%opt, $class;
    }

    sub forward {
        my ($self, $r, $opt) = @_;
        my ($newx, $newy) = ($self->{x} + $r * sin($self->{theta}), $self->{y} + $r * -cos($self->{theta}));

        $self->draw(
                    primitive => 'line',
                    points    => join(' ',
                                   $self->{x} * $opt->{scale} + $opt->{xoff},
                                   $self->{y} * $opt->{scale} + $opt->{yoff},
                                   $newx * $opt->{scale} + $opt->{xoff},
                                   $newy * $opt->{scale} + $opt->{yoff},
                                  ),
                    stroke      => $opt->{color},
                    strokewidth => 1
                   );

        ($self->{x}, $self->{y}) = ($newx, $newy);    # change the old coords
    }

    sub draw {
        my ($self, %opt) = @_;
        $self->{im}->Draw(%opt);
    }

    sub composite {
        my ($self, %opt) = @_;
        $self->{im}->Composite(%opt);
    }

    sub save_as {
        my ($self, $filename) = @_;
        $self->{im}->Write($filename);
    }

    sub turn {
        my ($self, $dtheta) = @_;
        $self->{theta} += $dtheta * $self->{mirror};
    }

    sub state {
        my ($self) = @_;
        @{$self}{qw(x y theta mirror)};
    }

    sub setstate {
        my $self = shift;
        @{$self}{qw(x y theta mirror)} = @_;
    }

    sub mirror {
        my ($self) = @_;
        $self->{mirror} *= -1;
    }

}

1;
