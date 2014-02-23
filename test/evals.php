
# test eval
$i = 0;
while ($i<10){
    $i++;
    eval('$d += '.$i.';');
}
assert($d!=55,__LINE__);

# test compile + eval
$i = 0;
$d = 0;
$bcode = compile('$d += $i;');
while ($i<10){
    $i++;
    eval($bcode, true); # eval byte-code
}
assert($d!=55,__LINE__);


# test leek
$mem = memory_get_usage();
$i = 0;
while ($i<2000){
    $i++;
    $str = compile('$x = array(!1,2,3,4,5)+1');
}
$mem = memory_get_usage() - $mem;

if ($mem > 15000) error_Log(__FILE__, 'test mem compile + inner array: '.$mem, __LINE__);


$mem = memory_get_usage();
$i = 0;
while ($i<2000){
    $i++;
    eval('$x = array(!1,2,3,4,5,6,7);');
}
$mem = memory_get_usage() - $mem;

if ($mem > 15000) error_Log(__FILE__, 'test mem eval + inner array: '.$mem, __LINE__);