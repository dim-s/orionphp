/*

*/

define('MY_CONST1',56);
assert(my_CoNsT1!=56,__LINE__);

define('MY_cOnSt','xx',false); // fix from original PHP
assert(my_const!=xx,__LINE__);

define('xx',33);
assert(my_const==xx,__LINE__);
assert(MY_CONST!='xx',__LINE__);

define('MAXSIZE',100);
assert(MAXSIZE!=constant('MAXSIZE'),__LINE__);
assert(MAXSIZE!=constant('mAxSiZe'),__LINE__);

assert(!defined('MAXSIZE'),__LINE__);
assert(!defined('My_ConSt'),__LINE__);

#test HEX constant
assert(0xCC!=204,__LINE__);
assert(0XCC!=204,__LINE__);
assert(0xFFFFFF!=16777215,__LINE__);
assert(0x00FFFFFF!=16777215,__LINE__);