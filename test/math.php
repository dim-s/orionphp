assert(abs(-2147483647) != 2147483647, __LINE__);
assert(abs(-5.5) != 5.5, __LINE__);

assert(acos(1) != 0, __LINE__); 

if ( acosh(1) != 0 ) error_Log(__FILE__, 'acosh', __LINE__);
if ( acosh(1) != 0 ) error_Log(__FILE__, 'acosh', __LINE__);

if ( round(5.5) != 6 ) error_Log(__FILE__, 'round(5.5)', __LINE__);
if ( round(5.4) != 5 ) error_Log(__FILE__, 'round(5.4)', __LINE__);

if ( floor(5.6) != 5 ) error_Log(__FILE__, 'floor(5.6)', __LINE__);
if ( ceil(5.3) != 6 ) error_Log(__FILE__, 'ceil(5.3)', __LINE__);

if ( pow(5,3) != 125 ) error_Log(__FILE__, 'pow(5,3)', __LINE__);

assert( hypot(3,4) != 5, __LINE__ );
assert( rad2deg(M_PI_4) != 45, __LINE__ );
assert( deg2rad(45) != M_PI_4, __LINE__ );
assert( fmod(5.7, 1.3)!= 0.5, __LINE__);
assert( ceil(exp(5.7))!=299, __LINE__);
assert( sqrt(16)!=4, __LINE__);
assert( sqr(4)!=16, __LINE__);
assert( log10(1)!=0, __LINE__);
assert( !is_nan(acos(9)), __LINE__);

// convert
if ( base_convert("FF",16,2) != 11111111) error_Log(__FILE__, 'base_convert("FF",16,2)', __LINE__);
if ( base_convert("11111111",2,16) != "FF") error_Log(__FILE__, 'base_convert("11111111",2,16)', __LINE__);
if ( base_convert("200",10,16) != "C8") error_Log(__FILE__, 'base_convert("200",10,16)', __LINE__);

if ( bindec('11111111') != 255 ) error_Log(__FILE__, 'bindec(11111111)', __LINE__);
if ( bindec('10101010') != 170 ) error_Log(__FILE__, 'bindec(10101010)', __LINE__);
if ( bindec('10101010') != 170 ) error_Log(__FILE__, 'bindec(10101010)', __LINE__);
if ( bindec('1111111111111111111111111111111') != 2147483647 ) error_Log(__FILE__, 'bindec(1111111111111111111111111111111)', __LINE__);

if ( decbin(255) != '11111111' ) error_Log(__FILE__, 'decbin(255)', __LINE__);
if ( decbin(2147483647) != '1111111111111111111111111111111' ) error_Log(__FILE__, 'decbin(2147483647)', __LINE__);

if ( dechex(2147483647) != '7fffffff') error_Log(__FILE__, 'dechex(2147483647)', __LINE__);
if ( decoct(2147483647) != '17777777777' ) error_Log(__FILE__, 'decoct', __LINE__);

if ( hexdec('7fffffff') != 2147483647 ) error_Log(__FILE__, hexdec('7fffffff'), __LINE__);
if ( octdec('17777777777') != 2147483647) error_Log(__FILE__, 'octdec(17777777777)', __LINE__);