for ($j=0;$j<5;$j++){
        if ($j == 3) continue;
        for ($i=0;$i<10;$i++){
                if ( $i >= 3 ) break; 
                echo 'i='.$i;
        }
        echo 'j='.$j;
}
