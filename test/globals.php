$GLOBALS['myX'] = 20;
$myX = &$GLOBALS['myX'];
$myX = 40;
global $myX;

assert($myX!=40, __LINE__);
assert($GLOBALS['myX']!=40, __LINE__);