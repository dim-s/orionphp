// Speed Test
// ORION - 250 mlsec
// PHP 5.2.4 - 1350 mlsec

class URa {
    
    const MY_CONST = 20;
    
    function test(){
        return URa::MY_CONST;
    }
}

$i = 0;
while ($i < 100000){
   $i++;
   $d = URa::MY_CONST + URa::MY_CONST + URa::MY_CONST;
   $d = URa::test();
}

echo $d;