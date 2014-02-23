unit ori_Math;


//{$mode objfpc}
{$H+}

interface

uses
  SysUtils, Math, ori_Types;

  function base_convert(NumIn: MP_String; BaseIn: Byte; BaseOut: Byte): MP_String;
  function bindec(Value: MP_String): MP_Int;
  function decbin( Int: Integer ): MP_String; inline;
  function dechex(const d: MP_Int): MP_String; inline;
  function decoct(Src: Longint): MP_String; inline;
  function hexdec(hex: MP_string): Longint;
  function octdec(oct: MP_String): Longint;

implementation

function base_convert(NumIn: MP_String; BaseIn: Byte; BaseOut: Byte): MP_String;
var
  i: integer;
  currentCharacter: MP_Char;
  CharacterValue: Integer;
  PlaceValue: Integer;
  RunningTotal: Double;
  Remainder: Double;
  BaseOutDouble: Double;
  NumInCaps: MP_String;
  s: MP_String;
begin
  if (NumIn = '') or (BaseIn < 2) or (BaseIn > 36) or (BaseOut < 1) or (BaseOut
    > 36) then
  begin
    Result := '';
    Exit;
  end;

  NumInCaps := UpperCase(NumIn);
  PlaceValue := Length(NumInCaps);
  RunningTotal := 0;

  for i := 1 to Length(NumInCaps) do
  begin
    PlaceValue := PlaceValue - 1;
    CurrentCharacter := NumInCaps[i];
    CharacterValue := 0;
    if (Ord(CurrentCharacter) > 64) and (Ord(CurrentCharacter) < 91) then
      CharacterValue := Ord(CurrentCharacter) - 55;

    if CharacterValue = 0 then
      if (Ord(CurrentCharacter) < 48) or (Ord(CurrentCharacter) > 57) then
      begin
        Result := '';
        Exit;
      end
      else
        CharacterValue := Ord(CurrentCharacter) - 48;

    if (CharacterValue < 0) or (CharacterValue > BaseIn - 1) then
    begin
      Result := '';
      Exit;
    end;
    RunningTotal := RunningTotal + CharacterValue * (Power(BaseIn, PlaceValue));
  end;

  while RunningTotal > 0 do
  begin
    BaseOutDouble := BaseOut;
    Remainder := RunningTotal - (int(RunningTotal / BaseOutDouble) *
      BaseOutDouble);
    RunningTotal := (RunningTotal - Remainder) / BaseOut;

    if Remainder >= 10 then
      CurrentCharacter := MP_Char(Trunc(Remainder + 55))
    else
    begin
      s := IntToStr(trunc(remainder));
      CurrentCharacter := s[Length(s)];
    end;
    Result := CurrentCharacter + Result;
  end;
end;

function bindec(Value: MP_String): MP_Int;
var
   i, iValueSize: Integer;
begin
   Result := 0;
   iValueSize := Length(Value);
   for i := iValueSize downto 1 do
     if Value[i] = '1' then Result := Result + (1 shl (iValueSize - i));
end;

function decbin( Int: Integer ): MP_String;
var
  i, j: Integer;
begin
  Result := '';
  i := 0;
  j := 1;
  while i = 0 do
    if( ( Int Mod (j*2) ) = Int )
      then i := j
      else j := j * 2;
  while i > 0 do
  begin
    if( ( Int div i ) > 0 ) then
    begin
      Int := Int - i;
      Result := Result + '1';
    end
    else Result := Result + '0';
    i := Trunc( i * 0.5 );
  end;
end;

 function dechex(const d: MP_Int): MP_String;
 begin
   Result := LowerCase(IntToHex(d,0));
 end;

function hexdec(hex: MP_string): Longint;
  function getValue(hex: MP_char): Longint;
  begin
	  if (Ord(hex) > 47) and (Ord(hex) < 57) then
		  Result:= Ord(hex) - 48
	  else if (Ord(hex) > 96) then
		  Result:= Ord(hex) - 87
	  else
		  Result:= Ord(hex)-55;
  end;

var
  i,r: Integer;
begin
  r:=0;
  for i := 1 to Length(hex) do
    r := r*16+ getValue(hex[i]);
  Result := r;
end;


function decoct(Src: Longint): MP_String;
const DICT = '01234567';
begin
  Result := '';
  repeat
    Result := DICT[(Src mod 8) + 1] + Result;
    Src := Src div 8;
  until (Src div 8) = 0;
  Result := DICT[(Src mod 8) + 1] + Result;
end;

function octdec(oct: MP_String): Longint;
begin
    Result := StrToIntDef( base_convert(oct,8,10),0 );
end;


end.
