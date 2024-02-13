#!/usr/bin/perl

# Author: Trizen
# Date: 13 February 2024
# https://github.com/trizen

# Rename PDFs downloaded from arxiv.org, to their paper title.

# usage: perl script.pl [PDF files]

use 5.036;
use WWW::Mechanize;
use File::Basename        qw(dirname basename);
use File::Spec::Functions qw(catfile);

my $mech = WWW::Mechanize->new(
                               show_progress => 1,
                               stack_depth   => 10,
                               agent         => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:122.0) Gecko/20100101 Firefox/122.0',
                              );

foreach my $pdf_file (@ARGV) {

    my $pdf_content = do {
        open my $fh, '<:raw', $pdf_file
          or do {
            warn "Can't open file <<$pdf_file>>: $!\n";
            next;
          };
        local $/;
        <$fh>;
    };

    if ($pdf_content =~ m{\bURI\((https?://arxiv\.org/.*?)\)}) {

        my $url = $1;
        $url =~ s{^http://}{https://};

        my $resp  = $mech->get($url);
        my $title = $resp->title;

        $title =~ s{\[.*?\]\s*}{};
        $title .= ".pdf";

        my $basename = basename($pdf_file);
        say "Renaming: $basename -> $title";

        rename($pdf_file, catfile(dirname($pdf_file), $title));
    }
    else {
        say "Not an arxiv PDF: $pdf_file"
    }
}

__END__

# Example:

$ perl arxiv_pdf_renamer.pl *.pdf
** GET https://arxiv.org/abs/math/0504119v1 ==> 200 OK (1s)
Renaming: 0504119.pdf -> The Carmichael numbers up to $10^{17}$.pdf
** GET https://arxiv.org/abs/2311.07048v1 ==> 200 OK
Renaming: 2311.07048.pdf -> Gauss-Euler Primality Test.pdf
