unit ori_vmLoader;

// IN PROGRESS
// модуль для загрузки и сохранения байткода в память
//{$mode objfpc}
{$H+}

interface

uses
  SysUtils, Classes,
  ori_StrUtils,
  ori_Types,
  ori_vmTypes,
  ori_Stack,
  ori_vmMemory;

  procedure ori_bcodeSave(code: TOpcodeArray; s: TStream);
  procedure ori_bcodeLoad(code: TOpcodeArray; s: TStream);
  procedure ori_bcodeSaveFile(code: TOpcodeArray; const FileName: String);
  procedure ori_bcodeLoadFile(code: TOpcodeArray; const FileName: String);
  procedure ori_bcodeSaveString(code: TOpcodeArray; var S: AnsiString);
  procedure ori_bcodeLoadString(code: TOpcodeArray; const S: AnsiString);

  const
    ORI_PREFIX_Format = 'ORI'#0#0;
    ORI_PREFIX_Num    = 7520;

implementation

   uses
   ori_vmCompiler,
   ori_Parser;

procedure String2Stream(a: AnsiString; b: TMemoryStream);
begin
b.Position := 0;
b.WriteBuffer(Pointer(a)^,Length(a));
b.Position := 0;
end;

procedure Stream2String(b: TStream; var a: AnsiString);
begin
b.Position := 0;
SetLength(a,b.Size);
b.ReadBuffer(Pointer(a)^,b.Size);
b.Position := 0;
end;


procedure ori_bcodeSaveString(code: TOpcodeArray; var S: AnsiString);
   var
   M: TMemoryStream;
begin
   try
     M := TMemoryStream.Create;
     ori_bcodeSave(code, M);
     Stream2String(M, S);
   finally
     M.Free;
   end;
end;

procedure ori_bcodeLoadString(code: TOpcodeArray; const S: AnsiString);
   var
   M: TMemoryStream;
begin
   try
      M := TMemoryStream.Create;
      String2Stream(S, M);
      ori_bcodeLoad(code, M);
   finally
      M.Free;
   end;
end;

procedure ori_bcodeSaveFile(code: TOpcodeArray; const FileName: String);
   var
   M: TFileStream;
begin
   try
      M := TFileStream.Create(FileName, fmCreate or fmOpenWrite);
      M.Write(ORI_PREFIX_Format, Length(ORI_PREFIX_Format));
      ori_bcodeSave(code, M);
   finally
       M.Free;
   end;
end;

procedure ori_bcodeLoadFile(code: TOpcodeArray; const FileName: String);
   var
   M: TMemoryStream;
begin
   try
      M := TMemoryStream.Create();
      M.LoadFromFile(FileName);
      M.Position := length(ORI_PREFIX_Format);
      ori_bcodeLoad(code, M);
   finally
       M.Free;
   end;
end;


procedure ReadFloat(Stream: TStream; var Value: Double); overload; inline;
begin
Stream.Read(Value, SizeOf(Double));
end;

procedure ReadFloat(Stream: TStream; var Value: Extended); overload; inline;
begin
Stream.Read(Value, SizeOf(extended));
end;

procedure ReadFloat(Stream: TStream; var Value: Single); overload; inline;
begin
Stream.Read(Value, SizeOf(Single));
end;

procedure ReadFloat(Stream: TStream; var Value: Real); overload; inline;
begin
Stream.Read(Value, SizeOf(Real));
end;

procedure WriteFloat(Stream: TStream; const Value: Double); overload; inline;
begin
Stream.Write(Value, SizeOf(Double));
end;

procedure WriteFloat(Stream: TStream; const Value: Extended); overload; inline;
begin
Stream.Write(Value, SizeOf(Extended));
end;

procedure WriteFloat(Stream: TStream; const Value: Single); overload; inline;
begin
Stream.Write(Value, SizeOf(Single));
end;

procedure WriteLongInt(Stream: TStream; const Value: LongInt); inline;
begin
Stream.Write(Value, SizeOf(LongInt));
end;


