
{

 Наши оп-коды:

 Добавление в стек:
 -----------------------
 OP_PUSH <link on value in table>
 OP_PUSH_S <string>,<len>
 OP_PUSH_L <integer>
 OP_PUSH_D <double>
 OP_PUSH_B <boolean>
 OP_PUSH_NULL
 not - OP_PUSH_H
 not - OP_PUSH_O
 not - OP_PUSH_F

     see OP_PUSH

 OP_PUSH_R - добавляет в стек значение вызова
 OP_RETURN - задает значение последнего вызова функции, стековая система!!!
 OP_RET - возвратится в строку,
          откуда был последний вызов (стековая система на уровне VM!!!!)

 Удаление из стека:
 -----------------------
 OP_DISCARD <count> - удаляет из стека count раз последнее значение

 /////// Примеры, вызов функции
 OP_CALL FUNC, <кол-во параметров, ск. брать из стека>
 ; после вызова функции, результат ее уже имеется на верхущке стека
 ...
 OP_DEF_FUNC <name>
 OP_PUSH_NULL - задает результат как null
 ....
 OP_PUSH <value> -- задаем результат функции
 OP_RET         -- выходим сразу не дожидаясь, т.к. это return
 ...
 OP_RET



 //// return <значение>:
 OP_PUSH <значение>
 OP_RET

 //// exit
 OP_RET

 //// die
 OP_DIE

 //// $d = <значение>
 OP_ASSIGN $d - присваивает последнее значение из стека переменной
              и удаляет последний элемент из стека
 OP_DISCARD 1 - удаляет значение из стека

 OP_INC, OP_DEC и т.п. операции с присваиванием удаляют последнее значение из стека
 
 /// $d = <значение если в выражении>
 OP_ASSIGN $d
 OP_PUSH $d

 /// $d = $c = 0;
 OP_PUSH_L 0
 OP_ASSIGN $c
 OP_PUSH $c
 OP_ASSIGN $d

 /// $d++
 OP_INC_ONE $d

 /// $d += 5;
 OP_PUSH 5
 OP_INC $d

 /// $d--
 OP_DEC_ONE $d

 /// $d -= 10;
 OP_PUSH 10
 OP_DEC $d

 /// $d *= 10
 OP_PUSH 10
 OP_MUL_EQ $d
 OP_ASSIGN $d

 /// $d++ если в выражении
 OP_INC $d,1
 OP_PUSH $d

 ///  $c = 4; $d = $c++
 OP_PUSH_L 4;
 OP_ASSIGN $c
 ...
 OP_INC $c,1
 OP_PUSH $c
 OP_ASSIGN $d


 //// $c > $d
 OP_PUSH $c
 OP_PUSH $d
 OP_ISMAX //
          сравнивает последние 2 значения в стеке, больше
          после сравнения удаляет последние 2 значения из стека
          и добавляет 1 значение в стек - результат

  // $c < $d
  ...
  OP_ISMIN


  // $c >= $d
  ...
  OP_ISMAX_EQ


  // $c <= $d
  ...
  OP_ISMIN_EQ

  // $c != $d
  OP_PUSH $c
  OP_PUSH $d
  OP_NOEQUAL

  // $c == $d
  OP_EQUAL

  // $c !== $d
  OP_NOEQUAL_T

  // $c === $d
  OP_EQUAL_T

  // !$c
  OP_PUSH $c
  OP_NOT // берет обратное от последнего значения в стеке,
         затем удаляем последнее значение, а вместо него записывает результат

  // конкатенация
  // $c . $d
  OP_PUSH $c
  OP_PUSH $d
  OP_CONCAT

  // $c + $b
  OP_PUSH $c
  OP_PUSH $b
  OP_PLUS

  // $c - $b
  OP_MINUS

  // $c * $b
  OP_MUL

  // $c / $b
  OP_DIV

  // $c ^ $b
  OP_XOR

  // $c % $b - остатока от деления
  OP_MOD


  // достать значение хеш массива и поместить его в стек
  // $arr[$key]
  PUSH $arr
  PUSH $key
  CALL HASH_BY_KEY, 2 // вызов функции HASH_BY_KEY, результат кладется в стек,
                    но перед этим 2 последних значения удаляются из стека


  // достать значение из много мерного массива
  // $arr[$x][$y]
  PUSH $arr
  PUSH $x
  CALL HASH_BY_KEY, 2
  PUSH $y
  CALL HASH_BY_KEY, 2

  // $d = $arr[$c]
  PUSH $arr
  PUSH $c
  CALL HASH_BY_KEY, 2
  ASSIGN $d

  // $arr[$x] = $arr[$y]
  PUSH $arr
  PUSH $y
  CALL HASH_BY_KEY, 2
  PUSH $arr
  PUSH $x
  CALL HASH_BY_KEY, 2
  ASSIGN_LAST // приравнивает последние значение из стека к предпоследнему,
                 // очищает из стека 2 значения, а затем кладет результат в стек

  // $arr[$x][$y] = $arr[$i][$j]
  PUSH $arr
  PUSH $i
  CALL HASH_BY_KEY, 2
  PUSH $j
  CALL HASH_BY_KEY, 2   <--- в стеке осталось 1 значение

  PUSH $arr
  PUSH $x
  CALL HASH_BY_KEY, 2
  PUSH $y
  CALL HASH_BY_KEY, 2   <--- в стеке уже 2 значения осталось

  ASSIGN_LAST <--- а вот и присваивание последних 2х значений
  <--- в стеке одно значение

  // $arr[$x][$y] += $arr[$i][$j]
  ... тоже самое ...
  <--- в стеке есть 1 значение
  OP_INC_LAST

  Приписка _LAST, говорит что брать параметр из стека


  ///////////// условия
1 OP_PUSH <результат выражения>
2 OP_IF <если условие true, тогда перепригиваем через одну метку вперед>
3 OP_JMP 12; begin
  ...
  ...
  ...
11 OP_JMP 17 <----- перепригиваем иначе
12 OP_JMP 13 end
12 else (!!!!!)
13 ...
14 ...
15 ...
16 end (!!!! конец иначе)
17 ...

// пример
if ($a == $b)
   anycode
elseif ($b > $a)  <-------- (!!!!) elseif
   anycode
else
   anycode


 1 OP_PUSH $a
 2 OP_PUSH $b             Алгоритм прост, перепригивание
 3 OP_EQUAL               рассмотрим, если 1 условие выполняется, мы будем прыгать
 4 OP_IF                  <- true
   <if>
 5 OP_JMP 8               <- no
 6 ... anycode ...        <- eval
 7 OP_JMP 11              <- прыжок в 11 строку
 8 OP_PUSH $a, $b
 9 OP_MAX
10 OP_IF
  <elseif>                <- прыжок в 13 строку
11 OP_JMP 14
12 ... anycode ...
13 OP_JMP 15              <- опять прыжок, в 15 строку
  <else>
14 ... anycode ...
15 <end>


 1 OP_PUSH $a
 2 OP_PUSH $b
 3 OP_EQUAL               рассмотрим, если 2 условие выполняется, мы будем прыгать
 4 OP_IF                  <- false
   <if>
 5 OP_JMP 8               <- прыжок в 8 строку
 6 ... anycode ...
 7 OP_JMP 11
 8 OP_PUSH $a, $b         <- eval
 9 OP_MAX                 <- eval
10 OP_IF                  <- true, перепрыгиваем на 12 строку
  <elseif>
11 OP_JMP 14
12 ... anycode ...        <- eval
13 OP_JMP 15              <- прыжок, в 15 строку
  <else>
14 ... anycode ...
15 <end>




func($a, $b)[$my]
func($a, $b)%
func(%)%

        OP_PUSH $my
        OP_PUSH $a
        OP_PUSH $b
        OP_CALL func, 2
        OP_CALL HASH_BY_KEY_R, 2

func($a, $b)[$x][$y]

         OP_PUSH $y
         OP_PUSH $x
         OP_PUSH $a
         OP_PUSH $b
         OP_CALL func, 2          <---- в стеке $y, $x, $result
         OP_CALL HASH_BY_KEY_R, 2  <---- берем значение с обратной стороны $result, $x
         OP_CALL HASH_BY_KEY_R, 2  <---- $result, $y

         Похоже массив надо просчитывать задом наперед, с верхушки
         стек:
         [$y] - ключ 2
         [$x] - ключ 1
         [$arr] - массив



Все работает как надо
}
unit ori_vmTypes;

