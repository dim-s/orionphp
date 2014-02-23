unit ori_vmConstants;

{$H+}

interface

uses
  SysUtils,
  ori_StrUtils,
  ori_Types,
  ori_vmTypes,
  ori_vmValues,
  ori_vmTables,
  ori_Stack,
  ori_Errors,
  ori_HashList,
  ori_vmCrossValues,
  ori_Parser,
  ori_vmMemory;

   type
     TOriConsts = class(TObject)

   public
      Constants: TArrayVMConstant;
      ConstHashList: THashList;
      ConstNames: array of MP_String;
      ConstantLen: Cardinal;
      // задает константе значение из стекового значения
      class procedure assignVMConstant(var cnst: TVMConstant; val: TOriMemory);
      // кладет константу в стековое значение
      procedure putVMConstant(M: TOriMemory; var cnst: TVMConstant); overload;

      procedure addConstant(const name: MP_String; val: TOriMemory); overload;
      procedure addConstant(const name: MP_String; const val: MP_Float); overload;
      procedure addConstant(const name: MP_String; const val: MP_Int); overload;
      procedure addConstant(const name: MP_String; const val: MP_String); overload;
      procedure addConstant(const name: MP_String; const val: boolean); overload;

      function getConstant(const name: MP_String): Integer;

      procedure Clear;
      constructor Create;
      destructor Destroy;
   end;

   procedure initConstantSystem();
   procedure finalConstantSystem();

   var
      VM_Constants: TOriConsts;

implementation


procedure initConstantSystem();
begin
  VM_Constants := TOriConsts.Create;
end;

procedure finalConstantSystem();
begin
  VM_Constants.Free;
end;

class procedure TOriConsts.assignVMConstant(var cnst: TVMConstant; val: TOriMemory);
begin
  case val.typ of
      mvtInteger: cnst.lval := val.Mem.lval;
      mvtDouble : cnst.dval := val.Mem.dval;
      mvtString : cnst.str  := val.Mem.str;
      mvtPChar  : begin
                   cnst.str  := val.Mem.pchar^;
                   cnst.typ := mvtString;
                   exit;
                  end;
      mvtBoolean: cnst.bval := val.Mem.bval;
      mvtVariable,mvtGlobalVar:
        begin
              assignVMConstant(cnst, val.AsMemory);
        end;
  end;
  cnst.typ := val.Typ;
end;

procedure TOriConsts.Clear;
begin
  SetLength(Constants,0);
  SetLength(ConstNames,0);
  ConstHashList.clear;
end;

constructor TOriConsts.Create;
begin
  SetLength(Constants,0);
  SetLength(ConstNames,0);
  ConstantLen := 0;
  ConstHashList := THashList.Create;
end;

destructor TOriConsts.Destroy;
begin
  SetLength(Constants,0);
  SetLength(ConstNames,0);
  ConstHashList.Free;
end;

procedure TOriConsts.putVMConstant(M: TOriMemory; var cnst: TVMConstant);
begin
    case cnst.typ of
      mvtInteger: M.ValL(cnst.lval);
      mvtDouble : M.ValF(cnst.dval);
      mvtString : M.Val(cnst.str);
      mvtBoolean: M.Val(cnst.bval);
      mvtNull   : M.ValNull;
    end;
end;

// добавляет переменную
procedure TOriConsts.addConstant(const name: MP_String; val: TOriMemory);
begin
   SetLength(Constants, ConstantLen+1);
   SetLength(ConstNames, ConstantLen+1);

   assignVMConstant(Constants[ConstantLen], val);
   begin
       ConstNames[ConstantLen] := AnsiUpperCase( name );
       Inc(ConstantLen,1);
       ConstHashList.setValue(UpperCase(name), ConstantLen);
   end;
end;


// добавляет переменную
procedure TOriConsts.addConstant(const name: MP_String; const val: MP_Float);
begin
   SetLength(Constants, ConstantLen+1);
   SetLength(ConstNames, ConstantLen+1);

   Constants[ConstantLen].dval := val;
   Constants[ConstantLen].typ  := mvtDouble;
   ConstNames[ConstantLen] := AnsiUpperCase( name );
   Inc(ConstantLen,1);
   ConstHashList.setValue(UpperCase(name), ConstantLen);
end;

procedure TOriConsts.addConstant(const name: MP_String; const val: MP_Int);
begin
   SetLength(Constants, ConstantLen+1);
   SetLength(ConstNames, ConstantLen+1);

   Constants[ConstantLen].lval := val;
   Constants[ConstantLen].typ  := mvtInteger;
   ConstNames[ConstantLen] := UpperCase( name );
   Inc(ConstantLen,1);
   ConstHashList.setValue(UpperCase(name), ConstantLen);
end;

procedure TOriConsts.addConstant(const name: MP_String; const val: MP_String);
begin
   SetLength(Constants, ConstantLen+1);
   SetLength(ConstNames, ConstantLen+1);

   Constants[ConstantLen].str  := val;
   Constants[ConstantLen].typ  := mvtString;
   ConstNames[ConstantLen] := UpperCase( name );
   Inc(ConstantLen,1);
   ConstHashList.setValue(UpperCase(name), ConstantLen);
end;

procedure TOriConsts.addConstant(const name: MP_String; const val: boolean);
begin
   SetLength(Constants, ConstantLen+1);
   SetLength(ConstNames, ConstantLen+1);

   Constants[ConstantLen].bval := val;
   Constants[ConstantLen].typ  := mvtBoolean;
   ConstNames[ConstantLen] := UpperCase( name );
   Inc(ConstantLen,1);
   ConstHashList.setValue(UpperCase(name), ConstantLen);
end;

function TOriConsts.getConstant(const name: MP_String): Integer;
begin
  Result := ConstHashList.getHashValueEx(UpperCase(name)) -1;
end;


initialization
  initConstantSystem;

finalization
  finalConstantSystem;

end.
