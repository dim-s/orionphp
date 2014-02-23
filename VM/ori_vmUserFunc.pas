unit ori_vmUserFunc;

{$ifdef fpc}
{$mode delphi}
{$endif}
{$H+}
{$i './ori_Options.inc'}

interface

uses
  Classes, SysUtils,
  ori_StrUtils,
  ori_vmTypes,
  ori_OpGen,
  ori_Errors,
  ori_StrConsts,
  ori_Stack,
  ori_vmTables,
  ori_vmValues,
  ori_Parser,
  ori_vmEval,
  ori_Types,
  ori_vmVariables,
  ori_HashList,
  ori_vmCrossValues,
  ori_vmMemory


  {$IFDEF THREAD_SAFE}
    {$IFDEF MSWINDOWS}
    , Windows
    {$ELSE}
    , SyncObjs
    {$ENDIF}
  {$ENDIF}
  ;


  type
    TUserFunc = class(TObject)
    public
        id    : Cardinal;
        line  : Cardinal;
        MinParamCount: Word;
        RealParamCount: Word;

        info: PCodeFunction;
        xcode: TOpcodeArray;

        Ref_count: integer;
        InManager: Boolean;

        DefClass: Pointer;
        Name: MP_String;

        procedure Unuse; inline;
        procedure Use; inline;

        constructor Create();
        destructor Destroy(); override;

        procedure Invoke(params: TOriMemoryArray; const cnt: Cardinal;
                  Return: TOriMemory = nil); overload;
        function Invoke(aEval: TOriEval): TOriEval; overload;
        function Invoke(xErrPool: TOriErrorPool): TOriEval; overload;
    end;

    function findByName(const name: MP_String): TUserFunc;
    function findByNameIndex(const name: MP_String): Integer;
    function findByIndex(const id: cardinal): TUserFunc;

    function createFunction(f: PCodeFunction; acode: TOpcodeArray; start,fin: integer; ErrPool: TOriErrorPool): TUserFunc;
    function createFunctionEx(f: PCodeFunction; acode: TOpcodeArray; start,fin: integer): TUserFunc;
    procedure addNamedFunc(const name: MP_String; Func: TUserFunc; ErrPool: TOriErrorPool);
    function delNamedFunc(const name: MP_String): Boolean;

    procedure initUserFuncs();
    procedure finalUserFuncs();

    procedure tryUserFuncFree(Func: TUserFunc); inline;

    
implementation

    uses
      ori_vmCompiler,
      ori_ManRes;

    var
      FuncHashTable: THashList;
      FuncNames: MP_ArrayString;
      FuncPtrs : Array of TUserFunc;

procedure initUserFuncs();
begin
    FuncHashTable := THashList.create;
    SetLength(FuncNames,0);
    SetLength(FuncPtrs,0);
end;

procedure finalUserFuncs();
   var
   i: integer;
begin
    FuncHashTable.Free;
    SetLength(FuncNames,0);
    for i := 0 to Length(FuncPtrs) - 1 do
        FuncPtrs[i].Free;
    SetLength(FuncPtrs,0);
end;

procedure tryUserFuncFree(Func: TUserFunc); inline;
begin
    with Func do
    begin
       Unuse;
       if Ref_count < 1 then
       MANFuncs.Add( Func );
    end;
end;

function delNamedFunc(const name: MP_String): Boolean;
  var
  id: integer;
begin
   id := ori_vmUserFunc.findByNameIndex( name );
   Result := id > -1;
   if Result then
   begin
      FuncHashTable.setValue( name, 0 );

      with FuncPtrs[ id ] do begin
          dec(ref_count);
          if ref_count < 1 then
          begin
              Free;
          end;
      end;


      Finalize(FuncNames[ id ]);
      FuncPtrs[ id ] := nil;
   end;
end;

procedure addNamedFunc(const name: MP_String; Func: TUserFunc; ErrPool: TOriErrorPool);
   var
   id: integer;
begin
   id := FuncHashTable.getHashValueEx(name);
   if id > 0 then
   begin
      ErrPool.newError(errFatal, Format(MSG_ERR_FUNC_EXISTS,[name]), 0);
      exit;
   end;

   id := FuncHashTable.Counts;
   SetLength(FuncNames,id+1);
   SetLength(FuncPtrs, id+1);
   FuncNames[id] := name;
   FuncPtrs[id]  := Func;

   FuncHashTable.setValue(name,id+1);
   Func.Name := name;
   Func.ref_count := 1;
end;


function findByNameIndex(const name: MP_String): Integer;
begin
     Result := ori_vmUserFunc.FuncHashTable.getHashValueEx(name)-1;
end;

function findByName(const name: MP_String): TUserFunc;
   var
   id: integer;
begin
    id := findByNameIndex(name);
    if id = -1 then
        Result := nil
    else
        Result := ori_vmUserFunc.FuncPtrs[id];
end;

