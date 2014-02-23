unit ori_CoreString;


//{$mode objfpc}
{$H+}
{$WARNINGS OFF}
{$I '../ori_Options.inc'}

interface

uses
  Classes, SysUtils, StrUtils,

  ori_vmTables,
  ori_Types,
  ori_vmConstants,
  ori_vmUserFunc,

  ori_StrUtils,
  ori_vmTypes,
  ori_Errors,
  ori_vmValues,
  ori_StrConsts,
  ori_FastArrays,
  ori_vmNativeFunc,
  ori_vmMemory;


implementation

{$ifdef fpc}
// in fpc rtl this problem function
{ This function is loosely based on SoundBts which was written by John Midwinter }
function Soundex(const AText: string; ALength: TSoundexLength): string;
const

  // This table gives the Soundex score for all characters upper- and lower-
  // case hence no need to convert.  This is faster than doing an UpCase on the
  // whole input string.  The 5 non characters in middle are just given 0.
  CSoundexTable: array[65..122] of ShortInt =
  // A  B  C  D  E  F  G  H   I  J  K  L  M  N  O  P  Q  R  S  T  U  V  W   X  Y  Z
    (0, 1, 2, 3, 0, 1, 2, -1, 0, 2, 2, 4, 5, 5, 0, 1, 2, 6, 2, 3, 0, 1, -1, 2, 0, 2,
  // [  /  ]  ^  _  '
     0, 0, 0, 0, 0, 0,
  // a  b  c  d  e  f  g  h   i  j  k  l  m  n  o  p  q  r  s  t  u  v  w   x  y  z
     0, 1, 2, 3, 0, 1, 2, -1, 0, 2, 2, 4, 5, 5, 0, 1, 2, 6, 2, 3, 0, 1, -1, 2, 0, 2);

  function Score(AChar: Integer): Integer;
  begin
    Result := 0;
    if (AChar >= Low(CSoundexTable)) and (AChar <= High(CSoundexTable)) then
      Result := CSoundexTable[AChar];
  end;

var
  I, LScore, LPrevScore: Integer;
begin
  Result := '';
  if AText <> '' then
  begin
    Result := Upcase(AText[1]);
    LPrevScore := Score(Ord(AText[1]));
    for I := 2 to Length(AText) do
    begin
      LScore := Score(Ord(AText[I]));
      if (LScore > 0) and (LScore <> LPrevScore) then
      begin
        Result := Result + IntToStr(LScore);
        if Length(Result) = ALength then
          Break;
      end;
      if LScore <> -1 then
        LPrevScore := LScore;
    end;
    if Length(Result) < ALength then
      Result := Copy(Result + DupeString('0', ALength), 1, ALength);
  end;
end;

{$endif}


{=================================================================}
{====================== Cyr  Convert =============================}

procedure x_convert_cyr_string(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrUtils.convert_cyr_string(pr[0].AsString,
              pr[1].AsChar,pr[2].AsChar) );
end;


