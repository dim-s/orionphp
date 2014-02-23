# ...

#test plus
assert(20+43!=63,__LINE__);
assert('20'+43!=63,__LINE__);
assert(20+'43'!=63,__LINE__);
assert('20' + '43' != 63, __LINE__);

assert(2.4 + 4.11 != 6.51,__LINE__);
assert('2.4'+'4.11'!='6.51',__LINE__);

#test minus, unar-minus
assert(40-15!=25,__LINE__);
assert(3.5-1.5!=2,__LINE__);
// assert('3.5 '-' 1.5'!=2,__LINE__); no will work, never
$d = 1.5;
assert(3.5-(-$d)!=5,__LINE__);
assert(3.5 - ( -    $d)!=5,__LINE__);
$d = -1.5;
assert(3.5 + -$d!=5,__LINE__);

#test mul, div
assert(25*4!=100,__LINE__);
assert(100/25!=4,__LINE__);

assert((25*4)/25!=4,__LINE__);
assert((100/25)*25!=100,__LINE__);

assert(2.5/5!=0.5,__LINE__);
assert(0.5*5!=2.5,__LINE__);
assert('0.5'*6!=3,__LINE__);

#test mod
assert(22 % 7 != 1, __LINE__);
assert(21 % 7 != 0, __LINE__);
assert(6 % 7 != 6, __LINE__);
assert(0 % 1 != 0, __LINE__);
assert(26.4 % 5.1 != 1, __LINE__);

#test concat
$d = 'abc' . 'qwe';
assert($d!='abcqwe',__LINE__);
$d = "abc" . "qwe";
assert($d!='abcqwe',__LINE__);
$d = 'abc'."qwe";
assert($d!='abcqwe',__LINE__);
assert($d!="abcqwe",__LINE__);

$d = 'abc' . 1+3;
assert($d!='abc4',__LINE__);

$d = 'abc' . 1+3 . 'qwe';
assert($d!='abc4qwe',__LINE__);

$d = 'abc' . (1+3) . 'qwe';
assert($d!='abc4qwe',__LINE__);


#test logic AND
$d = true && true;
assert(!$d,__LINE__);
$d = true && false;
assert($d,__LINE__);
$d = false && false;
assert($d,__LINE__);
$d = false && true;
assert($d,__LINE__);
$d = true and true;
assert(!$d,__LINE__);

#test logic OR
$d = true || true;
assert(!$d,__LINE__);
$d = true || false;
assert(!$d,__LINE__);
$d = false || false;
assert($d,__LINE__);
$d = false || true;
assert(!$d,__LINE__);
$d = true or true;
assert(!$d,__LINE__);

#test logic XOR
$d = true xor true;
assert($d,__LINE__);
$d = true xor false;
assert(!$d,__LINE__);
$d = false xor false;
assert($d,__LINE__);
$d = false xor true;
assert(!$d,__LINE__);

#test Shl, Shr and other...
assert(4<<2!=16,__LINE__);
assert(5>>1!=2,__LINE__);
assert(6 band 5 != 4,__LINE__);
assert(6 | 5 != 7, __LINE__);
assert(6 bor 5 != 7, __LINE__);
assert(6^5!=3,__LINE__);

#test not
$b = !true;
assert($b!=false,__LINE__);
$b = !'0';
assert($b!=true,__LINE__);

#test typed equals
$b = !0;
assert($b===false,__LINE__);
assert($b!==true,__LINE__);
