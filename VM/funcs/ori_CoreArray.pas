unit ori_CoreArray;


//{$mode objfpc}
{$H+}
{$WARNINGS OFF}
{$I '../ori_Options.inc'}

interface

uses
  Classes, SysUtils,
  ori_vmCrossValues,
  ori_vmTables,
  ori_Types,
  ori_vmConstants,
  ori_vmEval,
  ori_ManRes,
  ori_StrUtils,
  ori_vmTypes,
  ori_Errors,
  ori_vmValues,
  ori_StrConsts,
  ori_vmNativeFunc,
  ori_vmMemory;

const
  CASE_LOWER = 0;
  CASE_UPPER = 1;

implementation


procedure x_in_array(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
var
  i:      integer;
  v:      MP_String;
  strong: Boolean;
begin
  if pr[1].IsArray then
    begin
    if cnt > 2 then
      strong := pr[2].AsBoolean
    else
      strong := False;

    with TOriTable(pr[1].Mem.ptr) do
      begin
      if strong then
        for i := 0 to count - 1 do
          begin
          if pr[0].EqualTyped(Value[i]) then
            begin
            Return.Val(True);
            exit;
            end;
          end
      else
        begin
        v := pr[0].AsString;
        for i := 0 to count - 1 do
          if Value[i].AsString = v then
            begin
            Return.Val(True);
            exit;
            end;
        end;

      Return.Val(False);
      end;
    end
  else
    begin
    Return.Val(False);

    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['2']),
      TOriEval(eval).tk^.line);
    // errors
    end;
end;

procedure x_count(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
     Return.ValL( TOriTable(pr[0].mem.ptr).count )
  else
     Return.ValL(0);
end;

procedure x_current(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    begin
    with TOriTable(pr[0].mem.ptr) do
      if Seek > count - 1 then
        Return.Val(False)
      else
        Return.Val( Current,false );
    end
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;

procedure x_eof(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    with TOriTable(pr[0].mem.ptr) do
       Return.Val(Seek > count - 1)
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;

procedure x_end(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
  begin
    with TOriTable(pr[0].mem.ptr) do
      begin
      if count = 0 then
        Return.Val(False)
      else
        begin
        Seek := count - 1;
        Return.Val( Current,false );
        end;
      end;
  end else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;

procedure x_seek(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    begin
    with TOriTable(pr[0].Mem.ptr) do
      begin
      Seek := pr[1].AsInteger;
      if Seek < 0 then
        Seek := 0
      else if Seek > count - 1 then
          Seek := count - 1;
      end;
    end
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;

procedure x_reset(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    begin
    with TOriTable(pr[0].Mem.ptr) do
      begin
      if count = 0 then
        Return.Val(False)
      else
        begin
        Seek := 0;
        Return.Val( Current,false );
        end;
      end;
    end
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;

procedure x_next(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    begin
    with TOriTable(pr[0].Mem.ptr) do
      begin
      next;
      if Seek > count - 1 then
        Return.Val(False)
      else
        Return.Val( Current,false );
      end;
    end
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;

procedure x_prev(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    begin
    with TOriTable(pr[0].Mem.ptr) do
      begin
      prev;
      if (Seek > count - 1) or (Seek < 0) then
        Return.Val(False)
      else
        Return.Val( Current,false );
      end;
    end
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;


procedure x_key(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if pr[0].IsArray then
    begin
    with TOriTable(pr[0].Mem.ptr) do
      if Seek > count - 1 then
        Return.Val(False)
      else
        Return.Val( Names.Values^[Seek] );
    end
  else
    getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
end;


procedure x_array_keys(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
var
  i: Integer;
  v: TOriMemory;
  arr: TOriTable;
begin
  Return.ValTable( TOriTable.CreateInManager );

  with TOriTable(Return.mem.ptr) do
    begin

    if pr[0].IsArray then
    begin
      arr := pr[0].Mem.ptr;

      for i := 0 to arr.Count - 1 do
      begin
        v := TOriMemory.GetMemory;
        v.Val( arr.Names.Values^[i] );
        add(v);
    end;

    end
    else
      getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
    end;
end;

procedure x_array_values(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
var
  i   : Integer;
  v   : TOriMemory;
  arr : TOriTable;
begin
  Return.ValTable( TOriTable.CreateInManager );

  with TOriTable(Return.Mem.ptr) do
    begin

    if pr[0].IsArray then
      begin
      arr := pr[0].Mem.ptr;

      for i := 0 to arr.Count - 1 do
        begin
          v := TOriMemory.GetMemory;
          v.Val( arr[i],false );
          add(v);
          v.UseObjectAll;
        end;

      end
    else
      getErrorPool(eval).newError(errWarning, Format(MSG_ERR_PARAM_ARRTYPE, ['1']));
    end;
end;


procedure x_is_array(pr: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( pr[0].IsArray );
end;


function loadModule(init: boolean): byte;
begin
  if init then
    begin
    addNativeFunc('array_keys', 1, @x_array_keys);
    addNativeFunc('array_values', 1, @x_array_values);

    addNativeFunc('count', 1, @x_count);
    addNativeFunc('sizeof', 1, @x_count);

    addNativeFunc('in_array', 2, @x_in_array);

    addNativeFunc('current', 1, @x_current);
    addNativeFunc('pos', 1, @x_current);
    addNativeFunc('key', 1, @x_key);
    addNativeFunc('next', 1, @x_next);
    addNativeFunc('prev', 1, @x_prev);
    addNativeFunc('end', 1, @x_end);
    addNativeFunc('reset', 1, @x_reset);
    addNativeFunc('eof', 1, @x_eof);
    addNativeFunc('seek', 1, @x_seek);

    addNativeFunc('is_array', 1, @x_is_array);

    VM_Constants.addConstant('CASE_LOWER', CASE_LOWER);
    VM_Constants.addConstant('CASE_UPPER', CASE_UPPER);
    end;
end;



initialization
  addNativeModule(@loadModule);

end.

