unit ori_vmMemory;

// IN PROGRESS
// Модуль ячейка памяти
{$ifdef fpc}
  {$mode delphi}
{$endif}
{$H+}

interface

uses
  SysUtils, Classes,
  ori_StrUtils,
  ori_Types,
  ori_vmTypes,
  ori_vmValues,
  ori_FastArrays,
  ori_HashList
  ;
  
  const
    mvtInteger = 0;
    mvtDouble  = 1;
    mvtFloat   = mvtDouble;
    mvtString  = 2;
    mvtBoolean = 3;
    mvtNull    = 4;
    mvtNone    = 5;
    mvtPointer = 6;
    mvtHash    = 7;
    mvtObject  = 8;
    mvtFunction= 9;
    mvtMethod  = 10;
    mvtNativeFunc = 11;

    // +stack
    mvtHashValue = 12;
    mvtLink      = 13;
    mvtPChar     = 14;
    mvtWord      = 15;
    mvtVariable  = 16;
    mvtGlobalVar = 17;

  type
    MVT_Type = Byte;
    

  type
    TOriCaseMem = packed record
        Str : MP_String;
        case longint of
          0: (lval: MP_Integer);
          1: (dval: MP_Float);
          2: (bval: Boolean);
          3: (ptr : pointer);
          4: (pchar: MP_PChar)
        end;

  type
    TOriMemory = class(TObject)
  public
          Typ: Byte;  // тип значения
          Ref_count: Integer; // кол-во ссылающихся на значение
          ID: Integer;

          Table: Pointer;
          Mem: TOriCaseMem;

          class function GetMemory: TOriMemory; overload;
          class function GetMemory(val: TOriMemory): TOriMemory; overload; inline;
          class function GetMemory(const typ: MVT_Type): TOriMemory; overload; inline;
          class function GetMemory(const Int: MP_Int): TOriMemory; overload; inline;
          
          class procedure Initialize;
          class procedure Finalize;

          procedure Unset;
          procedure Free;
          procedure Clear;

          procedure Use; inline;
          procedure UnUse; inline;

          procedure UseObject;
          procedure UnuseObject;

          procedure UseObjectAll;  // recursive
          procedure UnuseObjectAll;  // recursive

          function IsString: Boolean; inline;
          function IsInteger: Boolean; inline;
          function IsFloat: Boolean; inline;
          function IsBoolean: Boolean; inline;
          function IsNull: Boolean; inline;
          function IsRoot: Boolean; inline; // может ли содержать ссылки на другие значения
          function IsVar: Boolean; inline;
          function IsArray: Boolean; inline;

          function IsRealString: Boolean; inline;
          function GetRealType: MVT_Type; inline;

          function Empty: Boolean; inline;
          function IsSet: Boolean; inline;

          function AsString: MP_String;
          function AsInteger: MP_Int;
          function AsFloat: MP_Float;
          function AsBoolean: Boolean;
          function AsChar: MP_Char;
          function AsMemory: TOriMemory; inline;
          function AsRealMemory: TOriMemory; inline;  // for stack
          function AsPtrMemory: TOriMemory; inline;

          procedure ValL(const Lval: MP_Int); overload; inline;
          procedure ValF(const Dval: MP_Float); overload; inline;
          procedure Val(const Bval: Boolean); overload; inline;
          procedure Val(const Str: MP_String); overload; {$IFDEF FPC}{$ELSE}inline;{$ENDIF}
          procedure ValPtr(const Ptr: Pointer); overload; inline;
          procedure Val(value: TOriMemory; const Clear: Boolean); overload;
          procedure ValTable(ptr: Pointer);
          procedure ValFunction(ptr: Pointer);
          procedure ValObject(ptr: Pointer);
          procedure ValNull; inline;
          procedure ValType(const Typ: MVT_Type); inline;
          procedure ValWord(const Str: MP_String); {$IFDEF FPC}{$ELSE}inline;{$ENDIF}
          procedure ValCnst(var Cnst);
          procedure Assign(M: TOriMemory);

          function EqualTyped(M: TOriMemory): Boolean;
    end;

    TOriMemoryArray = class(TPtrArray)
        protected
          function GetValue(Index: Integer): TOriMemory; inline;
          procedure SetValue(Index: Integer; Val: TOriMemory); inline;
        public
          Ref_Count: Integer;
          Seek: Integer;

          function Push: TOriMemory; inline;
          function Pop: TOriMemory; inline;
          procedure Discard; inline;
          procedure Unset(Index: Integer);
          procedure UnsetAll;
          procedure NoneAll;
          procedure FreeAll;

          procedure UseObjectAll; // ref_count+1 of objective of all elements
          procedure UnuseObjectAll; // ref_count-1 of objective ...d

          function Next: TOriMemory;
          function Prev: TOriMemory;
          function Current: TOriMemory; inline;
          function First: TOriMemory;
          function Last: TOriMemory;

          property Value[Index: Integer]: TOriMemory read GetValue write SetValue; default;

          constructor Create;
    end;

    TOriMemoryStack = class(TOriMemoryArray)
        private
            RealStackSize: Integer;
        public
            Start: Integer;
            function Push: TOriMemory;
            function Pop: TOriMemory;
            function GetTop: TOriMemory; inline;
            procedure Discard;
            procedure DiscardAll;

            constructor Create;
    end;


    TCallBackScan = procedure ( Mem: TOriMemory );
    procedure ScanMemoryList(List: TOriMemoryArray; callback: TCallBackScan; Scaned: TPtrArray = nil);


