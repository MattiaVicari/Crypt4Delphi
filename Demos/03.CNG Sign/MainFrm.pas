unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  System.IOUtils, System.UITypes, Winapi.ShellAPI,

  CNGCrypt.Sign;

type
  TfrmMain = class(TForm)
    panelKeys: TPanel;
    panelPrivateKey: TPanel;
    btnGenerateKeyPair: TButton;
    panelPublicKey: TPanel;
    lblPrivateKey: TLabel;
    memoPrivateKey: TMemo;
    lblPublicKey: TLabel;
    memoPublicKey: TMemo;
    SplitterKey: TSplitter;
    panelSignVerify: TPanel;
    SplitterDataSign: TSplitter;
    Panel2: TPanel;
    lblData: TLabel;
    memoData: TMemo;
    btnSign: TButton;
    Panel3: TPanel;
    lblSignature: TLabel;
    memoSignature: TMemo;
    btnVerify: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnGenerateKeyPairClick(Sender: TObject);
    procedure btnSignClick(Sender: TObject);
    procedure btnVerifyClick(Sender: TObject);
  private
    FRsaSign: TCNGSign;
    FDataFolder: string;
    FPrivateKeyFilePath: string;
    FPublicKeyFilePath: string;
    FSignatureFilePath: string;

    function KeyExists: Boolean;
    function ReadBinDataToHex(const FilePath: string): string;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnGenerateKeyPairClick(Sender: TObject);
var
  BatchPath: string;
  Ret: Integer;
begin
  BatchPath := TPath.Combine(FDataFolder, 'createKeyPair.bat');
  Ret := ShellExecute(HInstance, 'open', PWideChar(BatchPath), nil, PWideChar(FDataFolder), SW_HIDE);
  if Ret > 32 then
    btnSign.Enabled := KeyExists
  else
    MessageDlg('Fail to generate key pair. Error code: ' + IntToStr(GetLastError), mtError, [mbOK], 0);
end;

procedure TfrmMain.btnSignClick(Sender: TObject);
var
  DataToSign: TBytes;
  Signature: TBytes;
  PrivateKey: TBytes;
begin
  DataToSign := TEncoding.UTF8.GetBytes(memoData.Lines.Text);
  PrivateKey := TFile.ReadAllBytes(FPrivateKeyFilePath);
  FRsaSign.Sign(DataToSign, Signature, PrivateKey);
  if Length(Signature) > 0 then
  begin
    TFile.WriteAllBytes(FSignatureFilePath, Signature);
    memoSignature.Lines.Text := ReadBinDataToHex(FSignatureFilePath);
    btnVerify.Enabled := True;
  end;
end;

procedure TfrmMain.btnVerifyClick(Sender: TObject);
var
  DataToSign: TBytes;
  Signature: TBytes;
  PublicKey: TBytes;
begin
  DataToSign := TEncoding.UTF8.GetBytes(memoData.Lines.Text);
  PublicKey := TFile.ReadAllBytes(FPublicKeyFilePath);
  Signature := TFile.ReadAllBytes(FSignatureFilePath);
  if FRsaSign.Verify(DataToSign, Signature, PublicKey) then
    MessageDlg('Success!', mtInformation, [mbOK], 0)
  else
    MessageDlg('Fail!', mtWarning, [mbOK], 0)
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FDataFolder := TPath.Combine(ExtractFileDir(ParamStr(0)), 'data');
  FSignatureFilePath := TPath.Combine(FDataFolder, 'signature.bin');
  FPrivateKeyFilePath := TPath.Combine(FDataFolder, 'keypair.pem');
  FPublicKeyFilePath := TPath.Combine(FDataFolder, 'pubkey.pem');
  FRsaSign := TCNGSign.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FRsaSign.Free;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if KeyExists then
  begin
    memoPrivateKey.Lines.Text := TFile.ReadAllText(FPrivateKeyFilePath, TEncoding.UTF8);
    memoPublicKey.Lines.Text := TFile.ReadAllText(FPublicKeyFilePath, TEncoding.UTF8);
    btnSign.Enabled := True;
  end
  else
    btnSign.Enabled := False;
  btnVerify.Enabled := TFile.Exists(FSignatureFilePath);
end;

function TfrmMain.KeyExists: Boolean;
begin
  Result := TFile.Exists(FPrivateKeyFilePath) and TFile.Exists(FPublicKeyFilePath);
end;

function TfrmMain.ReadBinDataToHex(const FilePath: string): string;
var
  I: Integer;
  Data: TBytes;
begin
  Data := TFile.ReadAllBytes(FilePath);
  for I := Low(Data) to High(Data) do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + IntToHex(Data[I], 2);
  end;
end;

end.
