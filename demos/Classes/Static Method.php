class IUra {
    static protected function x($y){
        return $y+1;
    }
}

class URa extends IUra {
    
    function test($y){
        return self::x ( $y );
    }
}

$i = 0;
while ($i < 100000){
  $i++;
  URa::test($i);
}
