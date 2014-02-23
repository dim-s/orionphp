$i = 0;
$d = 0;

do {
   usleep(200); // delay

   $i++;
   $d = $d+2;
   print($d);

} while ($i < 10);