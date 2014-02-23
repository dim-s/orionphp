program OrionTest;

uses
  Forms,
  Unit1 in 'Unit1.pas' {fmMain},
  uTestFuncs in 'uTestFuncs.pas',
  uAbout in 'uAbout.pas' {fmAbout},
  uDemos in 'uDemos.pas' {fmDemos},
  uDebug in 'uDebug.pas' {Form2};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfmMain, fmMain);
  Application.CreateForm(TfmAbout, fmAbout);
  Application.CreateForm(TfmDemos, fmDemos);
  Application.CreateForm(TForm2, Form2);
  Application.Run;
end.
