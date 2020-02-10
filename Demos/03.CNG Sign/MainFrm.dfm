object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'DEMO Sign'
  ClientHeight = 468
  ClientWidth = 655
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object panelKeys: TPanel
    Left = 0
    Top = 0
    Width = 655
    Height = 193
    Align = alTop
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 0
    object SplitterKey: TSplitter
      Left = 320
      Top = 0
      Width = 5
      Height = 162
      ExplicitLeft = 16
      ExplicitTop = 16
      ExplicitHeight = 120
    end
    object panelPrivateKey: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 162
      Align = alLeft
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 0
      DesignSize = (
        320
        162)
      object lblPrivateKey: TLabel
        Left = 8
        Top = 8
        Width = 55
        Height = 13
        Caption = 'Private Key'
      end
      object memoPrivateKey: TMemo
        Left = 8
        Top = 25
        Width = 307
        Height = 131
        Anchors = [akLeft, akTop, akRight, akBottom]
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitWidth = 300
        ExplicitHeight = 89
      end
    end
    object btnGenerateKeyPair: TButton
      AlignWithMargins = True
      Left = 3
      Top = 165
      Width = 649
      Height = 25
      Align = alBottom
      Caption = 'Generate key pair (openssl required)'
      TabOrder = 1
      OnClick = btnGenerateKeyPairClick
      ExplicitLeft = 400
      ExplicitTop = 112
      ExplicitWidth = 75
    end
    object panelPublicKey: TPanel
      Left = 325
      Top = 0
      Width = 330
      Height = 162
      Align = alClient
      ShowCaption = False
      TabOrder = 2
      ExplicitLeft = 318
      ExplicitWidth = 337
      DesignSize = (
        330
        162)
      object lblPublicKey: TLabel
        Left = 8
        Top = 8
        Width = 48
        Height = 13
        Caption = 'Public Key'
      end
      object memoPublicKey: TMemo
        Left = 8
        Top = 23
        Width = 315
        Height = 131
        Anchors = [akLeft, akTop, akRight, akBottom]
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitWidth = 322
        ExplicitHeight = 89
      end
    end
  end
  object panelSignVerify: TPanel
    Left = 0
    Top = 193
    Width = 655
    Height = 275
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitTop = 8
    ExplicitHeight = 145
    object SplitterDataSign: TSplitter
      Left = 320
      Top = 0
      Width = 5
      Height = 213
      ExplicitLeft = 16
      ExplicitTop = 16
      ExplicitHeight = 120
    end
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 213
      Align = alLeft
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 0
      DesignSize = (
        320
        213)
      object lblData: TLabel
        Left = 8
        Top = 8
        Width = 23
        Height = 13
        Caption = 'Data'
      end
      object memoData: TMemo
        Left = 8
        Top = 25
        Width = 307
        Height = 182
        Anchors = [akLeft, akTop, akRight, akBottom]
        Lines.Strings = (
          'Data to sign')
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitWidth = 300
        ExplicitHeight = 83
      end
    end
    object btnSign: TButton
      AlignWithMargins = True
      Left = 3
      Top = 216
      Width = 649
      Height = 25
      Align = alBottom
      Caption = 'Sign'
      TabOrder = 1
      OnClick = btnSignClick
      ExplicitTop = 117
    end
    object Panel3: TPanel
      Left = 325
      Top = 0
      Width = 330
      Height = 213
      Align = alClient
      ShowCaption = False
      TabOrder = 2
      ExplicitLeft = 448
      ExplicitTop = 48
      ExplicitWidth = 185
      ExplicitHeight = 41
      DesignSize = (
        330
        213)
      object lblSignature: TLabel
        Left = 8
        Top = 8
        Width = 46
        Height = 13
        Caption = 'Signature'
      end
      object memoSignature: TMemo
        Left = 8
        Top = 23
        Width = 315
        Height = 182
        Anchors = [akLeft, akTop, akRight, akBottom]
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitWidth = 322
        ExplicitHeight = 83
      end
    end
    object btnVerify: TButton
      AlignWithMargins = True
      Left = 3
      Top = 247
      Width = 649
      Height = 25
      Align = alBottom
      Caption = 'Verify'
      TabOrder = 3
      OnClick = btnVerifyClick
      ExplicitTop = 296
    end
  end
end
