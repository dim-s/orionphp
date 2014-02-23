/*

*/

$var1 = true;
assert($var1!=true,__LINE__);
assert($var2 = false,__LINE__);

#test clone
$x = 20;
$c = $x;
$c = 30;
assert($x!=20,__LINE__);
assert($c!=30,__LINE__);

$c =& $x;
$c = 40;
assert($x!=40,__LINE__);
assert($c!=40,__LINE__);

# test unset
unset($c);
assert($c==40,__LINE__);
assert($x!=40,__LINE__);

unset($x);
assert($x==40,__LINE__);