$b = function($x){
    print('- ' .$x);
}

for ($i=0;$i<10;$i++){
  usleep(200);
  $b($i);
}
