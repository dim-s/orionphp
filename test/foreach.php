# test foreach
$z = 0;
$arr = [1,2,3,4,5];
foreach($arr as $x) $z += $x;
assert( $z!= 15, __LINE__ );

$z = 0;
foreach([1,2,3,4,5] as $x) $z += $x;
assert( $z!= 15, __LINE__ );

$z = 0;
$arr = [10=>1,20=>2,30=>3,40=>4];
foreach($arr as $y=>$x) $z += $y + $x;
assert( $z!= 110, __LINE__ );

$str = '';
foreach(['a'=>'x','b'=>'y','c'=>'z'] as $y=>$x){
    $str .= $y . $x;
}
assert( $str!='axbycz', __LINE__ );

# test foreach +link
$arr = [10,20,30,40];
foreach ($arr as $x=>&$val) $val += $x+1;
$z = 0;
foreach ($arr as $val) $z += $val;
assert( $z!= 110, __LINE__ );

# test multi foreach
$z = 0;
$arr = [[1,2],[1,2],[1,2],[1,2]];
foreach ($arr as &$sub){
    foreach ($sub as $x){
        $z += $x;
        $sub = [2,3];
    }
}
assert( $z!= 12, __LINE__ );

$z = 0;
foreach ($arr as $sub)
    foreach ($sub as $x){
        $z += $x;
    }

assert( $z!= 20, __LINE__ );

$z = 0;
foreach ($arr as $sub) foreach ($sub as $x) $z += $x;
assert( $z!= 20, __LINE__ );