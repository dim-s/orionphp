unit uDemos;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TfmDemos = class(TForm)
    Label1: TLabel;
    category: TComboBox;
    files: TListBox;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure categoryChange(Sender: TObject);
    procedure filesDblClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmDemos: TfmDemos;

implementation

uses Unit1;

{$R *.dfm}
procedure ScanDir(Dir:string);
    var SearchRec:TSearchRec;
begin
  fmDemos.files.Clear;
    if Dir<>'' then if Dir[length(Dir)]<>'\' then Dir:=Dir+'\';
        if FindFirst(Dir+'*.*', faAnyFile, SearchRec)=0 then
        repeat
          if (SearchRec.name='.') or (SearchRec.name='..') then continue;
            if (SearchRec.Attr and faDirectory)<>0 then
              //ScanDir(Dir+SearchRec.name) //we found Directory: "Dir+SearchRec.name"
            else
             if (ExtractFileExt(SearchRec.Name) = '.ori') or
                (ExtractFileExt(SearchRec.Name) = '.php')
             then
              fmDemos.files.Items.Add(SearchRec.Name);
            until FindNext(SearchRec)<>0;
            
            FindClose(SearchRec);
end;


procedure loadCategories();
begin
    fmDemos.category.Items.LoadFromFile(progDir + '..\demos\category.cfg');
end;

procedure TfmDemos.categoryChange(Sender: TObject);
begin
  ScanDir( progDir + '..\demos\' + TComboBox(Sender).Items[TComboBox(Sender).ItemIndex] + '\' );
end;

procedure TfmDemos.filesDblClick(Sender: TObject);
begin
 if TListBox(Sender).ItemIndex > -1 then
 fmMain.memo1.Lines.LoadFromFile( progDir + '..\demos\' + category.Items[category.ItemIndex] + '\' +
  TListBox(Sender).Items[TListBox(Sender).ItemIndex] );
end;

procedure TfmDemos.FormCreate(Sender: TObject);
begin
  loadCategories;
  category.ItemIndex := 0;
  categoryChange(category);
end;

end.
