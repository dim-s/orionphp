unit ori_Hash32;
 
interface


   uses SysUtils;

function RSHash   (const Str : String) : Cardinal;
function JSHash   (const Str : String) : Cardinal;
function PJWHash  (const Str : String) : Cardinal;
function ELFHash  (const Str : String) : Cardinal;
function BKDRHash (const Str : String) : Cardinal;
function maBKDRHash(const Str : AnsiString) : Cardinal; overload; // for hashtable
function maBKDRHash(const Id: Word): Cardinal; inline; overload;
function maPrime2dHash (const Str: AnsiString): Cardinal;
function MaHash8v64 (const str: string): Cardinal;
function SDBMHash (const Str : String) : Cardinal;
function DJBHash  (const Str : String) : Cardinal;
function DEKHash  (const Str : String) : Cardinal;
function FNVHash  (const Str : String) : Cardinal;
function APHash   (const Str : String) : Cardinal;

const
     maBKDR_max = High(Word);

var
     maBKDR_numbers: array of Cardinal;
           
implementation


function RSHash(const Str : String) : Cardinal;
const b = 378551;
var
  a : Cardinal;
  i : Integer;
begin
  a      := 63689;
  Result := 0;
  for i := 1 to Length(Str) do
  begin
    Result := Result * a + Ord(Str[i]);
    a      := a * b;
  end;
end;
(* End Of RS Hash function *)
 
 
function JSHash(const Str : String) : Cardinal;
var
  i : Integer;
begin
  Result := 1315423911;
  for i := 1 to Length(Str) do
  begin
    Result := Result xor ((Result shl 5) + Ord(Str[i]) + (Result shr 2));
  end;
end;
(* End Of JS Hash function *)
 
 
function PJWHash(const Str : String) : Cardinal;
const BitsInCardinal = Sizeof(Cardinal) * 8;
const ThreeQuarters  = (BitsInCardinal  * 3) div 4;
const OneEighth      = BitsInCardinal div 8;
const HighBits       : Cardinal = (not Cardinal(0)) shl (BitsInCardinal - OneEighth);
var
  i    : Cardinal;
  Test : Cardinal;
begin
  Result := 0;
  for i := 1 to Length(Str) do
  begin
    Result := (Result shl OneEighth) + Ord(Str[i]);
    Test   := Result and HighBits;
    If (Test <> 0) then
    begin
      Result := (Result xor (Test shr ThreeQuarters)) and (not HighBits);
    end;
  end;
end;
(* End Of P. J. Weinberger Hash function *)
 
 
function ELFHash(const Str : String) : Cardinal;
var
  i : Cardinal;
  x : Cardinal;
begin
  Result := 0;
  for i := 1 to Length(Str) do
  begin
    Result := (Result shl 4) + Ord(Str[i]);
    x      := Result and $F0000000;
    if (x <> 0) then
    begin
      Result := Result xor (x shr 24);
    end;
    Result := Result and (not x);
  end;
end;
(* End Of ELF Hash function *)
 
 
function BKDRHash(const Str : String) : Cardinal;
const Seed = 31; (* 31 131 1313 13131 131313 etc... *)
var
  i,len: Cardinal;
begin
  Result := 0;
  len := Length(Str);
  for i := 1 to Len do
  begin
    Result := (Result * Seed) + Ord(Str[i]);
  end;
end;

const
  sTable: array[0..255] of Byte =
(
  $00a3,$00d7,$0009,$0083,$00f8,$0048,$00f6,$00f4,$00b3,$0021,$0015,$0078,$0099,$00b1,$00af,$00f9,
  $00e7,$002d,$004d,$008a,$00ce,$004c,$00ca,$002e,$0052,$0095,$00d9,$001e,$004e,$0038,$0044,$0028,
  $000a,$00df,$0002,$00a0,$0017,$00f1,$0060,$0068,$0012,$00b7,$007a,$00c3,$00e9,$00fa,$003d,$0053,
  $0096,$0084,$006b,$00ba,$00f2,$0063,$009a,$0019,$007c,$00ae,$00e5,$00f5,$00f7,$0016,$006a,$00a2,
  $0039,$00b6,$007b,$000f,$00c1,$0093,$0081,$001b,$00ee,$00b4,$001a,$00ea,$00d0,$0091,$002f,$00b8,
  $0055,$00b9,$00da,$0085,$003f,$0041,$00bf,$00e0,$005a,$0058,$0080,$005f,$0066,$000b,$00d8,$0090,
  $0035,$00d5,$00c0,$00a7,$0033,$0006,$0065,$0069,$0045,$0000,$0094,$0056,$006d,$0098,$009b,$0076,
  $0097,$00fc,$00b2,$00c2,$00b0,$00fe,$00db,$0020,$00e1,$00eb,$00d6,$00e4,$00dd,$0047,$004a,$001d,
  $0042,$00ed,$009e,$006e,$0049,$003c,$00cd,$0043,$0027,$00d2,$0007,$00d4,$00de,$00c7,$0067,$0018,
  $0089,$00cb,$0030,$001f,$008d,$00c6,$008f,$00aa,$00c8,$0074,$00dc,$00c9,$005d,$005c,$0031,$00a4,
  $0070,$0088,$0061,$002c,$009f,$000d,$002b,$0087,$0050,$0082,$0054,$0064,$0026,$007d,$0003,$0040,
  $0034,$004b,$001c,$0073,$00d1,$00c4,$00fd,$003b,$00cc,$00fb,$007f,$00ab,$00e6,$003e,$005b,$00a5,
  $00ad,$0004,$0023,$009c,$0014,$0051,$0022,$00f0,$0029,$0079,$0071,$007e,$00ff,$008c,$000e,$00e2,
  $000c,$00ef,$00bc,$0072,$0075,$006f,$0037,$00a1,$00ec,$00d3,$008e,$0062,$008b,$0086,$0010,$00e8,
  $0008,$0077,$0011,$00be,$0092,$004f,$0024,$00c5,$0032,$0036,$009d,$00cf,$00f3,$00a6,$00bb,$00ac,
  $005e,$006c,$00a9,$0013,$0057,$0025,$00b5,$00e3,$00bd,$00a8,$003a,$0001,$0005,$0059,$002a,$0046
);

