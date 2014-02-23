unit ori_vmClasses;

// модуль реализации классов
//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils,
  ori_vmTypes,
  ori_vmValues,
  ori_vmTables,
  ori_Stack,
  ori_Types,
  ori_vmShortApi,
  ori_Errors,
  ori_StrConsts,
  ori_vmCrossValues,
  ori_HashList,
  ori_vmConstants,
  ori_Parser,
  ori_vmMemory;

  type    
    TOriMethod = record
      typ: TOriMethod_type;
      modifer: TOriMethod_modifer;
      ptr: Pointer;
      name: AnsiString;
      aClass: Pointer;
      isStatic: Boolean;
    end;
    POriMethod = ^TOriMethod;


    procedure unsetMethod(method: POriMethod); inline;

  type
    TOriClass = class(TObject)
        protected

        public
            evalX: Pointer;
            asObject: Boolean;
            methodHash: THashList;
            methodArr : array of POriMethod;
            //constList : TOriConsts;
            
            ref_count: Integer;
            parent: TOriClass;

            __call: POriMethod;
            __callStatic: POriMethod;
            __set : POriMethod;
            __get : POriMethod;
            __construct: POriMethod;
            __destruct: POriMethod;
            __toString: POriMethod;
            __clone   : POriMethod;


            // clone as new operation in php
            function doNew(): TOriClass;

            // проверяет, унаследован ли когда либо класс от aClass
            // return extends from aClass
            function InstanceOf(aClass: TOriClass): boolean;

            // get public method
            function GetAbsMethod(const Name: AnsiString): POriMethod;

            // get in class method
            function GetInMethod(const Name: AnsiString; inClass: TOriClass): POriMethod;

            // свойства и метода, все одно и тоже... смотрим typ
            // props and method, to see "typ" param
            function GetMethod(const Name: AnsiString): POriMethod;
            function AddMethod(const Name: AnsiString; const modifer: TOriMethod_modifer;
                      const typ: TOriMethod_type; const isStatic: boolean; const func: Pointer): POriMethod;
            function SetMethod(const Name: AnsiString; const modifer: TOriMethod_modifer;
                      const typ: TOriMethod_type; const isStatic: boolean; const func: Pointer): POriMethod;
            function SetMethodEx(const Name: AnsiString; const modifer: TOriMethod_modifer;
                      const typ: TOriMethod_type; const isStatic: boolean; const func: Pointer): POriMethod;

            function CallMethod(method: POriMethod; params: TOriMemoryStack = nil; const cnt: cardinal = 0;
                 Return: TOriMemory = nil; eval: Pointer = nil): Boolean;
            
            procedure SetConst(const Name: AnsiString; val: TOriMemory); overload;
            function SetConst(prop: PCodeProperty; val: TOriMemory): Boolean; overload;
            function SetProperty(prop: PCodeProperty; val: TOriMemory = nil): Boolean;

            procedure DestroyMethod(method: POriMethod);
            
            constructor Create(Extends: TOriClass = nil);
            destructor Destroy; override;
    end;

    procedure initClassSystem();
    procedure finalClassSystem();
    procedure addNamedClass(name: MP_String; aClass: TOriClass; ErrPool: TOriErrorPool);
    function findByName(const name: MP_String): TOriClass;
    function findByNameIndex(const name: MP_String): Integer;

    var
      ClassPtrs : Array of TOriClass;

implementation

      uses
        ori_vmUserFunc,
        ori_vmNativeFunc,
        ori_ManRes,
        ori_vmEval;

      var
      ClassHashTable: THashList;
      ClassNames: MP_ArrayString;

procedure initClassSystem();
begin
    ClassHashTable := THashList.create;
    SetLength(ClassNames,0);
    SetLength(ClassPtrs,0);
end;

procedure finalClassSystem();
   var
   i: integer;
begin
    ClassHashTable.Free;
    SetLength(ClassNames,0);
    for i := 0 to Length(ClassPtrs) - 1 do
        ClassPtrs[i].Free;
    SetLength(ClassPtrs,0);
end;

procedure addNamedClass(name: MP_String; aClass: TOriClass; ErrPool: TOriErrorPool);
   var
   id: integer;
