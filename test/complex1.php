function generate_password($number){
    $arr = array('a','b','c','d','e','f',
                 'g','h','i','j','k','l',
                 'm','n','o','p','r','s',
                 't','u','v','x','y','z',
                 'A','B','C','D','E','F',
                 'G','H','I','J','K','L',
                 'M','N','O','P','R','S',
                 'T','U','V','X','Y','Z',
                 '1','2','3','4','5','6',
                 '7','8','9','0','.',',',
                 '(',')','[',']','!','?',
                 '&','^','%','@','*','$',
                 '<','>','/','|','+','-',
                 '{','}','`','~');
    # ���������� ������
    $pass = "";
    for($i = 0; $i < $number; $i++)
    {
      # ��������� ��������� ������ �������
      $index = rand(0, count($arr) - 1);
      $pass .= $arr[$index];
    }
    return $pass;
}

$pass = generate_password(10);
assert(strlen($pass)!=10,__LINE__);


function encodestring($st)
{
    # ������� �������� "��������������" ������.
    $st=strtr($st,"������������������������_",
    "abvgdeeziyklmnoprstufh'iei");
    $st=strtr($st,"�����Ũ������������������_",
    "ABVGDEEZIYKLMNOPRSTUFH'IEI");
    # ����� - "���������������".
    $st=strtr($st, 
                    array(
                        "�"=>"zh", "�"=>"ts", "�"=>"ch", "�"=>"sh", 
                        "�"=>"shch","�"=>"", "�"=>"yu", "�"=>"ya",
                        "�"=>"ZH", "�"=>"TS", "�"=>"CH", "�"=>"SH", 
                        "�"=>"SHCH","�"=>"", "�"=>"YU", "�"=>"YA",
                        "�"=>"i", "�"=>"Yi", "�"=>"ie", "�"=>"Ye"
                        )
             );
    # ���������� ���������.
    return $st;
}

assert(encodestring('������ ���, �')!='Privet Mir, e',__LINE__);