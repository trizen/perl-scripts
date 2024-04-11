#!/usr/bin/perl

# Author: Trizen
# Date: 12 April 2024
# https://github.com/trizen

# Sort the subroutines inside a Perl script, using alphabetical order.
# Additionally, subroutines that are used by other subroutines, are defined earlier.

use 5.036;
use Perl::Tokenizer qw(perl_tokens);

binmode(STDOUT, ':utf8');

my $perl_script = $ARGV[0] // die "usage: $0 [perl_script.pl]\n";

my $perl_code = do {
    open my $fh, '<:utf8', $perl_script
      or die "Cannot open file <<$perl_script>> for reading: $!";
    local $/;
    <$fh>;
};

my %subs;
my $header     = '';
my $sub_header = '';

my $header_state     = 1;
my $sub_header_state = 0;
my $sub_state        = 0;

my $prev_token   = '';
my $prev_token_2 = '';
my $extract_name = 0;
my $sub_name     = '';
my $sub_content  = '';
my %calls;

my $curly_bracket_count = 0;

perl_tokens {
    my ($token, $pos_beg, $pos_end) = @_;

    my $value = substr($perl_code, $pos_beg, $pos_end - $pos_beg);

    if (
            $token eq 'keyword'
        and $value eq 'sub'
        and (
             $prev_token eq 'vertical_space'
             or (    $prev_token eq 'horizontal_space'
                 and $prev_token_2 eq 'vertical_space')
            )
      ) {
        $header_state     = 0;
        $sub_header_state = 0;
        $sub_state        = 1;
        $sub_content .= 'sub';
        $extract_name = 1;
    }
    elsif ($header_state) {
        $header .= $value;
    }
    elsif ($sub_header_state) {
        $sub_header .= $value;
    }
    elsif ($sub_state) {

        if ($extract_name and $token eq 'sub_name') {
            $sub_name     = $value;
            $extract_name = 0;
        }

        $sub_content .= $value;

        if ($token eq 'bare_word') {
            ++$calls{$value};
        }

        if ($token eq 'curly_bracket_open') {
            ++$curly_bracket_count;
        }
        elsif ($token eq 'curly_bracket_close') {
            --$curly_bracket_count;

            if ($curly_bracket_count == 0) {
                if ($sub_name eq '') {
                    $header .= $sub_content;
                }
                else {
                    push @{$subs{$sub_name}},
                      {
                        code  => $sub_header . $sub_content,
                        calls => [sort keys %calls],
                      };
                }
                $sub_header_state = 1;
                $sub_state        = 0;
                $sub_content      = '';
                $sub_header       = '';
                undef %calls;
            }
        }

    }

    ($prev_token_2, $prev_token) = ($prev_token, $token);
} $perl_code;

sub order_subroutines (@keys) {

    my @subs;
    foreach my $key (@keys) {

        exists($subs{$key}) or next;
        my $entry = delete $subs{$key};

        foreach my $sub (@$entry) {
            my @calls = grep { exists($subs{$_}) and $_ ne $key } @{$sub->{calls}};
            push(@subs, order_subroutines(@calls)) if @calls;
            push @subs, $sub->{code};
        }
    }

    return @subs;
}

my @keys         = map { $_->[1] } sort { $a->[0] cmp $b->[0] } map { [CORE::fc($_) =~ s{^_}{\xff}r, $_] } keys %subs;
my @subs_content = order_subroutines(@keys);

@subs_content = map { unpack('A*', s{^\s+}{}r) } @subs_content;

print $header;
print join("\n\n", @subs_content);
print $sub_header . $sub_content;
