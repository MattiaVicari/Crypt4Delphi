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

unit CNGCrypt.Sign;

interface

uses
  Winapi.Windows, System.Classes, Winapi.Messages,
  System.SysUtils, System.Hash;

type
  TRSAAlgorithm = class(TObject)
  private
    FHRsaAlg: Pointer;
    FKeyObjectLen: DWORD;
  public
    property HAesAlg: Pointer read FHRsaAlg;
    property KeyObjectLen: DWORD read FKeyObjectLen;
    constructor Create;
    destructor Destroy; override;
  end;

  // https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptimportkeypair
  TRSAKeyInfo = class(TObject)
  private
    FHKey: Pointer;
    FAlgorithm: TRSAAlgorithm;
    FPrivateKey: Boolean;
    procedure CreateAsymmetricKey(AAlgorithm: Pointer; const AKey: TBytes);
  public
    property HKey: Pointer read FHKey;

    constructor Create(AAlgorithm: TRSAAlgorithm; const AKey: TBytes; APrivateKey: Boolean);
    destructor Destroy; override;
  end;

  // https://docs.microsoft.com/en-us/windows/win32/seccng/signing-data-with-cng
  TCNGSign = class
  public
    procedure Sign(Data, SignedData: TStream; PrivateKey: TBytes); overload;
    procedure Sign(Data, SignedData, PrivateKey: TBytes); overload;

    function Verify(SignedData: TStream; PublicKey: TBytes): Boolean; overload;
    function Verify(SignedData, PublicKey: TBytes): Boolean; overload;
  end;

implementation

uses
  CNGCrypt.WinAPI,
  CNGCrypt.CAPI;

procedure MoveReverse(const Source; var Dest; Count: NativeInt);
var
  I: Integer;
begin
  for I := 0 to Count - 1 do
  begin
    PByte(Dest)[Count - I - 1] := PByte(Source)[I];
  end;
end;

{ TRSAAlgorithm }

constructor TRSAAlgorithm.Create;
var
  Status: Integer;