//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, ori_Types;

  const
  OP_NOP    = 0;
  OP_PUSH   = 1;
  OP_PUSH_L = 2;
  OP_PUSH_D = 3;
  OP_PUSH_S = 4;
  OP_PUSH_MS = 5; // magic string
  OP_CALL   = 6; // вызов фукции
  OP_RET    = 7; // return

  OP_ASSIGN  = 8; // =
  OP_ASSIGN_LAST = 9; // =
  OP_DISCARD = 10;

  OP_INC = 11; // $var++
  OP_INC_VAR = 12;
  OP_PLUS_ASSIGN = 13; // $var += 4;
  OP_BINC = 14; // ++$var
  //OP_BINC_ONE_LAST = 15;
  OP_MINUS_ASSIGN = 15;

  OP_DEC_ONE  = 16; // $var++
  OP_DEC_ONE_LAST = 17;
  OP_DEC      = 18;
  OP_DEC_VAR  = 19; //
  OP_BDEC_ONE_LAST = 20;

  OP_MUL_ASSIGN = 21; // $var *= 10
  OP_DIV_ASSIGN = 22; // $var /= 10;
  OP_XOR_ASSIGN = 23; // $var ^= 10;
  OP_CONCAT_ASSIGN = 24; // $var .= 10;
  OP_MOD_ASSIGN = 25; // $var %= 10;

  OP_ISMAX = 26; // $a > $b
  OP_ISMIN = 27;  // $a < $b
  OP_ISMAX_EQ = 28; // >=
  OP_ISMIN_EQ = 29; /// <=
  OP_NOEQUAL  = 30; // !=
  OP_EQUAL    = 31; // ==
  OP_NOEQUAL_T  = 32; // !==
  OP_EQUAL_T  = 33; // ===
  OP_NOT      = 34; // !$a

  OP_PLUS     = 35;
  OP_MINUS    = 36;
  OP_MUL      = 37; // *
  OP_DIV      = 38; // /
  OP_MOD      = 39; // %
  OP_XOR      = 40; // ^
  OP_CONCAT   = 41; // .

  OP_JMP      = 42;
  OP_IF       = 43;
  OP_IF_N     = 44; // if ( not ... () )

  OP_HISTORY_PUSH = 45;    // история для основного стека...
  OP_HISTORY_DISCARD = 46;

  OP_AND = 47;
  OP_OR  = 48;

  OP_SKO = 49;
  OP_SKC = 50;

  //OP_ASSIGN_LINK = 51;
  OP_UNARMINUS = 52;

  OP_CALL_VAR = 53; // call $var

  //OP_DEF_FUNC  = 54;
  OP_DEF_CLASS = 55;

  OP_LINK_PARAM = 56;

  OP_LOCTABLE_PUSH = 57;
  OP_LOCTABLE_DISCARD = 58;

  OP_ASSIGN_D = 59; // assign + discard, присваивание без закладывания в стек результата
  OP_ASSIGN_D_LINK = 60;


  OP_PUSH_FUNC = 61; // Добавляем в стек вызов функции
  OP_DISCARD_FUNC = 62; // удаляем из стека вызов функции

  OP_PUSH_B = 63;
  OP_CALL_NATIVE = 64;
  OP_BREAK = 65;

  OP_PUSH_V = 66; // push dinamyc var
  OP_PUSH_N = 67; // push null

  OP_DEFINE = 68;

  OP_ELSE = 69;
  OP_ELSEIF = 70;
  OP_WHILE = 71;
  OP_DO    = 72;
  OP_FOR   = 73;
  OP_FOREACH = 74;

  OP_JMP_D = 75; // jump + discard stack
  OP_IF_JMP = 76; // if + jump

  OP_GET_HASH = 77;

  OP_JMPZ = 78; // if + jmp
  OP_JMPZ_N = 79;

  OP_DEFINE_FUNC = 80;
  OP_UNDEFINE_FUNC = 81;

  OP_LINK = 82;

  OP_PUSH_GV = 83; // push global var

  OP_MODULE = 84;
  OP_CALL_STATIC = 85;
  OP_UNMODULE = 86;
  OP_IN = 87;

  OP_HASH_VALUE = 88; // operator '=>'

  OP_LOGIC_XOR = 89;
  OP_BIT_NOT   = 90;

  OP_SHL = 91; // сдвиг влево
  OP_SHR = 92; // сдвиг вправо

  OP_BIT_AND = 93;
  OP_BIT_OR  = 94;

  OP_CYCLE_BREAK = 95;
  OP_CYCLE_CONTINUE = 96;

  OP_FOREACH_INIT = 97;

  OP_NEW_ARRAY = 98;
  OP_CALL_DYN = 99;
  OP_GLOBAL   = 100;
  OP_UNSET    = 101;

  OP_UNDEF_CLASS = 103;
  OP_DEF_METHOD = 104;

  OP_TYPED_INT = 105;
  OP_TYPED_DOUBLE = 106;
  OP_TYPED_STR = 107;
  OP_TYPED_ARRAY = 108;
  OP_TYPED_BOOL = 109;
  OP_TYPED_OBJ  = 110;

  OP_CLASS_PROPERTY = 111;
  OP_CLASS_CONST    = 112;

  OP_USE_AS = 113;

  OP_CHECK_MEMORY = 114;

  OP_GET_CLONE_HASH = 115;

  const
    sOP_JUMP = [OP_JMP, OP_JMP_D, OP_JMPZ, OP_JMPZ_N, OP_DEFINE_FUNC, OP_UNDEFINE_FUNC, OP_FOREACH,
    OP_DEF_CLASS, OP_UNDEF_CLASS, OP_DEF_METHOD];

    sOP_CALL = [OP_CALL, OP_CALL_NATIVE, OP_CALL_STATIC, OP_NEW_ARRAY, OP_GLOBAL, OP_UNSET];
    sOP_CALL_EX = [OP_CALL, OP_CALL_NATIVE, OP_GET_HASH, OP_GET_CLONE_HASH, OP_DEFINE, OP_NEW_ARRAY, OP_GLOBAL, OP_UNSET];
    sOP_CALL_NIL = [OP_NEW_ARRAY, OP_GLOBAL, OP_UNSET, OP_DEFINE];

    sOP_PUSH = [OP_PUSH, OP_PUSH_L, OP_PUSH_D, OP_PUSH_S, OP_PUSH_MS, OP_PUSH_V, OP_PUSH_GV, OP_PUSH_N, OP_PUSH_B];

    sOP_UN_OPER = [OP_INC,OP_DEC,OP_UNARMINUS,OP_NOT, OP_LINK, OP_BIT_NOT,
                  // typed operators
                  OP_TYPED_INT, OP_TYPED_DOUBLE, OP_TYPED_STR, OP_TYPED_ARRAY, OP_TYPED_BOOL, OP_TYPED_OBJ
                  ];

    sOP_BIN_OPER = [OP_PLUS,OP_MINUS,OP_MUL,OP_DIV,OP_XOR,OP_MOD, OP_CONCAT, OP_ASSIGN, {OP_ASSIGN_LINK,}
                     OP_ISMAX,OP_ISMIN,OP_ISMAX_EQ,OP_ISMIN_EQ, OP_EQUAL, OP_NOEQUAL, OP_EQUAL_T, OP_NOEQUAL_T,
                    OP_GET_HASH, OP_GET_CLONE_HASH, OP_CALL_STATIC,OP_AND,OP_OR,OP_IN,OP_HASH_VALUE,
                    OP_PLUS_ASSIGN,OP_MINUS_ASSIGN,OP_MUL_ASSIGN,OP_DIV_ASSIGN,OP_MOD_ASSIGN,OP_XOR_ASSIGN,
                    OP_CONCAT_ASSIGN,OP_LOGIC_XOR,
                    OP_SHL,OP_SHR,OP_BIT_AND,OP_BIT_OR];

    sOP_NOP = [OP_NOP, OP_SKO, OP_SKC, OP_DO, OP_BREAK,
     OP_FOR, OP_MODULE, OP_UNMODULE, OP_WHILE];

    sOP_ASSIGN = [OP_ASSIGN, OP_PLUS_ASSIGN, OP_MINUS_ASSIGN, OP_MUL_ASSIGN,
                  OP_DIV_ASSIGN, OP_XOR_ASSIGN, OP_MOD_ASSIGN, OP_CONCAT_ASSIGN];

  function opTypToStr(typ: byte): MP_String;


