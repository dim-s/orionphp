/*
   ARRAY Unit Test 1.0;
    
*/
$i = 0;
while ($i<100){
    $i++;

    $arr = array(1,2,3,4,5);
    $res = $arr[0] + $arr[1] + $arr[2] + $arr[3] + $arr[4];
    assert($res != 15, __LINE__);

    $arr = array();
    assert($arr[0] != null, __LINE__);

    $arr[] = array('aa','bb');
    assert($arr[0][1] . $arr[0][0] != 'bbaa', __LINE__);

    $arr = array('x'=>20,'y'=>30);
    assert($arr['x']+$arr['y']!=50, __LINE__);
    assert($arr[x]+$arr[y]!=50,__LINE__);

    # test last_index
    $arr = ['x'=>20,'y'=>30];
    $arr[] = 40;
    assert($arr[0]!=40,__LINE__);
    
    # test multi array as sets
    $arr = ['x'=>[1,2,'a'],'y'=>[3,4,'b']];
    $str = ($arr['x'][0] . $arr['x'][1] . $arr['x'][2]) . ($arr['y'][0] . $arr['y'][1] . $arr['y'][2]);
    assert($str!='12a34b',__LINE__);
    
    # test clone
    $arr['z'] = $arr['x'];
    $arr['z'][0] = 10;
    assert($arr['z'][0]==$arr['x'][0],__LINE__);
    
    # test link
    $arr['m'] =& $arr['z'];
    $arr['m'][0] = 444;
    assert($arr['z'][0]!=444,__LINE__);
    
    # test in operator
    $arr = [1,'2',3,4.0,5,6,7];
    assert(!(2 in $arr), __LINE__);
    assert(!(3 in $arr), __LINE__);
    assert(!(4 in $arr), __LINE__);
}