implementation

  Uses
    ori_vmTables, ori_vmClasses, ori_vmUserFunc, ori_Parser;

  Var
    MemoryList_Free: TOriMemoryArray;
    MemoryList_Used: TOriMemoryArray;

    Scaned_List: TPtrArray;

function GetScanList: TPtrArray;
begin
  if Scaned_List.Count > 0 then
  begin
      Result := Scaned_List.Pop;
      Result.Clear;
  end else
      Result := TPtrArray.Create;
end;

procedure ScanMemoryList(List: TOriMemoryArray; callback: TCallBackScan; Scaned: TPtrArray = nil);
   var
   i: integer;
   toFree: Boolean;
begin
    toFree := false;
    for i := 0 to List.Count - 1 do
    begin
        with List[ i ] do begin
          if IsRoot then begin
              if Scaned = nil then begin
                Scaned := GetScanList;
                toFree := true;
              end;

              if not Scaned.IsExists(Mem.ptr) then
              begin
                  Scaned.Add( Mem.ptr );
                  case Typ of
                    mvtHash  :  ScanMemoryList( TOriMemoryArray(Mem.ptr), callback, Scaned );
                    mvtObject:  // ScanMemoryList( TOriMemoryArray(Mem.ptr) );  --TODO
                  end;
                  callback( List[ i ] );
              end;
          end else
              callback( List[ i ] );
        end;
    end;
    if toFree then begin
      Scaned_List.Add( Scaned );
    end;
end;

{ TOriMemory }

procedure TOriMemory.Clear;
begin
    if IsString then
      System.Finalize(Mem.Str);

    ValType(mvtNull);
end;

function TOriMemory.Empty: Boolean;
begin
  Result := not AsBoolean;
end;

function TOriMemory.EqualTyped(M: TOriMemory): Boolean;
begin
  if Self.typ <> M.typ then
        Result := false
    else begin
        case Self.typ of
            mvtInteger: Result := Self.mem.lval = M.Mem.lval;
            mvtDouble :  Result := Self.mem.dval = M.Mem.dval;
            mvtBoolean: Result := Self.mem.bval = M.Mem.bval;
            mvtString : Result := Self.mem.str = M.Mem.str;
            mvtPChar  : Result := Self.mem.PChar = M.Mem.PChar;
            mvtHash,mvtObject,mvtFunction,mvtPointer: Result := Self.mem.ptr = M.Mem.ptr;
            else
              Result := true;
        end;
    end;