procedure ReadLongInt(Stream: TStream; var Value: Longint); inline;
begin
Stream.Read(Value, SizeOf(Longint));
end;

procedure ReadCardinal(Stream: TStream; var Value: Cardinal); inline;
begin
Stream.Read(Value, SizeOf(Cardinal));
end;


procedure WriteBool(Stream: TStream; const Value: Boolean); inline;
begin
Stream.Write(Value, SizeOf(Boolean));
end;

procedure ReadBool(Stream: TStream; var Value: Boolean); inline;
begin
Stream.Read(Value, SizeOf(Boolean));
end;


procedure WriteByte(Stream: TStream; const Value: Byte); inline;
begin
Stream.Write(Value, SizeOf(Byte));
end;

procedure ReadByte(Stream: TStream; var Value: Byte); inline;
begin
Stream.Read(Value, SizeOf(Byte));
end;


procedure WriteString(Stream: TStream; const Value: MP_String);
var
L: LongInt;
begin
  L := Length(Value);
  WriteLongInt(Stream, L);
  Stream.Write(Value[1], L);
end;

procedure ReadString(Stream: TStream; var Value: MP_String); inline;
  var
  L: LongInt;
begin
  ReadLongInt(Stream, L);
  SetLength(Value, L);
  Stream.Read(Value[1], L);
end;


procedure WriteCnst(Stream: TStream; var Value: TVMConstant);
begin
  WriteByte(Stream, byte(Value.typ));
  //Stream.Write( Value.modifer
  case Value.typ of
    mvtInteger: WriteLongInt(Stream, Value.lval);
    mvtDouble: WriteFloat(Stream, Value.dval);
    mvtString: WriteString(Stream, Value.str) ;
    mvtNull: ;
    mvtBoolean: WriteBool(Stream, Value.bval);
  end;
end;

procedure ReadCnst(Stream: TStream; var Value: TVMConstant);
  var
  b: byte;
begin
  ReadByte(Stream, Value.typ);

  case Value.typ of
    mvtInteger: ReadLongInt(Stream, Value.lval);
    mvtDouble: ReadFloat(Stream, Value.dval);
    mvtString: ReadString(Stream, Value.str) ;
    mvtNull: ;
    mvtBoolean: ReadBool(Stream, Value.bval);
  end;
end;

procedure stack_Save(oper: TOriMemory; s: TStream);
begin
   if oper = nil then
   begin
      WriteLongInt(s, -1);
      exit;
   end;

   WriteByte(s, oper.typ);
   WriteLongInt(s, oper.id);
   case oper.typ of
      mvtInteger: WriteLongInt(s, oper.mem.lval);
      mvtDouble : WriteFloat(s, oper.mem.dval);
      mvtBoolean: WriteBool(s, oper.mem.bval);
      mvtWord,mvtString: WriteString(s, oper.mem.str);
      mvtVariable,mvtGlobalVar: WriteString(s, oper.mem.str);
   end;
end;

procedure stack_Load(var oper: TOriMemory; s: TStream);
  var
  typ: Byte;
begin
  ReadByte(s, typ);

  if typ = -1 then
   begin
      oper := nil;
      exit;
   end;
   oper := TOriMemory.Create;

   oper.typ := typ;
   ReadLongInt(s, oper.id);
   case oper.typ of
      mvtInteger: ReadLongInt(s, oper.mem.lval);
      mvtDouble : ReadFloat(s, oper.mem.dval);
      mvtBoolean: ReadBool(s, oper.mem.bval);
      mvtWord,mvtString: ReadString(s, oper.mem.str);
      mvtVariable,mvtGlobalVar: ReadString(s, oper.mem.str);
   end;
end;


procedure line_Save(line: POpcodeLine; s: TStream);
begin
    WriteLongInt(s, line^.line);
    WriteByte(s, line^.typ);
    WriteLongInt(s, line^.cnt);
    WriteLongInt(s, line^.id);
    WriteBool(s, line^.toStack);
    WriteBool(s, line^.checkMemory);

    stack_Save(line^.oper1, s);
    stack_Save(line^.oper2, s);
