unit ori_vmShortApi;

{$H+}
{$ifdef fpc}
        {$mode delphi}
{$endif}

interface

uses
  SysUtils, Classes,
  ori_Types,
  ori_vmTypes,
  ori_vmValues,
  ori_vmTables,
  ori_Stack,
  ori_Errors,
  ori_vmConstants,
  ori_vmLoader,
  ori_vmCrossValues,
  ori_vmMemory;

// ORI Utils
function ori_version(): longint; cdecl;

function ori_newStr(size: cardinal): PAnsiChar; cdecl;
procedure ori_freeStr(var s: PAnsiChar); cdecl;

// ORI Main
function ori_init(): byte; cdecl;
function ori_final(): byte; cdecl;

function ori_create(): pointer; cdecl;
function ori_destroy(const o: pointer): byte; cdecl;
function ori_evalfile(const o: pointer; const fileName: PAnsiChar): byte; cdecl;
function ori_evalcode(const o: pointer; const Script: PAnsiChar; const Len: cardinal): byte; cdecl;
function ori_err_count(o: pointer): longint; cdecl;
procedure ori_err_get(o: pointer; const Num: longint; var aLine: longint; var aTyp: byte; var aMsg: PAnsiChar; var aFileName: PAnsiChar); cdecl;

// ORI Variables
procedure ori_set_var(o: pointer; const Name: PAnsiChar; val: Pointer); cdecl;
function ori_get_var(o: pointer; const Name: PAnsiChar): Pointer; cdecl;

// ORI COnstants
function ori_addconst_int(const Name: PAnsiChar; const val: MP_Int): byte; cdecl;
function ori_addconst_float(const Name: PAnsiChar; const val: MP_Float): byte; cdecl;
function ori_addconst_str(const Name: PAnsiChar; const val: PAnsiChar; const len: cardinal): byte; cdecl;
function ori_addconst_bool(const Name: PAnsiChar; const val: byte): byte; cdecl;
function ori_const_exists(const Name: PAnsiChar): byte; cdecl;

function ori_getconst_int(const Name: PAnsiChar): MP_Int; cdecl;
function ori_getconst_float(const Name: PAnsiChar): MP_Float; cdecl;
procedure ori_getconst_str(const Name: PAnsiChar; var Result: PAnsiChar); cdecl;
function ori_getconst_bool(const Name: PAnsiChar): byte; cdecl;

// ORI Byte code
function ori_compilecode(const O: Pointer; const script: PAnsiChar; const len: cardinal; var ResultLen: longint): PAnsiChar; cdecl;
function ori_compilefile(const O: Pointer; const fileName: PAnsiChar; var ResultLen: integer): PAnsiChar; cdecl;
function ori_evalcompiled(const bytecode: PAnsiChar; const Len: cardinal): Pointer; cdecl;

// ORI Modules and funcs
procedure ori_func_add(func: Pointer; Name: PAnsiChar; const Cnt: cardinal); cdecl;
procedure ori_module_add(func: Pointer); cdecl;

// VM Constants

implementation

uses
  Orion,
  ori_vmCompiler,
  ori_Parser,
  ori_ManRes,
  ori_vmEval,
  ori_vmVariables,
  ori_vmNativeFunc;

function ori_version(): longint; cdecl;
begin
  Result := ORION_VERSION;
end;

function ori_newStr(size: cardinal): PAnsiChar; cdecl;
begin
  Result := ori_vmCrossValues.AnsiStrAlloc(size);
end;

procedure ori_freeStr(var s: PAnsiChar); cdecl;
begin
  if s <> nil then
  begin
    StrDispose(S);
    s := nil;
  end;
end;

function ori_init(): byte; cdecl;
begin
  try
    Result := 1;
    initOrionEngine();
  except
    Result := 0;
  end;
end;

function ori_final(): byte; cdecl;
begin
  try
    Result := 1;
    finalOrionEngine();
  except
    Result := 0;
  end;
end;

function ori_create(): pointer; cdecl;
begin
  Result := TOrionEngine.Create(False);
end;

function ori_destroy(const o: pointer): byte; cdecl;
begin
  try
    Result := 1;
    TOrionEngine(o).Destroy;
  except
    Result := 0;
  end;
end;


function ori_evalfile(const o: pointer; const fileName: PAnsiChar): byte; cdecl;
begin
  try
    Result := 1;
    TOrionEngine(o).EvalFile(fileName);
  except
    Result := 0;
  end;