end;

class procedure TOriMemory.Finalize;
begin
  MemoryList_Free.Free;
  MemoryList_Used.Free;
  Scaned_List.Free;
end;

class procedure TOriMemory.Initialize;
begin
  MemoryList_Free := TOriMemoryArray.Create();
  MemoryList_Used := TOriMemoryArray.Create();

  MemoryList_Used.NewSize(100000);
  Scaned_List := TPtrArray.Create;
end;

function TOriMemory.IsArray: Boolean;
begin
  Result := Typ = mvtHash;
end;

function TOriMemory.IsBoolean: Boolean;
begin
  Result := Typ = mvtBoolean;
end;

function TOriMemory.IsFloat: Boolean;
begin
  Result := Typ = mvtDouble;
end;

function TOriMemory.IsInteger: Boolean;
begin
  Result := Typ = mvtInteger;
end;

function TOriMemory.IsNull: Boolean;
begin
  Result := Typ = mvtNull;
end;

function TOriMemory.IsRealString: Boolean;
begin
  case Typ of
    mvtString, mvtPChar: Result := true;
    mvtVariable, mvtGlobalVar: Result := AsMemory.IsString;
    mvtPointer: Result := AsMemory.IsRealString;
  end;
end;

function TOriMemory.IsRoot: Boolean;
begin
  Result := Typ in [mvtHash, mvtObject];
end;

function TOriMemory.IsSet: Boolean;
begin
  Result := Typ <> mvtNone;
end;

function TOriMemory.IsString: Boolean;
begin
  Result := (Typ = mvtString){ or (Typ = mvtPChar)};
end;

function TOriMemory.IsVar: Boolean;
begin
  Result := Typ in [mvtVariable, mvtGlobalVar];  
end;

function TOriMemory.AsBoolean: Boolean;
begin
    case Typ of
        mvtInteger: Result := Mem.lval <> 0;
        mvtDouble : Result := Mem.dval <> 0;
        mvtBoolean: Result := Mem.bval;
        mvtString: Result := (Mem.str <> '') and (Mem.str <> '0');
        mvtHash : Result := TOriTable(Mem.ptr).count > 0;
        mvtFunction,mvtObject: Result := True;
        mvtPointer: Result := AsMemory.AsBoolean;
        mvtVariable,mvtGlobalVar: Result := AsMemory.AsBoolean;
        else Result := false;
    end;
end;

function TOriMemory.AsChar: MP_Char;
begin
   case typ of
        mvtInteger: Result := MP_String(IntToStr( mem.lval ))[1];
        mvtDouble : Result := MP_String(FloatToStr( mem.dval ))[1];
        mvtBoolean: if mem.bval then Result := '1' else Result := ' ';
        mvtString : Result := Mem.str[1];
        mvtPChar  : Result := Mem.pchar^;
        mvtVariable, mvtGlobalVar: Result := AsMemory.AsString[1];
        else Result := ' ';
    end;
end;

function TOriMemory.AsFloat: MP_Float;
begin
   case Typ of
        mvtInteger: Result := Mem.lval;
        mvtDouble : Result := Mem.dval;
        mvtBoolean: if Mem.bval then Result := 1 else Result := 0;
        mvtString: Result := StrToFloatDef(Mem.str, 0);
        mvtPointer: Result := AsMemory.AsFloat;
        mvtVariable,mvtGlobalVar: Result := AsMemory.AsFloat;
        mvtFunction: Result := 1;
        else Result := 0;
    end;
end;