begin
   name := LowerCase(name);
   id := ClassHashTable.getHashValueEx(name);
   if id > 0 then
   begin
      ErrPool.newError(errFatal, Format(MSG_ERR_CLASS_EXISTS,[name]), 0);
      exit;
   end;

   id := ClassHashTable.Counts;
   SetLength(ClassNames,id+1);
   SetLength(ClassPtrs, id+1);
   ClassNames[id] := name;
   ClassPtrs[id]  := aClass;

   ClassHashTable.setValue(name,id+1);
end;

function findByNameIndex(const name: MP_String): Integer;
begin
     Result := ClassHashTable.getHashValueEx(LowerCase(name))-1;
end;

function findByName(const name: MP_String): TOriClass;
   var
   id: integer;
begin
    id := findByNameIndex(name);
    if id = -1 then
        Result := nil
    else
        Result := ClassPtrs[id];
end;

{ TOriClass }

procedure unsetMethod(method: POriMethod);
  var
  r: TOriMemory;
begin
     case method^.typ of
        omtUser: dec(TUserFunc(method^.ptr).ref_count);
        omtProp,omtConst: begin
                 r := method^.ptr;
                 r.UnuseObjectAll;
                 r.Unset;
        end;
      end;
end;

function TOriClass.AddMethod(const Name: AnsiString; const modifer: TOriMethod_modifer;
  const typ: TOriMethod_type; const isStatic: boolean; const func: Pointer): POriMethod;
  var
  l: integer;
begin
   l := length(methodArr);
   SetLength(methodArr, l+1);
   new( Self.methodArr[l] );
   Self.methodArr[l]^.modifer := modifer;
   Self.methodArr[l]^.typ     := typ;
   Self.methodArr[l]^.ptr     := func;
   Self.methodArr[l]^.name    := Name;
   Self.methodArr[l]^.aClass  := Self;
   Self.methodArr[l]^.isStatic := isStatic;
   Self.methodHash.setValue(Name, l+1);

   case typ of
     omtUser: inc(TUserFunc(func).ref_count) ;
     //omtProp,omtConst: useVMValue(PVMValue(func));
   end;
   Result := Self.methodArr[l];
end;

function TOriClass.CallMethod(method: POriMethod;
                 params: TOriMemoryStack = nil; const cnt: cardinal = 0;
                 Return: TOriMemory = nil; eval: Pointer = nil): Boolean;
   var
   func: PNativeFunc;
   uFunc: TUserFunc;
   nFunc: TNativeProcedure;
begin
  case method^.typ of
      omtNative: begin
          func := method^.ptr;
          nFunc := TNativeProcedure(func^.func);
          callNativeFunc(nFunc, params, cnt, Return, eval);
          
          Result := true;
        end;
      omtUser : begin
          uFunc := TUserFunc(method^.ptr);
          uFunc.Invoke(params, cnt, Return);
          Result := true;
      end;
      else
        Result := false;
  end;
end;

constructor TOriClass.Create(Extends: TOriClass = nil);
begin
   asObject := false;
   parent := Extends;
   __call := nil;
   __callStatic := nil;
   __set  := nil;
   __get  := nil;
   __construct := nil;
   __destruct := nil;
   __toString := nil;
   evalX := nil;
   methodHash := THashList.Create;
end;

destructor TOriClass.Destroy;
  var
  l,i: integer;
begin
  l := length(methodArr);
  for i := 0 to l-1 do
  begin
     unsetMethod(Self.methodArr[i]);
     Dispose(Self.methodArr[i]);
  end;
  SetLength(Self.methodArr,0);
  methodHash.Free;

  if __call <> nil then DestroyMethod(__call);
  if __callStatic <> nil then DestroyMethod(__callStatic);
  if __construct <> nil then DestroyMethod(__construct);
  if __destruct <> nil then DestroyMethod(__destruct);
  if __clone <> nil then DestroyMethod(__clone);
  if __set <> nil then DestroyMethod(__set);
  if __get <> nil then DestroyMethod(__get);
  if __toString <> nil then DestroyMethod(__toString);

  inherited;
end;

procedure TOriClass.DestroyMethod(method: POriMethod);
begin
      unsetMethod(method);
      Dispose(method);
end;

function TOriClass.GetAbsMethod(const Name: AnsiString): POriMethod;
   var
   pr: TOriClass;
begin
   Result := GetMethod(Name);
   if (Result = nil) or (Result^.modifer <> ommPublic) then
   begin
      if Self.parent = nil then
      begin
          Result := nil;
          exit;
      end;
      pr := TOriClass(Self.parent);
      while True do
      begin
          Result := pr.GetMethod(Name);
          if (Result <> nil) and (Result^.modifer in [ommPublic,ommSuperPublic]) then exit;
          if pr.parent = nil then
          begin
              Result := nil;
              exit;
          end;
          pr := TOriClass(pr).parent;
      end;
   end;
