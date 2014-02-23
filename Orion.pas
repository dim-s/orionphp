unit Orion;

{$ifdef fpc}
 {$mode delphi}
{$endif}

{$H+}
{$i './VM/ori_Options.inc'}

interface

uses
  Classes, SysUtils,
  ori_Errors,
  ori_Types,

  {$IFDEF osWIN}
    Windows,
  {$ELSE}
    LclIntf,
  {$ENDIF}    

  ori_vmValues,
  ori_vmCompiler,
  ori_vmEval,
  ori_vmConstants,
  ori_vmVariables,
  ori_vmLoader,
  ori_vmUserFunc,
  ori_vmNativeFunc,
  ori_Parser,
  ori_Stack,
  ori_ManRes,
  ori_vmClasses,
  ori_vmMemory,

  // native functions of core
   ori_Core, ori_CoreMath, ori_CoreString, ori_CoreArray, ori_CoreClasses
  ;

  const
    ORION_VERSION = -3;
    ORION_VERSION_STR = '0.3';

  type
    TOrionThreadCallback = procedure (th: TThread; eval: TOriEval);
    
  type
    TOrionEvalThread = class(TThread)
    private
          FEval: TOriEval;
          FCallBack: TOrionThreadCallback;
          FTime: Integer;
          procedure SetEval(const Value: TOriEval);
          procedure SetCallback(const Value: TOrionThreadCallback);
          procedure SetTime(const Value: Integer);
    protected
          procedure doCallBack;
    public
          constructor Create;
          destructor Destroy; override;
          procedure toExit;
          procedure Execute; override;

          property Callback: TOrionThreadCallback read FCallback write SetCallback;
          property Eval: TOriEval read FEval write SetEval;
          property Time: Integer read FTime write SetTime;
    end;

  type
    TOrionEngine = class(TObject)
  private
      protected
        function GetErrors(): PArrayError;
        function GetGlobalVars: TOriVariables;
      public
        __FILE__: MP_String;
        ErrPool: TOriErrorPool;
        FEval: TOriEval;
        function getVersion(): AnsiString;
        constructor Create(const initEngine: boolean);
        destructor Destroy; override;

        procedure AddModule(func_init: pointer);

        procedure EvalFile(const aFile: AnsiString; Return: TOriMemory = nil);
        procedure EvelBCodeFile(const aFile: AnsiString; Return: TOriMemory = nil);
        procedure Eval(const script: MP_String; Return: TOriMemory = nil); overload;
        procedure Eval(ByteCode: TOpcodeArray; Return: TOriMemory = nil); overload;
        procedure Compile(const script: MP_String; ByteCode: TOpcodeArray);
        procedure SaveBCode(ByteCode: TOpcodeArray; const Stream: TStream);
        procedure LoadBCode(ByteCode: TOpcodeArray; const Stream: TStream);

        function EvalThread(const script: MP_String; const resume: boolean = true): TOrionEvalThread;

        // errors ... //
        procedure setErrorHandle(const proc: TErrorHandle);
        function ErrorExists: Boolean;
        procedure GetError(const id: Integer; var typ: byte; var line: integer;
                      var Msg,AFile: AnsiString);
        function ErrorCount: Integer;
        property Errors: PArrayError read GetErrors;

        property GlobalVars: TOriVariables read GetGlobalVars;
        procedure AddConstant(const Name: MP_String; const val: MP_Integer); overload;
        procedure AddConstant(const Name: MP_String; const val: MP_Float); overload;
        procedure AddConstant(const Name: MP_String; const val: MP_String); overload;
        procedure AddConstant(const Name: MP_String; const val: Boolean); overload;
        function GetConstant(const Name: MP_String): TVMConstant;

        procedure ResetConstants;
    end;

    procedure initOrionEngine();
    procedure finalOrionEngine();

    function getTime(): Longint;
    
implementation

function getTime(): Longint;
begin
{$IFDEF MSWINDOWS}
  Result := Windows.GetTickCount;
{$ELSE}
  Result := LclIntf.GetTickCount;
{$ENDIF}
end;

{ TOrionEngine }
procedure initOrionEngine();
begin
   initManMemory;
   initErrSystem;
   initNativeFuncSystem;
   initUserFuncs;
   initClassSystem;
   initSGlobalVars;