function TOriMemory.AsInteger: MP_Int;
begin
   case Typ of
        mvtInteger: Result := Mem.lval;
        mvtDouble : Result := Trunc( Mem.dval );
        mvtBoolean: if Mem.bval then Result := 1 else Result := 0;
        mvtString: Result := StrToIntDef( Mem.str, 0);
        mvtPointer: Result := AsMemory.AsInteger;
        mvtVariable,mvtGlobalVar: Result := AsMemory.AsInteger;
        mvtFunction: Result := 1;
        else Result := 0;
    end;
end;

function TOriMemory.AsMemory: TOriMemory;
begin
  Result := Mem.Ptr;
end;

function TOriMemory.AsPtrMemory: TOriMemory;
begin
  if Typ = mvtPointer then
    Result := AsMemory
  else
    Result := Self;
end;

function TOriMemory.AsRealMemory: TOriMemory;
begin
  if AsMemory.Typ = mvtPointer then
    Result := AsMemory.AsMemory
  else
    Result := AsMemory;
end;

procedure TOriMemory.Assign(M: TOriMemory);
begin
  Typ := M.Typ;
  ID  := M.ID;
  Table := M.Table;
  Ref_count := M.Ref_count;
  Mem := M.Mem;
end;

function TOriMemory.AsString: MP_String;
begin
   case Typ of
        mvtInteger: Result := IntToStr(Mem.lval);
        mvtDouble : Result := FloatToStr(Mem.dval);
        mvtBoolean: if Mem.bval then Result := '1' else Result := '';
        mvtString: Result := Mem.str;
        mvtHash   : Result := 'Array';
        mvtFunction: Result := 'Function';
        mvtPointer,mvtVariable,mvtGlobalVar: Result := TOriMemory(Mem.ptr).AsString;
        else Result := '';
    end;
end;

class function TOriMemory.GetMemory: TOriMemory;
begin
  if MemoryList_Free.Count > 0 then
      Result := MemoryList_Free.Pop
  else begin
      Result := TOriMemory.Create;
      MemoryList_Used.Add( Result );
  end;

  Result.Ref_count := 1;
  Result.Table     := nil;
  Result.Typ       := mvtNone;
end;


class function TOriMemory.GetMemory(val: TOriMemory): TOriMemory;
begin
  Result := TOriMemory.GetMemory;
  Result.Val( val,true );
end;

class function TOriMemory.GetMemory(const Int: MP_Int): TOriMemory;
begin
  Result := TOriMemory.GetMemory;
  Result.ValL(Int);
end;

function TOriMemory.GetRealType: MVT_Type;
begin
  case Typ of
      mvtVariable, mvtGlobalVar: Result := AsMemory.Typ;
      else
        Result := Typ;
  end;
end;

procedure TOriMemory.Free;
begin
  Clear;
  MemoryList_Free.Add( Self );
end;

procedure TOriMemory.Unset;
begin
   UnUse;
   if Ref_count < 1 then
      Free;
end;


procedure TOriMemory.UnUse;
begin
  Dec( Ref_count );
end;

procedure TOriMemory.UnuseObject;
begin
   case Typ of
     mvtHash: TOriTable( Mem.ptr ).Unuse();
     mvtObject: ;
     mvtFunction: TUserFunc( Mem.ptr ).Unuse();
   end;
end;

procedure TOriMemory.UnuseObjectAll;
begin
   case Typ of
     mvtHash: begin
                 TOriTable( Mem.ptr ).UnuseObjectAll();
                 TOriTable( Mem.ptr ).Unuse;
              end;
     mvtObject: ;
     mvtFunction: TUserFunc( Mem.ptr ).Unuse();
     {mvtPointer: begin
          AsMemory.UnuseObjectAll;
     end;}
   end;
end;

procedure TOriMemory.Use;
begin
  Inc( Ref_count );
end;

procedure TOriMemory.UseObject;
begin
   case Typ of
     mvtHash: TOriTable( Mem.ptr ).Use();
     mvtObject: ;
     mvtFunction: TUserFunc( Mem.ptr ).Use();
   end;
end;

