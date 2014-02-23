unit ori_Types;

// модуль типов и структур
//{$mode objfpc}
{$H+}

{$I 'VM/ori_Options.inc'}

interface

uses
  SysUtils;

  type
    {$IFDEF CPUx86_64}
    MP_Integer = Int64;
    PtrInt     = Int64;
    {$ELSE}
    MP_Integer = Longint;
    PtrInt     = Longint;
    {$ENDIF}
    
    MP_Float   = Double;
    MP_Int     = MP_Integer;

    MP_String  = AnsiString;
    MP_Char    = AnsiChar;
    MP_PChar   = PAnsiChar;
    MP_ArrayString = array of AnsiString;

    MP_ArrayByte = array of byte;

  const
      MAX_STR_ARRAY = High(Word);

  var
      INT_STR_ARRAY: array of MP_String;

    function AnsiStrAlloc(Size: Cardinal): PAnsiChar;

implementation

function AnsiStrAlloc(Size: Cardinal): PAnsiChar;
begin
  Inc(Size, SizeOf(Cardinal));
  GetMem(Result, Size);
  Cardinal(Pointer(Result)^) := Size;
  Inc(Result, SizeOf(Cardinal));
end;

procedure init();
  var
  i: integer;
begin
  SetLength(INT_STR_ARRAY,MAX_STR_ARRAY+1);
    for i := 0 to MAX_STR_ARRAY do
      INT_STR_ARRAY[i] := IntToStr(i);
end;



initialization
    init;


end.

