unit ori_vmCrossValues;

//{$mode objfpc}
{$i './ori_Options.inc'}

{$IFDEF FPC}
  {$MODE DELPHI}
  {$H+}            (* use AnsiString *)
  {$PACKENUM 4}    (* use 4-byte enums *)
  {$PACKRECORDS C} (* C/C++-compatible record packing *)
{$ELSE}
  {$MINENUMSIZE 4} (* use 4-byte enums *)
{$ENDIF}

interface

  uses SysUtils, ori_Types;


  type
     MP_String = AnsiString;
     MP_Int = Longint;
     MP_Integer = MP_Int;
     MP_Float = Double;

  type
     TdynVMValue_type = (dvtInteger, // 0
                      dvtDouble,  // 1
                      dvtString,  // 2
                      dvtWString, // 3
                      dvtBoolean, // 4
                      dvtHash,    // 5
                      dvtObject,  // 6
                      dvtFunction,// 7
                      dvtNull,    // 8
                      dvtNone,    // 9
                      dvtPointer, // 10
                      dvtMethod);// 11

  type
      dynVMValue = record
        typ: TdynVMValue_type;  // тип значения
        len: Cardinal;
        case val: longint of
          0: (lval: MP_Integer);
          1: (dval: MP_Float);
          2: (bval: Boolean);
          3: (ptr : pointer);
          4: (str : PAnsiChar);
      end;

      PdynVMValue = ^dynVMValue;
      TdynVMValues = array of PdynVMValue;
      PdynVMValues = ^TdynVMValues;

     procedure MVAL_STRING(const v: PdynVMValue; const s: PAnsiChar; const len: Cardinal); overload;
     procedure MVAL_STRING(const v: PdynVMValue; const s: MP_String); overload;
     

     procedure MVAL_DOUBLE(var v: PdynVMValue; const d: MP_Float);
     procedure MVAL_INT(var v: PdynVMValue; const I: MP_Integer);
     procedure MVAL_BOOL(var v: PdynVMValue; const B: Boolean);
     procedure MVAL_NULL(var v: PdynVMValue);

     function convertToDouble(const v: PdynVMValue): MP_Float;
     function convertToInt(const v: PdynVMValue): MP_Integer;
     function convertToBool(const v: PdynVMValue): Boolean;
     function convertToString(const v: PdynVMValue): MP_String;
                                 
     function AnsiStrAlloc(Size: Cardinal): PAnsiChar;


implementation

function AnsiStrAlloc(Size: Cardinal): PAnsiChar;
begin
  Inc(Size, SizeOf(Cardinal));
  GetMem(Result, Size);
  Cardinal(Pointer(Result)^) := Size;
  Inc(Result, SizeOf(Cardinal));
end;


procedure MVAL_STRING(const v: PdynVMValue; const s: PAnsiChar; const len: Cardinal);
begin
    v^.typ := dvtString;
    v^.len := len;
    v^.str := AnsiStrAlloc(v^.len+1);
    STrLCopy(v^.str, @s[1], v^.len);
end;

procedure MVAL_STRING(const v: PdynVMValue; const s: MP_String);
begin
   v^.typ := dvtString;
   v^.len := Length(s);
   v^.str := AnsiStrAlloc(v^.len+1);
   strmove(v^.str, @s[1], v^.len);
end;

procedure MVAL_INT(var v: PdynVMValue; const I: MP_Integer);
begin
   v^.typ := dvtInteger;
   v^.lval := I;
end;

procedure MVAL_DOUBLE(var v: PdynVMValue; const d: MP_Float);
begin
   v^.typ := dvtDouble;{vtDouble}
   v^.dval := d;
end;

procedure MVAL_BOOL(var v: PdynVMValue; const B: Boolean);
begin
    v^.typ  := dvtBoolean;
    v^.bval := b;
end;

procedure MVAL_NULL(var v: PdynVMValue);
begin
   v^.typ := dvtNull;
end;

function convertToDouble(const v: PdynVMValue): MP_Float;
begin
    case v^.typ of
        dvtInteger: Result := v^.lval;
        dvtDouble : Result := v^.dval;
        dvtBoolean: if v^.bval then Result := 1 else Result := 0;
        dvtString: Result := StrToFloatDef(v^.str, 0);
        else Result := 0;
    end;
end;


function convertToInt(const v: PdynVMValue): MP_Integer;
begin
    case v^.typ of
        dvtInteger: Result := v^.lval;
        dvtDouble : Result := Trunc( v^.dval );
        dvtBoolean: if v^.bval then Result := 1 else Result := 0;
        dvtString: Result := StrToIntDef(v^.str, 0);
        else Result := 0;
    end;
end;


function convertToBool(const v: PdynVMValue): Boolean;
begin
    case v^.typ of
        dvtInteger: Result := v^.lval <> 0;
        dvtDouble : Result := v^.dval <> 0;
        dvtBoolean: Result := v^.bval;
        dvtString: Result := (v^.str <> nil) and (v^.str <> '') and (v^.str <> '0');
        dvtHash,dvtFunction,dvtObject,dvtMethod: Result := true;
        else Result := false;
    end;
end;


function convertToString(const v: PdynVMValue): MP_String;
begin
    case v^.typ of
        dvtInteger: Result := IntToStr(v^.lval);
        dvtDouble : Result := FloatToStr(v^.dval);
        dvtBoolean: if v^.bval then Result := '1' else Result := '';
        dvtString: begin
           SetLength(Result, v^.len);
           StrMove(@Result[1], v^.str, v^.len);
           end;
        dvtHash: Result := 'Array';
        else Result := '';
    end;
end;


end.