function findByIndex(const id: cardinal): TUserFunc;
begin
   Result := ori_vmUserFunc.FuncPtrs[id];
end;


function createFunction(f: PCodeFunction; acode: TOpcodeArray; start,fin: integer; ErrPool: TOriErrorPool): TUserFunc;
   var
   i,c: integer;
begin
   Result := TUserFunc.Create;
   Result.info := f;
   Result.RealParamCount := length(f^.vars);
   Result.MinParamCount  := Result.RealParamCount - Length(f^.defs);
   Result.line := start-1;

   with Result do begin
       xcode.SetLength(fin - start + 1);
       c := 0;
       for i := start to fin do
       begin
          xcode[c] := cloneOpcode(acode[i]);
          inc(c);
       end;
   end;

   if f^.name = '' then
   begin
      addManFunc(Result);
   end else
      addNamedFunc(f^.name, Result, errPool);
end;

function createFunctionEx(f: PCodeFunction; acode: TOpcodeArray; start,fin: integer): TUserFunc;
   var
   i,c: integer;
begin
   Result := TUserFunc.Create;
   Result.info := f;
   Result.RealParamCount := length(f^.vars);
   Result.MinParamCount  := Result.RealParamCount - Length(f^.defs);
   Result.line := start-1;

   with Result do begin
       xcode.SetLength(fin - start + 1);
       c := 0;
       for i := start to fin do
       begin
          xcode[c] := cloneOpcode(acode[i]);
          inc(c);
       end;
   end;
end;

{ TUserFunc }

constructor TUserFunc.Create;
begin
  inherited Create;
  ref_count := 0;

  xcode := TOpcodeArray.Create;
  DefClass := nil;
  InManager := false;
end;

destructor TUserFunc.Destroy;
  var
  i: integer;
begin
  for i := 0 to xcode.Count - 1 do
      discardOpcode(xcode[i]);

  xcode.Free;
  inherited Destroy;
end;

procedure TUserFunc.Invoke(params: TOriMemoryArray; const cnt: Cardinal;
                  Return: TOriMemory = nil);
  var
  i: integer;
  eval: TOriEval;
begin
  eval := mr_getEval;
  with eval do
  begin
      isUse := true;
      code := xcode;

      for i := cnt-1 downto 0 do
      begin
            // --todo
            TOriEval(eval).variables.setVariable(Self.info^.vars[i],params[i],
                  info^.vars_link[i]);
      end;
      eval.DefClass := Self.DefClass;
      Run;
      Variables.FastClear;
  end;
end;

function TUserFunc.Invoke(xErrPool: TOriErrorPool): TOriEval;
  var
  i: integer;
  lErr: TOriErrorPool;
begin
  Result := mr_getEval;
  with (Result) do
  begin
      isUse := true;
      code := xcode;
      Result.cashFuncReturn.Clear;
      lErr := Result.ErrPool;
      Result.ErrPool := xErrPool;
      Result.DefClass := Self.DefClass;


      for i := MinParamCount to RealParamCount-1 do
      begin
            Result.Variables.setVariable(Self.info^.vars[i],
            info^.defs[i-MinParamCount], DefClass, xErrPool, self.line);
      end;

      Run;
      Result.ErrPool := lErr;
      
      Variables.FastClear;
      Result.Stack.Count := 0;
  end;
end;

procedure TUserFunc.Unuse;
begin
  dec( ref_count );
  if ref_count < 1 then
  if not InManager then
     addManFunc(self);
end;

procedure TUserFunc.Use;
begin
  inc( ref_count );
end;

function TUserFunc.Invoke(aEval: TOriEval): TOriEval;
   var
   i,r: integer;
   lErr: TOriErrorPool;
begin
  Result := mr_getEval;
  
  with Result do
  begin
     isUse := true;
     lErr := Result.ErrPool;
     ErrPool := aEval.ErrPool;
     code := xcode;
     cashFuncReturn.Clear;
     r := (MinParamCount-1) + (aEval.tk.cnt-MinParamCount);
     with Variables do begin
        for i := r  downto 0 do
        begin
          if i = 0 then
          begin
            if aEval.tk^.oper2 = nil then
              setVariableFromStack(Self.info^.vars[i], aEval.Stack.pop(), info^.vars_link[i])
            else begin
              aEval.stackVariable(aEval.tk^.oper2);
              setVariableFromStack(Self.info^.vars[i], aEval.tk^.oper2, info^.vars_link[i])
            end;
          end else
            setVariableFromStack(Self.info^.vars[i], aEval.Stack.pop(), info^.vars_link[i])
        end;

        for i := r+1 to RealParamCount-1 do
        begin
            setVariable(Self.info^.vars[i], info^.defs[i-MinParamCount], DefClass, aEval.ErrPool, self.line);
        end;
     end;

    Result.DefClass := Self.DefClass;
    Run;
    ErrPool := lErr;

    Variables.FastClear;
    Result.Stack.Count := 0; 

  end;
end;

end.
