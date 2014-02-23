unit cPlus;


//{$mode objfpc}
{$H+}

interface

uses
  SysUtils, uTypes, FileCtrl,

  uStrUtils, uStrConsts;

  type
  ptrdiff_t = Integer;
  size_t = Integer;

  const
  NULL = nil;

  // Stdlib.h
  type
  div_t = packed record
    quot, rem: Integer;
  end;
  ldiv_t = packed record
    quot, rem: LongInt;
  end;

  const
  EXIT_SUCCESS = 0;
  EXIT_FAILURE = 1;

function calloc(nb_blocs, size: size_t): Pointer;
function malloc(size: size_t): Pointer;
procedure realloc(adr: Pointer; size: size_t);
procedure free(adr: Pointer);

procedure abort_;
procedure exit_(state: Integer);

function div_(num, den: Integer): div_t;
function ldiv(num, den: LongInt): ldiv_t;


//==============================================================================
// stdlib.h
//==============================================================================

function rand: Integer;

//==============================================================================
// Ctype.h
//==============================================================================
function isalnum(c: Integer): integer;
function isalpha(c: Integer): integer;
function iscntrl(c: Integer): integer;
function isdigit(c: Integer): integer;
function isgraph(c: Integer): integer;
function islower(c: Integer): integer;
function isprint(c: Integer): integer;
function ispunct(c: Integer): integer;
function isspace(c: Integer): integer;
function isupper(c: Integer): integer;
function isxdigit(c: Integer): integer;


//==============================================================================
// String.h
//==============================================================================
function memcpy(dst: Pointer; const src: Pointer; len: size_t): Pointer;
function memmove(dst: Pointer; const src: Pointer; len: size_t): Pointer;
function strcpy(dst: MP_PChar; const src: MP_PChar): MP_PChar;
function strncpy(dst: MP_PChar; const src: MP_PChar; len: size_t): MP_PChar;

function strcat(dst: MP_PChar; const src: MP_PChar): MP_PChar;
function strncat(dst: MP_PChar; const src: MP_PChar; len: size_t): MP_PChar;

function memcmp(const buf1, buf2: Pointer; len: size_t): Integer;
function strcmp(const str1, str2: MP_PChar): Integer;
function strcoll(const str1, str2: MP_PChar): Integer;
function strncmp(const str1, str2: MP_PChar; len: size_t): Integer;
function strxfrm(dst: MP_PChar; const src: MP_PChar; len: size_t): size_t;

function memchr(const buf: Pointer; c: Integer; len: size_t): Pointer;
function strchr(const str: MP_PChar; c: Integer): MP_PChar;
function strcspn(const str1, str2: MP_PChar): size_t;
function strpbrk(const str1, str2: MP_PChar): MP_PChar;
function strrchr(const str: MP_PChar; c: Integer): MP_PChar;
function strspn(const str1, str2: MP_PChar): size_t;
function strstr(const str1, str2: MP_PChar): MP_PChar;
function strtok(str: MP_PChar; const tok: MP_PChar): MP_PChar;

function memset(buf: Pointer; c: Integer; len: size_t): Pointer;
function strerror(nb_error: Integer): MP_PChar;
function strlen(const str1: MP_PChar): size_t;

function atoi(s: MP_PChar): Integer;
function atof(s: MP_PChar): Single;

implementation

//==============================================================================
// Stdlib.h
//==============================================================================

function calloc(nb_blocs, size: size_t): Pointer;
begin
  Result := malloc(nb_blocs * size);
end;

function malloc(size: size_t): Pointer;
begin
  GetMem(Result, size);
end;

procedure realloc(adr: Pointer; size: size_t);
begin
  ReallocMem(adr, size);
end;

procedure free(adr: Pointer);
begin
  FreeMem(adr);
end;

procedure abort_;
begin
  exit_(EXIT_FAILURE);
end;

procedure exit_(state: Integer);
begin
  Halt(state);
end;

function div_(num, den: Integer): div_t;
begin
  Result.quot := num div den;
  Result.rem := num mod den;
end;

function ldiv(num, den: LongInt): ldiv_t;
begin
  Result.quot := num div den;
  Result.rem := num mod den;
end;


