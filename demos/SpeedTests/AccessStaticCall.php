# PHP 5.2: 1300 mlsec
# Orion: 500-550 mlsec =)

class xURa {
    
    const xMY_CONST = 2.7;
    
    static function myTest($x){
        return $x;
    }
}

class URa extends xURa {

    const MY_CONST = 20;

    static function test($x){
        return xURa::myTest($x);
    }
}

$i = 100000;
while ($i--){
    $d = URa::MY_CONST + xURa::xMY_CONST + URa::MY_CONST + xURa::xMY_CONST;
    $d = URa::myTest(URa::test(URa::test($i)));
}