#!/usr/bin/perl

# Translation of: https://github.com/shiffman/The-Nature-of-Code-Examples/blob/master/chp08_fractals/NOC_8_09_LSystem/Turtle.pde

package Turtle {

    use 5.014;
    use warnings;
    use GD::Simple qw();

    sub new {
        my (undef, %opt) = @_;

        my %vars = (
                    seq    => [],
                    angle  => 90,
                    width  => 1920,
                    height => 1080,
                    len    => 1080 / 3,
                    %opt
                   );

        my $img = GD::Simple->new($vars{width}, $vars{height});
        $vars{img} = $img;

        bless \%vars, __PACKAGE__;
    }

    sub draw {
        my ($self) = @_;

        foreach my $c (@{$self->{seq}}) {
            if ($c eq 'F' or $c eq 'G') {
                my $angle = $self->{img}->angle;
                $self->{img}->line($self->{len});
                $self->{img}->angle($angle);
            }
            elsif ($c eq '+') {
                $self->{img}->angle($self->{angle});
            }
            elsif ($c eq '-') {
                $self->{img}->angle(-$self->{angle});
            }
            elsif ($c eq '[') {
                push @{$self->{stuck}}, [$self->{img}->curPos, $self->{img}->angle];
            }
            elsif ($c eq ']') {
                my ($x, $y, $angle) = @{pop @{$self->{stuck}}};
                $self->{img}->moveTo($x, $y);
                $self->{img}->angle($angle);
            }
        }
    }

    sub move_to {
        my ($self, $x, $y) = @_;
        $self->{img}->moveTo($x, $y);
    }

    sub rotate {
        my ($self, $angle) = @_;
        $self->{img}->angle($angle);
    }

    sub get_img {
        my ($self) = @_;
        $self->{img};
    }

    sub render_as {
        my ($self, $name) = @_;
        open my $fh, '>:raw', $name;
        print {$fh} $self->{img}->png;
        close $fh;
    }

    sub set_len {
        my ($self, $len) = @_;
        $self->{len} = $len;
    }

    sub scale_len {
        my ($self, $percent) = @_;
        $self->{len} *= $percent;
    }

    sub set_seq {
        my ($self, $seq) = @_;
        $self->{seq} = $seq;
    }
};

1
