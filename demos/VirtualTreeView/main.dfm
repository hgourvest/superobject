object MainForm: TMainForm
  Left = 275
  Top = 276
  Caption = 'SuperObject Editor'
  ClientHeight = 520
  ClientWidth = 625
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Menu = MainMenu
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object Splitter1: TSplitter
    Left = 0
    Top = 345
    Width = 625
    Height = 2
    Cursor = crVSplit
    Align = alBottom
  end
  object treeview: TVirtualStringTree
    Left = 0
    Top = 21
    Width = 625
    Height = 324
    Align = alClient
    EditDelay = 200
    Header.AutoSizeIndex = 0
    Header.DefaultHeight = 17
    Header.Font.Charset = DEFAULT_CHARSET
    Header.Font.Color = clWindowText
    Header.Font.Height = -11
    Header.Font.Name = 'Tahoma'
    Header.Font.Style = []
    Header.Options = [hoColumnResize, hoDblClickResize, hoDrag, hoVisible]
    Header.SortColumn = 0
    Header.Style = hsFlatButtons
    TabOrder = 0
    TreeOptions.AutoOptions = [toAutoDropExpand, toAutoScrollOnExpand, toAutoSort, toAutoTristateTracking, toAutoDeleteMovedNodes]
    TreeOptions.MiscOptions = [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning]
    TreeOptions.PaintOptions = [toShowButtons, toShowDropmark, toShowRoot, toShowTreeLines, toShowVertGridLines, toThemeAware, toUseBlendedImages, toUseBlendedSelection]
    TreeOptions.SelectionOptions = [toFullRowSelect]
    OnChange = treeviewChange
    OnCompareNodes = treeviewCompareNodes
    OnFreeNode = treeviewFreeNode
    OnGetText = treeviewGetText
    OnGetNodeDataSize = treeviewGetNodeDataSize
    OnHeaderClick = treeviewHeaderClick
    Columns = <
      item
        Position = 0
        Width = 246
        WideText = 'key'
      end
      item
        Position = 1
        Width = 300
        WideText = 'value'
      end>
    WideDefaultText = ''
  end
  object StatusBar: TStatusBar
    Left = 0
    Top = 501
    Width = 625
    Height = 19
    Panels = <>
    SimplePanel = True
  end
  object Memo: TMemo
    Left = 0
    Top = 347
    Width = 625
    Height = 154
    Align = alBottom
    ScrollBars = ssVertical
    TabOrder = 2
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 625
    Height = 21
    Align = alTop
    BevelOuter = bvNone
    Caption = 'Panel1'
    TabOrder = 3
    DesignSize = (
      625
      21)
    object edGetURL: TEdit
      Left = 0
      Top = 0
      Width = 625
      Height = 21
      Anchors = [akLeft, akTop, akRight]
      TabOrder = 0
      Text = 
        'http://www.google.com/uds/GwebSearch?rsz=large&v=1.0&q=open sour' +
        'ce'
      OnKeyPress = edGetURLKeyPress
    end
  end
  object MainMenu: TMainMenu
    Left = 16
    Top = 160
    object mFile: TMenuItem
      Caption = '&File'
      object Open1: TMenuItem
        Action = acFileOpen
      end
    end
    object Options1: TMenuItem
      Caption = '&Options'
      object acPackxml: TMenuItem
        Action = Action1
      end
    end
  end
  object ActionList: TActionList
    Left = 16
    Top = 192
    object acFileOpen: TFileOpen
      Category = 'Fichier'
      Caption = '&Open...'
      Dialog.Filter = 
        'all know files (*.json, *.xml)|*.json;*.xml|json (*.json)|*.json' +
        '|xml (*.xml)|*.xml'
      Hint = 'Ouvrir|Ouvrir un fichier existant'
      ImageIndex = 7
      ShortCut = 16463
      OnAccept = acFileOpenAccept
    end
    object Action1: TAction
      Caption = 'pack xml'
      Checked = True
      OnExecute = Action1Execute
    end
  end
end