//==============================================================================
// stdlib.h
//==============================================================================

function rand: Integer;
const
  RAND_MAX = $7FFF;
begin
  Result := Random(RAND_MAX);
end;


//==============================================================================
// Ctype.h
//==============================================================================

function isalnum(c: Integer): integer;
begin
  if Chr(c) in ['a'..'z', 'A'..'Z', '0'..'9'] then
    Result := 1
  else
    Result := 0;
end;

function isalpha(c: Integer): integer;
begin
  if Chr(c) in ['a'..'z', 'A'..'Z'] then
    Result := 1
  else
    Result := 0;
end;

function iscntrl(c: Integer): integer;
begin
  if Chr(c) in [#0..#31, #127] then
    Result := 1
  else
    Result := 0;
end;

function isdigit(c: Integer): integer;
begin
  if Chr(c) in ['0'..'9'] then
    Result := 1
  else
    Result := 0;
end;

function isgraph(c: Integer): integer;
begin
  if Chr(c) in [#33..#126, #128..#254] then
    Result := 1
  else
    Result := 0;
end;

function islower(c: Integer): integer;
begin
  if Chr(c) in ['a'..'z'] then
    Result := 1
  else
    Result := 0;
end;

function isprint(c: Integer): integer;
begin
  if Chr(c) in [#32..#126, #128..#254] then
    Result := 1
  else
    Result := 0;
end;

function ispunct(c: Integer): integer;
begin
  Result := 0;
  if isprint(c) = 1 then
    if (isalnum(c) + isspace(c)) = 0 then
      Result := 1;
end;

function isspace(c: Integer): integer;
begin
  if Chr(c) in [#09, #10, #11, #13, #32] then
    Result := 1
  else
    Result := 0;
end;

function isupper(c: Integer): integer;
begin
  if Chr(c) in ['A'..'Z'] then
    Result := 1
  else
    Result := 0;
end;

function isxdigit(c: Integer): integer;
begin
  if Chr(c) in ['a'..'f', 'A'..'F', '0'..'9'] then
    Result := 1
  else
    Result := 0;
end;



//==============================================================================
// String.h
//==============================================================================

function min(const a, b: Integer): Integer;
begin
  if a <= b then
    Result := a
  else
    Result := b;
end;

function memcpy(dst: Pointer; const src: Pointer; len: size_t): Pointer;
begin
  Move(src^, dst^, len);
  Result := dst;
end;

function memmove(dst: Pointer; const src: Pointer; len: size_t): Pointer;
begin
  Move(src^, dst^, len);
  Result := dst;
end;

function strcpy(dst: MP_PChar; const src: MP_PChar): MP_PChar;
begin
  Result := memcpy(dst, src, strlen(src) + 1);
end;

function strncpy(dst: MP_PChar; const src: MP_PChar; len: size_t): MP_PChar;
begin
  Result := memcpy(dst, src, min(strlen(src) + 1, len));
end;

function strcat(dst: MP_PChar; const src: MP_PChar): MP_PChar;
begin
  Result := dst;
  while dst[0] <> #0 do
    Inc(Dst);
  memcpy(dst, src, strlen(src) + 1);
end;

function strncat(dst: MP_PChar; const src: MP_PChar; len: size_t): MP_PChar;
begin
  Result := dst;
  while dst[0] <> #0 do
    Inc(Dst);
  memcpy(dst, src, min(strlen(src) + 1, len));
end;

function memcmp(const buf1, buf2: Pointer; len: size_t): Integer;
var
  i: Integer;
begin
  Result := 0;
  i := 0;
  while (i < len) and (Result = 0) do
  begin
    if MP_PChar(buf1)[i] < MP_PChar(buf2)[i] then
      Result := -1
    else if MP_PChar(buf1)[i] > MP_PChar(buf2)[i] then
      Result := 1;
    Inc(i);
  end;
end;

function strcmp(const str1, str2: MP_PChar): Integer;
var
  l1, l2: Integer;
begin
  l1 := strlen(str1);
  l2 := strlen(str2);
  Result := memcmp(str1, str2, min(l1, l2));
  if Result = 0 then
    if l1 < l2 then
      Result := -1
    else if l1 > l2 then
      Result := 1;
end;

function strcoll(const str1, str2: MP_PChar): Integer;
begin
  Result := strcmp(str1, str2);
end;

function strncmp(const str1, str2: MP_PChar; len: size_t): Integer;
var
  l1, l2: Integer;
begin
  l1 := min(strlen(str1), len);
  l2 := min(strlen(str2), len);
  Result := memcmp(str1, str2, min(l1, l2));
  if Result = 0 then
    if l1 < l2 then
      Result := -1
    else if l2 > l1 then
      Result := 1;
end;

function strxfrm(dst: MP_PChar; const src: MP_PChar; len: size_t): size_t;
begin
  Result := strlen(src);
  if Result <= len then
    strcpy(dst, src);
end;

function memchr(const buf: Pointer; c: Integer; len: size_t): Pointer;
var
  l: Char;
begin
  Result := buf;
  l := chr(c);
  while len <> 0 do
  begin
    if MP_PChar(Result)[0] = l then
      Exit;
    Inc(Integer(Result));
    Dec(len);
  end;
  Result := NULL;
end;

function strchr(const str: MP_PChar; c: Integer): MP_PChar;
begin
  Result := memchr(str, c, strlen(str) + 1);
end;

function strcspn(const str1, str2: MP_PChar): size_t;
var
  t: MP_PChar;
begin
  Result := 0;
  t := str1;
  while t[0] <> #0 do
  begin
    if strchr(str2, Ord(t[0])) <> NULL then
      Exit;
    Inc(Result);
    Inc(t);
  end;
end;

function strpbrk(const str1, str2: MP_PChar): MP_PChar;
begin
  Result := str1;
  while Result[0] <> #0 do
  begin
    if strchr(str2, Ord(Result[0])) <> NULL then
      Exit;
    Inc(Result);
  end;
  Result := NULL;
end;

function strrchr(const str: MP_PChar; c: Integer): MP_PChar;
var
  len: Integer;
  l: Char;
begin
  len := strlen(str);
  Result := str + len;
  l := chr(c);
  while len <> 0 do
  begin
    if Result[0] = l then
      Exit;
    Dec(Result);
    Dec(len);
  end;
  Result := NULL;
end;

function strspn(const str1, str2: MP_PChar): size_t;
var
  t: MP_PChar;
begin
  Result := 0;
  t := str1;
  while t[0] <> #0 do
  begin
    if strchr(str2, Ord(t[0])) = NULL then
      Exit;
    Inc(Result);
    Inc(t);
  end;
end;

function strstr(const str1, str2: MP_PChar): MP_PChar;
var
  l: Integer;
begin
  l := strlen(str2);
  Result := str1;
  while Result[0] <> #0 do
  begin
    if strncmp(Result, str2, l) = 0 then
      Exit;
    Inc(Result);
  end;
  Result := NULL;
end;

var
  strtok_str: MP_PChar;

function strtok(str: MP_PChar; const tok: MP_PChar): MP_PChar;
begin
  if str <> NULL then
    strtok_str := str;
  Result := strtok_str;
  while strtok_str[0] <> #0 do
  begin
    if strchr(tok, Ord(strtok_str[0])) <> NULL then
    begin
      strtok_str[0] := #0;
      Inc(strtok_str);
      Exit;
    end;
    Inc(strtok_str);
  end;
  Result := NULL;
end;

function memset(buf: Pointer; c: Integer; len: size_t): Pointer;
begin
  FillChar(buf^, len, c);
  Result := buf;
end;

function strerror(nb_error: Integer): MP_PChar;
begin
  Result := NULL;
end;

function strlen(const str1: MP_PChar): size_t;
begin
  Result := 0;
  while str1[Result] <> #0 do
    Inc(Result);
end;

function atoi(s: MP_PChar): Integer;
begin
  Result := StrToIntDef(s, 0);
end;

function atof(s: MP_PChar): Single;
var
  s2: MP_String;
  i: Integer;
begin
  s2 := s;
  for i := 1 to Length(s2) do
  begin
    if s2[i] in ['.', ','] then
      s2[i] := SysUtils.DecimalSeparator;
  end;
  Result := StrToFloatDef(s2, 0.0);
end;






end.