unit Unit1;

interface


uses
  Classes, Windows, Messages, SysUtils, Variants,  Graphics, Controls, Forms,
  Dialogs, StdCtrls, Menus, Buttons, CheckLst, ExtCtrls,  ComCtrls,
  
  SynEdit,
  SynHighlighterPHP,
  SynEditHighlighter,
  SynHighlighterGeneral,

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
  ori_OpGen,
  ori_vmMemory,
  ori_vmTables,
  ori_FastArrays
  ;

type

  { TForm1 }

  TfmMain = class(TForm)
    PageControl: TPageControl;
    TabSheet1: TTabSheet;
    memo2: TSynEdit;
    SynGeneralSyn: TSynGeneralSyn;
    memo1: TSynEdit;
    SynPHPSyn: TSynPHPSyn;
    MainMenu1: TMainMenu;
    Orion1: TMenuItem;
    itOpen: TMenuItem;
    itRun: TMenuItem;
    OD: TOpenDialog;
    TabSheet2: TTabSheet;
    Label1: TLabel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    l_demos: TCheckListBox;
    l_info: TLabel;
    console: TMemo;
    itStop: TMenuItem;
    N1: TMenuItem;
    itAbout: TMenuItem;
    err_list: TListBox;
    Label2: TLabel;
    Splitter1: TSplitter;
    Panel1: TPanel;
    b_start: TBitBtn;
    b_stop: TBitBtn;
    ms_count: TLabel;
    show_console: TCheckBox;
    use_thread: TCheckBox;
    BitBtn3: TBitBtn;
    BitBtn4: TBitBtn;
    File1: TMenuItem;
    SaveBytecode1: TMenuItem;
    Reset1: TMenuItem;
    Engine1: TMenuItem;
    Constants1: TMenuItem;
    N2: TMenuItem;
    All1: TMenuItem;
    procedure b_startClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure itRunClick(Sender: TObject);
    procedure itOpenClick(Sender: TObject);
    procedure b_stopClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure itStopClick(Sender: TObject);
    procedure itAboutClick(Sender: TObject);
    procedure BitBtn3Click(Sender: TObject);
    procedure BitBtn4Click(Sender: TObject);
    procedure SaveBytecode1Click(Sender: TObject);
    procedure Constants1Click(Sender: TObject);
    procedure Engine1Click(Sender: TObject);
    procedure All1Click(Sender: TObject);
    procedure FormClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmMain: TfmMain;
  OrionPHP: TOrionEngine;
  th: TOrionEvalThread;
  progDir: MP_String;

implementation

uses uAbout, uDemos;


{$R *.dfm}


procedure showErrors();
  var
  i: integer;
begin
      if OrionPHP.ErrorExists then
         begin
            MessageBeep(MB_ICONERROR);
            fmMain.err_list.Items.Text := '';
            for i := 0 to Length(OrionPHP.ErrPool.errorTable^) - 1 do
            begin
                fmMain.err_list.Items.Add('['+ErrorTypeToStr(OrionPHP.Errors^[i].typ)+'] '
                + (OrionPHP.ErrPool.errorTable^[i].msg)+' on line '+IntToStr(OrionPHP.Errors^[i].line))
            end;
         end;
end;


function showByteCode(opCode: TOpcodeArray): MP_String;
function stackToString(var v: TOriMemory): MP_String;
begin
if v = nil then
   Result := '#'
else
   case v.typ of
        mvtVariable,mvtGlobalVar:
        begin
            Result := v.Mem.str;
        end;
        else
          Result := v.AsString;
    end;
end;

   var
   i: integer;
   ss: MP_String;
begin
   for i := 0 to opCode.Count - 1 do
   begin
     if opCode[i] = nil then continue;
        ss := opTypToStr(opCode[i]^.typ)+':  '+
        stackToString(opCode[i]^.oper1) + ' , ' + stackToString(opCode[i]^.oper2);

     if opCode[i]^.cnt <> -1 then
     begin
        ss := ss +' , '+intToStr(opCode[i]^.cnt);
     end;
     ss := ss + '   ###';
        if opCode[i]^.checkMemory then
        ss := ss + ' +check';

        if opCode[i]^.toStack then
        ss := ss + ' +toStack';
        
     Result := Result + ss + #13#10;
   end;
