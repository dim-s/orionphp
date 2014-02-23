print('Start...');

$i = 0;
$d = 0;

while ($i<1000000){
   $i++;
   $d = $d + cos($i);
}

print($d);