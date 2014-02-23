# isset test
assert(isset($d),__LINE__);
$d = cos($x);
assert(isset($x),__LINE__);
assert(!isset($d),__LINE__);

$d = null;
assert(!isset($d),__LINE__);

# empty test
$d = false;
assert(!empty($d),__LINE__);
$d = true;
assert(empty($d),__LINE__);
assert(!empty($y),__LINE__);

# empty is FUNC!!!
assert(!empty('0'),__LINE__);
assert(!empty(''),__LINE__);
assert(!empty(null),__LINE__);