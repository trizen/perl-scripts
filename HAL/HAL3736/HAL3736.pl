#!/usr/bin/perl

# Author: Daniel "Trizen" Șuteu
# License: GPLv3
# Date: 14 April 2014
# Website: http://github.com/trizen

# A basic A.I. concept, inspired by HAL9000.

use utf8;
use 5.014;
use autodie;
use warnings;

use Data::Dump qw(pp);
use Text::ParseWords qw(quotewords);

# UTF-8 ready
use open IO => ':encoding(UTF-8)';

# Constants
use constant {
              NAME        => 'HAL3736',
              MEMORY_FILE => 'HAL3736.memory',
             };

require Term::ReadLine;
my $term = Term::ReadLine->new(NAME);

# Save memory
sub save_mem {
    my ($memory) = @_;
    open my $fh, '>', MEMORY_FILE;
    print {$fh} <<"HEADER", pp($memory), "\n";
#!/usr/bin/perl

# This file is part of the ${\NAME} program.
# Don't edit this file, unless you know what are you doing!

# Updated on: ${\scalar localtime}
#         by: $0

HEADER
    close $fh;
}

# Create the memory if doesn't exist
if (not -e MEMORY_FILE) {
    save_mem(scalar {});
}

# Load the memory
my $MEM = (do MEMORY_FILE);

# Read or create memories
sub hal {
    my ($items, $ref) = @_;

    foreach my $item (@{$items}) {
        $ref = ($ref->{$item} //= {});
    }

    return $ref;
}

# Speak the text (with espeak)
sub speak {
    my ($text) = @_;
    `espeak \Q$text\E &> /dev/null`;    # speak the answer
}

print <<"EOF";
********************************************************************************
                    Hello there! My name is ${\NAME}.
I'm a "Heuristically programmed ALgorithmic computer", a descendant of HAL9000.
In this training program, I'm ready to answer and learn new things about your
awesome world. So, please, don't hesitate and ask me anything. I'll try my best.
********************************************************************************
EOF

speak("Hello!");

my $q = 'a';
while (1) {
    my $question = unpack('A*', lc($term->readline("\n[?] Ask me $q question: ") // next)) =~ s/^\h+//r;

    last if $question eq 'q';
    if (not $question =~ /\?\z/) {
        say "[*] This is not a question! :-)";
        speak("This is not a question!");

        if ($question eq '') {
            say "[!] Insert 'q' if you're bored already...";
        }

        next;
    }

    $q = 'another';
    $question =~ s/\b's\b/ is/g;      # what's  => what is
    $question =~ s/\b're\b/ are/g;    # you're you => are
    $question =~ s/\b'm\b/ am/g;      # I'm => I am

    my $requestion = $question;
    $requestion =~ s/\byour\b/my/g;       # your => my
    $requestion =~ s/\bare\b/am/g;        # are => am
    $requestion =~ s/\byou\b/I/g;         # you => I
    $requestion =~ s/\byours\b/mine/g;    # yours => mine

    my $answer = $requestion;

    my $q_suffix = '';
    if ($answer =~ s/^what\h+//) {
        if ($answer =~ /am\b/) { }        # ok
        elsif ($answer =~ s/^(\w+)\h*//) {
            $q_suffix = " $1";
        }
    }

    my $an_suffix = '';
    if ($answer =~ s/^how\h+//) {
        if ($answer =~ /^am\b/) { }       # ok
        elsif ($answer =~ s/^(\w+)\h*//) {
            $an_suffix = " $1";
        }
    }

    $answer =~ s/^where\b\h*//;
    $answer =~ s/\bam\h+I\b/I am/g;
    $answer =~ s/\?+\z//;

    #$answer =~ s/^does\b\h*//;

    my @input = quotewords(qr/\s+/o, 0, $question);
    next if scalar(@input) == 0;

    my $ref = hal(\@input, $MEM);
    if (exists $ref->{ANSWER}) {
        print "[*] ";
        my $ans;
        if ($ref->{ANSWER} =~ /^(yes|no)[[:punct:]]?\z/i) {
            $ans = "\u\L$1\E!";
        }
        else {
            $ans = "\u$answer$q_suffix $ref->{ANSWER}$an_suffix.";
        }

        say $ans;
        speak($ans);
    }
    else {
        say "\n[*] I don't know... :(";
        speak("I don't know...");
        speak($requestion);
        my $input = $term->readline("[?] \u$requestion ");
        speak("Are you sure?");
        if ($term->readline("[!] Are you sure? ") =~ /^y/i) {
            $ref->{ANSWER} = $input;
            speak("Roger that!");
        }
    }
}

# Save what we learned
save_mem($MEM);
