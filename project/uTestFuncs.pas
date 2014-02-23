unit uTestFuncs;

interface

uses
  Classes, SysUtils,

  ori_CoreMath,
  ori_vmTables,
  ori_Types,

   {$IFDEF MSWINDOWS}
    Windows,
  {$ELSE}
    LclIntf,
  {$ENDIF}

  ori_StrUtils,
  ori_vmTypes,
  ori_Errors,
  ori_vmValues,
  ori_StrConsts,
  ori_vmNativeFunc,
  ori_vmMemory;

implementation

   uses Unit1;
   
// test function message!!!
procedure testFunc(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
{$IFDEF MSWINDOWS}
      MessageBoxA(0,PAnsiChar(params[0].AsString),'',0);
{$ENDIF}
end;

procedure x_print(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
   var
   i: integer;
begin
   for i := 0 to cnt - 1 do
   begin
      if fmMain.show_console.Checked then
      begin
          fmMain.memo2.Lines.Add(params[i].AsString);
         // fmMain.memo2.Lines.Text := (convertToString(param[i]));
          fmMain.memo2.CaretY := fmMain.memo2.Lines.Count-1;
          fmMain.memo2.Repaint;
      end
      else begin
          {fmMain.Console.Lines.Add(convertToString(param[i]));
          fmMain.Console.SelStart := Length(fmMain.console.Lines.Text)-1;}
      end;
   end;
end;

procedure x_assert(params: TOriMemoryStack; const cnt: cardinal; Return: TOriMemory; eval: Pointer); cdecl;
begin
  if params[0].AsBoolean then
  begin
      if fmMain.show_console.Checked then
      begin
          fmMain.memo2.Lines.Add( fmMain.memo1.Lines[params[1].AsInteger-1] );
          fmMain.memo2.CaretY := fmMain.memo2.Lines.Count-1;
          fmMain.memo2.Repaint;
      end
  end;
end;


function loadModule(init: boolean): byte;
begin               
    if init then
    begin
          addNativeFunc('print',1,@x_print);
          addNativeFunc('echo',1,@x_print);
          addNativeFunc('assert',1,@x_assert);

          addNativeFunc('pre',1,@testFunc);
          addNativeFunc('msg',1,@testFunc);
          addNativeFunc('alert',1,@testFunc);
          addNativeFunc('message',1,@testFunc);
          addNativeFunc('showMessage',1,@testFunc);
    end;
end;



initialization
   addNativeModule(@loadModule);

end.
