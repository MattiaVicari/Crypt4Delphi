object frmMain: TfrmMain
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMinimize]
  BorderStyle = bsSingle
  Caption = 'CNG AES Demo'
  ClientHeight = 529
  ClientWidth = 645
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lblPlainText: TLabel
    Left = 8
    Top = 264
    Width = 45
    Height = 13
    Caption = 'Plain text'
  end
  object lblCipherText: TLabel
    Left = 8
    Top = 386
    Width = 157
    Height = 13
    Caption = 'Cipher text (hex representation)'
  end
  object grpKeySettings: TRadioGroup
    Left = 8
    Top = 8
    Width = 185
    Height = 81
    Caption = 'Key settings'
    TabOrder = 0
  end
  object radioKeyAndIV: TRadioButton
    Left = 24
    Top = 32
    Width = 113
    Height = 17
    Action = actKeySettings
    Caption = 'Use Key && IV'
    TabOrder = 1
  end
  object radioPassword: TRadioButton
    Left = 24
    Top = 55
    Width = 113
    Height = 17
    Action = actKeySettings
    Caption = 'Use Password'
    TabOrder = 2
    TabStop = True
  end
  object grpKeyIVPassword: TGroupBox
    Left = 208
    Top = 8
    Width = 419
    Height = 249
    Caption = 'Key && IV / Password'
    TabOrder = 5
    object lblPassword: TLabel
      Left = 16
      Top = 25
      Width = 46
      Height = 13
      Caption = 'Password'
    end
    object lblKey: TLabel
      Left = 16
      Top = 52
      Width = 75
      Height = 26
      Caption = 'Key (hex representation)'
      WordWrap = True
    end
    object lblIV: TLabel
      Left = 16
      Top = 147
      Width = 75
      Height = 26
      Caption = 'IV (hex representation)'
      WordWrap = True
    end
    object edtPassword: TEdit
      Left = 104
      Top = 22
      Width = 305
      Height = 21
      TabOrder = 0
      Text = 'MyPassword'
    end
    object memKey: TMemo
      Left = 104
      Top = 49
      Width = 305
      Height = 89
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object btnLoadKey: TButton
      Left = 16
      Top = 87
      Width = 82
      Height = 25
      Action = actLoadKey
      TabOrder = 2
    end
    object btnLoadIV: TButton
      Left = 16
      Top = 182
      Width = 82
      Height = 25
      Action = actLoadIV
      TabOrder = 3
    end
    object memIV: TMemo
      Left = 104
      Top = 144
      Width = 305
      Height = 89
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 4
    end
  end
  object memPlainText: TMemo
    Left = 8
    Top = 283
    Width = 619
    Height = 89
    Lines.Strings = (
      
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras vu' +
        'lputate dictum ullamcorper. Nullam id felis accumsan, '
      
        'hendrerit neque sit amet, tempor libero. Nunc suscipit venenatis' +
        ' enim. Donec mi odio, pharetra a elit quis, fringilla lacinia '
      
        'turpis. Nulla facilisi. Praesent non ipsum vel mauris pulvinar p' +
        'lacerat. Praesent condimentum, orci vel tempus sodales, nunc '
      
        'lorem laoreet elit, a luctus libero eros sit amet odio. Duis cur' +
        'sus imperdiet odio ut placerat. Donec diam lorem, porttitor in '
      
        'rhoncus vel, semper quis velit. Vestibulum a nibh tristique, pha' +
        'retra libero ut, maximus libero. Nullam sollicitudin neque '
      
        'vitae odio tincidunt, eu rhoncus dui pulvinar. Nulla eleifend ju' +
        'sto ut nunc convallis iaculis.')
    ScrollBars = ssVertical
    TabOrder = 6
  end
  object memCipherText: TMemo
    Left = 8
    Top = 412
    Width = 619
    Height = 89
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 9
  end
  object btnLoadCipher: TButton
    Left = 195
    Top = 381
    Width = 111
    Height = 25
    Action = actLoadCipherData
    TabOrder = 7
  end
  object btnEncrypt: TButton
    Left = 8
    Top = 95
    Width = 185
    Height = 25
    Action = actEncrypt
    TabOrder = 3
  end
  object btnDecrypt: TButton
    Left = 8
    Top = 126
    Width = 185
    Height = 25
    Action = actDecrypt
    TabOrder = 4
  end
  object btnSaveCipher: TButton
    Left = 312
    Top = 381
    Width = 111
    Height = 25
    Action = actSaveCipherData
    TabOrder = 8
  end
  object Actions: TActionList
    Left = 72
    Top = 168
    object actKeySettings: TAction
      Caption = 'ActionKeySettings'
      Checked = True
      OnExecute = actKeySettingsExecute
    end
    object actEncrypt: TAction
      Caption = 'Encrypt'
      OnExecute = actEncryptExecute
    end
    object actLoadKey: TAction
      Caption = 'Load Key...'
      OnExecute = actLoadKeyExecute
    end
    object actLoadIV: TAction
      Caption = 'Load IV...'
      OnExecute = actLoadIVExecute
    end
    object actDecrypt: TAction
      Caption = 'Decrypt'
      OnExecute = actDecryptExecute
    end
    object actLoadCipherData: TAction
      Caption = 'Load cipher text...'
      OnExecute = actLoadCipherDataExecute
    end
    object actSaveCipherData: TAction
      Caption = 'Save cipher text...'
      OnExecute = actSaveCipherDataExecute
    end
  end
  object OpenDialogBinary: TOpenDialog
    Filter = 'Binary file|*.bin'
    Options = [ofHideReadOnly, ofPathMustExist, ofFileMustExist, ofEnableSizing]
    Title = 'Load binary file'
    Left = 72
    Top = 216
  end
  object SaveDialogBinary: TSaveDialog
    DefaultExt = 'bin'
    FileName = 'cipher'
    Filter = 'Binary file|*.bin'
    Options = [ofHideReadOnly, ofPathMustExist, ofEnableSizing]
    Title = 'Save binary file'
    Left = 168
    Top = 216
  end
end
