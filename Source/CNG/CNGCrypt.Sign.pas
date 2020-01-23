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
  System.SysUtils, System.Hash,

  CNGCrypt.CAPI;

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
    function GetCAPIPrivateKeyBlobStruct(AKeyBlob: TBytes; AKeyBlobSize: DWORD): PRIVATEKEYBLOB;
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
  CNGCrypt.Utils;

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

function TRSAKeyInfo.GetCAPIPrivateKeyBlobStruct(AKeyBlob: TBytes; AKeyBlobSize: DWORD): PRIVATEKEYBLOB;
var
  Cursor: DWORD;
begin
  Cursor := 0;
  Move(AKeyBlob[Cursor], Result, SizeOf(Result.PublicKeyStruc) + SizeOf(Result.RSAPubKey));
  Inc(Cursor, SizeOf(Result.PublicKeyStruc) + SizeOf(Result.RSAPubKey));

  SetLength(Result.Modulus, Result.RSAPubKey.Bitlen div 8);
  Move(AKeyBlob[Cursor], Result.Modulus[0], Length(Result.Modulus));
  Inc(Cursor, Length(Result.Modulus));

  SetLength(Result.Prime1, Result.RSAPubKey.Bitlen div 16);
  Move(AKeyBlob[Cursor], Result.Prime1[0], Length(Result.Prime1));
  Inc(Cursor, Length(Result.Prime1));

  SetLength(Result.Prime2, Result.RSAPubKey.Bitlen div 16);
  Move(AKeyBlob[Cursor], Result.Prime2[0], Length(Result.Prime2));
  Inc(Cursor, Length(Result.Prime2));

  SetLength(Result.Exponent1, Result.RSAPubKey.Bitlen div 16);
  Move(AKeyBlob[Cursor], Result.Exponent1[0], Length(Result.Exponent1));
  Inc(Cursor, Length(Result.Exponent1));

  SetLength(Result.Exponent2, Result.RSAPubKey.Bitlen div 16);
  Move(AKeyBlob[Cursor], Result.Exponent2[0], Length(Result.Exponent2));
  Inc(Cursor, Length(Result.Exponent2));

  SetLength(Result.Coefficient, Result.RSAPubKey.Bitlen div 16);
  Move(AKeyBlob[Cursor], Result.Coefficient[0], Length(Result.Coefficient));
  Inc(Cursor, Length(Result.Coefficient));

  SetLength(Result.PrivateExponent, Result.RSAPubKey.Bitlen div 8);
  Move(AKeyBlob[Cursor], Result.PrivateExponent[0], Length(Result.PrivateExponent));
  Inc(Cursor, Length(Result.PrivateExponent));
  if Cursor <> AKeyBlobSize then
    raise Exception.Create('Mismatch bewteen the Key blob size and Private key structure size');
end;

