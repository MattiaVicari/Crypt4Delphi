object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'DEMO CNG RNG'
  ClientHeight = 153
  ClientWidth = 636
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object lblBufferSize: TLabel
    Left = 8
    Top = 11
    Width = 51
    Height = 13
    Caption = 'Buffer size'
  end
  object lblMinValue: TLabel
    Left = 8
    Top = 65
    Width = 49
    Height = 13
    Caption = 'Min. value'
  end
  object lblMaxValue: TLabel
    Left = 8
    Top = 92
    Width = 53
    Height = 13
    Caption = 'Max. value'
  end
  object lblStringLength: TLabel
    Left = 8
    Top = 119
    Width = 61
    Height = 13
    Caption = 'String length'
  end
  object btnGenRandomBuffer: TButton
    Left = 385
    Top = 8
    Width = 236
    Height = 21
    Caption = 'Generate random buffer'
    TabOrder = 2
    OnClick = btnGenRandomBufferClick
  end
  object edtRandomBuffer: TEdit
    Left = 143
    Top = 8
    Width = 236
    Height = 21
    Alignment = taCenter
    ReadOnly = True
    TabOrder = 1
  end
  object edtBufferSize: TEdit
    Left = 81
    Top = 8
    Width = 56
    Height = 21
    NumbersOnly = True
    TabOrder = 0
    Text = '128'
  end
  object edtRandomNumber: TEdit
    Left = 143
    Top = 35
    Width = 236
    Height = 21
    Alignment = taCenter
    ReadOnly = True
    TabOrder = 3
  end
  object btnGenRandomNumber: TButton
    Left = 385
    Top = 35
    Width = 236
    Height = 21
    Caption = 'Generate random number'
    TabOrder = 4
    OnClick = btnGenRandomNumberClick
  end
  object edtMinValue: TEdit
    Left = 81
    Top = 62
    Width = 56
    Height = 21
    NumbersOnly = True
    TabOrder = 5
    Text = '0'
  end
  object edtMaxValue: TEdit
    Left = 81
    Top = 89
    Width = 56
    Height = 21
    NumbersOnly = True
    TabOrder = 6
    Text = '100'
  end
  object edtRandomRangeNumber: TEdit
    Left = 143
    Top = 89
    Width = 236
    Height = 21
    Alignment = taCenter
    ReadOnly = True
    TabOrder = 7
  end
  object btnGenRandomRangeNumber: TButton
    Left = 385
    Top = 89
    Width = 236
    Height = 21
    Caption = 'Generate random (range)  number'
    TabOrder = 8
    OnClick = btnGenRandomRangeNumberClick
  end
  object edtStringLength: TEdit
    Left = 81
    Top = 116
    Width = 56
    Height = 21
    NumbersOnly = True
    TabOrder = 9
    Text = '12'
  end
  object edtRandomString: TEdit
    Left = 143
    Top = 116
    Width = 236
    Height = 21
    Alignment = taCenter
    ReadOnly = True
    TabOrder = 10
  end
  object btnGenRandomString: TButton
    Left = 385
    Top = 116
    Width = 236
    Height = 21
    Caption = 'Generate random string'
    TabOrder = 11
    OnClick = btnGenRandomStringClick
  end
end
