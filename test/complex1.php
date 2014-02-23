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
    # Генерируем пароль
    $pass = "";
    for($i = 0; $i < $number; $i++)
    {
      # Вычисляем случайный индекс массива
      $index = rand(0, count($arr) - 1);
      $pass .= $arr[$index];
    }
    return $pass;
}

$pass = generate_password(10);
assert(strlen($pass)!=10,__LINE__);


function encodestring($st)
{
    # Сначала заменяем "односимвольные" фонемы.
    $st=strtr($st,"абвгдеёзийклмнопрстуфхъыэ_",
    "abvgdeeziyklmnoprstufh'iei");
    $st=strtr($st,"АБВГДЕЁЗИЙКЛМНОПРСТУФХЪЫЭ_",
    "ABVGDEEZIYKLMNOPRSTUFH'IEI");
    # Затем - "многосимвольные".
    $st=strtr($st, 
                    array(
                        "ж"=>"zh", "ц"=>"ts", "ч"=>"ch", "ш"=>"sh", 
                        "щ"=>"shch","ь"=>"", "ю"=>"yu", "я"=>"ya",
                        "Ж"=>"ZH", "Ц"=>"TS", "Ч"=>"CH", "Ш"=>"SH", 
                        "Щ"=>"SHCH","Ь"=>"", "Ю"=>"YU", "Я"=>"YA",
                        "ї"=>"i", "Ї"=>"Yi", "є"=>"ie", "Є"=>"Ye"
                        )
             );
    # Возвращаем результат.
    return $st;
}

assert(encodestring('Привет Мир, ё')!='Privet Mir, e',__LINE__);