implementation

  //uses uParser;

  var
  lineCount : Cardinal;

function opTypToStr(typ: byte): MP_String;
begin
   case typ of
      OP_NOP:  Result := 'nop';
      OP_PUSH: Result := 'push';
      OP_PUSH_L: Result := 'push_l';
      OP_PUSH_D: Result := 'push_d';
      OP_PUSH_S: Result := 'push_s';
      OP_PUSH_MS: Result := 'push_ms';
      OP_CALL: Result := 'call';
      OP_CALL_VAR: Result := 'call_var';
      OP_ASSIGN: Result := 'assign';
      OP_ASSIGN_D: Result := 'assign_d';
     // OP_ASSIGN_LINK: Result := 'assign_link';
      OP_PLUS: Result := 'plus';
      OP_MINUS: Result := 'minus';
      OP_INC: Result := 'inc';
      OP_IN: Result := 'in';
      OP_PLUS_ASSIGN: Result := 'plus_assign';
      OP_MINUS_ASSIGN: Result := 'minus_assign';
      OP_MUL_ASSIGN: Result := 'mul_assign';
      OP_CONCAT_ASSIGN: Result := 'concat_assign';
      OP_ISMAX: Result := 'ismax';
      OP_ISMIN: Result := 'ismin';
      OP_EQUAL: Result := 'equal';
      OP_NOT: Result   := 'not';
      OP_MUL: Result := 'mul';
      OP_DIV: Result := 'div';
      OP_CONCAT: Result := 'concat';
      OP_NOEQUAL: Result := 'noequal';
      OP_DEC: Result := 'dec';
      OP_IF: Result := 'if';
      OP_JMP: Result := 'jmp';
      OP_JMP_D: Result := 'jmp_d';
      OP_XOR: Result := 'xor';
      OP_MOD: Result := 'mod';
      OP_UNARMINUS: Result := 'unar_minus';
      OP_XOR_ASSIGN: Result := 'xor_assign';
      OP_DIV_ASSIGN: Result := 'div_assign';
      OP_MOD_ASSIGN: Result := 'mod_assign';
      OP_AND: Result := 'and';
      OP_OR: Result := 'or';
      OP_DEFINE_FUNC: Result := 'def_func';
      OP_DEF_CLASS: Result := 'def_class';
      OP_LINK_PARAM: Result := 'push link';
      OP_SKO: Result := '{';
      OP_SKC: Result := '}';
      OP_LOCTABLE_PUSH: Result := 'table_push';
      OP_LOCTABLE_DISCARD: Result := 'table_discard';
      OP_HISTORY_PUSH: Result := 'history_push';
      OP_HISTORY_DISCARD: Result := 'history_discard';
      OP_DISCARD: Result := 'discard';
      OP_RET: Result := 'return';
      OP_ASSIGN_D_LINK: Result := 'assign_d_link';
      OP_PUSH_B: Result := 'push_b';
      OP_PUSH_V: Result := 'push_var';
      OP_PUSH_N: Result := 'push_null';
      OP_DEFINE: Result := 'define';
      OP_ELSE  : Result := 'else';
      OP_ELSEIF: Result := 'elseif';
      OP_IF_JMP: Result := 'if+jmp';
      OP_JMPZ  : Result := 'jmpz';
      OP_JMPZ_N: Result := 'jmpz_n';
      OP_GET_HASH: Result := 'get_hash';
      OP_GET_CLONE_HASH: Result := 'get_hash_clone';
      OP_BREAK : Result := ';;;;;;';
      OP_UNDEFINE_FUNC: Result := 'undef';
      OP_LINK: Result := 'link';
      OP_PUSH_GV: Result := 'push_gv';
      OP_CALL_STATIC: Result := 'call_static';
      OP_NEW_ARRAY: Result := 'new_array';
      else
        Result := 'unknow_' + IntToStr(typ); 
   end;

   Result := UpperCase(Result);

end;



end.