function MaHash8v64 (const str: string): Cardinal;
   function LROT14(const x: integer): integer; inline;
   begin
      Result := ((x shl 14) or (x shr 18));
   end;
   function RROT14(const x: integer): integer; inline;
   begin
      Result := ((x shl 18) or (x shr 14));
   end;

   var
   sh1,sh2,hash1,hash2,len,i,x,y: integer;
   digest: cardinal;
begin
  len := length(str);
  hash1 := len;
  hash2 := len;

  for i := 1 to len do
  begin
     x := sTable[(ord(str[i]) + i - 1) and 255];
     inc(hash1, x);
     hash1 := LROT14(hash1 + ((hash1 shl 6) xor (hash1 shr 11)));

     inc(hash2, x);
     hash2 := RROT14(hash2 + ((hash2 shl 6) xor (hash2 shr 11)));

     sh1 := hash1;
     sh2 := hash2;

    hash1 := ((sh1 shr 16) and $00ffff) or ((sh2 and $00ffff) shl 16);
    hash2 := ((sh2 shr 16) and $00ffff) or ((sh1 and $00ffff) shl 16);
  end;

  Result := (hash2 shl 32) or hash1;
end;


function maPrime2dHash (const Str: AnsiString): Cardinal;
const
   seed = $001A4E41;

var
  len,hash: Cardinal;
  i: integer;
  rotate: integer;

begin
  hash := 0;
  rotate := 2;
  len := length(Str);

  for i := 1 to len do
  begin
      inc(hash, sTable[(ord(str[i])+(i-1)) and 255]);
      hash := (hash shl (32 - rotate) ) or (hash shr rotate);
      hash := (hash + (i-1)) * seed;
  end;

  Result := (hash + len) * seed;
end;


function maBKDRHash(const Str : AnsiString) : Cardinal;
const Seed = 131313; (* 31 131 1313 13131 131313 etc... *)
var
  i,len : Integer;
begin
  Result := 0;
  len := length(str);
  for i := 1 to len do
    Result := (Result * Seed) + Ord(Str[i]){ + i};
end;
(* End Of BKDR Hash function *)

procedure initMaBKDR();
  var
  i: Integer;
begin
  SetLength(maBKDR_numbers,maBKDR_max+1);

  for i := 0 to maBKDR_max do
      maBKDR_numbers[i] := maBKDRHash(IntToStr(i));
end;

function maBKDRHash(const Id: Word): Cardinal;
begin
  Result := maBKDR_numbers[Id];
end;
 
 
function SDBMHash(const Str : String) : Cardinal;
var
  i : Cardinal;
begin
  Result := 0;
  for i := 1 to Length(Str) do
  begin
    Result := Ord(str[i]) + (Result shl 6) + (Result shl 16) - Result;
  end;
end;
(* End Of SDBM Hash function *)
 
 
function DJBHash(const Str : String) : Cardinal;
var
  i : Cardinal;
begin
  Result := 5381;
  for i := 1 to Length(Str) do
  begin
    Result := ((Result shl 5) + Result) + Ord(Str[i]);
  end;
end;
(* End Of DJB Hash function *)
 
 
function DEKHash(const Str : String) : Cardinal;
var
  i : Cardinal;
begin
  Result := Length(Str);
  for i := 1 to Length(Str) do
  begin
    Result := ((Result shr 5) xor (Result shl 27)) xor Ord(Str[i]);
  end;
end;
(* End Of DEK Hash function *)
 
 
function BPHash(const Str : String) : Cardinal;
var
  i : Cardinal;
begin
  Result := 0;
  for i := 1 to Length(Str) do
  begin
    Result := Result shl 7 xor Ord(Str[i]);
  end;
end;
(* End Of BP Hash function *)
 
 
function FNVHash(const Str : String) : Cardinal;
const FNVPrime = $811C9DC5;
var
  i : Cardinal;
begin
  Result := 0;
  for i := 1 to Length(Str) do
  begin
    Result := Result * FNVPrime;
    Result := Result xor Ord(Str[i]);
  end;
end;
(* End Of FNV Hash function *)
 
 
function APHash(const Str : String) : Cardinal;
var
  i : Cardinal;
begin
  Result := $AAAAAAAA;
  for i := 1 to Length(Str) do
  begin
    if ((i - 1) and 1) = 0 then
      Result := Result xor ((Result shl 7) xor Ord(Str[i]) * (Result shr 3))
    else
      Result := Result xor (not((Result shl 11) + Ord(Str[i]) xor (Result shr 5)));
  end;
end;
(* End Of AP Hash function *)

initialization
   initMaBKDR();
     
 
 
end.
