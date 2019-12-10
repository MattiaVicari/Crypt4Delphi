unit MainFrm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  CNGCrypt.Rng;

type
  TfrmMain = class(TForm)
    btnGenRandomBuffer: TButton;
    edtRandomBuffer: TEdit;
    lblBufferSize: TLabel;
    edtBufferSize: TEdit;
    edtRandomNumber: TEdit;
    btnGenRandomNumber: TButton;
    lblMinValue: TLabel;
    edtMinValue: TEdit;
    lblMaxValue: TLabel;
    edtMaxValue: TEdit;
    edtRandomRangeNumber: TEdit;
    btnGenRandomRangeNumber: TButton;
    lblStringLength: TLabel;
    edtStringLength: TEdit;
    edtRandomString: TEdit;
    btnGenRandomString: TButton;
    procedure btnGenRandomBufferClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnGenRandomNumberClick(Sender: TObject);
    procedure btnGenRandomRangeNumberClick(Sender: TObject);
    procedure btnGenRandomStringClick(Sender: TObject);
  private
    FCNGRng: TCNGCryptRng;
    function ByteToHexString(var BytesData: TBytes): string;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.dfm}

procedure TfrmMain.btnGenRandomBufferClick(Sender: TObject);
var
  Output: TBytes;
  BufferSize: Integer;
begin
  BufferSize := StrToIntDef(edtBufferSize.Text, 0);
  SetLength(Output, BufferSize);

  FCNGRng.GetRandom(Output);

  edtRandomBuffer.Text := ByteToHexString(Output);
end;

procedure TfrmMain.btnGenRandomNumberClick(Sender: TObject);
begin
  edtRandomNumber.Text := IntToStr(FCNGRng.GetRandomNumber);
end;

procedure TfrmMain.btnGenRandomRangeNumberClick(Sender: TObject);
begin
  edtRandomRangeNumber.Text := IntToStr(FCNGRng.GetRandomNumber(StrToInt(edtMinValue.Text), StrToInt(edtMaxValue.Text)));
end;

procedure TfrmMain.btnGenRandomStringClick(Sender: TObject);
begin
  edtRandomString.Text := FCNGRng.GetRandomString(StrToInt(edtStringLength.Text), $41, $5A);
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

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FCNGRng := TCNGCryptRng.Create;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FCNGRng.Free;
end;

end.
