unit uDemos;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, LResources, Forms, Controls, Graphics, Dialogs,
  StdCtrls;

type

  { TfmDemos }

  TfmDemos = class(TForm)
    category: TComboBox;
    files: TListBox;
    Label1: TLabel;
    Label2: TLabel;
    procedure categoryChange(Sender: TObject);
    procedure filesDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end; 

var
  fmDemos: TfmDemos;

implementation
  uses
      uMain;

{ TfmDemos }
procedure ScanDir(Dir:string);
    var SearchRec:TSearchRec;
begin
  fmDemos.files.Clear;
    if Dir<>'' then if Dir[length(Dir)]<>'/' then Dir:=Dir+'/';
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
    fmDemos.category.Items.LoadFromFile(progDir + '../demos/category.cfg');
end;

procedure TfmDemos.FormCreate(Sender: TObject);
begin
   loadCategories;
  category.ItemIndex := 0;
  categoryChange(category);
end;

procedure TfmDemos.categoryChange(Sender: TObject);
begin
    ScanDir( progDir + '../demos/' + TComboBox(Sender).Items[TComboBox(Sender).ItemIndex] + '/' );
end;

procedure TfmDemos.filesDblClick(Sender: TObject);
begin
  if TListBox(Sender).ItemIndex > -1 then
 fmMain.memo1.Lines.LoadFromFile( progDir + '../demos/' + category.Items[category.ItemIndex] + '/' +
  TListBox(Sender).Items[TListBox(Sender).ItemIndex] );
end;

initialization
  {$I uDemos.lrs}

end.

