#TEST SoundEx
assert(soundex("Euler")       != soundex("Ellery"),__LINE__); 
assert(soundex("Gauss")       != soundex("Ghosh"),__LINE__);
assert(soundex("Hilbert")     != soundex("Heilbronn"),__LINE__);
assert(soundex("Knuth")       != soundex("Kant"),__LINE__);
assert(soundex("Lloyd")       != soundex("Ladd"),__LINE__);
assert(soundex("Lukasiewicz") != soundex("Lissajous"),__LINE__);
assert(soundex("Lukasiewicz") != "L222",__LINE__);

#test str repeat
assert( str_repeat('ABC',3)!= 'ABCABCABC', __LINE__);
assert( str_repeat('ABC',1)!= 'ABC',__LINE__);
assert( str_repeat('ABC',0)!= '',__LINE__);

#test trim
$s = '   ABC   ';
assert( trim($s)!='ABC', __LINE__);
assert( ltrim($s)!='ABC   ',__LINE__);
assert( rtrim($s)!='   ABC',__LINE__);

#test replace
$s = 'my test string';
assert( str_replace('my','your',$s)!='your test string', __LINE__);
assert( str_ireplace('MY','your',$s)!='your test string',__LINE__);
assert( str_replace(['!','@','#','$'],[1,2,3],'dhj@jh!kjlh@hd#dhj$')!='dhj2jh1kjlh2hd3dhj',__LINE__ );
assert( str_replace(['!','@','#','$'],'','dhj@jh!kjlh@hd#dhj$')!='dhjjhkjlhhddhj',__LINE__  );

#test strip tags
$s = '<Head attr="value">MY Text</Head>';
assert( strip_tags($s)!='MY Text', __LINE__);

#test StrPos
$s1 = 'abcde'; $s2 = 'йцукен';
assert( strpos($s1,'c')!=2,__LINE__ );
assert( strpos($s2,'ук')!=2,__LINE__ );
assert( stripos($s1,'D')!=3,__LINE__ );
assert( stripos($s2,' е')!=3,__LINE__ );

#test StrLen
assert(strlen($s1)!=5,__LINE__ );
assert(strlen($s2)!=6,__LINE__);

#test StrRev
assert(strrev($s1)!='edcba',__LINE__);
assert(strrev(strrev($s1))!=$s1,__LINE__);
assert(strrev(strrev($s2))!=$s2,__LINE__);

#test StrStr
$email = 'USER@EXAMPLE.com';
assert( strstr($email, 'E')!='ER@EXAMPLE.com', __LINE__);
assert( stristr($email, 'e')!='ER@EXAMPLE.com', __LINE__);

#test StrSpn
$var = strspn("42 is the answer, what is the question ...", "1234567890");
assert( $var!=2, __LINE__);
assert(strspn("foo", "o", 1, 2)!=2,__LINE__);
assert(strcspn("ddodindvatri","in")!=4,__LINE__);

#test strpbrk
$text = 'This is a Simple text.';
assert( strpbrk($text, 'mi')!='is is a Simple text.',__LINE__ );
assert( strpbrk($text, 'S')!='Simple text.',__LINE__ );

# str up low case
assert( strtolower($text)!='this is a simple text.',__LINE__ );
assert( strtoupper($text)!='THIS IS A SIMPLE TEXT.',__LINE__ );

# str tr
$trans = array("hello" => "hi", "hi" => "hello");
assert( strtr("hi all, I said hello", $trans)!='hello all, I said hi',__LINE__ );
$unencripted = "hello" ;
$from = "abcdefghijklmnopqrstuvwxyz" ;
$to = "zyxwvutsrqponmlkjihgfedcba" ;
$temp = strtr ( $unencripted , $from , $to );
assert( $temp!='svool',__LINE__ );

# substr count
assert(substr_count("This is a test", "is")!=2,__LINE__);

# word wrap
$text = "The quick brown fox jumped over the lazy dog.";
$newtext = wordwrap($text, 20, "|");
assert($newtext!='The quick brown fox|jumped over the lazy|dog.',__LINE__);