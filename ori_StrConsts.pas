unit ori_StrConsts;

// модуль типов и структур
//{$mode objfpc}
{$H+}
{$i './VM/ori_Options.inc'}

interface

uses
  SysUtils;

  const
  {$IFDEF RUS}
    MSG_ERR_STACK_OVERFLOW = 'Произошло переполнение стека';
    // errors
    MSG_ERR_NOSKOBA   = 'Отсутствует завершающая в выражении скобка';
    MSG_ERR_NOCORRECTSKOBE = 'Неправильная расстановка фигурных скобок для блоков';
    MSG_ERR_NOSKOBA_F = 'Отсутствует завершающая "%s" скобка';
    MSG_ERR_SKOBA     = 'Ошибка в расстановке скобок';
    MSG_ERR_NOQUOTE   = 'Отсутствует завершающая кавычка';
    MSG_ERR_NOQUOTE_F = 'Отсутствует завершающая %s кавычка';
    MSG_ERR_PARAMZ    = 'Некорректно поставлен разделитель "," или открывающая скобка';
    MSG_ERR_ASSIGNLINK= 'Ссылки можно только присваивать';
    MSG_ERR_FUNCNAME  = 'Неправильно задано название для функции';
    MSG_ERR_FORPRMS   = 'Неправильно объявлена конструкция цикла for';
    MSG_ERR_FOREACH   = 'Неправильно объявлена конструкция цикла foreach';
    MSG_ERR_COND      = 'Не задано выражение для условия';
    MSG_ERR_USE       = 'Неправильно объявлена конструкция Use .. as ..';

    // fatal
    MSG_ERR_ASSIGN    = 'Невозможно присвоить значение не переменной!';
    MSG_ERR_NOPTR     = 'Ожидается операция над переменной, но ее нет';
    MSG_ERR_PRMCNT    = 'Слишком мало передано параметров для функции';
    MSG_ERR_PRMCNT_F  = 'Слишком мало передано параметров для функции %s(), их должно быть не меньше %d';
    MSG_ERR_CONSTVAL  = 'Константа может содержать только простые значения - числа, строки и булево';
    MSG_ERR_CONSTNAME = 'Имя константы должно быть строкой';
    MSG_ERR_CONST_NOVAL = 'Значение для константы %s должно быть задано';
    MSG_ERR_CONSTEX_F = 'Константа %s уже объявлялась ранее';


    MSG_ERR_NOTFOUND_FUNC = 'Функция "%s" не объявлена, чтобы на нее ссылаться';
    MSG_ERR_NOTFUNC       = 'Вызов несуществующей функции или метода';
    MSG_ERR_FUNC_EXISTS = 'Функция "%s" уже объявлялась ранее';
    MSG_ERR_PARAMFUNC   = 'Некорректно объявлены параметры для функции %s';
    MSG_ERR_INCOR_FUNC  = 'Функция объявлена неправильно, не найдены блочные скобки';

    MSG_ERR_CALLSTATIC  = 'Отсутствие статического свойства "%s" у значения';

    MSG_ERR_INCORRECT_IND = 'Использован некорректный идентификатор "%s"';


    MSG_ERR_EXPR = 'Синтаксически неверное выражение';
    MSG_ERR_ARR  = 'Неверное обращение к массиву';

    MSG_ERR_DO   = 'Ошибка в конструкции цикла';
    MSG_ERR_ELSE = 'Ошибка в конструкции else';

    MSG_ERR_HEXNUM = 'Ошибка в формате 16-го числа';

    MSG_ERR_BREAK  = 'Оператор break или continue должен находится внутри цикла';

    // Warnings
    // array
    MSG_ERR_PARAM_ARRTYPE = '%s-й параметр функции должен быть массивом';
    MSG_ERR_NOFILE        = 'Файл "%s" не доступен для чтения';
    MSG_ERR_EXPR_ARR      = 'Ожидается операция над массивом, но он отсутствует';

    MSG_ERR_NOFIND_IND    = 'Идентификатор "%s" нигде не объявлялся, на него ссылаться нельзя';

    // CLASSES
    MSG_ERR_FUNC_MODIFER = 'Некорректный тип для функции или метода';
    MSG_ERR_FUNC_MODIFER_F = 'Некорректный тип "%s" для функции или метода';
    MSG_ERR_CLASS_EXISTS = 'Класс "%s" уже объявлялся ранее';
    MSG_ERR_CLASS_NOEXISTS = 'Класс "%s" не объявлялся, чтобы на него ссылаться';

    MSG_ERR_NOCAN_CALL_STATIC = 'Метод "%s" не может быть вызван статически';
    MSG_ERR_NOMETHOD_IN_CLASS = 'Метод или свойство "%s" отсутствует, либо является приватным';
    MSG_ERR_NO_CLASS_OR_OBJECT = 'Класс или объект%sотсутствует';

    MSG_ERR_NO_CLASS_CONST = 'Константа %s не объявлена в классе %s';
    MSG_ERR_PROPERTEX_F = 'Свойство "%s" уже объявлялось ранее в классе';

  {$ELSE}
    MSG_ERR_STACK_OVERFLOW = 'Stack Overflow';
    // Errors
    MSG_ERR_NOSKOBA = 'Is missing final bracket in the expression';
    MSG_ERR_NOCORRECTSKOBE = 'Incorrect placement of curly braces for blocks';
    MSG_ERR_NOSKOBA_F = 'Is missing final "%s" bracket';
    MSG_ERR_SKOBA = 'Error in the alignment of the brackets';
    MSG_ERR_NOQUOTE = 'Is missing final quote';
    MSG_ERR_NOQUOTE_F = '%s is missing final quote';
    MSG_ERR_PARAMZ = 'Ill-supplied separator, or an opening bracket';
    MSG_ERR_ASSIGNLINK = 'Links can only assign';
    MSG_ERR_FUNCNAME = 'Incorrect name specified for the function';
    MSG_ERR_FORPRMS = 'Wrong declared design cycle for';
    MSG_ERR_FOREACH = 'Wrong declared design cycle foreach';
    MSG_ERR_USE     = 'Wrong declared design Use .. as ..';
    MSG_ERR_COND = 'Not set expression for the condition';

    // Fatal
    MSG_ERR_ASSIGN = 'Can not assign a value not a variable';
    MSG_ERR_NOPTR = 'Expected operation of the variable, but it does not exist';
    MSG_ERR_PRMCNT = 'Not enough parameters passed to function';
    MSG_ERR_PRMCNT_F = 'Not enough parameters passed to the function %s(), there should be no smaller than %d';
    MSG_ERR_CONSTVAL = 'Constant may only contain simple values - numbers, strings and boolean';
    MSG_ERR_CONSTNAME = 'Constant name must be a string';
    MSG_ERR_CONST_NOVAL = 'Constant value for %s must be set';
    MSG_ERR_CONSTEX_F = 'Constant %s already been announced previously';


    MSG_ERR_NOTFOUND_FUNC = 'Function "%s" is not declared to refer to it';
    MSG_ERR_NOTFUNC = 'Undefined function or method';
    MSG_ERR_FUNC_EXISTS = 'Function "%s" has already been announced previously';
    MSG_ERR_PARAMFUNC = 'Incorrectly declared parameters for the function% s';
    MSG_ERR_INCOR_FUNC = 'Function is declared incorrectly found block bracket';

    MSG_ERR_CALLSTATIC = 'No static property "%s" have the meanings';

    MSG_ERR_INCORRECT_IND = 'Used an invalid identifier "%s"';


    MSG_ERR_EXPR = 'Syntactically invalid expression';
    MSG_ERR_ARR = 'Invalid array access';

    MSG_ERR_DO = 'Error in the design cycle';
    MSG_ERR_ELSE = 'Error in construction else';

    MSG_ERR_HEXNUM = 'Error in 16-th day';

    MSG_ERR_BREAK = 'Operator break or continue should be located inside the loop';
    MSG_ERR_NOFIND_IND  = 'Identifier "%s" is not advertised anywhere, it can not be invoked';

    // Warnings
    // Array
    MSG_ERR_PARAM_ARRTYPE = '%s-d parameter to the function should be an array';
    MSG_ERR_NOFILE = 'File "%s" is not readable';
    MSG_ERR_EXPR_ARR = 'Expected operation of the array, but it''s missing';

    // CLASSES
    MSG_ERR_FUNC_MODIFER = 'Invalid type for a function or method';
    MSG_ERR_FUNC_MODIFER_F = 'Invalid type "%s" for a function or method';
    MSG_ERR_CLASS_EXISTS = 'Class "%s" has already been announced previously';
    MSG_ERR_CLASS_NOEXISTS = 'The class "%s" is declared to refer to it';
    MSG_ERR_NOCAN_CALL_STATIC = 'Method "%s" can not be called statically';
    MSG_ERR_NOMETHOD_IN_CLASS = 'The method or property "%s" does not exist or is private';
    MSG_ERR_NO_CLASS_OR_OBJECT = 'The class or object%sdoes not exist';

    MSG_ERR_NO_CLASS_CONST = 'Constant %s not declared in class %s';

    MSG_ERR_PROPERTEX_F = 'Property "%s" already been announced previously';
  {$ENDIF}

implementation

end.