begin
  Status := BCryptOpenAlgorithmProvider(FHRsaAlg, PChar(BCRYPT_RSA_ALGORITHM), MS_PRIMITIVE_PROVIDER, 0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptOpenAlgorithmProvider error: ' + IntToStr(Status));
end;

destructor TRSAAlgorithm.Destroy;
begin
  if Assigned(FHRsaAlg) then
  begin
    BCryptCloseAlgorithmProvider(FHRsaAlg, 0);
    FHRsaAlg := nil;
  end;
  inherited;
end;

{ TCNGSign }

procedure TCNGSign.Sign(Data, SignedData: TStream; PrivateKey: TBytes);
var
  InputBuffer: TBytes;
  OutputBuffer: TBytes;
begin
  SetLength(InputBuffer, Data.Size);
  Data.Position := 0;
  Data.Read(InputBuffer[0], Data.Size);
  Sign(InputBuffer, OutputBuffer, PrivateKey);
  SignedData.WriteBuffer(OutputBuffer[0], Length(OutputBuffer));
end;

procedure TCNGSign.Sign(Data, SignedData, PrivateKey: TBytes);
var
  Status: Integer;
  HashData: TBytes;
  DataStream: TMemoryStream;
  RsaAlg: TRSAAlgorithm;
  RsaKey: TRSAKeyInfo;
  PaddingInfo: BCRYPT_PKCS1_PADDING_INFO;
  SignatureLen, SignedLen: DWORD;
begin
  DataStream := TMemoryStream.Create;
  try
    DataStream.WriteBuffer(Data[0], Length(Data));
    HashData := THashSHA2.GetHashBytes(DataStream);
  finally
    DataStream.Free;
  end;

  RsaAlg := TRSAAlgorithm.Create;
  try
    RsaKey := TRSAKeyInfo.Create(RsaAlg, PrivateKey, True);
    try
      Status := BCryptSignHash(RsaKey.HKey,
                               Pointer(PaddingInfo),
                               Pointer(HashData),
                               Length(HashData),
                               nil,
                               0,
                               SignatureLen,
                               0);
      if not Succeeded(Status) then
        raise Exception.Create('BCryptSignHash error: ' + IntToStr(Status));

      SetLength(SignedData, SignatureLen);

      // Use the SHA256 algorithm to create padding information.
      PaddingInfo.pszAlgId := BCRYPT_SHA256_ALGORITHM;

      Status := BCryptSignHash(RsaKey.HKey,
                               Pointer(PaddingInfo),
                               Pointer(HashData),
                               Length(HashData),
                               Pointer(SignedData),
                               SignatureLen,
                               SignedLen,
                               BCRYPT_PAD_PKCS1);
      if not Succeeded(Status) then
        raise Exception.Create('BCryptSignHash error: ' + IntToStr(Status));

    finally
      RsaKey.Free;
    end;
  finally
    RsaAlg.Free;
  end;
end;

function TCNGSign.Verify(SignedData: TStream; PublicKey: TBytes): Boolean;
var
  InputBuffer: TBytes;
begin
  SetLength(InputBuffer, SignedData.Size);
  SignedData.Position := 0;
  SignedData.Read(InputBuffer[0], SignedData.Size);
  Result := Verify(InputBuffer, PublicKey);
end;

function TCNGSign.Verify(SignedData, PublicKey: TBytes): Boolean;
begin
  Result := False;
  // TODO
end;

{ TKeyPairInfo }

constructor TRSAKeyInfo.Create(AAlgorithm: TRSAAlgorithm; const AKey: TBytes; APrivateKey: Boolean);
begin
  FAlgorithm := AAlgorithm;
  FPrivateKey := APrivateKey;
  FHKey := nil;

  CreateAsymmetricKey(FAlgorithm.FHRsaAlg, AKey);
end;

destructor TRSAKeyInfo.Destroy;
begin
  if Assigned(FHKey) then
  begin
    BCryptDestroyKey(FHKey);
    FHKey := nil;
  end;
  inherited;
end;

procedure TRSAKeyInfo.CreateAsymmetricKey(AAlgorithm: Pointer; const AKey: TBytes);
var
  Status: Integer;
  BlobBuffer, KeyBlob: TBytes;
  CbPrivateKeySize, CbKeyBlobSize: DWORD;
  CbSkip: DWORD;
  CbFlags: DWORD;
  PrivateKeyString: PWideChar;
begin
  // I have to use the CryptoAPI to load the Private Key from PEM
  PrivateKeyString := PWideChar(TEncoding.UTF8.GetString(AKey));
  Status := CryptStringToBinaryW(PrivateKeyString,
                                 0,
                                 CRYPT_STRING_BASE64HEADER,
                                 nil,
                                 CbPrivateKeySize,
                                 CbSkip,
                                 CbFlags);
  if Status <> 1 then
    raise Exception.Create('CryptStringToBinaryW error: ' + IntToStr(Status));

  SetLength(BlobBuffer, CbPrivateKeySize);
  Status := CryptStringToBinaryW(PrivateKeyString,
                                 0,
                                 CRYPT_STRING_BASE64HEADER,
                                 BlobBuffer,
                                 CbPrivateKeySize,
                                 CbSkip,
                                 CbFlags);
  if Status <> 1 then
    raise Exception.Create('CryptStringToBinaryW error: ' + IntToStr(Status));

  Status := CryptDecodeObjectEx(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                                PKCS_RSA_PRIVATE_KEY,
                                BlobBuffer,
                                CbPrivateKeySize,
                                0,
                                nil,
                                nil,
                                CbKeyBlobSize);
  if Status <> 1 then
    raise Exception.Create('CryptDecodeObjectEx error: ' + IntToStr(Status));

  SetLength(KeyBlob, CbKeyBlobSize);
  Status := CryptDecodeObjectEx(X509_ASN_ENCODING or PKCS_7_ASN_ENCODING,
                                PKCS_RSA_PRIVATE_KEY,
                                BlobBuffer,
                                CbPrivateKeySize,
                                0,
                                nil,
                                KeyBlob,
                                CbKeyBlobSize);
  if Status <> 1 then
    raise Exception.Create('CryptDecodeObjectEx error: ' + IntToStr(Status));

  // Import the key in order to use it to sign.
  Status := BCryptImportKeyPair(AAlgorithm,
                                nil,
                                BCRYPT_RSAPRIVATE_BLOB,
                                FHKey,
                                KeyBlob,
                                CbKeyBlobSize,
                                0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptImportKeyPair error: ' + IntToStr(Status));
end;

end.
