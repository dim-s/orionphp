unit ori_HashList;


interface

{$i '../VM/ori_Options.inc'}
{$ifdef fpc}
    {$mode delphi}
{$endif}

uses
  Classes, SysUtils, ori_Hash32, ori_StrUtils, ori_Types;

type
    PHashValue = ^THashValue;
    THashValue = record
        val      : Cardinal; // Хеш значение 0 - пусто
        real_crc : Cardinal;  // реальный хеш, т.к. могут быть коллизии
        twin     : PHashValue;
    end;
    PArrayHashValue = ^TArrayHashValue;
    TArrayHashValue = array[0..MaxInt div Sizeof(THashValue) - 1] of PHashValue;

    THashList = class(TObject)
        protected
            FItems: PArrayHashValue;
            FSize : Cardinal;
            FCapacity: integer;
            FLoadFactor: Integer; // precent, 75% max
            FThreshold: Integer;
            procedure Rehash(const newSize: Cardinal);

            function ItemNew(const key: AnsiString; const val: Cardinal): PHashValue;
            function ItemGet(const crc: Cardinal): PHashValue;
            procedure ItemPut(Item: PHashValue);
            procedure ItemRemove(const crc: cardinal);
        public
            procedure Clear;
            //class function getHash(const key: AnsiString): Cardinal; {inline; }
            property Counts: Cardinal read FSize;     // реальное количество заполненных элементов

            procedure doClone(const donor: THashList);
            
            procedure setValue(const key: AnsiString; const val: Cardinal);
            function setValueHash(const key: cardinal; const val: Cardinal): boolean;
            procedure delValue(const key: AnsiString); inline;
            procedure decValue(const key: AnsiString);
            function ItemHasKey(const crc: Cardinal): boolean;
            

            {$ifdef fpc}
            function getHashValue(const key: AnsiString; const Len: Integer): Cardinal;
            {$else}
            function getHashValue(const key: AnsiString; const Len: Integer): Cardinal; inline;
            {$endif}

            function getHashValueCrc(const crc: Cardinal): Cardinal;

            function getHashValueEx(const key: AnsiString): Cardinal;

            constructor Create(const initSize: cardinal = 150;
                         const initLoadFactory: byte = 70);
            destructor  Destroy(); override;
    end;


      function HashTable_Func(const key: AnsiString): Cardinal; {inline; }
      procedure HashTable_FuncVar(const key: AnsiString; var Result: Cardinal); {inline;}

    function HashTable_Func2(const key: AnsiString; const Len: Integer): Cardinal; inline;
    procedure HashTable_FuncVar2(const key: AnsiString; const Len: Integer; var Result: Cardinal);

    function HashTable_Func3(const key: PAnsiChar): Cardinal;
                                              
implementation

// BKDRHash
function HashTable_Func(const key: AnsiString): Cardinal;
const Seed = 31; (* 31 131 1313 13131 131313 etc... *)
var
  i,len: Cardinal;
begin
  Result := 0;
  len := Length(Key);
  for i := 1 to Len do
    Result := (Result * Seed) + Ord(Key[i]);

  Result := Result and $7FFFFFFF;
end;

function HashTable_Func2(const key: AnsiString; const Len: Integer): Cardinal;
const Seed = 31; (* 31 131 1313 13131 131313 etc... *)
var
  i: Cardinal;
begin
  Result := 0;
  for i := 1 to Len do
    Result := (Result * Seed) + Ord(Key[i]);

  Result := Result and $7FFFFFFF;
end;

function HashTable_Func3(const key: PAnsiChar): Cardinal;
const Seed = 31; (* 31 131 1313 13131 131313 etc... *)
var
  i,len: Integer;
begin
  Result := 0;
  i := 0;
  while Key[i] <> #0 do
  begin
    Result := (Result * Seed) + Ord(Key[i]);
    inc(i);
  end;

  Result := Result and $7FFFFFFF;
end;


procedure HashTable_FuncVar(const key: AnsiString; var Result: Cardinal);
const Seed = 31; (* 31 131 1313 13131 131313 etc... *)
var
  i,len: Cardinal;
begin
  Result := 0;
  len := Length(Key);
  for i := 1 to Len do
    Result := (Result * Seed) + Ord(Key[i]);

  Result := Result and $7FFFFFFF;
end;

procedure HashTable_FuncVar2(const key: AnsiString; const Len: Integer; var Result: Cardinal);
const Seed = 31; (* 31 131 1313 13131 131313 etc... *)
var
  i: Cardinal;
begin
  Result := 0;
  for i := 1 to Len do
    Result := (Result * Seed) + Ord(Key[i]);

  Result := Result and $7FFFFFFF;
end;

procedure FillNull(var Arr: PArrayHashValue; const Size: Longint); inline;
   var
   i: integer;
begin
    for i := 0 to Size - 1 do
      Arr[i] := nil;
end;

{ THashList }



constructor THashList.Create(const initSize: cardinal = 150; const initLoadFactory: byte = 70);
begin
   FLoadFactor := initLoadFactory;
   Rehash(initSize);
end;

procedure THashList.delValue(const key: AnsiString);
begin
  Self.ItemRemove( HashTable_Func(key) );
end;

destructor THashList.destroy;
begin
  Clear;
  FreeMem(FItems);
  inherited;
end;

procedure THashList.doClone(const donor: THashList);
  var
  x: integer;
  item,newItem: PHashValue;
