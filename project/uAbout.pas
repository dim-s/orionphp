unit uAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, GIFImg, ExtCtrls, StdCtrls, Buttons;

type
  TfmAbout = class(TForm)
    Bevel1: TBevel;
    Image1: TImage;
    Bevel2: TBevel;
    BitBtn1: TBitBtn;
    Label1: TLabel;
    Label2: TLabel;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  fmAbout: TfmAbout;

implementation

{$R *.dfm}

end.
