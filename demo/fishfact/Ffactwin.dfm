object Form1: TForm1
  Left = 460
  Top = 162
  ActiveControl = DBImage1
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'FISH FACTS'
  ClientHeight = 297
  ClientWidth = 500
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = True
  ShowHint = True
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object Panel1: TPanel
    Left = 6
    Top = 8
    Width = 259
    Height = 217
    Hint = 'Scroll grid below to see other fish'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 0
    object DBLabel1: TDBText
      Left = 4
      Top = 183
      Width = 249
      Height = 24
      DataField = 'Common_Name'
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clRed
      Font.Height = -19
      Font.Name = 'MS Serif'
      Font.Style = [fsBold, fsItalic]
      ParentFont = False
    end
    object DBImage1: TDBImage
      Left = 5
      Top = 8
      Width = 248
      Height = 168
      Hint = 'Scroll grid below to see other fish'
      DataField = 'Graphic'
      DataSource = DataSource1
      TabOrder = 0
    end
  end
  object Panel2: TPanel
    Left = 275
    Top = 8
    Width = 223
    Height = 22
    TabOrder = 1
    object Label1: TLabel
      Left = 7
      Top = 4
      Width = 56
      Height = 13
      Caption = 'About the'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object DBLabel2: TDBText
      Left = 67
      Top = 4
      Width = 56
      Height = 13
      AutoSize = True
      DataField = 'Common_Name'
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlue
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object Panel3: TPanel
    Left = 276
    Top = 32
    Width = 223
    Height = 193
    BevelOuter = bvLowered
    TabOrder = 2
    object DBMemo1: TDBMemo
      Left = 3
      Top = 2
      Width = 217
      Height = 183
      BorderStyle = bsNone
      Color = clSilver
      Ctl3D = False
      DataField = 'Notes'
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentCtl3D = False
      ParentFont = False
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
  object Panel4: TPanel
    Left = 0
    Top = 225
    Width = 500
    Height = 72
    Align = alBottom
    BevelInner = bvRaised
    BorderStyle = bsSingle
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    object DBGrid1: TDBGrid
      Left = 12
      Top = 8
      Width = 386
      Height = 53
      Hint = 'Scroll up/down to see other fish!'
      DataSource = DataSource1
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -11
      Font.Name = 'MS Sans Serif'
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      TitleFont.Charset = DEFAULT_CHARSET
      TitleFont.Color = clBlack
      TitleFont.Height = -11
      TitleFont.Name = 'MS Sans Serif'
      TitleFont.Style = []
    end
    object BitBtn1: TBitBtn
      Left = 424
      Top = 20
      Width = 57
      Height = 29
      Hint = 'Close Fish Facts'
      Caption = 'E&xit'
      Kind = bkClose
      NumGlyphs = 2
      TabOrder = 1
    end
  end
  object DataSource1: TDataSource
    DataSet = Pdx1
    Left = 19
    Top = 193
  end
  object Pdx1: TPdx
    TableName = '.\biolife.db'
    Codepage = 'CP1251'
    EncodingMemo = True
    Left = 230
    Top = 192
  end
end