begin
   Self.Clear;
   //Self.Rehash(150);
   //Self.Rehash(donor.FCapacity);

   for x := 0 to donor.FCapacity - 1 do
   begin
       item := donor.FItems[x];
       if item <> nil then
       begin
          new(newItem);
          newItem.val := item.val;
          newItem.real_crc := item.real_crc;
          newItem.twin := nil;
          Self.ItemPut(newItem);

          while (item.twin <> nil) do
          begin
              new(newItem);
              newItem^ := item.twin^;
              newItem.twin := nil;
              Self.ItemPut(newItem);

              item := item.twin;
          end;
          {if item.twin <> item then
          begin

          end;}
       end;
   end;
end;

procedure THashList.Clear;
var
  x: Integer;
  oldItem, hashItem: PHashValue;
begin
  for x := 0 to FCapacity - 1 do
  begin
    hashItem := FItems[x];
    while hashItem <> nil do
    begin
      oldItem := hashItem;
      hashItem := hashItem.Twin;
      dispose(oldItem);
    end;
    FItems[x] := nil;
  end;
  FSize := 0;
end;


function THashList.ItemGet(const crc: Cardinal): PHashValue;
begin
  Result := FItems[crc mod FCapacity];

  while Result <> nil do
  begin
    if Result.real_crc = crc then Exit;
    Result := Result.Twin;
  end;

  Result := nil;
end;

function THashList.ItemNew(const key: AnsiString;
  const val: Cardinal): PHashValue;
begin
   new(Result);
   Result.val := val;
   HashTable_FuncVar(key, Result.real_crc);
   Result.twin := nil;
end;

function THashList.ItemHasKey(const crc: Cardinal): boolean;
var
  hashItem: PHashValue;
  x: Cardinal;
begin
  Result := False;
  x := crc mod FCapacity;
  hashItem := FItems^[x];

  while hashItem <> nil do
  begin
    if hashItem.real_crc = crc then
    begin
      Result := True;
      Exit;
    end;
    hashItem := hashItem.Twin;
  end;
end;

procedure THashList.ItemPut(Item: PHashValue);
var
  hash: integer;
begin
  if FSize > FThreshold then
    Rehash(FCapacity * 2);

  hash := Item.real_crc mod FCapacity;
  Item.Twin := FItems[hash];

  if (Item.twin = nil) or (item.twin.real_crc <> item.real_crc) then
    Inc(FSize);


  FItems[hash] := Item;
end;


procedure THashList.ItemRemove(const crc: cardinal);
var
  hashItem, lastItem: PHashValue;
  hash: cardinal;
begin
  hash := crc mod FCapacity;
  hashItem := FItems[hash];
  lastItem := nil;

  while hashItem <> nil do
  begin
    if hashItem.real_crc = crc then
    begin
      // Remove item from pointer chain
      if lastItem = nil then
        FItems[hash] := hashItem.Twin
      else
        lastItem.Twin := hashItem.Twin;

      // Dispose item
      Dispose(hashItem);
      Dec(FSize);
      Exit;
    end;
    lastItem := hashItem;
    hashItem := hashItem.Twin;
  end;
end;

function THashList.getHashValue(const key: AnsiString; const Len: Integer): Cardinal;
  var
  Item: PHashValue;
begin
  Item := Self.ItemGet( HashTable_Func2(key, Len) );
  if Item <> nil then
      Result := Item.val
  else
      Result := 0;
end;

function THashList.getHashValueCrc(const crc: Cardinal): Cardinal;
var
  Item: PHashValue;
begin
  Item := ItemGet(crc);
  if Item <> nil then
      Result := Item.val
  else
      Result := 0;
end;

function THashList.getHashValueEx(const key: AnsiString): Cardinal;
  var
  Item: PHashValue;
begin
  Item := Self.ItemGet( HashTable_Func(key) );
  if Item <> nil then
      Result := Item.val
  else
      Result := 0;

end;

procedure THashList.Rehash(const newSize: Cardinal);
var
  hash: Cardinal;
  x: integer;
  newItems: PArrayHashValue;
  item, twin: PHashValue;
begin
  // Enlarge the size of the hashtable
  GetMem(newItems, Sizeof(THashValue) * newSize);
  FillNull(newItems, newSize);

  // Transfer items to the new hashtable
  for x := 0 to FCapacity - 1 do
  begin
    item := FItems[x];
    while item <> nil do
    begin
      Twin := item.Twin;
      hash := item.real_crc mod newSize;
      item.Twin := newItems[hash];
      newItems[hash] := item;
      item := Twin;
    end;
  end;

  FreeMem(FItems);

  FItems     := newItems;
  FThreshold := (newSize div 100) * FLoadFactor;

  FCapacity := newSize;
end;

procedure THashList.setValue(const key: AnsiString; const val: Cardinal);
   var
   item: PHashValue;
   crc: cardinal;
begin
   HashTable_FuncVar(key, crc);
   item := Self.ItemGet(crc);
   if item = nil then
   begin
       new(item);
       item.real_crc := crc;
       item.twin := nil;
       Self.ItemPut(item);
   end;
   item.val := val;
end;

procedure THashList.decValue(const key: AnsiString);
   var
   item: PHashValue;
begin
   item := Self.ItemGet(HashTable_Func(key));
   if item <> nil then
   begin
        dec(item.val);
   end;
end;

function THashList.setValueHash(const key: cardinal; const val: Cardinal): boolean;
  var
  item: PHashValue;
begin
  new(item);
  item.val := val;
  item.real_crc := key;
  item.twin := nil;

    Self.ItemPut( item );
end;

end.
