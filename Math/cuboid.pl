       sub say{print@_,$/}sub cube
      {my($x,$y,$z)=map{int}@_;my(
     $c,$h,$v,$d,$s)=((qw{+ - | /}
    ),$ARGV[3]||' ');my($p,$o)=(0,
   0);say ' 'x($z+1),$c,$h x$x,$c;
  for(1..$z){say ' 'x($z-$_+1),$d,
 $s x$x,$d,$s x($_-1-$p),$_>$y?!$p
 ?do{$p=1;$o=$z-$y;$c}:$p++?$d:$c:
 $v;}say$c,$h x$x,$c,$z<$y?do{$s x
 $z,$v}:$p?do{$s x($z-$o),$d}:do{$
 s x$z,$c};for(1..$y){say$v,$s x$x
 ,$v,$z-1>=$y?$_>=$z?($s x$x,$c):(
 $s x($z-$_-$o),$d):$z==$y?do{$s#
 x($y-$_),$d}:$y-$_>$z?do{$s x$z
 ,$v}:$y-$_==$z?do{$s x($y-$_),
 $c}:do{$s x($y-$_),$d}}say$c,
 $h x$x,$c}cube @ARGV>2?@ARGV
 [0..2]:map{rand($_)}20,10,8
