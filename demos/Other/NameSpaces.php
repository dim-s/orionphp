module Math {

   const PI = 3.1416;
   const E  = 2.7;
   
    function test($i){
   
        echo $i;
    }
    
    class URa {
        const MY_X = 20;
    }
}

echo Math:PI, Math:E;
Math:test('My string');
echo Math:URa::MY_X;