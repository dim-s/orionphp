program OrionTest;

{$i '../VM/ori_Options.inc'}

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, uMain, uDemos;

{$IFDEF WINDOWS}{$R OrionTest.rc}{$ENDIF}

//{$R *.res}

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmDemos, fmDemos);
  Application.Run;
end.