procedure TRSAKeyInfo.CreateAsymmetricKey(AAlgorithm: Pointer; const AKey: TBytes);
var
  Status: Integer;
  BlobBuffer, KeyBlob, RSAKeyBlobBuffer: TBytes;
  CbPrivateKeySize, CbKeyBlobSize, CbRSAKeyBlobBufferSize: DWORD;
  CbSkip: DWORD;
  CbFlags: DWORD;
  RSACursor: DWORD;
  PrivateKeyString: PWideChar;
  PKKeyBlobStruct: PRIVATEKEYBLOB;
  RSAKeyBlob: BCRYPT_RSAKEY_BLOB;
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

  PKKeyBlobStruct := GetCAPIPrivateKeyBlobStruct(KeyBlob, CbKeyBlobSize);
  RSAKeyBlob.BitLength := PKKeyBlobStruct.RSAPubKey.Bitlen;
  RSAKeyBlob.Magic := PKKeyBlobStruct.RSAPubKey.Magic;
  RSAKeyBlob.cbPublicExp := SizeOf(PKKeyBlobStruct.RSAPubKey.PubExp);
  RSAKeyBlob.cbModulus :=  Length(PKKeyBlobStruct.Modulus);
  RSAKeyBlob.cbPrime1 := Length(PKKeyBlobStruct.Prime1);
  RSAKeyBlob.cbPrime2 := Length(PKKeyBlobStruct.Prime2);

  RSACursor := 0;
  CbRSAKeyBlobBufferSize := SizeOf(RSAKeyBlob) + RSAKeyBlob.cbPublicExp + RSAKeyBlob.cbModulus;
  if (RSAKeyBlob.cbPrime1 > 0) and (Length(PKKeyBlobStruct.Prime1) > 0) then
    Inc(CbRSAKeyBlobBufferSize, RSAKeyBlob.cbPrime1);
  if (RSAKeyBlob.cbPrime2 > 0) and (Length(PKKeyBlobStruct.Prime2) > 0) then
    Inc(CbRSAKeyBlobBufferSize, RSAKeyBlob.cbPrime2);
  if (RSAKeyBlob.cbPrime1 > 0) and (Length(PKKeyBlobStruct.Exponent1) > 0) then
    Inc(CbRSAKeyBlobBufferSize, RSAKeyBlob.cbPrime1);
  if (RSAKeyBlob.cbPrime2 > 0) and (Length(PKKeyBlobStruct.Exponent2) > 0) then
    Inc(CbRSAKeyBlobBufferSize, RSAKeyBlob.cbPrime2);
  if (RSAKeyBlob.cbPrime1 > 0) and (Length(PKKeyBlobStruct.Coefficient) > 0) then
    Inc(CbRSAKeyBlobBufferSize, RSAKeyBlob.cbPrime1);
  if Length(PKKeyBlobStruct.PrivateExponent) > 0 then
    Inc(CbRSAKeyBlobBufferSize, RSAKeyBlob.cbModulus);
  SetLength(RSAKeyBlobBuffer, CbRSAKeyBlobBufferSize);

  Move(RSAKeyBlob, RSAKeyBlobBuffer[RSACursor], SizeOf(RSAKeyBlob));
  Inc(RSACursor, SizeOf(RSAKeyBlob));

  Move(PKKeyBlobStruct.RSAPubKey.PubExp, RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbPublicExp);
  Inc(RSACursor, RSAKeyBlob.cbPublicExp);

  Move(PKKeyBlobStruct.Modulus[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbModulus);
  Inc(RSACursor, RSAKeyBlob.cbModulus);

  if (RSAKeyBlob.cbPrime1 > 0) and (Length(PKKeyBlobStruct.Prime1) > 0) then
  begin
    Move(PKKeyBlobStruct.Prime1[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbPrime1);
    Inc(RSACursor, RSAKeyBlob.cbPrime1);
  end;
  if (RSAKeyBlob.cbPrime2 > 0) and (Length(PKKeyBlobStruct.Prime2) > 0) then
  begin
    Move(PKKeyBlobStruct.Prime2[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbPrime2);
    Inc(RSACursor, RSAKeyBlob.cbPrime2);
  end;

  if (RSAKeyBlob.cbPrime1 > 0) and (Length(PKKeyBlobStruct.Exponent1) > 0) then
  begin
    Move(PKKeyBlobStruct.Exponent1[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbPrime1);
    Inc(RSACursor, RSAKeyBlob.cbPrime1);
  end;
  if (RSAKeyBlob.cbPrime2 > 0) and (Length(PKKeyBlobStruct.Exponent2) > 0) then
  begin
    Move(PKKeyBlobStruct.Exponent2[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbPrime2);
    Inc(RSACursor, RSAKeyBlob.cbPrime2);
  end;

  if (RSAKeyBlob.cbPrime1 > 0) and (Length(PKKeyBlobStruct.Coefficient) > 0) then
  begin
    Move(PKKeyBlobStruct.Coefficient[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbPrime1);
    Inc(RSACursor, RSAKeyBlob.cbPrime1);
  end;

  if Length(PKKeyBlobStruct.PrivateExponent) > 0 then
  begin
    Move(PKKeyBlobStruct.PrivateExponent[0], RSAKeyBlobBuffer[RSACursor], RSAKeyBlob.cbModulus);
    Inc(RSACursor, RSAKeyBlob.cbModulus);
  end;

  if RSACursor <> CbRSAKeyBlobBufferSize then
    raise Exception.Create('Mismatch between the size of the blob to import and the destination blob buffer');  


  // Import the key in order to use it to sign.
  Status := BCryptImportKeyPair(AAlgorithm,
                                nil,
                                BCRYPT_RSAFULLPRIVATE_BLOB,
                                FHKey,
                                RSAKeyBlobBuffer,
                                CbRSAKeyBlobBufferSize,
                                0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptImportKeyPair error: ' + IntToStr(Status));
end;

end.
