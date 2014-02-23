unit ori_CoreClasses;


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
  ori_vmClasses;


implementation

  uses
    Orion,
    ori_vmEval,
    ori_vmVariables,
    ori_vmCompiler,
    ori_Parser,
    ori_ManRes;

{=================================================================}
{======================= Class Exists ============================}

{function x_class_exists(param: PVMValues; const cnt: cardinal; var Return: PVMValue; eval: Pointer): byte;
begin
  MVAL_BOOL(Return, ori_vmClasses.findByNameIndex(convertToString(param^[0])) <> -1);
end; }

function loadModule(init: boolean): byte;
begin
    if init then
    begin
         // addNativeFunc('class_exists',1,@x_class_exists);
    end else
    begin

    end;
end;



initialization
   addNativeModule(@loadModule);



end.