{=================================================================}
{====================== Count Chars  =============================}
procedure x_count_chars(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  sym_c: array of Integer;
  i,len,o: integer;
  s: MP_String;
  mode: Byte;
  hash: TOriTable;
begin
  s := pr[0].AsString;
  len := length(s);

  SetLength(sym_c,255);

  for i := 1 to len do begin
      o := Ord(s[i]);
      if o < 256 then inc(sym_c[o]);
  end;

  if cnt = 1 then mode := 0
  else mode := pr[1].AsInteger;

  if mode < 3 then
  begin
      hash := TOriTable.CreateInManager;
      Return.ValTable(hash);
  end else
      s := '';
      
  case mode of
    0: for i := 0 to 255 do hash.Add(IntToStr(i),TOriMemory.GetMemory(sym_c[i]));
    1: for i := 0 to 255 do if sym_c[i] > 0 then hash.Add(IntToStr(i),TOriMemory.GetMemory(sym_c[i]));
    2: for i := 0 to 255 do if sym_c[i] = 0 then hash.Add(IntToStr(i),TOriMemory.GetMemory(sym_c[i]));

    3: for i := 0 to 255 do if sym_c[i] > 0 then s := s + MP_Char(i);
    4: for i := 0 to 255 do if sym_c[i] = 0 then s := s + MP_Char(i);
  end;

  if mode > 2 then
    Return.Val(s);
end;

{=================================================================}
{====================== Strip Tags ===============================}

procedure x_strip_tags(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
var
  istart, iend: Integer;
  s: MP_String;
begin
  s := pr[0].AsString;
  iend := 1; istart := 1;
  while iend <= Length(s) do
  begin
    case s[iend] of
      '<': istart := iend;
      '>': begin
             delete(s, istart, iend - istart + 1);
             dec(iend, iend - istart + 1);
           end;
    end;
    inc(iend);
  end;

  Return.Val( s );
end;


{=================================================================}
{====================== Trim  ====================================}

procedure x_rtrim(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( TrimRight(pr[0].AsString) );
end;

procedure x_ltrim(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( TrimLeft(pr[0].AsString) );
end;

procedure x_trim(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( Trim(pr[0].AsString) );
end;

procedure x_chr(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( MP_Char(pr[0].AsInteger) );
end;

procedure x_ord(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( Ord(pr[0].AsChar) );
end;

{=================================================================}
{====================== Replace ==================================}

procedure hide_str_replace(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; const flags: TReplaceFlags);
  var
  h1,h2: TOriTable;
  i: integer;
  S: MP_String;
begin
  Return.typ := mvtString;

  if (pr[0].typ = mvtHash) and (pr[1].typ = mvtHash) then
  begin
      Return.Mem.str := pr[2].AsString;
      h1 := TOriTable(pr[0].Mem.ptr);
      h2 := TOriTable(pr[1].Mem.ptr);
      for i := 0 to h1.count - 1 do
      begin
        if i+1 > h2.count then
            Return.Mem.str := FastStringReplace(Return.Mem.str, h1[i].AsString,'',flags)
        else
            Return.Mem.str := FastStringReplace(Return.Mem.str,
                                          h1[i].AsString,h2[i].AsString,flags);
      end;
  end else if pr[0].typ = mvtHash then
  begin
     Return.Mem.str := pr[2].AsString;
     S := pr[1].AsString;
     
     h1 := TOriTable(pr[0].Mem.ptr);
     for i := 0 to h1.count - 1 do
        Return.Mem.str := FastStringReplace(Return.Mem.str,h1[i].AsString,S,flags);
      
  end else
    Return.Mem.Str := 
      FastStringReplace(pr[2].AsString, pr[0].AsString,pr[1].AsString,flags);
end;

procedure x_str_ireplace(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
   hide_str_replace(pr,cnt,Return,[rfReplaceAll,rfIgnoreCase]);
end;

procedure x_str_replace(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
   hide_str_replace(pr,cnt,Return,[rfReplaceAll]);
end;

procedure x_str_repeat(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  S: MP_String;
  I,C: Integer;
begin
  Return.Mem.str := '';
  Return.typ := mvtString;

  S := pr[0].AsString;
  C := pr[1].AsInteger;

  for i := 1 to C do
      Return.Mem.str := Return.Mem.str + S;
end;


{=================================================================}
{====================== Soundex ==================================}

procedure x_soundex(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( Soundex(pr[0].AsString,4) );
end;


{=================================================================}
{====================== Str Len ==================================}

procedure x_strlen(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( length(pr[0].AsString) );
end;

{=================================================================}
{====================== Str Pos  ==================================}

procedure x_strpos(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var k: integer;
begin
  case cnt of
    2: k := Pos(pr[1].AsString,pr[0].AsString);
    3: k := PosEx(pr[1].AsString,pr[0].AsString,pr[2].AsInteger+1);
  end;

  if k = 0 then Return.Val(False)
  else Return.ValL(k-1);
end;

procedure x_stripos(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var k: integer;
begin
  case cnt of
    2: k := Pos(ori_StrLower(pr[1].AsString), ori_StrLower(pr[0].AsString));
    3: k := PosEx(ori_StrLower(pr[1].AsString),ori_StrLower(pr[0].AsString),pr[2].AsInteger+1);
  end;

  if k = 0 then Return.Val(False)
  else Return.ValL(k-1);
end;

{=================================================================}
{====================== StrStr  ==================================}

procedure x_strstr(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrUtils.StrStr(pr[0].AsString,pr[1].AsString) );
end;

procedure x_stristr(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrUtils.StrIStr(pr[0].AsString,pr[1].AsString) );
end;

procedure x_strtr(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  akeys,avalues: TStringArray;
  i: integer;
begin
  case cnt of
      2: begin

          if pr[1].IsArray then
          begin
             with TOriTable(pr[1].Mem.ptr) do
             begin
                //SetLength(akeys,count);
                avalues := TStringArray.Create;
                for i := 0 to count - 1 do
                begin
                    //akeys[i] := Names[i];
                    avalues.Add( Value[i].AsString );
                end;


                Return.Val(ori_StrUtils.StrTr(pr[0].AsString,Names,avalues));
             end;
             
          end else begin
              Return.Val(pr[0].AsString);
              getErrorPool(eval).newError(errNotice,Format(MSG_ERR_PARAM_ARRTYPE,['2']));
          end;

          end;
      3: begin
          Return.Val( ori_StrUtils.StrTr(pr[0].AsString,pr[1].AsString,
                      pr[2].AsString) );
      end;
  end;

end;



{=================================================================}
{====================== StrRev  ==================================}

procedure x_strrev(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( AnsiReverseString(pr[0].AsString) );
end;

{=================================================================}
{====================== Str Spn  =================================}

procedure x_strspn(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var k: integer;
begin
  case cnt of
    2: k := StrSpn(pr[0].AsString,pr[1].AsString);
    3: k := StrSpn(pr[0].AsString,pr[1].AsString,pr[2].AsInteger+1);
    4: k := StrSpn(pr[0].AsString,pr[1].AsString,pr[2].AsInteger+1,pr[3].AsInteger);
  end;

  if k = 0 then Return.Val(False)
  else Return.ValL(k-1);
end;

procedure x_strcspn(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var k: integer;
begin
  case cnt of
    2: k := StrCSpn(pr[0].AsString,pr[1].AsString);
    3: k := StrCSpn(pr[0].AsString,pr[1].AsString,pr[2].AsInteger+1);
    4: k := StrCSpn(pr[0].AsString,pr[1].AsString,pr[2].AsInteger+1,pr[3].AsInteger);
  end;

  if k = 0 then Return.Val(False)
  else Return.ValL(k-1);
end;


{=================================================================}
{====================== strpbrk =================================}

procedure x_strpbrk(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  Var k : MP_String;
begin
  k := ori_StrUtils.strpbrk(pr[0].AsString,pr[1].AsString);
  if k = #0 then Return.Val(False)
  else Return.Val(k);
end;

{=================================================================}
{====================== Str Up Low  ==================================}

procedure x_strtolower(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrLower(pr[0].AsString) );
end;

procedure x_strtoupper(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrUpper(pr[0].AsString) );
end;

{=================================================================}
{====================== Substr Count =============================}

procedure x_substr_count(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( ori_StrUtils.Substr_Count(pr[0].AsString,pr[1].AsString) );
end;

{=================================================================}
{====================== Word Wrap =============================}

procedure x_wordwrap(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  case cnt of
      1: Return.Val( WordWrap(pr[0].AsString) );
      2: Return.Val( WordWrap(pr[0].AsString,pr[1].AsInteger) );
      3: Return.Val( WordWrap(pr[0].AsString,pr[1].AsInteger,pr[2].AsString) );
      4: Return.Val( WordWrap(pr[0].AsString,pr[1].AsInteger,pr[2].AsString,pr[3].AsBoolean));
  end;
end;

{=================================================================}
{====================== levenshtein ==============================}

procedure x_levenshtein(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.ValL( ori_StrUtils.levenshtein(pr[0].AsString,pr[1].AsString) );
end;


{=================================================================}
{========================= ucfirst ===============================}

procedure x_ucfirst(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrUtils.UCFirst(pr[0].AsString) );
end;

{=================================================================}
{========================= ucwords ===============================}

procedure x_ucwords(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( ori_StrUtils.ucwords(pr[0].AsString) );
end;

{=================================================================}
{========================= sprintf ===============================}

procedure x_sprintf(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  arr: array of Pointer;
  types: TArrayByte;
  i,h: integer;
  S: MP_String;
  l: ^MP_Int;
  d: ^MP_Float;
  a: ^MP_String;
begin
  S := pr[0].AsString;
  if cnt > 1 then
  begin
      formatTypes(S,types);
      h := high(types);
      SetLength(arr,h+1);

      if pr[1].typ = mvtHash then
      begin
          with TOriTable(pr[1].Mem.ptr) do
          begin
              if h > count-1 then
                h := count-1;
              
              for i := 0 to h do
              begin
                 case types[i] of
                      1: begin new(l); l^ := Value[i].AsInteger; arr[i] := l; end;
                      2: begin new(d); d^ := Value[i].AsFloat; arr[i] := d; end;
                      3: begin new(a); a^ := Value[i].AsString; arr[i] := a; end;
                  end;
              end;
          end;
            
      end else begin
          if h > cnt-1 then
                h := cnt-1;
                
          for i := 0 to h do
          begin
              if i > cnt-1 then break;
                  case types[i] of
                      1: begin new(l); l^ := pr[i+1].AsInteger; arr[i] := l; end;
                      2: begin new(d); d^ := pr[i+1].AsFloat; arr[i] := d; end;
                      3: begin new(a); a^ := pr[i+1].AsString; arr[i] := a; end;
                  end;
          end;
      end;
  end;
  
  try
  Return.Val( sprintf(S,arr[0]) );
  except
      Return.Val(S);
  end;
  for i := 0 to h do begin
      case types[i] of
           1: dispose(PLongint(arr[i]));
           2: dispose(PDouble(arr[i]));
           3: Dispose(PAnsiString(arr[i]));
      end;

  end;
end;


function loadModule(init: boolean): byte;
begin
    if init then
    begin
          addNativeFunc('rtrim',1,@x_rtrim);
              addNativeFunc('chop',1,@x_rtrim);
          addNativeFunc('ltrim',1,@x_ltrim);
          addNativeFunc('trim',1,@x_trim);

          addNativeFunc('convert_cyr_string',3,@x_convert_cyr_string);
          addNativeFunc('count_chars',1,@x_count_chars);

          addNativeFunc('chr',1,@x_chr);
          addNativeFunc('ord',1,@x_ord);

          addNativeFunc('str_replace',3,@x_str_replace);
          addNativeFunc('str_ireplace',3,@x_str_ireplace);
          addNativeFunc('str_repeat',2,@x_str_repeat);

          addNativeFunc('soundex',1,@x_soundex);

          addNativeFunc('strip_tags',1,@x_strip_tags);

          addNativeFunc('strlen',1,@x_strlen);
          addNativeFunc('strpos',2,@x_strpos);
          addNativeFunc('stripos',2,@x_stripos);

          addNativeFunc('strstr',2,@x_strstr);
              addNativeFunc('strchr',2,@x_strstr);
          addNativeFunc('stristr',2,@x_stristr);
          addNativeFunc('strtr',3,@x_strtr);

          addNativeFunc('strrev',1,@x_strrev);
          addNativeFunc('strspn',2,@x_strspn);
          addNativeFunc('strcspn',2,@x_strcspn);
          addNativeFunc('strpbrk',2,@x_strpbrk);

          addNativeFunc('strtolower',1,@x_strtolower);
          addNativeFunc('strtoupper',1,@x_strtoupper);

          addNativeFunc('strtr',1,@x_strtr);
          addNativeFunc('substr_count',2,@x_substr_count);
          addNativeFunc('wordwrap',1,@x_wordwrap);

          addNativeFunc('levenshtein',2,@x_levenshtein);
          addNativeFunc('ucfirst',1,@x_ucfirst);
          addNativeFunc('ucwords',1,@x_ucwords);

          addNativeFunc('sprintf',1,@x_sprintf);

    end else
    begin
    
    end;
end;



initialization
   addNativeModule(@loadModule);



end.
