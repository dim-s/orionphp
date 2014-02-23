#test unar typed operators
$x = '20';
assert((int)$x !== 20, __LINE__);
assert((integer)$x !== 20, __LINE__);
assert((bool)$x !== true, __LINE__);
assert($x !== '20', __LINE__);
assert((double)$x !== 20, __LINE__);
assert(!is_array((array)$x), __LINE__);
assert(is_array($x), __LINE__);

# test array typed operator
$mem = memory_get_usage();
$i = 0;
while ($i<2000){
    $i++;
    $x = (array)$y;
    $y =& $x;
}
$mem = memory_get_usage() - $mem;

if ($mem > 15000) error_Log(__FILE__, 'test mem array typed operator: '.$mem, __LINE__); 
assert(!is_array($y) && !is_array($x), __LINE__);