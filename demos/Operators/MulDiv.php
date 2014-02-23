print('Start...');
sleep(1);

$d = 20;
$c = $d * 5;
print('$c = '.$d.' * 5 = '.$c);

sleep(1);
$x = $d;
$d = $c / $d;
print( '$d = '.$c.' / '.$x.' = '.$d );

sleep(1);
$x = $d;
$d = $c / ($d * 40);
print( '$d = '.$c.' / ('.$x.' * 40) = '.$d );