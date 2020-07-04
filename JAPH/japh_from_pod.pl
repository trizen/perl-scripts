sub f{my%D;@D{@_}=();for(@_){if(-d){next if${_}eq'.';my@g;opendir(D,${_})||next;
while(defined(my$d=readdir(D))){unless(${d}eq'.'or${d}eq'..'){push@g,"${_}/$d"}}
closedir(D);push@f,grep({-f}@g);f(grep((!exists($D{$_})),grep({-d}@g)))}elsif(-f
){push@f,$_}}return@f}my$q=qr/["']\w[^\W\d]{3}\h\w{5}([[:alpha:]])\S\b\N\D\1\w+?
\s\p{PosixAlpha}\B.[\x63-\x72]{4,},?(?:\\n)?["']/six;do{-T||next;open(_,'<',$_);
sysread _,$_,-s;if(/$q/o){$_=eval$&;chomp;local$\=$/;print;exit}}foreach(f@INC);
