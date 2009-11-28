object SearchForm: TSearchForm
  Left = 0
  Top = 0
  Caption = 'SearchForm'
  ClientHeight = 290
  ClientWidth = 426
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  DesignSize = (
    426
    290)
  PixelsPerInch = 96
  TextHeight = 13
  object GSearch: TEdit
    Left = 8
    Top = 8
    Width = 370
    Height = 21
    TabOrder = 0
  end
  object go: TButton
    Left = 384
    Top = 8
    Width = 34
    Height = 25
    Caption = 'go'
    TabOrder = 1
    OnClick = goClick
  end
  object ResultList: TListBox
    Left = 8
    Top = 40
    Width = 409
    Height = 241
    Anchors = [akLeft, akTop, akRight, akBottom]
    ItemHeight = 13
    TabOrder = 2
  end
end