procedure TOriMemory.UseObjectAll;
begin
  case Typ of
     mvtHash: begin
                 TOriTable( Mem.ptr ).UseObjectAll();
                 TOriTable( Mem.ptr ).Use;
              end;
     mvtObject: ;
     mvtFunction: TUserFunc( Mem.ptr ).Use();
   end;
end;

procedure TOriMemory.ValF(const Dval: MP_Float);
begin
   ValType(mvtDouble);
   Mem.dval := Dval;
end;

procedure TOriMemory.ValL(const Lval: MP_Int);
begin
   ValType(mvtInteger);
   Mem.lval := Lval;
end;


procedure TOriMemory.Val(const Bval: Boolean);
begin
   ValType(mvtBoolean);
   Mem.Bval := Bval;
end;

procedure TOriMemory.Val(const Str: MP_String);
begin
   ValType(mvtString);
   Mem.Str := Str;
end;

procedure TOriMemory.Val(value: TOriMemory; const Clear: Boolean);
begin
 if clear then
 begin
   //Self.UnuseObject;
   Self.Clear;
 end;

   case value.Typ of
     mvtInteger: ValL( value.Mem.lval );
     mvtDouble: ValF( value.Mem.dval );
     mvtString: Val( value.Mem.Str );
     mvtBoolean: Val( value.Mem.bval );
     mvtHash: ValTable( value.Mem.ptr );
     mvtObject: ValObject( value.Mem.ptr );
     mvtFunction: ValFunction( value.Mem.ptr );
     mvtNull: ValType(mvtNull);
     mvtNone: ValType(mvtNone);
     mvtPointer: begin ValPtr( value.Mem.ptr ); ValType(mvtPointer);  end;
     mvtVariable,mvtGlobalVar: Val(value.AsMemory, clear) ;
     mvtMethod: ;
     mvtLink: begin
        if value.Mem.ptr <> Self then
        begin
        Value.AsMemory.Use;
        Self.ValPtr( Value.Mem.ptr );
        Self.Typ := mvtPointer;
        end;
     end;
   end;
end;

procedure TOriMemory.ValCnst(var Cnst);
begin
with TVMConstant(Cnst) do
  case typ of
        mvtInteger: Self.ValL(lval);
        mvtDouble: Self.ValF(dval);
        mvtString: Self.Val(str);
        mvtBoolean: Self.Val(bval);
        mvtHash: begin
            Self.ValTable( TOriTable.CreateInManager );
            TOriTable(Self.Mem.ptr).Use;
        end;
        else
          Self.ValType(mvtNull);
  end;
end;

procedure TOriMemory.ValPtr(const Ptr: Pointer);
begin
   Mem.ptr := Ptr;
end;

procedure TOriMemory.ValFunction(ptr: Pointer);
begin
  ValType(mvtFunction); ValPtr(ptr);
end;

procedure TOriMemory.ValNull;
begin
  ValType(mvtNull);
end;

procedure TOriMemory.ValObject(ptr: Pointer);
begin
  ValType(mvtObject); ValPtr(ptr);
end;

procedure TOriMemory.ValTable(ptr: Pointer);
begin
  ValType(mvtHash); ValPtr(ptr);
end;

procedure TOriMemory.ValType(const Typ: MVT_Type);
begin
  Self.Typ := Typ;
end;

procedure TOriMemory.ValWord(const Str: MP_String);
begin
  ValType(mvtWord);
  Mem.Str := Str;
end;


class function TOriMemory.GetMemory(const typ: MVT_Type): TOriMemory;
begin
  Result := GetMemory;
  Result.ValType( typ );
end;

{ TOriMemoryArray }


function TOriMemoryArray.Pop: TOriMemory;
begin
  Result := inherited Pop;
end;

function TOriMemoryArray.Prev: TOriMemory;
begin
   Dec(Seek);
   Result := Current;
end;

