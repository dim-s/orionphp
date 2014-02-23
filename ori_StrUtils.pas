unit ori_StrUtils;

// модуль типов и структур
//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils, ori_Types, StrUtils,
  ori_FastArrays;

  const
       funcName = 'qwertyuiopasdfghjklzxcvbnm_1234567890';
       varName  = '$@qwertyuiopasdfghjklzxcvbnm_1234567890';
       defQuote   = '''';
       defMQuote  = '"';
       
  type
      TArrayString = MP_ArrayString;
      TArrayWide = array of WideString;
      TArrayCardinal = array of Cardinal;
      TArrayInteger  = array of Longint;
      TArrayByte = array of Byte;
      TArrayConst = array of TVarRec;

  function PosFrom(const Substr, S: MP_String; FromPos: integer): Integer;
  function getExprPos(const str: MP_String): Integer;
  function Cut(const S:MP_String; const Index: Integer; Len: Integer = -1):MP_String;
  function CopyL(const S:MP_String; const Srch:MP_String):MP_String;
  function CopyR(const S:MP_String; const Srch:MP_String):MP_String;

  function StrStr(const S:MP_String; const Srch:MP_String):MP_String;
  function StrIStr(const S:MP_String; const Srch:MP_String):MP_String;
  function StrCSpn(const S: MP_String; const Chars: MP_String; StartIndex: Integer = 1; Len: Integer = -1): integer;
  function StrSpn(const S: MP_String; const Chars: MP_String; StartIndex: Integer = 1; Len: Integer = -1): integer;
  function StrPbrk(const s1, s2: MP_String): MP_String;
  function StrTr(const S:MP_String; const From,_To:MP_String): MP_String; overload;
  function StrTr(const S:MP_String; Keys,Values: TStringArray): MP_String; overload;
  function Substr_Count(const Text: MP_String; const subtext: MP_String): Integer;
  function WordWrap(const S: MP_String; const Width: Integer = 75;
                  const Break: MP_String = #13; const Cut: Boolean = false):MP_String;
  function levenshtein(s, t: MP_String): integer;
  function UCfirst(const S: MP_String): MP_String;
  function UCWords(const S: MP_String): MP_String;
  function sprintf(const Format: MP_String; var Params: array of Pointer): MP_String;


  function FastStringReplace(const S: Ansistring; OldPattern: Ansistring;
                  const NewPattern: Ansistring;
                    Flags: TReplaceFlags = [rfReplaceAll]): Ansistring;


  
  procedure formatTypes(const s: MP_String; var Result: TArrayByte);
  function PosR(const Sub,S:MP_String):integer;
  function char_count(str: MP_String; ch: MP_Char): integer;

  procedure GetParamStr(const src: MP_String; var Result: MP_ArrayString; const glue: mp_char = ',');
  function ReplaceStrOC(Str,Old,New: MP_String): MP_String;

  function strcmp(const a,b: MP_String): Shortint;
  function strcasecmp(const a,b: MP_String): Shortint;

  function is_number(const s: MP_String): byte;
  function LowCase(ch: MP_Char): MP_Char;
  function CopyEx(const S: MP_String; const start,finish: integer): MP_String;

  procedure array_delete( var A: TArrayCardinal; const Index:integer );
  procedure array_insert( var A: TArrayCardinal; Index,len: integer; const ANew: Cardinal );
  procedure delElem( var A:TArrayConst; Index:integer );

  function ori_StrUpper(const S: MP_String): MP_String;
  function ori_StrLower(const S: MP_String): MP_String;
  function convert_cyr_string(str : MP_String; const from, to_ : MP_Char) : MP_String;

  procedure xorStr(var s1: MP_String; const s2: MP_String);
  procedure xorStrInt(var s1: MP_String; const x: integer);

  function isQuote(const str: MP_String; const i: integer; const quoCh: MP_char): boolean;
  procedure ori_explode(const Delim: MP_Char; const S: MP_String; var Result: MP_ArrayString);
  function CopyL2(const S:MP_String; const Srch:MP_String):MP_String;


implementation

  uses ori_Math;

procedure ori_explode(const Delim: MP_Char; const S: MP_String; var Result: MP_ArrayString);
var i, k, Len, Count: Integer;
begin
  Len := Length(S);
  Count := 0;
  k := 1;
  for i := 1 to Len do
  begin
    if S[i] = Delim then
    begin
      Inc(Count);
      SetLength(Result, Count);
      SetString(Result[Count-1], MP_PChar(@S[k]), i-k);
      k := i + 1;
    end; // if
  end; // for i
  Inc(Count);
  SetLength(Result, Count);
  SetString(Result[Count-1], MP_PChar(@S[k]), Len-k+1);
end;

function isQuote(const str: MP_String; const i: integer; const quoCh: MP_char): boolean;
begin
     if (str[i-1] <> '\') or ((str[i-1] = '\') and (str[i-2] = '\')) then
     begin
          if quoCh = #0 then
             Result := (str[i] = defQuote) or (str[i] = defMQuote )
          else
             Result := str[i] = quoCh;
     end else
        Result := false;
end;
  

procedure xorStr(var s1: MP_String; const s2: MP_String);
       var
       i,len: integer;
    begin
        len := Length(s2);
        for i := 1 to length(s1) do
        begin
          if i > len then break;
          s1[i] := MP_Char(ord(MP_Char(s1[i])) xor ord(MP_Char(s2[i])));
        end;
    end;

procedure xorStrInt(var s1: MP_String; const x: integer);
      var
      i: integer;
    begin
        for i := 1 to length(s1) do
        begin
          s1[i] := MP_Char(ord(s1[i]) xor x);
        end;
    end;

function  convert_cyr_string(str : MP_String; const from, to_ : MP_Char) : MP_String;
var
  i       : integer;
  p       : integer;
  c       : MP_Char;
  fromstr : MP_String;
  tostr   : MP_String;
begin
  case from of
    'w' : fromstr := 'абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
    'd','a' : fromstr :=  #160#161#162#163#164#165#241#166#167#168#169#170#171#172#173#174#175#224#225#226#227#228#229#230#231#232#233#234#235#236#237#238#239#128#129#130#131#132#133#240#134#135#136#137#138#139#140#141#142#143#144#145#146#147#148#149#150#151#152#153#154#155#156#157#158#159;
    'k' : fromstr := 'БВЧЗДЕJЦЪЙКЛМНОПРТУФХЖИГЮЫЭЯЩШЬАСбвчздеjцъйклмнопртуфхжигюыэящшьас';
  else
          fromstr := 'абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
  end;
  case to_ of
    'w' : tostr := 'абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
    'd','a' : tostr :=  #160#161#162#163#164#165#241#166#167#168#169#170#171#172#173#174#175#224#225#226#227#228#229#230#231#232#233#234#235#236#237#238#239#128#129#130#131#132#133#240#134#135#136#137#138#139#140#141#142#143#144#145#146#147#148#149#150#151#152#153#154#155#156#157#158#159;
    'k' : tostr := 'БВЧЗДЕJЦЪЙКЛМНОПРТУФХЖИГЮЫЭЯЩШЬАСбвчздеjцъйклмнопртуфхжигюыэящшьас';
  else
          tostr := 'абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ';
  end;

   for i := 1 to length(str) do
   begin
     c := str[i];
     p := pos(c, fromstr);
     if p <> 0 then
     begin
       c      := tostr[p];
       str[i] := c;
     end;
     str[i] := c;
   end;
   convert_cyr_string := str;
 end;

function ori_StrUpper(const S: MP_String): MP_String;
begin
    {$IFDEF IS_WIDE}
    Result := WideUpperCase(S);
    {$ELSE}
    Result := AnsiUpperCase(S);
    {$ENDIF}
end;

function ori_StrLower(const S: MP_String): MP_String;
begin
    {$IFDEF IS_WIDE}
    Result := WideLowerCase(S);
    {$ELSE}
    Result := AnsiLowerCase(S);
    {$ENDIF}
end;


function PosFrom(const Substr, S: MP_String; FromPos: integer): Integer;
var
  P: MP_PChar;
begin
  Result := 0;
  P := AnsiStrPos(MP_PChar(S) + fromPos - 1, MP_PChar(SubStr));
  if P <> nil then
    Result := Integer(P) - Integer(MP_PChar(S)) + 1;
end;

procedure delElem( var A:TArrayConst; Index:integer );
var Last : integer;
begin
   Last:= high( A );
   if Index <  Last then move( A[Index+1], A[ Index ],
       (Last-Index) * sizeof( A[Index] )  );
   setLength( A, Last );
end;



procedure array_delete( var A: TArrayCardinal; const Index:integer );
var Last : integer;
begin
   Last:= high( A );
   if Index <  Last then move( A[Index+1], A[ Index ],
       (Last-Index) * sizeof( A[Index] )  );
   setLength(A, Last);
end;

procedure array_insert( var A: TArrayCardinal; Index,len: integer;
                                      const ANew: Cardinal );
begin
   if Index >= Len then Index := Len+1;
   setLength( A, Len+1);
   move( A[Index], A[ Index+1 ],
         (Len-Index) * sizeof( A[Index] ));
   A[Index] := ANew;
end;


function LowCase(ch: MP_Char): MP_Char;
begin
  case ch of
    'A'..'Z': LowCase := mp_char(ORD(ch) + 32);
  else
    LowCase := ch;
  end;
end;


// 0 - false, 1 - integer, 2 - double, 3 - error (example: 2.3.4 or 2..3)
function is_number(const s: MP_String): byte;
   var
   i, len: cardinal;
   pt: boolean;
begin
   len := length(s);
   pt       := false;
   Result   := 0;
   if len = 0 then exit;
   for i := 1 to len do
   begin
       if s[i] = '.' then
       begin
          if pt = true then
          begin
              Result := 3;
              exit;
          end;
          pt := true;
       end;

       if i > 1 then
       begin
           //if (s[i] = '-') then
           if (s[i] = '-') and not (s[i-1] in ['e','E']) then
             Exit
           else
           if not (s[i] in ['0'..'9','.','e','E','-']) then
             Exit;
       end else begin
            if not (s[i] in ['0'..'9','+','-']) then
              exit;
       end;

   end;

   if not pt then
   begin
      if len < 19 then
          Result := 1 // int
      else
          Result := 2;
   end
   else
      Result := 2; // double
end;

function char_count(str: MP_String; ch: MP_Char): integer;
  var
  i,len: integer;
begin
  len := length(str);
  Result := 0;
  for i := 1 to len do
      if str[i] = ch then
         inc(Result);
end;

function FastStringReplace(const S: AnsiString; OldPattern: AnsiString;
  const NewPattern: AnsiString;
  Flags: TReplaceFlags = [rfReplaceAll]): AnsiString;
var
  I, J, Idx: Integer;
  IsEqual: Boolean;
  UpperFindStr: ansistring;
  pS: PAnsiChar; // Указатель на массив для сравнения символов
  CanReplace: Boolean;
begin
  if OldPattern = '' then
  begin
    Result := S;
    Exit;
  end;

  Result := '';
  if S = '' then Exit;

  if rfIgnoreCase in Flags then
  begin
    OldPattern := AnsiUpperCase(OldPattern);

    // Для режима "не учитывать регистр"
    // потребуется дополнительная строка
    UpperFindStr := AnsiUpperCase(S);

    pS := PAnsiChar(UpperFindStr);
  end else
    pS := PAnsiChar(S);

  // Если новая подстрока не превышает старой, то...
  if Length(OldPattern) >= Length(NewPattern) then
  begin
    SetLength(Result, Length(S));
  end else // Точный размер буфера не известен...
    SetLength(Result, (Length(S) + Length(OldPattern) +
      Length(NewPattern)) * 2);

  I := 1;
  Idx := 0;
  CanReplace := True;
  while I <= Length(S) do
  begin
    IsEqual := False;

    if CanReplace then // Если замена разрешена
    begin
      // Если I-й символ совпадает с OldPattern[1]
      if pS[I - 1] = OldPattern[1] then // Запускаем цикл поиска
      begin
        IsEqual := True;
        for J := 2 to Length(OldPattern) do
        begin
          if pS[I + J - 2] <> OldPattern[J] then
          begin
            IsEqual := False;
            Break; // Прерываем внутренний цикл
          end;
        end;

        // Совпадение найдено! Выполняем замену
        if IsEqual then
        begin
          for J := 1 to Length(NewPattern) do
          begin
            Inc(Idx);

            // Расширяем строку Result при необходимости
            if Idx > Length(Result) then
              SetLength(Result, Length(Result) * 2);

            Result[Idx] := NewPattern[J];
          end;

          // Пропускаем байты в исходной строке
          Inc(I, Length(OldPattern));

          if not (rfReplaceAll in Flags) then
            CanReplace := False; // Запрещаем дальнейшую замену
        end;
      end;
    end;

    // Если подстрока не найдена, то просто копируем символ
    if not IsEqual then
    begin
      Inc(Idx);

      // Расширяем строку Result при необходимости
      if Idx > Length(Result) then
        SetLength(Result, Length(Result) * 2);

      Result[Idx] := S[I];
      Inc(I);
    end;
  end; // while I <= Length(S) do

  // Ограничиваем длину строки-результата
  SetLength(Result, Idx);
end;


function Cut(const S:MP_String; const Index: Integer; Len: Integer = -1):MP_String;
begin
  if Len = -1 then
    Len := Length(S) - Index - 2;

  Result:=Copy(S, Index+Len, Length(S)-Len+Index);
end;

function CopyEx(const S: MP_String; const start,finish: integer): MP_String; inline;
begin
   Result := Copy(S, start, finish-start);
end;

function CopyL(const S:MP_String; const Srch:MP_String):MP_String;
begin
  Result:=Copy(s,1,Pos(Srch,S)-1);
end;

function CopyL2(const S:MP_String; const Srch:MP_String):MP_String;
begin
  //Result:=Copy(s,1,Pos(Srch,S)-1);
end;

function CopyR(const S:MP_String; const Srch:MP_String):MP_String;
begin
  Result:=Cut(s,1,Pos(Srch,S)+(length(Srch)-1));
end;

function StrStr(const S:MP_String; const Srch:MP_String):MP_String;
   var
   k: integer;
begin
  k := Pos(Srch,S);
  if k > 0 then begin
     Result := s;
     Delete(Result,1,k-1);
  end
  else Result := '';
end;

function StrIStr(const S:MP_String; const Srch:MP_String):MP_String;
   var
   k: integer;
begin
  k := Pos(ori_StrLower(Srch),ori_StrLower(S));
  if k > 0 then begin
     Result := s;
     Delete(Result,1,k-1);
  end
  else Result := '';
end;

function StrTr(const S:MP_String; const From,_To:MP_String): MP_String; overload;
   var
   i,x,len: integer;
begin
  Result := S;
  len := length(Result);
  for i := 1 to len do
  begin
      x := Pos(Result[i],From);
      if x > 0 then Result[i] := _To[x];
  end;
end;

function StrTr(const S:MP_String; Keys,Values:TStringArray): MP_String; overload;
   function array_search(const word: MP_String; var arr: TStringArray): Integer;
   begin
       for Result := 0 to arr.Count-1 do
       if word = arr.Values^[Result] then
          Exit;
       Result := -1;
   end;

   // сортировка пузырьком
   procedure sort_array(var keys,values: TStringArray);
      var
      i,j,n: integer;
      p: MP_String;
   begin
     n := keys.Count;
      for i := n - 1 downto 1 do
        for j := 0 to i-1 do
          begin
              if length(keys.Values^[j]) < length(keys.Values^[j + 1]) then
              begin
                 p := keys.Values^[j]; keys.Values^[j] := keys.Values^[j+1];
                 keys.Values^[j+1] := p;

                 p := values.Values^[j]; values.Values^[j] := values.Values^[j+1];
                 values.Values^[j+1] := p;
              end;
          end;
   end;

   var
   i,j,l,h: integer;
begin
  Result := s;
  sort_array(Keys,Values);
  h := Keys.Count-1;
  i := 0;
  while True do
  begin
      inc(i);
      if i > length(Result) then break;
      
      for j := 0 to h do
      begin
          l := length(keys.Values^[j]);
          if l > i then continue;

          if PosEx(keys.Values^[j],Result,(i-l)+1) = (i-l)+1 then
          begin
              Delete(Result,(i-l)+1,l);
              Insert(values.Values^[j],Result,(i-l)+1);
              i := i - l + (length(values.Values^[j])*2);
          end;
      end;

  end;
end;

function StrCSpn(const S: MP_String; const Chars: MP_String; StartIndex: Integer = 1; Len: Integer = -1): integer;
var
  i,_to,l: integer;
begin
  if StartIndex <= 0 then StartIndex := 1;
  l := length(s);

  if (len > -1) then begin
    _to := StartIndex + len;
    if _to > l then _to := l;
  end else _to := l;

  for i:=StartIndex to _to do
    if Pos(S[i],Chars) > 0 then
    begin
      Result := i;
      exit;
    end;

  Result := _to;
end;


function StrSpn(const S: MP_String; const Chars: MP_String; StartIndex: Integer = 1; Len: Integer = -1): integer;
var
  i,_to,l: integer;
begin
  if StartIndex <= 0 then StartIndex := 1;
  l := length(s);

  if (len > -1) then begin
    _to := StartIndex + len;
    if _to > l then _to := l;
  end else _to := l;

  for i:=StartIndex to _to do
    if Pos(S[i],Chars) = 0 then
    begin
      Result := i;
      exit;
    end;

  Result := _to;
end;


function StrPbrk(const s1, s2: MP_String): MP_String;
  var
  i,len: integer;
begin
  Result := #0;
  len := length(s1);
  for i := 1 to len do
       if StrStr(s2,s1[i]) <> '' then
       begin
         Result := s1;
         Delete(Result,1,i-1);
         exit;
       end;
end;

function Substr_Count(const Text: MP_String; const subtext: MP_String): Integer;
 var
 i,l,len: integer;
begin
  Result := 0;
  l := length(subtext);
  len := length(text);
  for i := 1 to len do
      if l <= i then
      if PosEx(subtext,text,(i-l)+1) = (i-l)+1 then
          inc(Result);
end;


// fix no concat breakstr
function WrapText(const Line, BreakStr: Ansistring; const BreakChars: TSysCharSet;
  MaxCol: Integer): string;
const
  QuoteChars = ['''', '"'];

  {$ifdef fpc}
  function CharLength(const S: ansistring; Index: Integer): Integer;
  begin
  Result := 1;
  assert((Index > 0) and (Index <= Length(S)));
  if SysLocale.FarEast and (S[Index] in LeadBytes) then
    Result := StrCharLength(PAnsiChar(S) + Index - 1);
   end;
   {$endif}
