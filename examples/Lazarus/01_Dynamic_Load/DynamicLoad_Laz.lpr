program DynamicLoad_Laz;

{$mode objfpc}{$H+}
{$IFDEF LINUX} {$DEFINE UNIX} {$ENDIF}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  { you can add units after this }
  SysUtils,
  {$ifdef MSWINDOWS}
  Windows,
  {$endif}
  vmCrossValues,
  OriWrap;

//{$R *.res}

const
{$IFDEF MSWINDOWS}
    libName = '../../../dynamic/OrionPHP.dll';
{$ENDIF}
{$IFDEF LINUX}
    libName = '../../../dynamic/OrionPHP.so';
{$ENDIF}

  var
    OriEn: Pointer;

    ErrCount: Integer;
    ErrMsg: PAnsiChar;
    ErrFile: PAnsiChar;
    ErrLine, I: Longint;
    ErrType: Byte;

{$IFDEF WINDOWS}{$R DynamicLoad_Laz.rc}{$ENDIF}

{$IFDEF MSWINDOWS}
function ToDos(St: AnsiString): AnsiString;
var
   Ch   :    PAnsiChar;
begin
          Ch := PAnsiChar(StrAlloc(Length(St) + 1));
          AnsiToOem(PAnsiChar(St), Ch);
          Result := Ch;
          StrDispose(Ch);
end;
{$ELSE}
function ToDos(St: AnsiString): AnsiString;
begin
 Result := St;
end;
{$ENDIF}

function x_print(param: PdynVMValues; const cnt: cardinal; var Return: PdynVMValue; eval: Pointer): byte;
  var
  i: integer;
begin
  for i := 0 to cnt - 1 do
    Writeln(ToDos(convertToString(param^[i])));
end;

begin

  if not OriWrap.ORION_LOAD( libName ) then
  begin
       WriteLn('Error while loading ORION engine');
       Sleep(3000);
       exit;
  end;

  // init Orion Engine
  // [ru] инициализация движка
  ori_init();

  // add module of functions
  // [ru] добавляем нативные функции в движок
  ori_func_add(@x_print,'print',1);
  ori_func_add(@x_print,'echo',1);

  // create orion item engine
  // [ru] создаем объект движка
  OriEn := ori_create();

  // eval code from file
  // [ru] выполняем скрипт из файла
  ori_evalfile( OriEn, 'code.ori');

  // check errors
  // [ru] проверка на ошибки
  ErrCount := ori_err_count( OriEn );
  if ErrCount > 0 then begin
  for i := 0 to ErrCount - 1 do
  begin
       ori_err_get( OriEn, i, ErrLine, ErrType, ErrMsg, ErrFile );
       WriteLn('[', ErrLine, ']: ', ErrMsg);

       ori_freeStr( ErrMsg );
       ori_freeStr( ErrFile );
       exit;
  end;
  Sleep(3000);
  end;



  // final
  ori_destroy( OriEn );
  ori_final();

end.

