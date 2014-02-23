# PHP 5.2: 3500 mlsec
# Orion: 800-900 mlsec =)

class URa {
  
  static $var1 = 20;
  static $var2;
  static $var3;
}

$i = 1000000;
while ($i--){
  URa::$var1 = $i;
  URa::$var2 = $i;
  URa::$var3 = $i;
}