end;

procedure finalOrionEngine();
begin
   finalErrSystem;
   finalNativeFuncSystem;
   finalUserFuncs;
   finalClassSystem;
   finalSGlobalVars;
   finalManMemory;
end;

procedure TOrionEngine.AddConstant(const Name: MP_String; const val: MP_Float);
begin
    VM_Constants.addConstant(Name,val);
end;

procedure TOrionEngine.AddConstant(const Name: MP_String;
  const val: MP_Integer);
begin
    VM_Constants.addConstant(Name,val);
end;

procedure TOrionEngine.AddConstant(const Name: MP_String; const val: Boolean);
begin
    VM_Constants.addConstant(Name,val);
end;

procedure TOrionEngine.AddModule(func_init: pointer);
begin
  ori_vmNativeFunc.addNativeModule(func_init);
end;

procedure TOrionEngine.AddConstant(const Name, val: MP_String);
begin
   VM_Constants.addConstant(Name,val);
end;

procedure TOrionEngine.Compile(const script: MP_String; ByteCode: TOpcodeArray);
  var
  Parser: TOriParser;
  Compiler: TOriCompiler;
  Ev: TOriEval;
  i: integer;
begin
  ErrPool := nil;
    
  Parser := mr_getParser;
  Parser.Parse(Script);

  if Parser.ErrPool.existsFatalError then
      ErrPool := Parser.ErrPool;

  Compiler := mr_getCompiler;
  Compiler.__FILE__ := Self.__FILE__;
  Compiler.compile(Parser.blocks);

  if Compiler.ErrPool.existsFatalError then
     ErrPool := Compiler.ErrPool;

  ByteCode.DoClone( Compiler.Opcode );
  
  Compiler.clearSource;
  Compiler.isUse := false;
  Parser.isUse := false;
end;

constructor TOrionEngine.Create(const initEngine: boolean);
begin
  if initEngine then
      initOrionEngine;
  FEval := mr_getEval;
end;

destructor TOrionEngine.Destroy;
begin
   FEval.clearInfo;
   FEval.isUse := false;
   inherited;
end;

function TOrionEngine.ErrorCount: Integer;
begin
  Result := length(self.ErrPool.errorTable^);
end;

function TOrionEngine.ErrorExists: Boolean;
begin
  Result := (ErrPool <> nil) and (Length(Self.ErrPool.errorTable^) > 0);
end;

procedure TOrionEngine.Eval(ByteCode: TOpcodeArray; Return: TOriMemory = nil);
begin
  FEval.toExit;
  ErrPool := FEval.ErrPool;
  ErrPool.clearErrors;
  
  FEval.code := ByteCode;
  FEval.run;
  if Return <> nil then
      Return.Val( FEval.cashFuncReturn, true );

  FEval.clearInfo;
end;

procedure TOrionEngine.EvalFile(const aFile: AnsiString; Return: TOriMemory);
var
  FS: TFileStream;
  Script: MP_String;
begin
  FS := TFileStream.Create(aFile, fmOpenRead);
  try
    SetLength(Script, FS.Size div SizeOf(Script[1]));
    FS.ReadBuffer(Script[1], FS.Size);
  finally
    FS.Free;
  end;
  Self.__FILE__ := aFile;
  Eval(Script, Return);
end;

function TOrionEngine.EvalThread(const script: MP_String; const resume: boolean = true): TOrionEvalThread;
begin
  //clearErrors;
  Result := TOrionEvalThread.Create;
  Self.Compile(script, Result.Eval.code);

  if ErrorExists then
  begin
      discardOpcodeS(Result.Eval.code);
      exit;
  end;

      if resume then
        Result.Resume;
end;

procedure TOrionEngine.EvelBCodeFile(const aFile: AnsiString; Return: TOriMemory);
var
  FS: TFileStream;
  code: TOpcodeArray;
begin
  code := TOpcodeArray.Create;
  ori_bcodeLoadFile(code, aFile);
  Self.__FILE__ := aFile;
  Eval(code, Return);
  discardOpcodeS(code);
end;

function TOrionEngine.GetConstant(const Name: MP_String): TVMConstant;
  var
  id: integer;
