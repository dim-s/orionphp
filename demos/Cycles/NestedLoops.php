function test($x){ }
$n = 10;
$x = 0;
for ($a=0; $a<$n; $a++)
    for ($b=0; $b<$n; $b++)
    for ($c=0; $c<$n; $c++)
        for ($d=0; $d<$n; $d++)
        for ($e=0; $e<$n; $e++)
            for ($f=0; $f<$n; $f++){
               test($f);
               test($f);
               test($f);
               test($f);
            }