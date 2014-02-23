/*
    Cycles Unit Test 1.0
    Orion Language
*/

#while1

$i = 0;
while ($i<100){
    $i++;
}
assert($i!=100,__LINE__);

$i = 0;
while ($i<100) $i++;
assert($i!=100,__LINE__);

$i = 0;
do {
    $i++;
} while ($i<100);
assert($i!=100,__LINE__);

$i = 0;
do $i++; while ($i<100);
assert($i!=100,__LINE__);


# test break
$i = 0;
$x = 2;
while ($i<100){
    $i++;
    $x = $x * $i;
    if ($i > 5) break;
}
assert($x!=1440,__LINE__);

# test continue
$i = 0;
$x = 2;
while ($i<100){
    $i++;
    $x = $x * $i;
    if ($i > 5) break;
}