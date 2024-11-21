object StringViewerFrame: TStringViewerFrame
  Left = 0
  Top = 0
  Width = 548
  Height = 299
  Color = clBtnFace
  ParentBackground = False
  ParentColor = False
  TabOrder = 0
  object Panel2: TPanel
    Left = 0
    Top = 0
    Width = 548
    Height = 29
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object Button1: TButton
      Left = 3
      Top = 4
      Width = 111
      Height = 25
      Caption = 'Copy to Clipboard'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 120
      Top = 4
      Width = 93
      Height = 25
      Caption = 'Save to File'
      TabOrder = 1
      OnClick = Button2Click
    end
  end
  object StatusBar1: TStatusBar
    Left = 0
    Top = 280
    Width = 548
    Height = 19
    Panels = <
      item
        Width = 500
      end>
  end
  object Memo: TMemo
    AlignWithMargins = True
    Left = 3
    Top = 32
    Width = 542
    Height = 245
    Align = alClient
    ScrollBars = ssBoth
    TabOrder = 2
  end
  object FSD: TFileSaveDialog
    DefaultExtension = '.txt'
    FavoriteLinks = <>
    FileName = 'out.txt'
    FileTypes = <>
    Options = [fdoOverWritePrompt, fdoPathMustExist]
    Title = 'Save string to file'
    Left = 10
    Top = 46
  end
end
