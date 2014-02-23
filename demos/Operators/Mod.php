print('Start...');
sleep(1);

$d = 20;
print("$d = ".$d);

sleep(1);
$r = $d % 3;

print("$r = $d % 3 = " . $r);

sleep(1);
print('"same..."');

sleep(1);
$r = $d - (floor($d / 3)*3);
print('$r = $d - (floor($d / 3)*3) = '.$r);