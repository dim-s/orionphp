﻿unit ori_Stack;


{$H+}
{$i './VM/ori_Options.inc'}
{$ifdef fpc}
{$mode delphi}
{$endif}

interface

uses
  Classes, SysUtils,
  ori_StrConsts,
  ori_StrUtils,
  ori_Types,
  ori_vmValues,
  ori_vmCrossValues,
  ori_vmTypes,
  ori_FastArrays,
  ori_vmMemory;


      type
      TOpcodeLine = packed record
            Line: cardinal;
            Typ: Byte;
            oper1: TOriMemory;
            oper2: TOriMemory;

            cnt: Integer; // число, иногда нужный параметр
            id:  integer;  // id в текущей таблице
            toStack: boolean;
            checkMemory: boolean;
            ptr: pointer;
      end;

      POpcodeLine = ^TOpcodeLine;

      // возвращает тру, если в стеке есть число, без разнице где и какое (дробное или целое)
      {function isRealNumber(const v: PStackValue): boolean;
      // возвращает тру, если в стеке есть булеан, =//= , null считает за булеан как false!!!
      function isRealBoolean(const v: PStackValue): boolean;
      }
      
      //function isRealNumeric(const v: PStackValue): Byte;

      type
      TOpcodeArray = class(TPtrArray)

      private
          function GetValue(Index: Integer): POpcodeLine; inline;
          procedure SetValue(Index: Integer; const Value: POpcodeLine); inline;
          procedure NewSize(const Size: Integer);
      public
          procedure DoClone(donor: TOpcodeArray);
          procedure SetLength(const Size: Integer); inline;
          property Value[Index: Integer]: POpcodeLine read GetValue write SetValue; default;
      end;
      function cloneOpcode(op: POpcodeLine): POpcodeLine;

      

implementation

  uses ori_Parser;

{ TOpcodeArray }

procedure TOpcodeArray.DoClone(donor: TOpcodeArray);
  var
  i: integer;
begin
   Clear;
   Self.SetLength(donor.Count);
   for i := 0 to donor.Count - 1 do
   begin
      Values^[i] := cloneOpcode(POpcodeLine(donor.Values^[i]));
   end;
end;

function TOpcodeArray.GetValue(Index: Integer): POpcodeLine;
begin
    Result := POpcodeLine( Values^[Index] );
end;

procedure TOpcodeArray.NewSize(const Size: Integer);
begin
   inherited NewSize(size);
end;

procedure TOpcodeArray.SetLength(const Size: Integer);
begin
  if Size > RealSize then
  begin
   inherited NewSize(Size);
  end;

   Count := Size;
end;

procedure TOpcodeArray.SetValue(Index: Integer; const Value: POpcodeLine);
begin
   Values^[Index] := Value;
end;

function cloneOpcode(op: POpcodeLine): POpcodeLine;
  var
  f: PCodeFunction;
  p: PCodeProperty;
  c: PCodeClass;
begin
  new(Result);
  Result^ := op^;
  if op^.oper1 = nil then Result^.oper1 := nil
  else begin
      Result^.oper1 := TOriMemory.Create;
      Result^.oper1.Assign( op.oper1 );
      if op.typ in [OP_DEFINE_FUNC,OP_DEF_METHOD] then
      begin
         new(f);
         f^ := PCodeFunction(op^.oper1.mem.ptr)^;
         Result^.oper1.mem.ptr := f;
      end else
      if op^.typ in [OP_CLASS_PROPERTY,OP_CLASS_CONST] then
      begin
         new(p);
         p^ := PCodeProperty(op^.oper1.mem.ptr)^;
         Result^.oper1.mem.ptr := p;
      end;
  end;

  if op^.oper2 = nil then Result^.oper2 := nil
  else begin
      Result^.oper2 := TOriMemory.Create;
      Result^.oper2.Assign( op.oper2 );
  end;
  
end;

end.


