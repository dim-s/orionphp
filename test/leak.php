# test mem array result func
function leakFunc1(){
    $d = array(1,2,3,4,5,6,7,8,9,10);
    return $d;
}

$mem = memory_get_usage();
$i = 0;
while ($i<10000){
    $i++; $x = leakFunc1();
}
$mem = memory_get_usage() - $mem;

if ($mem > 15000) error_Log(__FILE__, 'leak array result func: '.$mem, __LINE__);




# test mem array result func +link
function leakFunc2(){
    $d = array(1,2,3,4,5,6,7,8,9,10);
    $x =& $d;
    return $x;
}

$mem = memory_get_usage();
$i = 0;
while ($i<10000){
    $i++;
    $x = leakFunc2();
}
$mem = memory_get_usage() - $mem;

if ($mem > 15000) error_Log(__FILE__, 'leak array result func +link: '.$mem, __LINE__);


# test mem array in func 1 +link
function leakFunc3(){
    $d['z'] = 30;
    $d['x'] = 40;
    $d['y'] =& $d['z'];
    $d['z'] =& $d['x'];
    return $d;
}

$mem = memory_get_usage();
$i = 0;
while ($i<10000){
    $i++;
    $x = leakFunc3();
}
$mem = memory_get_usage() - $mem;

if ($mem > 15000) error_Log(__FILE__, 'test mem array in func 1 +link: '.$mem, __LINE__);




function leakFunc4(){
    $d['z'] = array(1,2,3);
    $d['x'] = array(1,2,3);
    $d['a'][0] = array('22');
    $d['y'] =& $d['z'];
    $d['z'] =& $d['x'];
    $d['b'] =& $d['a'][0];
    return $d;
}

$mem = memory_get_usage();
$i = 0;
while ($i<10000){
    $i++;
    $x = leakFunc4();
}
$mem = memory_get_usage() - $mem;

if ($mem > 25000) error_Log(__FILE__, 'test mem array in func 1 +link +multiarray: '.$mem, __LINE__);


$mem = memory_get_usage();
$i = 0;
while ($i<5000){
    $i++;
    $f[0] = array(20);
    $m = $f;
    $f[0] = 40;
}
$mem = memory_get_usage() - $mem;
if ($mem > 15000) error_Log(__FILE__, 'test mem two array+clone: '.$mem, __LINE__);
assert($f[0]!==40,__LINE__);
assert($m[0][0]!==20,__LINE__);


$mem = memory_get_usage();
$i = 0;
while ($i<10000){
    $i++;
    $x = array(1,2,3,4,5,6,7);
    $d =& $x;
    unset($x,$d);
}
$mem = memory_get_usage() - $mem;

if ($mem > 1500) error_Log(__FILE__, 'test mem array+value+unset+link: '.$mem, __LINE__);


# test array, anonym func, link
$mem = memory_get_usage();
$i = 5000;
while ($i--){
    $f[0] = function(){echo 1;}
    $mf[0] = $f;
    $f = function(){echo 1;}
}
$mem = memory_get_usage() - $mem;
if ($mem > 15000) error_Log(__FILE__, 'test mem array, anonym func, link: '.$mem, __LINE__); 