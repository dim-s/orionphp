unit ori_vmVariables;

// модуль для управления переменными и их значениями
//{$mode objfpc}
{$H+}

interface

uses
  Classes, SysUtils,
  ori_StrUtils,
  ori_vmTypes,
  ori_vmValues,
  ori_vmTables,
  ori_Stack,
  ori_Types,
  ori_Errors,
  ori_StrConsts,
  ori_vmCrossValues,
  ori_Parser,
  ori_vmClasses,
  ori_vmMemory;

  procedure initSGlobalVars();
  procedure finalSGlobalVars();
  
   type
      TOriVariables = class(TOriTable)

         public
            procedure setVariable(const name: MP_String; val: TOriMemory; const isLink: boolean = false); overload;
            procedure setVariableFromStack(const name: MP_String; val: TOriMemory; const isLink: boolean = false);

            function setVariable(const name: MP_String; var cnst: TVMConstant;
                aClass: TOriClass; ErrPool: TOriErrorPool; const line: Cardinal): Integer; overload;

            function getVariable(const name: MP_String): Integer;
            function getVariablePtr(var name: MP_String): TOriMemory; inline;

            procedure FastClear;
      end;

   var
    GlobalVars: TOriVariables;


implementation

  uses
    ori_vmShortApi,
    ori_ManRes,
    ori_vmConstants;

procedure initSGlobalVars();
   var
   id: integer;
begin
  GlobalVars := TOriVariables.Create;
  GlobalVars.GetCreateValue('globals').ValTable(GlobalVars);
end;

procedure finalSGlobalVars();
begin
  // --todo
  GlobalVars.Delete ( 'globals' );
  GlobalVars.Free;
end;


procedure TOriVariables.setVariable(const name: MP_String; val: TOriMemory; const isLink: boolean = false);
  var
  r: TOriMemory;
begin
   val.UseObjectAll;
   r := Self.GetCreateValue(Name);
   
   if isLink then
   begin
          r.Typ := mvtPointer;
          r.Mem.ptr := val.AsPtrMemory;
          val.Use;
          exit;
   end else
       r.Val( val, false );
end;

procedure TOriVariables.setVariableFromStack(const name: MP_String; val: TOriMemory; const isLink: boolean = false);
  var
  r: TOriMemory;
begin
   val.UseObjectAll;
   r := Self.GetCreateValue(Name);
   
   if isLink then
   begin
          r.Typ := mvtPointer;
          r.Mem.ptr := val.AsRealMemory;
          val.Use;
          exit;
   end else
       r.Val( val, false );
end;

function TOriVariables.setVariable(const name: MP_String; var cnst: TVMConstant;
         aClass: TOriClass; ErrPool: TOriErrorPool; const line: Cardinal): Integer;
  var
  r: TOriMemory;
  id: integer;
  x1,x2: MP_String;
  m: POriMethod;
  xClass: TOriClass;
begin

      r := Self.GetCreateValue(Name);

      if cnst.typ = mvtWord then
      begin
         if Pos(defStatic,cnst.str) > 0 then
         begin
             x1 := ori_StrLower( CopyL(cnst.str,defStatic) );
             x2 := CopyR(cnst.str,defStatic);

             if x1 = defSelf then
             begin
                xClass := aClass;
             end else if x1 = defParent then
             begin
                if (aClass = nil) or (aClass.parent = nil) then
                begin
                    xClass := nil;
                end else begin
                    xClass := aClass.parent;
                    aClass := xClass;
                end;
             end else
             begin
                 xClass := ori_vmClasses.findByName(x1);
             end;

             if xClass = nil then
             begin
                ErrPool.newError(errFatal, MSG_ERR_NO_CLASS_OR_OBJECT, line);
                exit;
             end;

             m := xClass.GetInMethod(x2, aClass);
             if (m <> nil) and (m^.typ = omtConst) then
             begin
                TOriConsts.assignVMConstant(cnst, TOriMemory(m^.ptr));
             end else begin
                ErrPool.newError(errFatal, Format(MSG_ERR_NO_CLASS_CONST,[x2,x1]), line);
                exit;
             end;

         end else begin
            id := ori_vmConstants.VM_Constants.getConstant(cnst.str);
            if id <> -1 then
            begin
                cnst := ori_vmConstants.VM_Constants.Constants[ id ];
            end;
         end;
      end;

      r.ValCnst(cnst);
end;

function TOriVariables.getVariable(const name: MP_String): Integer;
begin
      Result := byNameIndex(name);
      if Result = -1 then
      begin
         Result := Count;
         Add(name, TOriMemory.GetMemory(mvtNull));
      end;
end;


function TOriVariables.getVariablePtr(var name: MP_String): TOriMemory;
  var
  id: integer;
begin
   id := HashList.getHashValueEx(name);
   if id = 0 then
   begin
       Result := TOriMemory.GetMemory;
       inherited Add(name, Result);
   end else
      Result := Values^[ id - 1 ];
end;


{ TVariables }

procedure TOriVariables.FastClear;
  Var
  i: integer;
begin
  UnuseObjectAll;
  NoneAll;
end;


end.
