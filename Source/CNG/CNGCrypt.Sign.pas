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

  CNGCrypt.WinAPI,
  CNGCrypt.CAPI;

type
  TRSAKeyType = (rsaPrivateKey, rsaPublicKey, rsaFullPrivate);

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
    procedure CreatePrivateKey(AAlgorithm: Pointer; const AKey: TBytes);
    procedure CreatePublicKey(AAlgorithm: Pointer; const AKey: TBytes);
    procedure LoadKeyFromPEM(AAlgorithm: Pointer; const AKey: TBytes;
        var AKeyBlob: TBytes; var ACbKeyBlobSize: DWORD);
    function GetCAPIPrivateKeyBlobStruct(AKeyBlob: TBytes; AKeyBlobSize: DWORD): PRIVATEKEYBLOB;
    function GetCAPIPublicKeyBlobStruct(AKeyBlob: TBytes; AKeyBlobSize: DWORD): PUBLICKEYBLOB;
    function GetCNGKeyBlob(const AKeyBlob: PRIVATEKEYBLOB; var ACbRSAKeyBlobBufferSize: DWORD; AKeyType: TRSAKeyType): TBytes;
  public
    property HKey: Pointer read FHKey;
    property PrivateKey: Boolean read FPrivateKey;

    constructor Create(AAlgorithm: TRSAAlgorithm; const AKey: TBytes; APrivateKey: Boolean);
    destructor Destroy; override;
  end;

  // https://docs.microsoft.com/en-us/windows/win32/seccng/signing-data-with-cng
  TCNGSign = class
  public
    procedure Sign(Data, SignedData: TStream; PrivateKey: TBytes); overload;
    procedure Sign(Data: TBytes; var SignedData: TBytes; PrivateKey: TBytes); overload;

    function Verify(Data, Signature: TStream; PublicKey: TBytes): Boolean; overload;
    function Verify(Data, Signature, PublicKey: TBytes): Boolean; overload;
  end;

implementation

uses
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

procedure CopyAndAdvance(const ASourceBuffer: TBytes; var ADestBuffer; var ACursor: DWORD; ASize: DWORD);
begin
  Move(ASourceBuffer[ACursor], ADestBuffer, ASize);
  Inc(ACursor, ASize);
end;

{ TRSAAlgorithm }

constructor TRSAAlgorithm.Create;
var
  Status: DWORD;
begin
  Status := BCryptOpenAlgorithmProvider(FHRsaAlg, PChar(BCRYPT_RSA_ALGORITHM), nil, 0);
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

