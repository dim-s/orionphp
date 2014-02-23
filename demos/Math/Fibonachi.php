// Orion - 5500 mlsec
// PHP 5.2 - 6500 mlsec
function fibo($n){
    if ($n < 2){ 
      return 1;
    } else {
     return fibo($n - 2) + fibo($n - 1);
    }
}

$n = 32;
echo fibo($n);