end;

function evalScript(const Script: MP_String): Integer;
  Var
  bytecode: TOpcodeArray;
begin
   Result := -1;
   bytecode := TOpcodeArray.Create;
   OrionPHP.Compile(Script, bytecode);
   if not fmMain.show_console.Checked then
     fmMain.memo2.Text := showByteCode(bytecode);

   if not OrionPHP.ErrorExists then
   begin
      Result := GetTickCount;
      OrionPHP.Eval(bytecode);
      Result := GetTickCount - Result;
   end;
   discardOpcodeS(bytecode);
end;


procedure TfmMain.All1Click(Sender: TObject);
begin
  OrionPHP.ResetConstants;
  finalOrionEngine;
  initOrionEngine;
  {$IFDEF MSWINDOWS}
  MessageBeep(66);
  {$ENDIF}
end;

procedure TfmMain.BitBtn3Click(Sender: TObject);
begin
  if b_stop.Enabled then
      b_stopClick(nil);
  All1Click(nil);
  {finalOrionEngine;
  initOrionEngine;}
end;

procedure myCall( Mem: TOriMemory );
begin
    Mem.UseObject;
end;

procedure TfmMain.BitBtn4Click(Sender: TObject);
begin
  fmDemos.show;
end;

procedure TfmMain.b_startClick(Sender: TObject);
    procedure cback(th: TThread; eval: TOriEval);
       var
       i: integer;
    begin
         fmMain.b_stop.Enabled := false;
         fmMain.b_start.Enabled := true;
         fmMain.ms_count.Caption := IntToStr(TOrionEvalThread(th).Time) + ' ms';
         Unit1.th := nil;

         OrionPHP.ErrPool := eval.ErrPool;

         showErrors();

         if not fmMain.show_console.Checked then
            fmMain.memo2.Text := showByteCode(eval.code);
    end;
    
    var
    t: integer;
begin
   fmMain.memo2.Clear;
   fmMain.err_list.Clear;
   if use_thread.Checked then
   begin
        th := OrionPHP.EvalThread(memo1.Text, false);
//        OrionPHP.EvalThread(memo1.Text, true);
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


procedure TfmMain.b_stopClick(Sender: TObject);
begin
  TOrionEvalThread(th).Eval.toExit;

  fmMain.b_stop.Enabled := false;
  fmMain.b_start.Enabled := true;
end;

procedure TfmMain.Constants1Click(Sender: TObject);
begin
  OrionPHP.ResetConstants;
end;

procedure TfmMain.Engine1Click(Sender: TObject);
begin
  finalOrionEngine();
  initOrionEngine();
end;

procedure TfmMain.FormClick(Sender: TObject);
begin
  // mr_freeEval;
end;

procedure TfmMain.FormClose(Sender: TObject; var Action: TCloseAction);
  var
  f: TStrings;
begin
  try
    OrionPHP.Free;
  
    f := TStringList.Create;
    f.Text := memo1.Lines.Text;
    f.SaveToFile(ExtractFilePath(ParamStr(0))+'code.ori');
    f.Free;
  except

  end;
end;

procedure TfmMain.FormCreate(Sender: TObject);
begin
   OrionPHP := TOrionEngine.Create(True);
   progDir := ExtractFilePath(ParamStr(0));
end;


procedure TfmMain.FormShow(Sender: TObject);
begin
  if FileExists(ExtractFilePath(ParamStr(0))+'code.ori') then
  begin
      try
      memo1.Lines.LoadFromFile(ExtractFilePath(ParamStr(0))+'code.ori');
      except

      end;
  end;
end;

procedure TfmMain.itAboutClick(Sender: TObject);
begin
  fmAbout.ShowModal;
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


procedure TfmMain.SaveBytecode1Click(Sender: TObject);
   {var
   M: AnsiString;
   S: TMemoryStream;
   code: PArrayOpcode; }
begin
  {new(code);
  OrionPHP.Compile(memo1.Text, code);
  bcode_SaveFile(code, 'd:\code.pori');
  bcode_SaveString(code, M);
  
  //bcode_LoadFile(code, 'd:\code.pori');
  bcode_LoadString(code, M);
  //OrionPHP.LoadBCode(code, M);
  OrionPHP.Eval(code);  }
end;

end.