begin
  Result.typ := mvtNull;
  id := VM_Constants.getConstant(Name);
  if id <> -1 then
      Result := VM_Constants.Constants[id];
end;
                   
procedure TOrionEngine.GetError(const id: Integer; var typ: byte;
  var line: integer; var Msg, AFile: AnsiString);
begin
  typ  := ErrPool.errorTable^[id].typ;
  line := ErrPool.errorTable^[id].line;
  Msg  := ErrPool.errorTable^[id].msg;
  AFile := ErrPool.errorTable^[id].AFile;
end;

function TOrionEngine.GetErrors: PArrayError;
begin
  Result := ErrPool.errorTable;
end;

function TOrionEngine.GetGlobalVars: TOriVariables;
begin
  Result := GlobalVars;
end;

procedure TOrionEngine.LoadBCode(ByteCode: TOpcodeArray;
  const Stream: TStream);
begin
 ori_bcodeLoad(ByteCode, Stream);
end;

procedure TOrionEngine.ResetConstants;
begin
  ori_vmConstants.VM_Constants.Clear;
end;

procedure TOrionEngine.SaveBCode(ByteCode: TOpcodeArray;
  const Stream: TStream);
begin
   ori_bcodeSave(ByteCode, Stream);
end;

procedure TOrionEngine.setErrorHandle(const proc: TErrorHandle);
begin
  funcErrHandle := proc;
end;
              
procedure TOrionEngine.Eval(const script: MP_String; Return: TOriMemory);
  var
  Parser: TOriParser;
  Compiler: TOriCompiler;
begin
  Parser := mr_getParser;
  Parser.Parse(Script);
  
  if Parser.ErrPool.existsFatalError then
      ErrPool := Parser.ErrPool;

  Compiler := mr_getCompiler;
  Compiler.__FILE__ := Self.__FILE__;
  Compiler.compile(Parser.blocks);

  if Compiler.ErrPool.existsFatalError then
     ErrPool := Compiler.ErrPool;

  if not ErrorExists then
  begin
    FEval.code := Compiler.opcode;
    FEval.run;
    if Return <> nil then
      Return.Val( FEval.cashFuncReturn, true );

    if FEval.ErrPool.existsFatalError then
    begin
         ErrPool := FEval.ErrPool;
    end;

    FEval.clearInfo;
  end;

  Compiler.clearSource;
  Compiler.isUse := false;
  Parser.clearBlocks;
  Parser.isUse := false;
  Self.__FILE__ := '';
end;

function TOrionEngine.getVersion(): AnsiString;
   var
   v1,v2,x: integer;
begin
  x := ORION_VERSION;
  if x < 0 then
  begin
      Result := '0.' + IntToStr(abs(x));
  end else begin
      if x > 99 then
      begin
          v1 := trunc(x/100);
      end else begin
          v1 := trunc(x/10);
      end;
      v2 := x - v1;
      Result := IntToStr(v1)+'.'+IntToStr(v2);
  end;
end;

{ TOrionEvalThread }

constructor TOrionEvalThread.Create;
begin
  inherited Create(True);
  FreeOnTerminate := true;
  FEval := TOriEval.create(true);
  FEval.code := TOpcodeArray.Create;
end;

destructor TOrionEvalThread.Destroy;
begin
  discardOpcodeS(FEval.code);
  FEval.code.Free;
  FEval.Free;
  inherited;
end;

procedure TOrionEvalThread.doCallBack;
begin
    Callback(Self, Self.Eval);
end;

procedure TOrionEvalThread.Execute;
begin
  Time := getTime();
  Self.Eval.Run;
  Self.Eval.clearInfo;
  Time := getTime - Time;
  
  if Assigned(Callback) then
  begin
    Synchronize( doCallBack );
  end;

  Terminate;
end;

procedure TOrionEvalThread.SetCallback(const Value: TOrionThreadCallback);
begin
  FCallback := Value;
end;

procedure TOrionEvalThread.SetEval(const Value: TOriEval);
begin
  FEval := Value;
end;

procedure TOrionEvalThread.SetTime(const Value: Integer);
begin
  FTime := Value;
end;

procedure TOrionEvalThread.toExit;
begin
  Self.Eval.toExit;
end;

end.