function TOriMemoryArray.Push: TOriMemory;
begin
  Result := TOriMemory.GetMemory;
  Self.Add(Result);
end;

constructor TOriMemoryArray.Create;
begin
  inherited;
  Self.Ref_count := 0;
  Seek := 0;
end;

function TOriMemoryArray.Current: TOriMemory;
begin
  if (Seek > -1) and (Seek < Count) then
     Result := Self[ Seek ]
  else
     Result := nil;
end;

procedure TOriMemoryArray.Discard;
begin
  Self[ Count - 1 ].Free;
  Self.Pop;
end;

function TOriMemoryArray.First: TOriMemory;
begin
  Seek := 0;
  if Count > 0 then
     Result := Self[ Seek ]
  else
     Result := nil;
end;

procedure TOriMemoryArray.FreeAll;
  procedure callFree(mem: TOriMemory);
  begin
      mem.Free;
  end;
begin
   ScanMemoryList(Self, @callFree);
  {for i := 0 to Count - 1 do
      Self[ i ].Free;}
end;

function TOriMemoryArray.GetValue(Index: Integer): TOriMemory;
begin
  Result := TOriMemory( Self.Values^[ Index ] );
end;


function TOriMemoryArray.Last: TOriMemory;
begin
  Seek := Count - 1;
  if Count > 0 then
  begin
      Seek := Count - 1;
      Result := Self[ Seek ];
  end else
      Result := nil;
end;

function TOriMemoryArray.Next: TOriMemory;
begin
  Inc(Seek);
  Result := Current;
end;

procedure TOriMemoryArray.NoneAll;
 procedure callNoneAll(mem: TOriMemory);
 begin
      if mem.IsString then
          Finalize(Mem.Mem.Str);
      Mem.Typ := mvtNone;
 end;
 var
 i: integer;
begin
 for i := 0 to Count - 1 do
 with Self[ i ] do begin
  if IsString then
    System.Finalize( Mem.Str );
   Typ := mvtNone; 
 end;
end;

procedure TOriMemoryArray.SetValue(Index: Integer; Val: TOriMemory);
begin
  Self.Values^[ Index ] := Val;
end;

procedure TOriMemoryArray.Unset(Index: Integer);
begin
   Self[ Index ].Unset;
   Delete( Index );
end;

procedure TOriMemoryArray.UnsetAll;
  procedure callUnset(mem: TOriMemory);
  begin
      mem.Unset;
  end;
begin
   ScanMemoryList(Self, @callUnset);
end;

procedure TOriMemoryArray.UnuseObjectAll;

  procedure callUnuseObjectAll(mem: TOriMemory);
  begin
      mem.UnuseObject;
  end;
begin
  ScanMemoryList(Self, @callUnuseObjectAll);
end;

procedure TOriMemoryArray.UseObjectAll;
  procedure callUseObjectAll(mem: TOriMemory);
  begin
      mem.UseObject;
  end;
begin
  ScanMemoryList(Self, @callUseObjectAll);
end;

{ TOriMemoryStack }

constructor TOriMemoryStack.Create;
begin
    inherited Create;
    RealStackSize := 0;
end;

procedure TOriMemoryStack.Discard;
begin
    Dec( Count );
end;

procedure TOriMemoryStack.DiscardAll;
begin
    Count := 0;
end;

function TOriMemoryStack.GetTop: TOriMemory;
begin
   Result := Value[ Count - 1 ];
end;

function TOriMemoryStack.Pop: TOriMemory;
begin
    Result := GetTop;
    Dec( Count );
end;

function TOriMemoryStack.Push: TOriMemory;
begin
    if Count >= RealStackSize then begin
      Result := TOriMemory.Create;
      Add( Result );
      Inc(RealStackSize);
    end
    else begin
      Result := Value[ Count ];
      Inc(Count);
    end;
end;

initialization
  TOriMemory.Initialize;

finalization
  TOriMemory.Finalize;

end.
