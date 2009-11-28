object SuggestForm: TSuggestForm
  Left = 0
  Top = 0
  Caption = 'Google Suggest'
  ClientHeight = 293
  ClientWidth = 426
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object GSearch: TEdit
    Left = 8
    Top = 8
    Width = 409
    Height = 21
    TabOrder = 0
    OnChange = GSearchChange
  end
  object SuggestList: TListBox
    Left = 8
    Top = 40
    Width = 401
    Height = 225
    ItemHeight = 13
    TabOrder = 1
  end
end
