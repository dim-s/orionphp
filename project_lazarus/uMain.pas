unit uMain;

{$I '../VM/ori_Options.inc'}
{$mode objfpc}{$H+}


interface

uses
  Classes, SysUtils, Variants,  Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, Buttons, CheckLst, ExtCtrls,  ComCtrls,
  LResources, uTestFuncs,

  {$ifdef osWIN}
  Messages,
  {$endif}

  SynEdit,
  SynHighlighterPHP, SynMemo,

  Orion,
  ori_vmLoader,
  ori_vmTypes,
  ori_Stack,
  ori_vmNativeFunc,
  ori_Errors,
  ori_vmCompiler,
  ori_Types,
  ori_vmEval,
  ori_vmValues,
  ori_ManRes,
  ori_HashList,
  ori_Hash32,
  ori_FastArrays


  {$IFDEF osWIN}
    ,Windows
  {$ELSE}
    ,LclIntf
  {$ENDIF}

  ;

type

  { TfmMain }

  TfmMain = class(TForm)
    b_demos: TBitBtn;
    b_start: TBitBtn;
    b_stop: TBitBtn;
    b_restart: TBitBtn;
    err_list: TListBox;
    itAbout: TMenuItem;
    itOpen: TMenuItem;
    itRun: TMenuItem;
    itStop: TMenuItem;
    Label2: TLabel;
    MainMenu1: TMainMenu;
    memo1: TSynEdit;
    ms_count: TLabel;
    N1: TMenuItem;
    OD: TOpenDialog;
    Orion1: TMenuItem;
    PageControl: TPageControl;
    show_console: TCheckBox;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    memo2: TSynMemo;
    SynPHPSyn: TSynPHPSyn;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    use_thread: TCheckBox;
    procedure b_demosClick(Sender: TObject);
    procedure b_restartClick(Sender: TObject);
    procedure b_startClick(Sender: TObject);
    procedure b_stopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure itAboutClick(Sender: TObject);
    procedure itOpenClick(Sender: TObject);
    procedure itRunClick(Sender: TObject);
    procedure itStopClick(Sender: TObject);
    procedure memo1Change(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;



var
  fmMain: TfmMain;
  OrionPHP: TOrionEngine;
  th: TOrionEvalThread;
  ProgDir: MP_String;

implementation

  uses uDemos;

procedure showErrors();
  var
  i: integer;
begin
      if OrionPHP.ErrorExists then
         begin
            {$IFDEF osWIN}
            MessageBeep(MB_ICONERROR);
            {$ENDIF}
            fmMain.err_list.Items.Text := '';
            for i := 0 to Length(OrionPHP.ErrPool.errorTable^) - 1 do
            begin
                fmMain.err_list.Items.Add('[line '+ori_Types.IntToStr(OrionPHP.Errors^[i].line)+'] ' +
                  (OrionPHP.ErrPool.errorTable^[i].msg))
            end;
         end;
end;

function getTime(): Longint;
begin
{$IFDEF MSWINDOWS}
  Result := Windows.GetTickCount;
{$ELSE}
  Result := LclIntf.GetTickCount;
{$ENDIF}
end;

function showByteCode(opCode: TOpcodeArray): String;

function stackToString(const v: PStackValue): MP_String;
begin
if v = nil then
   Result := '#'
else
   case v^.typ of
        svtVariable,svtGlobalVar:
        begin
            Result := v^.str;
        end;
        svtInteger: Str(v^.lval, Result); // := IntToStr( v^.lval );
        svtDouble : Result := FloatToStr( v^.dval );
        svtBoolean: if v^.bl then Result := '1' else Result := '';
        svtString: Result := v^.str;
        svtPChar  : Result := v^.pchar^;
        svtNone   : Result := 'none';
        svtWord   : Result := v^.str;
        else Result := '';
    end;
end;
   var
   i: integer;
   ss: string;
begin
   for i := 0 to opCode.Count do
   begin
     if opCode[i] = nil then continue;
        ss := opTypToStr(opCode[i]^.typ)+':  '+
        stackToString(opCode[i]^.oper1) + ' , ' + stackToString(opCode[i]^.oper2);

     if opCode[i]^.cnt <> -1 then
     begin
        ss := ss +' , '+intToStr(opCode[i]^.cnt);
     end;
     Result := Result + ss + #13;
   end;
end;

function evalScript(const Script: String): Integer;
  Var
  bytecode: TOpcodeArray;
  i: integer;
begin
   Result := -1;
   bytecode := TOpcodeArray.Create;
   OrionPHP.Compile(Script, bytecode);
   if not fmMain.show_console.Checked then
     fmMain.memo2.Text := showByteCode(bytecode);

   if not OrionPHP.ErrorExists then
   begin
      Result := getTime;
          OrionPHP.Eval(bytecode);
      Result := getTime - Result;
   end;
   discardOpcodeS(bytecode);
   bytecode.Free;
end;


{ TfmMain }

procedure cback(th: TThread; eval: TOriEval);
       var
       i: integer;
    begin
         fmMain.b_stop.Enabled := false;
         fmMain.b_start.Enabled := true;
         fmMain.ms_count.Caption := IntToStr(TOrionEvalThread(th).Time) + ' ms';
         uMain.th := nil;

         showErrors();

         if not fmMain.show_console.Checked then
            fmMain.memo2.Text := showByteCode(eval.code);
end;

procedure TfmMain.b_startClick(Sender: TObject);
    var
    t,i: integer;
begin
   fmMain.memo2.Text := '';
   fmMain.err_list.Clear;
   if use_thread.Checked then
   begin
        th := OrionPHP.EvalThread(memo1.Text, false);
        if th <> nil then
        begin
            th.Callback := @cback;
            th.Priority := tpIdle;
            th.Resume;
            fmMain.b_start.Enabled := false;
            fmMain.b_stop.Enabled := true;
        end;

   end else begin
        t := evalScript(memo1.Text);
        ms_count.Caption :=
            IntToStr( t ) + ' ms';
        showErrors();
   end;
end;

procedure TfmMain.b_restartClick(Sender: TObject);
begin
    if b_stop.Enabled then
      b_stopClick(nil);

  OrionPHP.ResetConstants;
  finalOrionEngine;
  initOrionEngine;
end;

procedure TfmMain.b_demosClick(Sender: TObject);
  var
  sa: TStringArray;
begin
 sa := TStringArray.Create;
 Caption := DatetimeToStr(Now);
 for i := 1 to 100000000 do
  sa.Add('');

 Caption := DatetimeToStr(Now);

  fmDemos.show;
end;

procedure TfmMain.b_stopClick(Sender: TObject);
begin
  TOrionEvalThread(th).Eval.toExit;

  fmMain.b_stop.Enabled := false;
  fmMain.b_start.Enabled := true;
end;


procedure TfmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
   var
  f: TStrings;
begin
  OrionPHP.Free;

  f := TStringList.Create;
  f.Text := memo1.Lines.Text;
  f.SaveToFile(ExtractFilePath(ParamStr(0))+'code.ori');
  f.Free;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
   OrionPHP := TOrionEngine.Create(True);
end;

procedure TfmMain.FormShow(Sender: TObject);
begin
  if FileExists(ExtractFilePath(ParamStr(0))+'code.ori') then
  begin
      memo1.Lines.LoadFromFile(ExtractFilePath(ParamStr(0))+'code.ori');
  end;
end;

procedure TfmMain.itAboutClick(Sender: TObject);
begin
  ShowMessage('Copyright (c) 2010 Zaytsev Dmitriy Gennad''evich'#13#13'For PHP Fun');
end;

procedure TfmMain.itOpenClick(Sender: TObject);
begin
    if OD.Execute then
      memo1.Lines.LoadFromFile(OD.FileName);
end;

procedure TfmMain.itRunClick(Sender: TObject);
begin
    b_startClick(nil);
end;

procedure TfmMain.itStopClick(Sender: TObject);
begin
    b_stopClick(nil);
end;

procedure TfmMain.memo1Change(Sender: TObject);
begin

end;

initialization
  ProgDir := ExtractFilePath( ParamStr(0) );
  {$I uMain.lrs}


end.

