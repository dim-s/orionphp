$os = array("Mac", "NT", "Irix", "Linux");
assert(!in_array("Irix", $os),__LINE__);

#check register
assert(in_array("mac", $os),__LINE__);

#check strict param
$a = array('1.10', 12.4, 1.13);
assert(in_array('12.4', $a, true),__LINE__);
assert(!in_array(1.13, $a, true),__LINE__);

#check count
assert(count($a)!=3,__LINE__);
assert(sizeof($a)!=3,__LINE__);

#test seek functions
$transport = array('foot', 'bike', 'car', 'plane');
assert(current($transport)!=='foot', __LINE__);
assert(next($transport)!=='bike', __LINE__);
assert(next($transport)!=='car', __LINE__);
assert(prev($transport)!=='bike', __LINE__);
assert(end($transport)!=='plane', __LINE__);
assert(reset($transport)!=='foot',__LINE__);