var
  Col, Pos: Integer;
  LinePos, LineLen: Integer;
  BreakLen, BreakPos: Integer;
  QuoteChar, CurChar: AnsiChar;
  ExistingBreak: Boolean;
  L: Integer;
begin
  Col := 1;
  Pos := 1;
  LinePos := 1;
  BreakPos := 0;
  QuoteChar := #0;
  ExistingBreak := False;
  LineLen := Length(Line);
  BreakLen := Length(BreakStr);
  Result := '';
  while Pos <= LineLen do
  begin
    CurChar := Line[Pos];
    if CurChar in LeadBytes then
    begin
      L := CharLength(Line, Pos) - 1;
      Inc(Pos, L);
      Inc(Col, L);
    end
    else
    begin
      if CurChar in QuoteChars then
        if QuoteChar = #0 then
          QuoteChar := CurChar
        else if CurChar = QuoteChar then
          QuoteChar := #0;
      if QuoteChar = #0 then
      begin
        if CurChar = BreakStr[1] then
        begin
          ExistingBreak := StrLComp(PAnsiChar(BreakStr), PAnsiChar(@Line[Pos]), BreakLen) = 0;
          if ExistingBreak then
          begin
            Inc(Pos, BreakLen-1);
            BreakPos := Pos;
          end;
        end;

        if not ExistingBreak then
          if CurChar in BreakChars then
            BreakPos := Pos;
      end;
    end;

    Inc(Pos);
    Inc(Col);

    if not (QuoteChar in QuoteChars) and (ExistingBreak or
      ((Col > MaxCol) and (BreakPos > LinePos))) then
    begin
      Col := 1;
      //Result := Result + Copy(Line, LinePos, BreakPos - LinePos + 1);
      Result := Result + Copy(Line, LinePos, BreakPos - LinePos);
      if not (CurChar in QuoteChars) then
      begin
        while Pos <= LineLen do
        begin
          if Line[Pos] in BreakChars then
          begin
            Inc(Pos);
            ExistingBreak := False;
          end
          else
          begin
            if StrLComp(pAnsiChar(@Line[Pos]), sLineBreak, Length(sLineBreak)) = 0 then
            begin
              Inc(Pos, Length(sLineBreak));
              ExistingBreak := True;
            end
            else
              Break;
          end;
        end;
      end;
      if (Pos <= LineLen) and not ExistingBreak then
        Result := Result + BreakStr;

      Inc(BreakPos);
      LinePos := BreakPos;
      Pos := LinePos;
      ExistingBreak := False;
    end;
  end;
  Result := Result + Copy(Line, LinePos, MaxInt);