end;

function TOriClass.GetInMethod(const Name: AnsiString; inClass: TOriClass): POriMethod;
 var
   pr: TOriClass;
   label 1;
begin
   Result := GetMethod(Name);
   if (Result = nil) then
   begin
      1:
      if Self.parent = nil then
      begin
          Result := nil;
          exit;
      end;
      pr := TOriClass(Self.parent);
      while True do
      begin
          Result := pr.GetMethod(Name);
          if (Result <> nil) then begin
          if inClass = nil then begin
            if Result^.modifer in [ommSuperPublic, ommPublic] then exit;
          end else
            if Result^.modifer in [ommPublic,ommProtected,ommSuperPublic] then exit;
          end;

          if pr.parent = nil then
          begin
              Result := nil;
              exit;
          end;
          pr := TOriClass(pr).parent;
      end;
   end else begin
      case Result^.modifer of
          ommPrivate: if Self <> inClass then goto 1;
          ommProtected: if inClass = nil then
                          Result := nil
                        else
                          if not inClass.InstanceOf(Self) then goto 1;
      end;
   end;
end;

function TOriClass.GetMethod(const Name: AnsiString): POriMethod;
  var
  id: Integer;
begin
  id := methodHash.getHashValueEx(Name)-1;
  if id = -1 then
    Result := nil
  else
    Result := Self.methodArr[id];
end;


function TOriClass.InstanceOf(aClass: TOriClass): boolean;
  var
  pr: TOriClass;
begin
  Result := (Self = aClass);
  if not Result then
  begin
       pr := Self.parent;
       while True do
       begin
          if pr = aClass then
          begin
              Result := true;
              exit;
          end;
          pr := pr.parent;
       end;
  end else
    exit;
  Result := false;
end;

function TOriClass.doNew: TOriClass;
begin
  Result := TOriClass.Create(Self);
  Result.asObject := true;
  if __construct <> nil then
      Self.CallMethod(__construct);

  Result.__destruct := Self.__destruct;
  Result.__toString := Self.__toString;
  Result.__clone    := Self.__clone;
  Result.__call := Self.__call;
  Result.__callStatic := Self.__callStatic;
  Result.__get  := Self.__get;
  Result.__set  := Self.__set;
end;

procedure TOriClass.SetConst(const Name: AnsiString; val: TOriMemory);
begin
    SetMethod(Name, ommSuperPublic, omtConst, true, TOriMemory.GetMemory(val));
end;

function TOriClass.SetConst(prop: PCodeProperty; val: TOriMemory): Boolean;
begin
   Result := SetMethodEx(prop^.name,
                         prop^.modifer,
                         omtConst, true, TOriMemory.GetMemory(val) )
              <>
             nil;
end;

function TOriClass.SetProperty(prop: PCodeProperty; val: TOriMemory = nil): Boolean;
   var
   r: TOriMemory;
begin
   if val <> nil then
      r := TOriMemory.GetMemory(val)
   else
      r := TOriMemory.GetMemory(mvtNull);

   Result := SetMethodEx(prop^.name, prop^.modifer, omtProp, prop^.isStatic, r)
              <>
             nil;
end;

function TOriClass.SetMethod(const Name: AnsiString; const modifer: TOriMethod_modifer;
                      const typ: TOriMethod_type; const isStatic: boolean; const func: Pointer): POriMethod;
begin
  Result := Self.GetMethod(Name);
  if Result = nil then
      Result := Self.AddMethod(Name, modifer, typ, isStatic, func)
  else begin
      unsetMethod(Result);
      
      Result^.typ := typ;
      Result^.modifer := modifer;
      Result^.ptr := func;
      case typ of
        omtUser: inc(TUserFunc(func).ref_count);
        //omtProp,omtConst: useVMValue(PVMValue(func));
      end;
  end;
end;

function TOriClass.SetMethodEx(const Name: AnsiString; const modifer: TOriMethod_modifer;
                      const typ: TOriMethod_type; const isStatic: boolean; const func: Pointer): POriMethod;
begin
  Result := Self.GetMethod(Name);
  if Result = nil then
      Result := Self.AddMethod(Name, modifer, typ, isStatic, func)
  else
      Result := nil;
end;

end.