end;

function ori_evalcode(const o: pointer; const Script: PAnsiChar;
  const Len: cardinal): byte; cdecl;
begin
  try
    Result := 1;
    TOrionEngine(o).Eval(Copy(Script, 0, Len));
  except
    Result := 0;
  end;
end;


function ori_err_count(o: pointer): longint; cdecl;
begin
  if (TOrionEngine(o).ErrPool = nil) or (not TOrionEngine(o).ErrorExists) then
    Result := 0
  else
    Result := Length(TOrionEngine(o).ErrPool.errorTable^);
end;

procedure ori_err_get(o: pointer; const Num: longint; var aLine: longint;
  var aTyp: byte; var aMsg: PAnsiChar; var aFileName: PAnsiChar); cdecl;
begin
  with TOrionEngine(o).ErrPool.errorTable^[Num] do
  begin
    aLine := line;
    aTyp  := typ;

    aMsg := ori_newStr(length(msg) + 1);
    StrCopy(aMsg, @msg[1]);

    aFileName := ori_newStr(length(AFile) + 1);
    if aFile <> '' then
      StrCopy(aFileName, @aFile[1]);
  end;
end;

procedure ori_set_var(o: pointer; const Name: PAnsiChar; val: Pointer); cdecl;
var
  id: integer;
  v:  TOriVariables;
begin
  {if o = nil then
  begin
    with TOrionEngine(o) do
      v := FEval.variables;
  end
  else
    v := GlobalVars;

  id := v.table.byNameIndex(Name);
  if id > -1 then
  begin
    unsetVMValue(PVMValue(v.table.Values.V^[id]));
    v.table.Values.V^[id]   := val;
    PVMValue(val)^.table := v.table;
  end
  else
  begin
    v.table.addValue(Name, val, False);
  end;   }
end;

function ori_get_var(o: pointer; const Name: PAnsiChar): Pointer; cdecl;
var
  id: integer;
  v:  TOriVariables;
begin
  if o = nil then
  begin
    with TOrionEngine(o) do
      v := FEval.variables;
  end
  else
    v := GlobalVars;

  id := v.byNameIndex(Name);
  if id > -1 then
    Result := v[id]
  else
    Result := nil;
end;

procedure ori_func_add(func: Pointer; Name: PAnsiChar; const Cnt: cardinal); cdecl;
begin
  ori_vmNativeFunc.addNativeFunc(Name, Cnt, Func);
end;

procedure ori_module_add(func: Pointer); cdecl;
begin
  ori_vmNativeFunc.addNativeModule(Func);
end;

{ ============================= CONSTANTS ==================================== }

function ori_addconst_int(const Name: PAnsiChar; const val: MP_Int): byte; cdecl;
begin
  try
    Result := 1;
    VM_Constants.AddConstant(Name, val);
  except
    Result := 0;
  end;
end;

function ori_addconst_float(const Name: PAnsiChar; const val: MP_Float): byte; cdecl;
begin
  try
    Result := 1;
    VM_Constants.AddConstant(Name, val);
  except
    Result := 0;
  end;
end;

function ori_addconst_str(const Name: PAnsiChar; const val: PAnsiChar;
  const len: cardinal): byte; cdecl;
var
  S: ansistring;
begin
  try
    SetLength(S, len);
    S      := StrMove(val, 0, Len);
    Result := 1;
    VM_Constants.addConstant(Name, S);
  except
    Result := 0;
  end;
end;

function ori_addconst_bool(const Name: PAnsiChar; const val: byte): byte; cdecl;
begin
  try
    Result := 1;
    VM_Constants.AddConstant(Name, val);
  except
    Result := 0;
  end;
end;

function ori_const_exists(const Name: PAnsiChar): byte; cdecl;
begin
  if VM_Constants.getConstant(Name) = -1 then
    Result := 0
  else
    Result := 1;
end;

function ori_getconst_int(const Name: PAnsiChar): MP_Int; cdecl;
var
  id: integer;
begin
  id := VM_Constants.getConstant(Name);
  if id > -1 then
  begin
    with VM_Constants.Constants[id] do
      case typ of
        mvtInteger: Result := lval;
        mvtDouble: Result  := Trunc(dval);
        mvtBoolean: if bval then
            Result := 1
          else
            Result := 0;
        mvtString: Result := StrToIntDef(str, 0);
        else
          Result := 0;
      end;
  end
  else
    Result := 0;