end;

function WordWrap(const S: MP_String; const Width: Integer = 75;
                  const Break: MP_String = #13; const Cut: Boolean = false): MP_String;
begin
    if Cut then
    begin
       Result := WrapText(S,Break,[' '],Width+1); // todo fix Cut Param
    end
    else
       Result := WrapText(S,Break,[' '],Width+1);
end;





const
  cuthalf = 255; // константа, ограничивающая макс. длину
  // обрабатываемых строк

var
  buf: array[0..((cuthalf * 2) - 1)] of integer; // рабочий буффер, заменяет
  // матрицу, представленную
  // в описании

function levenshtein(s, t: MP_String): integer;

  function min3(a, b, c: integer): integer; // вспомогательная функция
  begin
    Result := a;
    if b < Result then
     Result := b;
    if c < Result then
      Result := c;
  end;

var
  i, j, m, n: integer;
  cost: integer;
  flip: boolean;
begin
  s := copy(s, 1, cuthalf - 1);
  t := copy(t, 1, cuthalf - 1);
  m := length(s);
  n := length(t);
  if m = 0 then
    Result := n
  else if n = 0 then
    Result := m
  else
  begin
    flip := false;
    for i := 0 to n do
      buf[i] := i;
    for i := 1 to m do
    begin
      if flip then
        buf[0] := i
      else
        buf[cuthalf] := i;
      for j := 1 to n do
      begin
        if s[i] = t[j] then
          cost := 0
        else
          cost := 1;
        if flip then
          buf[j] := min3((buf[cuthalf + j] + 1),
            (buf[j - 1] + 1),
            (buf[cuthalf + j - 1] + cost))
        else
          buf[cuthalf + j] := min3((buf[j] + 1),
            (buf[cuthalf + j - 1] + 1),
            (buf[j - 1] + cost));
      end;
      flip := not flip;
    end;
    if flip then
      Result := buf[cuthalf + n]
    else
      Result := buf[n];
  end;
end;


function UCfirst(const S: MP_String): MP_String;
  var
  t: MP_String;
begin
    Result := S;
    if length(Result) > 0 then
    begin
        t := AnsiUpperCase(Result[1]);
        Result[1] := t[1];
    end;
end;

function UCWords(const S: MP_String): MP_String;
  var
  t: MP_String;
  len,i: integer;
begin
    Result := AnsiLowerCase(S);
    len := length(Result);
    
    t := AnsiUpperCase(Result[1]);
    Result[1] := t[1];

    for i := 1 to len-1 do
    begin
        if (Result[i] in [' ',#8,#9,#13,#10]) then
        begin
            t := AnsiUpperCase(Result[i+1]);
            Result[i+1] := t[1];
        end;
    end;
end;

// возвращает типы учавствующие в форматированной строке...
procedure formatTypes(const s: MP_String; var Result: TArrayByte);
   var
   i,len,c: integer;
begin
  SetLength(Result,50);
  len := length(s);
  c := -1;
  i := 0;
  while i < len do
  begin
  inc(i);
      if s[i] = '%' then
      begin
            inc(i);
            while s[i] in ['0'..'9'] do inc(i);

            case s[i] of
              'b','c','d','u','o','x','X': begin
                    inc(c);
                    Result[c] := 1;
                  end;
              'e','f': begin
                       inc(c);
                       Result[c] := 2;
                       end;
              's': begin
                   inc(c);
                   Result[c] := 3;
                   end;
            end;
      end;
  end;
  SetLength(Result,c+1);
end;


function sprintf(const Format: MP_String; var Params: array of Pointer): MP_String;
 function Replicate(const R: MP_String; Len: byte): MP_String; inline;
  var
   S: MP_String;
   i: byte;
  begin
   S:='';
   for i:=1 to Len do S:=S+R;
   Replicate := S;
  end;

 function Space(Len: byte): MP_String; inline;
  begin
   Space:=Replicate(' ',Len);
  end;

 var
  Ind,len: Integer;
  S, Wstr: MP_String;
  LongPending,
  ParmPending,
  PointPending,
  LeftJustify,
  ZeroPad: Boolean;
  ParmIndex: Integer;
  Width, Decimals: Integer;
  CurrChar: MP_Char;

  procedure ClearFlags;
   begin
    LongPending:=False;
    ParmPending:=False;
    PointPending:=False;
    LeftJustify:=False;
    ZeroPad:=False;
    Width:=0;
    Decimals:=0;
   end;

  function NextChar: MP_Char;
   begin
    NextChar:=' ';
    if (Ind<=Length(Format)) then
     begin
      Inc(Ind);
      NextChar:=Format[Ind];
    end;
   end;

  function PrevChar: MP_Char;
   begin
    if (Ind>1) then PrevChar:=Format[Ind-1] else PrevChar:=Format[Ind];
   end;

  procedure SaveChar(C: MP_Char);
   begin
    S:=S+C;
   end;

  procedure SaveString(Wstr: MP_String);
   var
    i: Integer;
    PadChar: MP_Char;
    Delta: Integer;
   begin
    if (ZeroPad) then PadChar:='0' else PadChar:=' ';
    if (Length(Wstr)>Width) then Width := Length(Wstr);
    Delta := Width - Length(Wstr);
    for i:=1 to Width do if (LeftJustify) then if (i<=Length(Wstr)) then S := S+Wstr[i]
    else S := S  + (PadChar) else if (i<=Delta) then S := S + (PadChar)
    else if (Delta>0) then S := S + (Wstr[i-Delta]) else S := S + (Wstr[i]);
   end;

  procedure Convert(Base: MP_Char);
   begin
    Inc(ParmIndex);
    if (Params[ParmIndex]=nil) then
      case Base of
     'C','c': Wstr:=' ';
     'D','d': if (Width<10) then Wstr:=Space(8) else Wstr:=Space(10);
     'X','x': if (LongPending) then Wstr:=Space(8) else Wstr:=Space(4);
      else Wstr:=Space(Width);
     end else case (Base) of
      'C','c':
       begin
        SetLength(Wstr, 1);
        Wstr[1]:=MP_Char(Params[ParmIndex]^);
       end;
      'I','i': if (LongPending) then Str(Longint(Params[ParmIndex]^):-Width,Wstr)
           else Str(Integer(Params[ParmIndex]^):-Width, Wstr);
      'F','f':
       begin
        if (LongPending) then Str(Double(Params[ParmIndex]^):-Width:Decimals,Wstr)
        else Str(Real(Params[ParmIndex]^):-Width:Decimals,Wstr);
       end;
      'X': Wstr := ori_StrUpper( dechex(Integer(Params[ParmIndex]^)) );
      'x': Wstr := ori_StrLower( dechex(Integer(Params[ParmIndex]^)) );
      'S','s': if (Decimals>0) then Wstr:=Copy(MP_String(Params[ParmIndex]^), 1, Decimals)
           else if (Width=0) then Wstr:=MP_String(Params[ParmIndex]^)
           else Wstr:=Copy(MP_String(Params[ParmIndex]^),1,Width);
     end;
    SaveString(Wstr);
    ClearFlags;
   end;

  procedure CountNumbers(C: MP_char);
   begin
    if (PointPending) then Decimals:=Decimals*10+Ord(C)-48 else Width:=Width*10+Ord(C)-48;
  end;

 begin
  S:='';
  Ind:=0;
  ParmIndex:=-1;
  ClearFlags;
  len := length(Format);
  while (Ind<len) do
   begin
    CurrChar:=NextChar;
    if (CurrChar='%') then ParmPending := True;
    if (ParmPending) then
     begin
      if (CurrChar='%') then if (Ind < Len) then CurrChar:=NextChar
      else CurrChar := ' ';
      case UpCase(CurrChar) of
       '%':
        begin
         ClearFlags;
         S := S + CurrChar;
        end;
       'L': LongPending := True;
       'C','D','I','F','X','S': Convert(CurrChar);
       '0'..'9':
        begin
         if (CurrChar='0') then if not (PrevChar in ['%', '-']) then CountNumbers(CurrChar)
         else ZeroPad:=True else CountNumbers(CurrChar);
        end;
       '-': LeftJustify := True;
       '.': PointPending := True;
       else
        begin
         ClearFlags;
         S := S + CurrChar;
        end;
      end;
    end
   else S := S + (CurrChar);
  end;
  sPrintF := S;
end;


function PosR(const Sub, S: MP_String): Integer;

  function InvertS(const S: MP_String): MP_String; inline;
    {Инверсия строки S}
  var
    i, Len: Integer;
  begin
    Len := Length(S);
    SetLength(Result, Len);
    for i := 1 to Len do
      Result[i] := S[Len - i + 1];
  end;

var
  ps: Integer;
begin
  ps := Pos(InvertS(Sub), InvertS(S));
  if ps <> 0 then
    Result := Length(S) - Length(Sub) - ps + 2
  else
    Result := 0;
end;

{                               ><
  from: func( ...[.], ()., etc ) any code...
  return:                позиция^
}
function getExprPos(const str: MP_String): Integer;
  var
  n, len, i: integer;
  isOpen: boolean;
  ch: mp_char;
  isStr: boolean;
  sym, eSym: mp_char;
begin

  isOpen := false;
  isStr  := false;
  len    := Length(str);
  n      := 0;

  for i := 1 to len do
  begin
      ch := str[i];

      if (ch = defQuote) or (ch = defMQuote ) then isStr := not isStr;
      if isStr then continue;

      if isOpen and (n = 0) then
        begin
          Result := i;
          exit;
        end;

      case ch of
        '(','[','{':
          if not isOpen then
            begin
               isOpen := true;
               sym    := ch;
               case sym of
                  '(': eSym := ')';
                  '[': eSym := ']';
                  '{': eSym := '}';
               end;
               inc(n);
               continue;
            end;
      end;

      if isOpen then
      begin
        if ch = sym then inc(n)
        else if ch = eSym then dec(n);
      end;

  end;

  if isOpen and (n = 0) then
    Result := len
  else
    Result := -1;
end;

// возвращает массив строк - список параметров, практически аналог explode из php
// но игнорирует все что в скобках и кавычках
procedure GetParamStr(const src: MP_String; var Result: MP_ArrayString; const glue: mp_char = ',');
   var
   len, i, skN: integer;
   isStr: boolean;
   quoCh, ch: mp_char;
   inst: MP_String;
   lineCount: integer;
   skCh, skChE: mp_char; // (, {, [
begin

     i := 0;
     len := Length(src);
     lineCount := 0;
     quoCh := #0;
     skCh  := #0;
     skChE := #0;
     skN   := 0;
     SetLength(Result,0);
     isStr := false;

     while (true) do begin

         inc(i);

         if i > len then
            break;

         ch := src[i];

         inst := inst + ch;

         if (not isStr) and (skCh = #0) then
         case ch of
              '(','{','[': begin
                    skCh := ch;
                    skN := 1;
                    case skCh of
                         '(': skChE := ')';
                         '{': skChE := '}';
                         '[': skChE := ']';
                    end;

                    continue;
              end;
         end;

         if not isStr then begin
            if ch = skCh then Inc(skN)
            else if ch = skChE then Dec(skN);

            if (skCh <> #0) and (skN = 0) then
            begin
                 skCh := #0;
                 skChE:= #0;
            end;
         end;

         if isQuote(src, i, quoCh) then
         begin
             isStr := not isStr;
             if not isStr then
             begin
                  if isStr then quoCh := ch
                  else quoCh := #0;
             end;
         end;

         if (not isStr) and (skN = 0) and (ch = glue) then
         begin
              Inc(lineCount);
              SetLength(Result,lineCount);
              Result[lineCount-1] := copy(inst,1,length(inst)-1);
              inst := '';
         end;


     end;

     if isStr then
     begin
         // newError(errSyntax, Format(MSG_ERR_NOQUOTE_F, [quoCh]));
     end else
     if (skN <> 0) and (inst <> '') then
     begin
         // newError(errSyntax, Format(MSG_ERR_NOSKOBA_F, [skCh]));
     end else
     if inst <> '' then
     begin
          Inc(lineCount);
          SetLength(Result,lineCount);
          Result[lineCount-1] := inst
     end;
end;



// замена текста в обход строковых выражений
function ReplaceStrOC(Str,Old,New: MP_String): MP_String;
  Var
  KavType: mp_Char;
  I: Integer;
  Stroka: Boolean;
  tmp: MP_String;
begin
  Result := '';
  Stroka := False;
  for i:=1 to Length(Str) do
   begin
    if (not Stroka)and(Str[I] in [defQuote,defMQuote]) then KavType := Str[i];

     if Str[i] = KavType then begin
       Stroka := Not Stroka;
       tmp := tmp + Str[i];
        if Stroka then
          Result := Result + StringReplace(tmp,Old,New,[rfReplaceAll])
        else Result := Result + tmp;
       tmp := '';
       continue;
     end;

    tmp := tmp + Str[i];
   end;
  if tmp <> '' then Result := Result + StringReplace(tmp,Old,New,[rfReplaceAll]);
end;

function ReplaceStrIC(Str,Old,New: MP_String): MP_String;
  Var
  KavType: mp_Char;
  I: Integer;
  Stroka: Boolean;
  tmp: MP_String;
begin
  Result := '';
  Stroka := False;
  for i:=1 to Length(Str) do
   begin
    if (not Stroka)and(Str[I] in [defQuote,defMQuote]) then KavType := Str[i];

     if Str[i] = KavType then begin
       Stroka := Not Stroka;
       tmp := tmp + Str[i];
        if Stroka then
          Result := Result + tmp
        else Result := Result + StringReplace(tmp,Old,New,[rfIgnoreCase]);
       tmp := '';
       continue;
     end;

    tmp := tmp + Str[i];
   end;
end;

function strcmp(const a,b: MP_String): Shortint;
begin
    if a = b then
      Result := 0
    else if a > b then
      Result := 1
    else if a < b then
      Result := -1;
end;

function strcasecmp(const a,b: MP_String): Shortint;
begin
   Result := strcmp(AnsiLowerCase(a),AnsiLowerCase(b));
end;



end.


end.
