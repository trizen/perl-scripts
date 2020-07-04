BEGIN{$^W=1,$SIG{__WARN__}=sub{pop=~s/:+([^"]+)/die
"$1,$\/"=~tr\_\ \r/error}}$Just_another_Perl_hacker