end;

function ori_getconst_float(const Name: PAnsiChar): MP_Float; cdecl;
var
  id: integer;
begin
  id := VM_Constants.getConstant(Name);
  if id > -1 then
  begin
    with VM_Constants.Constants[id] do
      case typ of
        mvtInteger: Result := lval;
        mvtDouble: Result  := dval;
        mvtBoolean: if bval then
            Result := 1
          else
            Result := 0;
        mvtString: Result := StrToFloatDef(str, 0);
        else
          Result := 0;
      end;
  end
  else
    Result := 0;
end;

procedure ori_getconst_str(const Name: PAnsiChar; var Result: PAnsiChar); cdecl;
var
  id: integer;
  S:  MP_String;
begin
  id := VM_Constants.getConstant(Name);
  if id > -1 then
  begin
    with VM_Constants.Constants[id] do
      case typ of
        mvtInteger:
        begin
          S := IntToStr(lval);
          StrCopy(@S[1], Result);
        end;
        mvtDouble:
        begin
          S := FloatToStr(dval);
          StrCopy(@S[1], Result);
        end;
        mvtBoolean: if bval then
            Result := '1'
          else
            Result := '0';
        mvtString:
        begin
          StrLCopy(@str[1], Result, Length(str));
        end
        else
          Result := '';
      end;
  end
  else
    Result := '';
end;

function ori_getconst_bool(const Name: PAnsiChar): byte; cdecl;
var
  id: integer;
begin
  id := VM_Constants.getConstant(Name);
  if id > -1 then
  begin
    with VM_Constants.Constants[id] do
      case typ of
        mvtInteger: if lval > 0 then
            Result := 1
          else
            Result := 0;
        mvtDouble: if dval > 0 then
            Result := 1
          else
            Result := 0;
        mvtBoolean: if bval then
            Result := 1
          else
            Result := 0;
        mvtString: if (str <> '') and (str <> '0') then
            Result := 1
          else
            Result := 0;
        else
          Result := 0;
      end;
  end
  else
    Result := 0;
end;


{ =============================== BYTE CODE ================================== }

function ori_compilecode(const O: Pointer; const script: PAnsiChar;
  const len: cardinal; var ResultLen: longint): PAnsiChar; cdecl;
var
  pr:   TOriParser;
  cm:   TOriCompiler;
  code: TOpcodeArray;
  S:    ansistring;
label
  1;
begin
  pr := mr_getParser;
  cm := mr_getCompiler;
  code := TOpcodeArray.Create;

  pr.Parse(Copy(script, 0, len));
  if pr.ErrPool.existsFatalError then
  begin
    TOrionEngine(O).ErrPool := pr.ErrPool;
    goto 1;
  end;

  cm.compile(pr.blocks);

  if cm.ErrPool.existsFatalError then
  begin
    TOrionEngine(O).ErrPool := cm.ErrPool;
    goto 1;
  end;

  ori_bcodeSaveString(cm.opcode, S);

  ResultLen := Length(S);
  Result    := ori_newStr(Length(S) + 1);
  StrMove(Result, @S[1], ResultLen);

  1:
    code.Free;
  pr.clearBlocks;
  pr.isUse := False;

  cm.clearSource;
  cm.isUse := False;
end;

function ori_compilefile(const O: Pointer; const fileName: PAnsiChar;
  var ResultLen: integer): PAnsiChar; cdecl;
var
  M: TMemoryStream;
begin
  M := TMemoryStream.Create;

  try
    M.LoadFromFile(fileName);
    M.Position := 0;
    Result     := ori_compilecode(O, M.Memory, M.Size, ResultLen);
  finally
    M.Free;
  end;
end;

function ori_evalcompiled(const bytecode: PAnsiChar; const Len: cardinal): Pointer;
var
  code:  TOpcodeArray;
  ev:    TOriEval;
  lastV: TObject;
  S:     ansistring;
begin
  ev := mr_getEval;
  ev.code := TOpcodeArray.Create;
  SetLength(S, Len);
  StrMove(@S[1], bytecode, Len);
      {SetLength(S, len);
      Move(bytecode, S[1], len); }

  ori_bcodeLoadString(ev.code, s);
  ev.run;

  Result := TOriMemory.GetMemory(ev.cashFuncReturn);

  ev.clearInfo;
  discardOpcodeS(ev.code);
  ev.code.Free;
  ev.isUse := False;
end;

end.

