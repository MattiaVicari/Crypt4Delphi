{-------------------------------------------------------------------------------

  Project Crypt4Delphi

  The contents of this file are subject to the MIT License (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at https://opensource.org/licenses/MIT

  Software distributed under the License is distributed on an "AS IS" basis,
  WITHOUT WARRANTY OF ANY KIND, either express or implied.
  See the License for the specific language governing rights and limitations
  under the License.

  Author: Mattia Vicari

-------------------------------------------------------------------------------}

unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  System.Actions, Vcl.ActnList, System.IOUtils;

type
  TfrmMain = class(TForm)
    grpKeySettings: TRadioGroup;
    radioKeyAndIV: TRadioButton;
    radioPassword: TRadioButton;
    grpKeyIVPassword: TGroupBox;
    lblPassword: TLabel;
    edtPassword: TEdit;
    lblKey: TLabel;
    memKey: TMemo;
    btnLoadKey: TButton;
    lblIV: TLabel;
    btnLoadIV: TButton;
    memIV: TMemo;
    lblPlainText: TLabel;
    memPlainText: TMemo;
    lblCipherText: TLabel;
    memCipherText: TMemo;
    btnLoadCipher: TButton;
    btnEncrypt: TButton;
    btnDecrypt: TButton;
    Actions: TActionList;
    actKeySettings: TAction;
    actEncrypt: TAction;
    actLoadKey: TAction;
    OpenDialogBinary: TOpenDialog;
    actLoadIV: TAction;
    actDecrypt: TAction;
    btnSaveCipher: TButton;
    actLoadCipherData: TAction;
    actSaveCipherData: TAction;
    SaveDialogBinary: TSaveDialog;
    procedure actKeySettingsExecute(Sender: TObject);
    procedure actEncryptExecute(Sender: TObject);
    procedure actLoadKeyExecute(Sender: TObject);
    procedure actLoadIVExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure actDecryptExecute(Sender: TObject);
    procedure actLoadCipherDataExecute(Sender: TObject);
    procedure actSaveCipherDataExecute(Sender: TObject);
  private
    FKey: TBytes;
    FIV: TBytes;
    FCipherData: TBytes;
    function ByteToHexString(var BytesData: TBytes): string;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

uses
  CNGCrypt.Core;

procedure TfrmMain.actDecryptExecute(Sender: TObject);
var
  Aes: TCNGCrypt;
  Output: TBytes;
begin
  Aes := TCNGCrypt.Create;
  try
    Aes.UseIVBlock := radioPassword.Checked;
    if radioPassword.Checked then
      Aes.Password := edtPassword.Text
    else
    begin
      Aes.Key := FKey;
      Aes.IV := FIV;
    end;

    Aes.Decrypt(FCipherData, Output);
    memPlainText.Lines.Text := TEncoding.UTF8.GetString(Output);
  finally
    Aes.Free;
  end;
end;

procedure TfrmMain.actEncryptExecute(Sender: TObject);
var
  Aes: TCNGCrypt;
begin
  Aes := TCNGCrypt.Create;
  try
    Aes.UseIVBlock := radioPassword.Checked;
    if radioPassword.Checked then
      Aes.Password := edtPassword.Text
    else
    begin
      Aes.Key := FKey;
      Aes.IV := FIV;
    end;

    Aes.Encrypt(TEncoding.UTF8.GetBytes(memPlainText.Lines.Text), FCipherData);
    memCipherText.Lines.Text := ByteToHexString(FCipherData);
  finally
    Aes.Free;
  end;
end;

procedure TfrmMain.actKeySettingsExecute(Sender: TObject);
begin
  edtPassword.Enabled := radioPassword.Checked;
  memKey.Enabled := radioKeyAndIV.Checked;
  memIV.Enabled := radioKeyAndIV.Checked;
  btnLoadKey.Enabled := radioKeyAndIV.Checked;
  btnLoadIV.Enabled := radioKeyAndIV.Checked;
end;

procedure TfrmMain.actLoadCipherDataExecute(Sender: TObject);
begin
  if OpenDialogBinary.Execute then
  begin
    SetLength(FCipherData, 0);
    FCipherData := TFile.ReadAllBytes(OpenDialogBinary.FileName);
    memCipherText.Lines.Text := ByteToHexString(FCipherData);
  end;
end;

procedure TfrmMain.actLoadIVExecute(Sender: TObject);
begin
  SetLength(FIV, 0);
  memIV.Lines.Clear;
  if OpenDialogBinary.Execute then
  begin
    FIV := TFile.ReadAllBytes(OpenDialogBinary.FileName);
    memIV.Lines.Text := ByteToHexString(FIV);
  end;
end;

procedure TfrmMain.actLoadKeyExecute(Sender: TObject);
begin
  SetLength(FKey, 0);
  memKey.Lines.Clear;
  if OpenDialogBinary.Execute then
  begin
    FKey := TFile.ReadAllBytes(OpenDialogBinary.FileName);
    memKey.Lines.Text := ByteToHexString(FKey);
  end;
end;

procedure TfrmMain.actSaveCipherDataExecute(Sender: TObject);
var
  CipherStream: TFileStream;
begin
  if SaveDialogBinary.Execute then
  begin
    CipherStream := TFile.Create(SaveDialogBinary.FileName);
    try
      CipherStream.WriteBuffer(FCipherData, Length(FCipherData));
    finally
      CipherStream.Free;
    end;
  end;
end;

function TfrmMain.ByteToHexString(var BytesData: TBytes): string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(BytesData) to High(BytesData) do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + IntToHex(BytesData[I], 2);
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  actKeySettingsExecute(Self);
  OpenDialogBinary.InitialDir := TPath.Combine(ExtractFileDir(ParamStr(0)), 'Data');
  SaveDialogBinary.InitialDir := TPath.Combine(ExtractFileDir(ParamStr(0)), 'Data');
end;

end.
