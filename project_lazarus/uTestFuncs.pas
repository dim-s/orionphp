unit uTestFuncs;

interface

uses
  Classes, SysUtils,

  {$IFDEF osWIN}
  Windows,
  {$ENDIF}

  ori_vmTables,
  ori_Types,
  ori_StrUtils,
  ori_vmTypes,
  ori_Errors,
  ori_vmValues,
  ori_StrConsts,
  ori_vmNativeFunc;

implementation

   uses uMain;


function x_print(param: pVMValues;  const cnt: cardinal; var Return: PVMValue; eval: Pointer): byte;
   var
   i: integer;
begin
   for i := 0 to cnt - 1 do
   begin
      if fmMain.show_console.Checked then
      begin
          fmMain.memo2.Lines.Add(convertToString(param^[i]));
          fmMain.memo2.CaretY := fmMain.memo2.Lines.Count-1;
          fmMain.memo2.Repaint;
      end
      else begin
          {fmMain.Console.Lines.Add(convertToString(param[i]));
          fmMain.Console.SelStart := Length(fmMain.console.Lines.Text)-1;}
      end;
   end;
end;

function loadModule(init: boolean): byte;
begin
    if init then
    begin
          addNativeFunc('print',1,@x_print);
          addNativeFunc('echo',1,@x_print);
    end;
end;



initialization
   addNativeModule(@loadModule);

end.