procedure TCNGSign.Sign(Data: TBytes; var SignedData: TBytes; PrivateKey: TBytes);
var
  Status: DWORD;
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
    DataStream.Position := 0;
    HashData := THashSHA2.GetHashBytes(DataStream);
  finally
    DataStream.Free;
  end;

  RsaAlg := TRSAAlgorithm.Create;
  try
    RsaKey := TRSAKeyInfo.Create(RsaAlg, PrivateKey, True);
    try
      Status := BCryptSignHash(RsaKey.HKey,
                               nil,
                               @HashData[0],
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
                               @PaddingInfo,
                               @HashData[0],
                               Length(HashData),
                               SignedData,
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

function TCNGSign.Verify(Data, Signature: TStream; PublicKey: TBytes): Boolean;
var
  SignatureBuffer, DataBuffer: TBytes;
begin
  SetLength(DataBuffer, Data.Size);
  SetLength(SignatureBuffer, Signature.Size);

  Signature.Position := 0;
  Signature.Read(SignatureBuffer[0], Signature.Size);
  Data.Position := 0;
  Data.Read(DataBuffer[0], Data.Size);

  Result := Verify(DataBuffer, SignatureBuffer, PublicKey);
end;

function TCNGSign.Verify(Data, Signature, PublicKey: TBytes): Boolean;
var
  Status: DWORD;
  HashData: TBytes;
  DataStream: TMemoryStream;
  RsaAlg: TRSAAlgorithm;
  RsaKey: TRSAKeyInfo;
  PaddingInfo: BCRYPT_PKCS1_PADDING_INFO;
begin
  DataStream := TMemoryStream.Create;
  try
    DataStream.WriteBuffer(Data[0], Length(Data));
    DataStream.Position := 0;
    HashData := THashSHA2.GetHashBytes(DataStream);
  finally
    DataStream.Free;
  end;

  RsaAlg := TRSAAlgorithm.Create;
  try
    RsaKey := TRSAKeyInfo.Create(RsaAlg, PublicKey, False);
    try
      // Use the SHA256 algorithm to create padding information.
      PaddingInfo.pszAlgId := BCRYPT_SHA256_ALGORITHM;

      Status := BCryptVerifySignature(RsaKey.HKey,
                                      @PaddingInfo,
                                      @HashData[0],
                                      Length(HashData),
                                      @Signature[0],
                                      Length(Signature),
                                      BCRYPT_PAD_PKCS1);
      case Status of
        STATUS_SUCCESS: Result := True;
        STATUS_INVALID_SIGNATURE: Result := False;
      else
        raise Exception.Create('BCryptVerifySignature error: ' + IntToStr(Status));
      end;
    finally
      RsaKey.Free;
    end;
  finally
    RsaAlg.Free;
  end;
end;

{ TKeyPairInfo }

constructor TRSAKeyInfo.Create(AAlgorithm: TRSAAlgorithm; const AKey: TBytes; APrivateKey: Boolean);
begin
  FAlgorithm := AAlgorithm;
  FPrivateKey := APrivateKey;
  if APrivateKey then
    CreatePrivateKey(FAlgorithm.FHRsaAlg, AKey)
  else
    CreatePublicKey(FAlgorithm.FHRsaAlg, AKey);
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
  CbModulus, CbPrime: DWORD;
begin
  Cursor := 0;
  CopyAndAdvance(AKeyBlob, Result, Cursor, SizeOf(Result.PublicKeyStruc) + SizeOf(Result.RSAPubKey));

  CbModulus := Result.RSAPubKey.Bitlen div 8;
  CbPrime := Result.RSAPubKey.Bitlen div 16;

  SetLength(Result.Modulus, CbModulus);
  CopyAndAdvance(AKeyBlob, Result.Modulus[0], Cursor, CbModulus);

  SetLength(Result.Prime1, CbPrime);
  CopyAndAdvance(AKeyBlob, Result.Prime1[0], Cursor, CbPrime);

  SetLength(Result.Prime2, CbPrime);
  CopyAndAdvance(AKeyBlob, Result.Prime2[0], Cursor, CbPrime);

  SetLength(Result.Exponent1, CbPrime);
  CopyAndAdvance(AKeyBlob, Result.Exponent1[0], Cursor, CbPrime);

  SetLength(Result.Exponent2, CbPrime);
  CopyAndAdvance(AKeyBlob, Result.Exponent2[0], Cursor, CbPrime);

  SetLength(Result.Coefficient, CbPrime);
  CopyAndAdvance(AKeyBlob, Result.Coefficient[0], Cursor, CbPrime);

  SetLength(Result.PrivateExponent, CbModulus);
  CopyAndAdvance(AKeyBlob, Result.PrivateExponent[0], Cursor, CbModulus);

  if Cursor <> AKeyBlobSize then
    raise Exception.Create('Mismatch between the Key blob size and Private key structure size');
end;

function TRSAKeyInfo.GetCAPIPublicKeyBlobStruct(AKeyBlob: TBytes;
  AKeyBlobSize: DWORD): PUBLICKEYBLOB;
var
  Cursor: DWORD;
  CbModulus: DWORD;
begin
  Cursor := 0;
  CopyAndAdvance(AKeyBlob, Result, Cursor, SizeOf(Result.PublicKeyStruc) + SizeOf(Result.RSAPubKey));

  CbModulus := Result.RSAPubKey.Bitlen div 8;

  SetLength(Result.Modulus, CbModulus);
  CopyAndAdvance(AKeyBlob, Result.Modulus[0], Cursor, CbModulus);

  if Cursor <> AKeyBlobSize then
    raise Exception.Create('Mismatch between the Key blob size and Public key structure size');
end;

function TRSAKeyInfo.GetCNGKeyBlob(const AKeyBlob: PRIVATEKEYBLOB; var ACbRSAKeyBlobBufferSize: DWORD ;
  AKeyType: TRSAKeyType): TBytes;

  procedure ComputeBufferSize(ABuffer: TBytes; ASize: DWORD);
  begin
    if (ASize > 0) and (Length(ABuffer) > 0) then
      Inc(ACbRSAKeyBlobBufferSize, ASize);
  end;

  procedure CheckAndCopyToBuffer(ASourceBuffer: TBytes; ASize: DWORD; var ACursor: DWORD);
  begin
    if (ASize > 0) and (Length(ASourceBuffer) > 0) then
    begin
      TUtils.ReverseMemCopy(ASourceBuffer[0], Result[ACursor], ASize);
      Inc(ACursor, ASize);
    end;
  end;

var
  RSACursor: DWORD;
  RSAKeyBlob: BCRYPT_RSAKEY_BLOB;
  CbModulus, CbExp: DWORD;
begin
  CbModulus := (AKeyBlob.RSAPubKey.Bitlen + 7) div 8;
  CbExp := 1;
  if AKeyBlob.RSAPubKey.PubExp and $FF000000 > 0 then
    CbExp := 4
  else if AKeyBlob.RSAPubKey.PubExp and $00FF0000 > 0 then
    CbExp := 3
  else if AKeyBlob.RSAPubKey.PubExp and $0000FF00 > 0 then
    CbExp := 2;

  if CbModulus <> DWORD(Length(AKeyBlob.Modulus)) then
    raise Exception.Create('Modulus size doesn''t match');

  RSAKeyBlob.BitLength := AKeyBlob.RSAPubKey.Bitlen;
  case AKeyType of
    rsaPrivateKey: RSAKeyBlob.Magic :=  BCRYPT_RSAPRIVATE_MAGIC;
    rsaPublicKey: RSAKeyBlob.Magic :=  BCRYPT_RSAPUBLIC_MAGIC;
    rsaFullPrivate: RSAKeyBlob.Magic :=  BCRYPT_RSAFULLPRIVATE_MAGIC;
  else
    raise Exception.Create('Key type unknown');
  end;
  RSAKeyBlob.cbPublicExp := CbExp;
  RSAKeyBlob.cbModulus :=  CbModulus;
  RSAKeyBlob.cbPrime1 := Length(AKeyBlob.Prime1);
  RSAKeyBlob.cbPrime2 := Length(AKeyBlob.Prime2);

  RSACursor := 0;

  ACbRSAKeyBlobBufferSize := SizeOf(RSAKeyBlob) + RSAKeyBlob.cbPublicExp;

  ComputeBufferSize(AKeyBlob.Modulus, RSAKeyBlob.cbModulus);
  if AKeyType in [rsaPrivateKey, rsaFullPrivate] then
  begin
    ComputeBufferSize(AKeyBlob.Prime1, RSAKeyBlob.cbPrime1);
    ComputeBufferSize(AKeyBlob.Prime2, RSAKeyBlob.cbPrime2);
    if AKeyType = rsaFullPrivate then
    begin
      ComputeBufferSize(AKeyBlob.Exponent1, RSAKeyBlob.cbPrime1);
      ComputeBufferSize(AKeyBlob.Exponent2, RSAKeyBlob.cbPrime2);
      ComputeBufferSize(AKeyBlob.Coefficient, RSAKeyBlob.cbPrime1);
      ComputeBufferSize(AKeyBlob.PrivateExponent, RSAKeyBlob.cbModulus);
    end;
  end;

  SetLength(Result, ACbRSAKeyBlobBufferSize);

  // Header information
  Move(RSAKeyBlob, Result[RSACursor], SizeOf(RSAKeyBlob));
  Inc(RSACursor, SizeOf(RSAKeyBlob));

  // Public exponent
  TUtils.ReverseMemCopy(AKeyBlob.RSAPubKey.PubExp, Result[RSACursor], RSAKeyBlob.cbPublicExp);
  Inc(RSACursor, RSAKeyBlob.cbPublicExp);

  // Other components
  CheckAndCopyToBuffer(AKeyBlob.Modulus, RSAKeyBlob.cbModulus, RSACursor);
  if AKeyType in [rsaPrivateKey, rsaFullPrivate] then
  begin
    CheckAndCopyToBuffer(AKeyBlob.Prime1, RSAKeyBlob.cbPrime1, RSACursor);
    CheckAndCopyToBuffer(AKeyBlob.Prime2, RSAKeyBlob.cbPrime2, RSACursor);
    if AKeyType = rsaFullPrivate then
    begin
      CheckAndCopyToBuffer(AKeyBlob.Exponent1, RSAKeyBlob.cbPrime1, RSACursor);
      CheckAndCopyToBuffer(AKeyBlob.Exponent2, RSAKeyBlob.cbPrime2, RSACursor);
      CheckAndCopyToBuffer(AKeyBlob.Coefficient, RSAKeyBlob.cbPrime1, RSACursor);
      CheckAndCopyToBuffer(AKeyBlob.PrivateExponent, RSAKeyBlob.cbModulus, RSACursor);
    end;
  end;

  if RSACursor <> ACbRSAKeyBlobBufferSize then
    raise Exception.Create('Mismatch between the size of the RSA key blob and the source key blob');
end;

procedure TRSAKeyInfo.LoadKeyFromPEM(AAlgorithm: Pointer; const AKey: TBytes;
  var AKeyBlob: TBytes; var ACbKeyBlobSize: DWORD);
var
  Status: Integer;
  BlobBuffer: TBytes;
  CbKeySize: DWORD;
  CbSkip: DWORD;
  CbFlags: DWORD;
  CertEncodingType: DWORD;
  KeyString: string;
  StructType: PChar;
  PubKeyBlob: TBytes;
begin
  CertEncodingType := X509_ASN_ENCODING or PKCS_7_ASN_ENCODING;
  StructType := PKCS_RSA_PRIVATE_KEY;
  if not FPrivateKey then
    StructType := RSA_CSP_PUBLICKEYBLOB;

  // I have to use the CryptoAPI to load the Private Key from PEM
  KeyString := TEncoding.UTF8.GetString(AKey);
  Status := CryptStringToBinaryW(PChar(KeyString),
                                 0,
                                 CRYPT_STRING_BASE64HEADER,
                                 nil,
                                 CbKeySize,
                                 CbSkip,
                                 CbFlags);
  if Status <> 1 then
    raise Exception.Create('CryptStringToBinaryW error: ' + IntToStr(Status));

  SetLength(BlobBuffer, CbKeySize);
  Status := CryptStringToBinaryW(PChar(KeyString),
                                 0,
                                 CRYPT_STRING_BASE64HEADER,
                                 BlobBuffer,
                                 CbKeySize,
                                 CbSkip,
                                 CbFlags);
  if Status <> 1 then
    raise Exception.Create('CryptStringToBinaryW error: ' + IntToStr(Status));

  // For public key, check if I need to skip the first 24 bit in order to go from PUBLIC KEY to RSA PUBLIC KEY
  if (not FPrivateKey) and (KeyString.StartsWith('-----BEGIN PUBLIC KEY-----')) then
  begin
    Dec(CbKeySize, 24);
    SetLength(PubKeyBlob, CbKeySize);
    Move(BlobBuffer[24], PubKeyBlob[0], CbKeySize);
    SetLength(BlobBuffer, CbKeySize);
    Move(PubKeyBlob[0], BlobBuffer[0], CbKeySize);
  end;

  Status := CryptDecodeObjectEx(CertEncodingType,
                                StructType,
                                BlobBuffer,
                                CbKeySize,
                                0,
                                nil,
                                nil,
                                ACbKeyBlobSize);
  if Status <> 1 then
    raise Exception.Create('CryptDecodeObjectEx error: ' + IntToStr(Status));

  SetLength(AKeyBlob, ACbKeyBlobSize);
  Status := CryptDecodeObjectEx(CertEncodingType,
                                StructType,
                                BlobBuffer,
                                CbKeySize,
                                0,
                                nil,
                                AKeyBlob,
                                ACbKeyBlobSize);
  if Status <> 1 then
    raise Exception.Create('CryptDecodeObjectEx error: ' + IntToStr(Status));
end;

procedure TRSAKeyInfo.CreatePrivateKey(AAlgorithm: Pointer; const AKey: TBytes);
var
  Status: Integer;
  KeyBlob, RSAKeyBlobBuffer: TBytes;
  CbKeyBlobSize, CbRSAKeyBlobBufferSize: DWORD;
  PKKeyBlobStruct: PRIVATEKEYBLOB;
begin
  // Load private key from PEM data
  LoadKeyFromPEM(AAlgorithm, AKey, KeyBlob, CbKeyBlobSize);

  PKKeyBlobStruct := GetCAPIPrivateKeyBlobStruct(KeyBlob, CbKeyBlobSize);
  RSAKeyBlobBuffer := GetCNGKeyBlob(PKKeyBlobStruct, CbRSAKeyBlobBufferSize, rsaPrivateKey);

  // Import the key in order to use it to sign.
  Status := BCryptImportKeyPair(AAlgorithm,
                                nil,
                                BCRYPT_RSAPRIVATE_BLOB,
                                FHKey,
                                RSAKeyBlobBuffer,
                                CbRSAKeyBlobBufferSize,
                                0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptImportKeyPair error: ' + IntToStr(Status));
end;

procedure TRSAKeyInfo.CreatePublicKey(AAlgorithm: Pointer; const AKey: TBytes);
var
  Status: Integer;
  KeyBlob, RSAKeyBlobBuffer: TBytes;
  CbKeyBlobSize, CbRSAKeyBlobBufferSize: DWORD;
  PKKeyBlobStruct: PUBLICKEYBLOB;
  SuperBlobStruct: PRIVATEKEYBLOB;
begin
  // Load private key from PEM data
  LoadKeyFromPEM(AAlgorithm, AKey, KeyBlob, CbKeyBlobSize);

  PKKeyBlobStruct := GetCAPIPublicKeyBlobStruct(KeyBlob, CbKeyBlobSize);

  // I can use the PRIVATEKEYBLOB structure because it extends PUBLICKEYBLOB (due to the full private key type).
  CopyMemory(@SuperBlobStruct.PublicKeyStruc, @PKKeyBlobStruct.PublicKeyStruc, SizeOf(BLOBHEADER));
  CopyMemory(@SuperBlobStruct.RSAPubKey, @PKKeyBlobStruct.RSAPubKey, SizeOf(RSAPUBKEY));
  SetLength(SuperBlobStruct.Modulus, Length(PKKeyBlobStruct.Modulus));
  Move(PKKeyBlobStruct.Modulus[0], SuperBlobStruct.Modulus[0], Length(PKKeyBlobStruct.Modulus));

  // Get the public key blob
  RSAKeyBlobBuffer := GetCNGKeyBlob(SuperBlobStruct, CbRSAKeyBlobBufferSize, rsaPublicKey);

  // Import the key in order to use it to verify.
  Status := BCryptImportKeyPair(AAlgorithm,
                                nil,
                                BCRYPT_RSAPUBLIC_BLOB,
                                FHKey,
                                RSAKeyBlobBuffer,
                                CbRSAKeyBlobBufferSize,
                                0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptImportKeyPair error: ' + IntToStr(Status));
end;

end.
