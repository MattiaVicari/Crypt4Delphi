object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'DEMO Sign'
  ClientHeight = 502
  ClientWidth = 655
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
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
    ExplicitWidth = 649
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
      ExplicitWidth = 643
    end
    object panelPublicKey: TPanel
      Left = 325
      Top = 0
      Width = 330
      Height = 162
      Align = alClient
      ShowCaption = False
      TabOrder = 2
      ExplicitWidth = 324
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
        ExplicitWidth = 309
      end
    end
  end
  object panelSignVerify: TPanel
    Left = 0
    Top = 193
    Width = 655
    Height = 309
    Align = alClient
    BevelOuter = bvNone
    ShowCaption = False
    TabOrder = 1
    ExplicitWidth = 649
    ExplicitHeight = 300
    object SplitterDataSign: TSplitter
      Left = 320
      Top = 0
      Width = 5
      Height = 216
      ExplicitLeft = 16
      ExplicitTop = 16
      ExplicitHeight = 120
    end
    object Panel2: TPanel
      Left = 0
      Top = 0
      Width = 320
      Height = 216
      Align = alLeft
      BevelOuter = bvNone
      ShowCaption = False
      TabOrder = 0
      ExplicitHeight = 207
      DesignSize = (
        320
        216)
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
        Height = 185
        Anchors = [akLeft, akTop, akRight, akBottom]
        Lines.Strings = (
          'Data to sign')
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitHeight = 176
      end
    end
    object btnSign: TButton
      AlignWithMargins = True
      Left = 3
      Top = 219
      Width = 649
      Height = 25
      Align = alBottom
      Caption = 'Sign'
      TabOrder = 1
      OnClick = btnSignClick
      ExplicitTop = 210
      ExplicitWidth = 643
    end
    object Panel3: TPanel
      Left = 325
      Top = 0
      Width = 330
      Height = 216
      Align = alClient
      ShowCaption = False
      TabOrder = 2
      ExplicitWidth = 324
      ExplicitHeight = 207
      DesignSize = (
        330
        216)
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
        Height = 185
        Anchors = [akLeft, akTop, akRight, akBottom]
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 0
        ExplicitWidth = 309
        ExplicitHeight = 176
      end
    end
    object btnVerify: TButton
      AlignWithMargins = True
      Left = 3
      Top = 281
      Width = 649
      Height = 25
      Align = alBottom
      Caption = 'Verify'
      TabOrder = 3
      OnClick = btnVerifyClick
      ExplicitTop = 272
      ExplicitWidth = 643
    end
    object btnExportSign: TButton
      AlignWithMargins = True
      Left = 3
      Top = 250
      Width = 649
      Height = 25
      Align = alBottom
      Caption = 'Export Signature'
      TabOrder = 4
      OnClick = btnExportSignClick
      ExplicitTop = 241
      ExplicitWidth = 643
    end
  end
  object dlgSaveSignature: TSaveDialog
    FileName = 'data.signature'
    Filter = 'Signature|*.signature'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Export Signature'
    Left = 501
    Top = 281
  end
  object timerKeyPair: TTimer
    Enabled = False
    OnTimer = timerKeyPairTimer
    Left = 152
    Top = 72
  end
end
