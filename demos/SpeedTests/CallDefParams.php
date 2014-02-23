# PHP 5.2: 2050 mlsec
# Orion: 1100-1200 mlsec

define('MY_CONST',2.5);
function callDefParams($x = 20,$y = 'abc',$z = null,$a = MY_CONST){
   
}

$i = 1000000;
while ($i--){
  callDefParams();
}
