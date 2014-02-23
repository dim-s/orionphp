unit ori_Core;


//{$mode objfpc}
{$H+}
{$WARNINGS OFF}
{$I '../ori_Options.inc'}

interface

uses
  Classes, SysUtils,
  ori_File,
  ori_vmShortApi,
  ori_vmLoader,
  ori_vmCrossValues,
  ori_vmTables,
  ori_Types,
  ori_vmConstants,
  ori_vmUserFunc,
  ori_Stack,

  ori_Errors,
  ori_vmValues,
  ori_StrConsts,
  ori_vmNativeFunc,

  ori_vmMemory;


implementation

  uses
    Orion,
    ori_vmEval,
    ori_vmVariables,
    ori_vmCompiler,
    ori_Parser,
    ori_ManRes,
    ori_OpGen;

  var
   Ori: TOrionEngine;


{=================================================================}
{====================== IsSet & Empty ============================}

procedure x_isset(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( params[0].IsSet );
end;

procedure x_empty(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( params[0].Empty );
end;

{=================================================================}
{====================== Constants  ===============================}

procedure x_define(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
   var
   cname: MP_String;
begin
  cname := params[0].AsString;
  if VM_Constants.getConstant(cname) > -1 then
  begin
      getErrorPool(eval).newError(errFatal, Format(MSG_ERR_CONSTEX_F,[cname]));
      exit;
  end;

  VM_Constants.addConstant(cname, params[1]);
end;

procedure x_defined(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  Return.Val( VM_Constants.getConstant(params[0].AsString) > -1 );
end;

{=================================================================}
{====================== Constants  ===============================}

procedure x_constant(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
   var
   cname: MP_String;
   id: Integer;
begin
  id := VM_Constants.getConstant(params[0].AsString);
  if id > -1 then
  begin
      VM_Constants.putVMConstant(Return, VM_Constants.Constants[id]);
  end else
      Return.Clear;
end;


{=================================================================}
{====================== Require and Include ======================}

procedure x_include(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  f: MP_String;
begin
  f := params[0].AsString;
  if FileExists(f) then
  begin
      if ExtractFileExt(f) = '.bori' then
          Ori.EvelBCodeFile(f)
      else
          Ori.EvalFile(f,Return);
  end else
      getErrorPool(eval).newError(errWarning,Format(MSG_ERR_NOFILE,[f]));
end;

var
  OnceFiles: TStrings;

procedure x_include_once(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  f: MP_String;
begin
  f := realpath(params[0].AsString);
  if FileExists(f) then
  begin
      if OnceFiles.IndexOf(f) = -1 then
      begin
        OnceFiles.Add(f);
        if ExtractFileExt(f) = '.bori' then
          Ori.EvelBCodeFile(f, Return)
        else
          Ori.EvalFile(f,Return);
      end;
  end else getErrorPool(eval).newError(errWarning,Format(MSG_ERR_NOFILE,[f]));
end;

procedure x_require(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var f: MP_String;
begin
  f := params[0].AsString;
  if FileExists(f) then
  begin
      if ExtractFileExt(f) = '.bori' then
          Ori.EvelBCodeFile(f)
      else
          Ori.EvalFile(f);
  end else getErrorPool(eval).newError(errWarning,Format(MSG_ERR_NOFILE,[f]));
end;

procedure x_require_once(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  f: MP_String;
begin
  f := realpath(params[0].AsString);
  if FileExists(f) then
  begin
      if OnceFiles.IndexOf(f) = -1 then
      begin
        OnceFiles.Add(f);
        if ExtractFileExt(f) = '.bori' then
          Ori.EvelBCodeFile(f)
        else
          Ori.EvalFile(f);
      end;
  end else getErrorPool(eval).newError(errWarning,Format(MSG_ERR_NOFILE,[f]));
end;

{=================================================================}
{====================== Eval  ====================================}
procedure x_compile_eval(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
   var
   code: TOpcodeArray;
   ev: TOriEval;
   lastV: TObject;
begin
      ev := mr_getEval;
      ev.code := TOpcodeArray.Create;
      ori_bcodeLoadString(ev.code, params[0].AsString);
      if eval <> nil then
      begin
        lastV := ev.variables;
        ev.variables := TOriEval(eval).variables;
        ev.run;
        ev.variables := TOriVariables(lastV);
      end else
        ev.run;

      Return.Val( ev.cashFuncReturn, true );

      //ev.clearInfo;
      discardOpcodeS(ev.code);
      ev.code.free;
      ev.isUse := false;
end;

procedure x_eval(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  ev: TOriEval;
  cm: TOriCompiler;
  pr: TOriParser;
  lastV: TObject;
begin
      if (cnt > 1) and params[0].AsBoolean then
      begin
          x_compile_eval(params, cnt, Return, eval);
          exit;
      end;

      pr := mr_getParser;
      pr.Parse(params[0].AsString + ';');

      cm := mr_getCompiler;
      cm.compile(pr.blocks);

      ev := mr_getEval;
      ev.code := cm.opcode;
      if eval <> nil then
      begin
        lastV := ev.variables;
        ev.variables := TOriEval(eval).variables;
        ev.run;
        ev.variables := TOriVariables(lastV);
      end else
        ev.run;

      Return.Val( ev.cashFuncReturn,true );

      cm.clearSource;
      cm.isUse := false;
      pr.clearBlocks;
      pr.isUse := false;
      ev.isUse := false;

      tryObjectiveFree(Return);
end;


{=================================================================}
{====================== Sleep && uSleep ==========================}


procedure x_sleep(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
    Sleep(params[0].AsInteger *1000);
end;

procedure x_usleep(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
    Sleep(params[0].AsInteger);
end;

procedure x_myMemory(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
    Return.ValL( GetHeapStatus.TotalAllocated );
end;

procedure x_compile(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
  var
  cm: TOriCompiler;
  pr: TOriParser;
  ErrPool: TOriErrorPool;
  arr,el: TOriTable;
  i: integer;
  code: TOpcodeArray;
  label err;
begin
      pr := mr_getParser;
      pr.Parse(params[0].AsString + ';');

      ErrPool := pr.ErrPool;
      if ErrPool.existsFatalError then goto err;

      cm := mr_getCompiler;
      {ori_OpGen.safeString( params[0].AsString, cm.FTokens );
      ori_OpGen.polkaTokens( cm.FTokens, cm.FTokens2, cm.ErrPool );
      clearTokens(cm.FTokens); }
      cm.compile(pr.blocks);

      ErrPool := cm.ErrPool;
      if ErrPool.existsFatalError then goto err;

      Return.Typ := mvtString;
      ori_bcodeSaveString(cm.opcode, Return.Mem.str);
      cm.clearSource;
      pr.clearBlocks;

      cm.isUse := false;
      pr.isUse := false;
    exit;
    err:
        if cnt > 1 then
        begin
             // ---TODO
              (*v := PVMValue(vm_value_realptr(param^[1]));
              if v^.typ = vtHash then
              begin
                  arr := TOriTable(v^.ptr);
                  arr.clear;
              end
              else begin
                  unuseVMValue(v);
                  clearVMValue(v);
                  arr := hashTableCreate();
                  v^.typ := vtHash;
                  v^.ptr := arr;
              end;
              for i := 0 to high(ErrPool.errorTable^) do
              begin
                  el := hashTableCreate();
                  el.ref_count := 1;
                  // --todo
                  {el.addValue('line', intVMValue(ErrPool.errorTable^[i].line));
                  el.addValue('type', intVMValue(ErrPool.errorTable^[i].typ));
                  el.addValue('msg', stringVMValue(ErrPool.errorTable^[i].msg));
                  el.addValue('file', stringVMValue(ErrPool.errorTable^[i].AFile));}

                  // --todo
                  //arr.addValue(arrayVMValue(el));
              end;*)
        end;
        Return.ValNull;
        cm.clearSource;
        pr.clearBlocks;
        cm.isUse := false;
        pr.isUse := false;
end;


function loadModule(init: boolean): byte;
begin
    if init then
    begin
        Ori := TOrionEngine.Create(false);
        OnceFiles := TStringList.Create;

          addNativeFunc('isset',1,@x_isset);
          addNativeFunc('empty',1,@x_empty);
          //addNativeFunc('my_memory',0,@x_mymemory);
          addNativeFunc('memory_get_usage',0,@x_mymemory);

          addNativeFunc('define',2,@x_define);
          addNativeFunc('defined',1,@x_defined);
          addNativeFunc('constant',1,@x_constant);
          addNativeFunc('compile',1,@x_compile);
          addNativeFunc('eval_compiled',1,@x_compile_eval);

          addNativeFunc('include',1,@x_include);
          addNativeFunc('include_once',1,@x_include_once);
          addNativeFunc('require',1,@x_require);
          addNativeFunc('require_once',1,@x_require_once);
          addNativeFunc('eval',1,@x_eval);

          addNativeFunc('sleep',1,@x_sleep);
          addNativeFunc('usleep',1,@x_usleep);
    end else
    begin
        Ori.Free;
        OnceFiles.Free;
    end;
end;



initialization
   addNativeModule(@loadModule);



end.
