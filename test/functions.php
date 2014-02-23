# test param
function func1($x){
   assert($x!=='abc', __LINE__);
}
func1('abc');

# test multiparam
function func2($x,$y,$z){
    assert($x + $y + $z !== 6, __LINE__);
}
func2(1,2,3);

# test return
function func3($x,$y,$z){
    return $x + $y + $z;
}
assert(func3(1,2,3)!==6, __LINE__);

# test link
function func4(&$x){
    $x++;
}
$i = 20; func4($i);
assert($i!==21, __LINE__);

# test multilink
function func5(&$a,&$b){
    $a = 'abc';
    $b = 'xyz';
}
func5($x,$y);
assert($x.$y !== 'abcxyz', __LINE__);