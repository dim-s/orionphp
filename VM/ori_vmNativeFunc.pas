unit ori_vmNativeFunc;

// модуль дл€ хранени€ байт-кода функций объ€вленных пользователем
//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils,
  ori_Types,
  ori_vmTypes,
  ori_OpGen,
  ori_Errors,
  ori_vmCrossValues,
  ori_vmValues,
  ori_StrConsts,
  ori_HashList,
  ori_Stack,
  ori_vmShortApi,
  ori_vmMemory;

  type
    TNativeProcedure =
      procedure(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;

  type
    TNativeFunc = record
        name  : MP_String;
        cnt   : Cardinal;
        func  : pointer;
        id    : Cardinal;
    end;

    PNativeFunc = ^TNativeFunc;

    procedure addNativeModule(const ptr: pointer);
    procedure addNativeFunc(const name: MP_String; const cnt: cardinal; const ptr: pointer);
    
    function findByName(const name: MP_String): PNativeFunc;
    function findByNameIndex(const name: MP_String): Integer;
    function findByIndex(const id: cardinal): PNativeFunc;
    procedure initNativeFuncSystem();
    procedure finalNativeFuncSystem();
    function getErrorPool(const eval: Pointer): TOriErrorPool;


    procedure callNativeFunc(func: TNativeProcedure;
                 params: TOriMemoryStack = nil; const cnt: cardinal = 0;
                 Return: TOriMemory = nil; eval: Pointer = nil);

    var
      Native_Functions: array of PNativeFunc;

implementation

    uses
      ori_vmCompiler,
      ori_vmEval,
      ori_ManRes;

    type
    TmProc = function (const init: boolean): byte;

    var
    FuncHashTable: THashList;
    ModulesProcs: array of TmProc;


procedure callNativeFunc(func: TNativeProcedure;
                 params: TOriMemoryStack = nil; const cnt: cardinal = 0;
                 Return: TOriMemory = nil; eval: Pointer = nil);
   var
   dReturn: TOriMemory;
   i: integer;
begin
    if Return <> nil then
      dReturn := Return;

    params.UseObjectAll;

    func(params, cnt, dReturn, eval);
    
    params.UnuseObjectAll;
end;

function getErrorPool(const eval: Pointer): TOriErrorPool;
begin
        Result := TOriEval(eval).ErrPool;
end;

procedure initNativeFuncSystem();
   var
   i: integer;
   mProc: TmProc;
begin
   if length(ModulesProcs) > 0 then
   for i := 0 to length(ModulesProcs)-1 do
   begin
        mProc := ModulesProcs[i];
        mProc(true);
   end;
end;

procedure finalNativeFuncSystem();
  var
  i: integer;
  mProc: TmProc;
begin
    if length(ModulesProcs) > 0 then
    begin
         for i := 0 to length(ModulesProcs)-1 do
         begin
              mProc := ModulesProcs[i];
              mProc(false);
         end;
    end;
end;

function findByNameIndex(const name: MP_String): Integer;
begin
     Result := ori_vmNativeFunc.FuncHashTable.getHashValueEx(name)-1;
end;

function findByName(const name: MP_String): PNativeFunc;
   var
   id: integer;
begin
    id := findByNameIndex(name);
    if id = -1 then
        Result := nil
    else
        Result := ori_vmNativeFunc.Native_Functions[id];
end;

procedure addNativeModule(const ptr: pointer);
begin

      SetLength(ModulesProcs,length(ModulesProcs)+1);
      ModulesProcs[high(ModulesProcs)] := TmProc (ptr);
end;

procedure addNativeFunc(const name: MP_String; const cnt: cardinal; const ptr: pointer);
  var
  func: PNativeFunc;
begin
    New(func);
    func^.name := AnsiLowerCase(name);
    func^.func := ptr;
    func^.cnt  := cnt;

    SetLength(Native_Functions, length(Native_Functions)+1);
    Native_Functions[high(Native_Functions)] := func;
    Native_Functions[high(Native_Functions)]^.id := high(Native_Functions);
    FuncHashTable.setValue(name,high(Native_Functions)+1);
end;

procedure setNativeFunc(const name: MP_String; const cnt: cardinal; const ptr: pointer);
  var
  id: integer;
begin
    id := ori_vmNativeFunc.findByNameIndex(name);
    if id > -1 then
    begin
        Native_Functions[id]^.func := ptr;
        Native_Functions[id]^.cnt  := cnt;
        //Functions[id]^.paramAsVar := asVars;
    end else
      addNativeFunc(name,cnt,ptr);
end;


function findByIndex(const id: cardinal): PNativeFunc;
begin
  if id < length(Native_Functions) then
      Result := Native_Functions[id]
  else
      Result := nil;
end;


initialization
   SetLength(Native_Functions,0);
   FuncHashTable := THashList.create;



end.
