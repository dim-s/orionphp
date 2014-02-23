object fmDemos: TfmDemos
  Left = 20
  Top = 140
  BorderStyle = bsSizeToolWin
  Caption = 'Demos'
  ClientHeight = 520
  ClientWidth = 246
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  FormStyle = fsStayOnTop
  OldCreateOrder = False
  Position = poDesigned
  OnCreate = FormCreate
  DesignSize = (
    246
    520)
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 8
    Width = 55
    Height = 13
    Caption = 'Category:'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -11
    Font.Name = 'Tahoma'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 8
    Top = 57
    Width = 31
    Height = 13
    Caption = 'Demo:'
  end
  object category: TComboBox
    Left = 8
    Top = 27
    Width = 230
    Height = 24
    Style = csDropDownList
    Anchors = [akLeft, akTop, akRight]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Tahoma'
    Font.Style = []
    ItemHeight = 16
    ParentFont = False
    TabOrder = 0
    OnChange = categoryChange
  end
  object files: TListBox
    Left = 8
    Top = 72
    Width = 230
    Height = 440
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = RUSSIAN_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Verdana'
    Font.Style = []
    ItemHeight = 16
    ParentFont = False
    TabOrder = 1
    OnDblClick = filesDblClick
  end
end