end;

procedure line_Load(line: POpcodeLine; s: TStream);
begin
    ReadCardinal(s, line^.line);
    ReadByte(s, line^.typ);
    ReadLongInt(s, line^.cnt);
    ReadLongInt(s, line^.id);
    ReadBool(s, line^.toStack);
    ReadBool(s, line^.checkMemory);

    stack_Load(line^.oper1, s);
    stack_Load(line^.oper2, s);
end;

procedure func_Save(func: PCodeFunction; s: TStream);
 var
  l,i: Longint;
begin
   WriteString(s, Func^.name);
   WriteByte(s, byte(Func^.modifer));
   WriteBool(s, func^.isStatic);

   l := length(Func^.vars);
   WriteLongInt(s, l);
   for i := 0 to l - 1 do
      WriteString(s, func^.vars[i]);

   l := length(Func^.vars_link);
   WriteLongInt(s, l);
   for i := 0 to l - 1 do
      WriteBool(s, func^.vars_link[i]);

   l := Length(Func^.defs);
   WriteLongInt(s, l);
   for i := 0 to l - 1 do
      WriteCnst(s, Func^.defs[i]);
end;

procedure prop_Save(prop: PCodeProperty; s: TStream);
begin
  WriteString(s, prop^.name);
  WriteByte(s, byte(prop^.modifer));
  WriteBool(s, prop^.isStatic);
  WriteBool(s, prop^.isConst);
  WriteString(s, prop^.expr);
end;


procedure func_Load(var oper: TOriMemory; s: TStream);
 var
  l,i: Longint;
  b: byte;
  func: PCodeFunction;
begin
   new(func);
   if oper = nil then oper := TOriMemory.Create;

   oper.mem.ptr := func;
   ReadString(s, Func^.name);

   ReadByte(s, b);
   Func^.modifer := TOriMethod_modifer(b);
   ReadBool(s, func^.isStatic);

   ReadLongInt(s, l);
   SetLength(func^.vars, l);
   for i := 0 to l - 1 do
      ReadString(s, func^.vars[i]);

   ReadLongInt(s, l);
   SetLength(func^.vars_link, l);
   for i := 0 to l - 1 do
      ReadBool(s, func^.vars_link[i]);

   ReadLongInt(s, l);
   SetLength(func^.defs, l);
   for i := 0 to l - 1 do
      ReadCnst(s, func^.defs[i]);
end;

procedure prop_Load(var oper: TOriMemory; s: TStream);
 var
  b: byte;
  prop: PCodeProperty;
begin
   new(prop);
   if oper = nil then oper := TOriMemory.Create;

   oper.mem.ptr := prop;
   ReadString(s, prop^.name);

   ReadByte(s, b);
   prop^.modifer := TOriMethod_modifer(b);

   ReadBool(s, prop^.isStatic);
   ReadBool(s, prop^.isStatic);
   ReadString(s, prop^.expr);
end;

procedure ori_bcodeSave(code: TOpcodeArray; s: TStream);
   var
   i: Integer;
begin
   WriteLongInt(s, code.Count);
   for i := 0 to code.Count - 1 do
   begin
        line_Save(code[i], s);
        case code[i]^.typ of
        OP_DEFINE_FUNC,OP_DEF_METHOD: func_Save(code[i]^.oper1.mem.ptr, s);
        OP_CLASS_PROPERTY, OP_CLASS_CONST: prop_Save(code[i]^.oper1.mem.ptr, s);
        end;
   end;
end;

procedure ori_bcodeLoad(code: TOpcodeArray; s: TStream);
   var
   i,len: Integer;
begin
   discardOpcodeS(code);
   ReadLongInt(S, len);
   code.SetLength(len);
   
   for i := 0 to len - 1 do
   begin
        new(POpcodeLine(code.Values^[i]));
        line_Load(code[i], s);
        if code[i]^.typ = OP_DEFINE_FUNC then
          func_Load(code[i]^.oper1, s);
   end;
end;

end.
