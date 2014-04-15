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

# For saving the memory
use Data::Dump qw(pp);

# For transforming XML to HASH
use XML::Fast qw(xml2hash);

# For contracting the words ("I am" into "I'm")
use Lingua::EN::Contraction qw(contraction);

# For correcting common mistakes
use Lingua::EN::CommonMistakes qw(%MISTAKES_COMMON);
use Lingua::EN::CommonMistakes qw(:no-defaults :american %MISTAKES_GB_TO_US);

# UTF-8 ready
use open IO => ':utf8';

# Constants
use constant {
              NAME        => 'HAL8212',
              MEMORY_FILE => 'HAL8212.memory',
             };

# For getting STDIN
require Term::ReadLine;
my $term = Term::ReadLine->new(NAME);

# For splitting words
#require Lingua::EN::Bigram;
#my $ngrams = Lingua::EN::Bigram->new;

# For tagging words
require Lingua::EN::Tagger;
my $ltag = Lingua::EN::Tagger->new;

# For /dev/null
use File::Spec qw();

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
    state $null = File::Spec->devnull;
    `espeak -ven-us \Q$text\E 2>$null`;
}

# Transform GB to US (colour -> color)
sub gb_to_us {
    my ($word) = @_;

    if (defined(my $us_word = $MISTAKES_GB_TO_US{$word})) {
        return $us_word;
    }

    return $word;
}

# Fix common mistakes
sub fix_word {
    my ($word) = @_;

    if (defined(my $fixed_word = $MISTAKES_COMMON{$word})) {
        return $fixed_word;
    }

    return $word =~ s/^i('|$)/I$1/gr;
}

# Ask for a question
sub ask_question {
    state $one = 'a';

    my $q = "Ask me $one question: ";
    if ($one eq 'a') {
        speak($q), $one = 'another';
    }

    my $question = $term->readline("\n[?] " . $q);
    if (not defined $question or $question eq '') {
        say "[!] Insert 'q' if you're bored already...";
    }
    elsif ($question eq 'q') {
        return;
    }

    return contraction($question);
}

sub not_a_question {
    say "[*] This is not a question! :-)";
    speak("This is not a question!");
}

# Split a question into words
sub get_words {
    my ($text) = @_;

    my @words;
    foreach my $word (split(' ', $text)) {

        my @ws;
        if ($word =~ s/([[:punct:]]+)\z//) {
            push @ws, $1;
        }

        push @words, gb_to_us(fix_word($word)), @ws;
    }

    return @words;
}

sub INIT {
    print <<"EOF";
********************************************************************************
                    Hello there! My name is ${\NAME}.
I'm a "Heuristically programmed ALgorithmic computer", a descendant of HAL9000.
In this training program, I'm ready to answer and learn new things about your
awesome world. So, please, don't hesitate and ask me anything. I'll try my best.
********************************************************************************
EOF

    speak("Hello!");
}

while (1) {

    # Get a question
    my $question = ask_question() // last;

    # Split the question into words
    my @words = get_words($question);

    # On empty questions, do this:
    @words || next;

    say join('--', @words);
    my $xml = $ltag->add_tags(join(" ", @words));

    say $xml;
    my $tags = xml2hash($xml);

    while (my ($key, $value) = each %{$tags}) {
        if (ref $value ne 'ARRAY') {
            $tags->{$key} = [$value];
        }
    }

    if (not exists $tags->{pp} or $tags->{pp}[-1] ne '?') {
        not_a_question();
        next;
    }

    pp $tags;

    ##### NEEDS WORK #####

=cut

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
=cut

}

# Save what we learned
save_mem($MEM);
