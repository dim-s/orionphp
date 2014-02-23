unit ori_vmTables;

{$H+}

{$ifdef fpc}
{$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils,
  ori_StrUtils,
  ori_vmTypes,
  ori_vmValues,
  ori_HashList,
  ori_Types,
  ori_Hash32,
  ori_FastArrays,
  ori_vmMemory;

  type
    TOriTable = class(TOriMemoryArray)
        private
          function GetValue(const Index: AnsiString): TOriMemory;
          procedure SetValue(const Index: AnsiString; const Value: TOriMemory);
        public
          Names: TStringArray;
          HashList: THashList;
          LastNum : Integer;
          inManager: Boolean;

          class function CreateInManager: TOriTable;

          procedure FreeToManager; // удалить таблицу и закешировать в менеджере

          procedure Use;
          procedure Unuse;
          property Value[const Index: AnsiString]: TOriMemory read GetValue write SetValue; default;

          function Clone(const recursive: Boolean = true): TOriTable;
          procedure Add(const Index: AnsiString; M: TOriMemory); overload;
          procedure Add(const Index: AnsiString; M: TOriMemory; const Check: Boolean); overload;
          procedure Add(M: TOriMemory); overload; inline;


          procedure Delete(const Index: AnsiString); overload;
          procedure Delete(const Id: Integer); overload;
                           
          procedure Clear;
          constructor Create;
          destructor Destroy;

          function GetCreateValue(const Index: AnsiString): TOriMemory;

          function byPointer(ptr: Pointer): Integer;
          function byName(const name: MP_String): TOriMemory;
          function byNameIndex(const name: MP_String): integer; inline;
          function byNameIntIndex(const name: MP_Int): integer;
    end;

  procedure tryHashTableFree(Table: TOriTable); inline;

implementation

  uses ori_ManRes, ori_Stack;

procedure tryHashTableFree(Table: TOriTable);
begin
    with Table do
    if not inManager then
    begin
       dec(Table.Ref_Count);
       MANHashes.Add( Table );
    end;
end;


procedure TOriTable.Clear;
begin
  LastNum := -1;

  if Count > 0 then
  begin
      Names.CacheClear;
      CacheClear;
      HashList.Clear;
  end;

  //inherited Clear;
end;

function TOriTable.Clone(const recursive: Boolean = true): TOriTable;
  var
  i,j: integer;
begin
   Result := TOriTable.CreateInManager;
   Result.Count    := Self.Count;
   Result.LastNum  := Self.LastNum;

   Result.Names.DoClone( Self.Names );
   Result.SetLength(Self.count);

   for i := 0 to Self.Count - 1 do
   begin
        Result[i] := TOriMemory.GetMemory(mvtNull);
        with Result[i] do
        begin
             Table := Result;
             if recursive and (Self[i].typ = mvtHash) then
                ValTable( TOriTable(Self[i].Mem.ptr).Clone )
             else begin
                Val( Self[i],true );
                //UseObjectAll;
                //assignVMValue(PVMValue(Self.Values.V^[i]), PVMValue(Result.Values.V^[i]));
                //useVMValue(PVMValue(Result.Values.V^[i]));
             end;

        end;
   end;

   //Result.Hashes := Self.Hashes.clone;
   Result.HashList.doClone(Self.HashList);
end;


{ TOriMTable }

procedure TOriTable.Add(const Index: AnsiString; M: TOriMemory);
begin
      HashList.setValue( Index, Count+1 );
      Names.Add( Index );
      inherited Add( M );
      M.Table := Self;
end;

procedure TOriTable.Add(const Index: AnsiString; M: TOriMemory; const Check: Boolean);
   var
   id: integer;
begin
      Add(Index, M);
      if Check then
      if is_number(Index) = 1 then
      begin
          id := StrToIntDef(Index,0);
          if id > Self.LastNum then
            Self.LastNum := id;
      end;
end;

procedure TOriTable.Add(M: TOriMemory);
begin
   Inc(Self.LastNum);
   Add(IntToStr(LastNum), M);
end;

function TOriTable.byName(const name: MP_String): TOriMemory;
begin

end;

function TOriTable.byNameIndex(const name: MP_String): integer;
begin
    Result := HashList.getHashValueEx(name) - 1;
end;

function TOriTable.byNameIntIndex(const name: MP_Int): integer;
begin

end;

function TOriTable.byPointer(ptr: Pointer): Integer;
begin
  for Result := 0 to Count - 1 do
    if ptr = Values^[Result] then
      Exit;
  Result := -1;
end;

constructor TOriTable.Create;
begin
   HashList := THashList.Create;
   Names    := TStringArray.Create;
   LastNum  := -1;
end;

class function TOriTable.CreateInManager: TOriTable;
begin
  if MANHashes_f.Count > 0 then begin
      Result := TOriTable(MANHashes_f.Pop);
      Result.UnsetAll;
      Result.Clear;
  end
  else
     Result := TOriTable.Create;

  Result.ref_count := 0;
  // запрос на удаление таблицы,
  // если при следующей итерации на нее будет ссылаться < 1 сущности
  // она автоматом уничтожится
  Result.inManager := false;
  MANHashes.Add( Result );
end;

procedure TOriTable.Delete(const Index: AnsiString);
   var
   id, i: integer;
begin
   id := HashList.getHashValueEx(Index);
   if id <> 0 then begin
      Self[ id - 1 ].UnuseObjectAll;

      Names.Delete( id - 1 );
      HashList.delValue( Index );
      Unset( id - 1 );
      for i := id to Count - 1 do
         HashList.decValue(Names.Values^[i]);
   end;
end;

procedure TOriTable.Delete(const Id: Integer);
  var
  i: integer;
begin
   if id <> 0 then begin
      inherited Delete(id);
      HashList.delValue( Names.Values^[id] );
      Names.Delete( id );
      Unset( id );
      for i := id to Count - 1 do
         HashList.decValue(Names.Values^[i]);
   end;
end;

destructor TOriTable.Destroy;
begin
   HashList.Free;
   Names.Free;
end;

procedure TOriTable.FreeToManager;
begin
    if not inManager and not MANHashes_f.IsExists(Self) then
    begin
       UnsetAll;
       Clear;
       //assert( not MANHashes_f.IsExists(Table),'hashTableFree: IsExists(Table)' );
       if not MANHashes.IsExists( Self ) then
          MANHashes.Add( Self );
    end;
end;

function TOriTable.GetCreateValue(const Index: AnsiString): TOriMemory;
  var
  id: integer;
begin
   id := HashList.getHashValueEx(Index);
   if id = 0 then
   begin
       Result := TOriMemory.GetMemory(mvtNull);
       Add(Index, Result);
   end else
      Result := Values^[ id - 1 ];
end;

function TOriTable.GetValue(const Index: AnsiString): TOriMemory;
   var
   id: integer;
begin
   id := HashList.getHashValueEx(Index);
   if id = 0 then
      Result := nil
   else
      Result := Values^[ id - 1 ];
end;

procedure TOriTable.SetValue(const Index: AnsiString; const Value: TOriMemory);
   var
   id: integer;
begin
   id := HashList.getHashValueEx( Index );
   if id = 0 then
   begin
      Add(Index, Value);
   end else
      Values^[ id - 1 ] := Value;

   Value.Table := Self;
end;

procedure TOriTable.Unuse;
begin
  Dec( Ref_Count );
  if Ref_Count < 1 then
      FreeToManager;
end;

procedure TOriTable.Use;
begin
  Inc( Ref_Count );
end;

end.
