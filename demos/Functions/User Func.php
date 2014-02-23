function myFunc($x){
   if ( $x % 2 == 0 ){
        print('true');
   } else {
   	print('false');
   }
}

for ($i=1;$i<10;$i++){
  usleep(200);
  myFunc($i);
}