#!/usr/bin/perl

use GD::Simple;

#use ntheory ('is_prime');
print "** Generating image...\n";
$img = 'GD::Simple'->new(10000, 6000);
$img->fgcolor('blue');
$img->moveTo(1000, 2000);
for ($nr = 200 ; $nr <= 300 ; $nr += int rand 7) {
    $img->fgcolor('white');

    #$img->turn(-$nr);
    #$img->line(300) if $nr < 100;
    #$img->line($nr);
    $img->line($nr * 2);

    #$img->line( -$nr );

    #$img->line($nr);
    #if ( is_prime($nr) ) {
    #$img->turn($nr);
    #$img->turn($nr);
    #$img->line( int rand -$nr );
    #$img->turn( -$nr );
    #$img->line( rand $nr );
    #$img->line($nr);
    #print "$nr\n";
    foreach $_ (0 .. (rand(100)) + 30) {
        $img->fgcolor('green');
        $img->turn($nr);
        $img->line(-$nr);
        $img->line(-$nr);
        $img->line(-$nr);
        $img->line(-$nr);

        $img->fgcolor('gray');
        $img->turn(-$nr);
        $img->line($nr);
        $img->line($nr);
        $img->line($nr);
        $img->line($nr);

        #$img->line(-$nr);
        #$img->line($nr);
        #$img->line(-$nr);
        #$img->line($nr);
        #$img->line($nr);
        #$img->line($nr);

        $img->fgcolor('blue');
        $img->turn(-$nr);
        $img->line($nr);

        #$img->line($nr);
        #$img->line($nr);
        #$img->line($nr);

        $img->fgcolor('purple');
        $img->turn($nr);

        #$img->line( $nr );
        #$img->line( $nr );
        $img->line(-$nr);

        #$img->line(-$nr);
        #$img->line( $nr );

        $img->fgcolor('red');
        $img->turn($nr);

        #$img->line( -$nr );
        #$img->line( $nr );
        $img->line(-$nr);

        #$img->line(-$nr);
        #$img->line(-$nr);
        #$img->line(-$nr);
        #$img->line(-$nr);
        #$img->line(-$nr);
    }

    #}
    #$img->fgcolor('white');
    #$img->turn(-$nr);
    my $a = ($nr * (int rand 4)) + (int rand 2000) + 4000;
    my $b = ($nr * (int rand 4)) + (int rand 1000) + 1000;
    $img->moveTo($a, $b) if $nr =~ /5$/;

    #$img->turn(-$nr);
    #$img->turn(-$nr);
    #$img->line(-$nr*5+100);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line($nr);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line(-$nr);
    #$img->line($nr);
    #$img->line($nr);
    #$img->line($nr);
    #$img->line($nr);
    #$img->line($nr);
    #$img->line($nr);
    #$img->line($nr);
}

open FILE, '>test.png';
print FILE $img->png;
close FILE;
print "** Done\n";
`gliv test.png`;
