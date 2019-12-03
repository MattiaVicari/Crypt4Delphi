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
  Contributors:
    Luca Minuti

-------------------------------------------------------------------------------}

unit CNGCrypt.Core;

// https://docs.microsoft.com/it-it/windows/win32/seccng/encrypting-data-with-cng

interface

uses
  Winapi.Windows, System.Classes, Winapi.Messages,
  System.SysUtils, System.Variants, System.Hash;

type
  TAESAlgorithm = class(TObject)
  private
    FHAesAlg: Pointer;
    FBlockLen: DWORD;
    FKeyObjectLen: DWORD;
  public
    property HAesAlg: Pointer read FHAesAlg;
    property BlockLen: DWORD read FBlockLen;
    property KeyObjectLen: DWORD read FKeyObjectLen;
    constructor Create;
    destructor Destroy; override;
  end;

  TKeyInfo = class(TObject)
  private
    FIV, FKey: TBytes;

    FHAesKey: Pointer;
    FKeyObject, FIVObject: Pointer;
    FAlgorithm: TAESAlgorithm;
    procedure CreateSymmetricKey;
    procedure CreateIV(const IVData: TBytes; CbBlockLen: DWORD);
  public
    property HAesKey: Pointer read FHAesKey;
    property IVObject: Pointer read FIVObject;

    constructor Create(AAlgorithm: TAESAlgorithm; const AKey, AIV: TBytes);
    destructor Destroy; override;
  end;

  TCNGCrypt = class
  private
    FIV, FKey: TBytes;
    FUseIVBlock: Boolean;
    FPassword: string;
    procedure GenerateKeys(Algorithm: TAESAlgorithm; const Password: string);
  public
    ///  <summary>
    ///  Pass True to insert the IV at the first block during the encryption.
    ///  For the decryption operation, will be read the IV from the first block.
    ///  If you set this property to False, you have to provide the IV for both the encryption
    ///  and decryption procedures.
    ///  </summary>
    property UseIVBlock: Boolean read FUseIVBlock write FUseIVBlock;

    property Key: TBytes read FKey write FKey;
    ///  <summary>
    ///  The initialization vector to use. If you don't provide this data, one
    ///  will be created randomly.
    ///  </summary>
    property IV: TBytes read FIV write FIV;

    property Password: string read FPassword write FPassword;

    procedure Encrypt(Input, Output: TStream); overload;
    procedure Encrypt(Input: TBytes; var Output: TBytes); overload;
    procedure Decrypt(Input, Output: TStream); overload;
    procedure Decrypt(Input: TBytes; var Output: TBytes); overload;

    procedure EncryptFile(const InputFileName, OutputFileName: string);
    procedure DecryptFile(const InputFileName, OutputFileName: string);

    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses
  Math,
  CNGCrypt.WinAPI;

procedure ArrayMove(const Source: array of Byte; var Dest: array of Byte);
begin
  Move(Source, Dest, Length(Source));
end;

{ TCrypt }

constructor TCNGCrypt.Create;
begin
  FUseIVBlock := True;
end;

procedure TCNGCrypt.Decrypt(Input, Output: TStream);
var
  InputBuffer: TBytes;
  OutputBuffer: TBytes;
begin
  SetLength(InputBuffer, Input.Size);
  Input.Position := 0;
  Input.Read(InputBuffer[0], Input.Size);
  Decrypt(InputBuffer, OutputBuffer);
  Output.WriteBuffer(OutputBuffer[0], Length(OutputBuffer));
end;

procedure TCNGCrypt.Decrypt(Input: TBytes; var Output: TBytes);
var
  Key: TKeyInfo;
  Algorithm: TAESAlgorithm;
  CipherData: TBytes;
  Status: Integer;
  CbCipherData, CbPlainText: DWORD;
begin
  Algorithm := TAESAlgorithm.Create;
  try
    if FPassword <> '' then
      GenerateKeys(Algorithm, Password);
    if FUseIVBlock then
    begin
      FIV := Copy(Input, 0, Algorithm.BlockLen);
      CipherData := Copy(Input, Algorithm.BlockLen, Length(Input));
    end
    else
    begin
      CipherData := Input;
    end;

    CbCipherData := Length(CipherData);
    Key := TKeyInfo.Create(Algorithm, FKey, FIV);
    try
      FKey := Key.FKey;
      FIV := Key.FIV;
      Status := BCryptDecrypt(Key.HAesKey,
                              CipherData,
                              CbCipherData,
                              nil,
                              Key.IVObject,
                              Algorithm.BlockLen,
                              nil,
                              0,
                              CbPlainText,
                              BCRYPT_BLOCK_PADDING);
      if not Succeeded(Status) then
        raise Exception.Create('BCryptDecrypt error: ' + IntToStr(Status));

      SetLength(Output, CbPlainText);

      Status := BCryptDecrypt(Key.HAesKey,
                              CipherData,
                              CbCipherData,
                              nil,
                              Key.IVObject,
                              Algorithm.BlockLen,
                              Output,
                              CbPlainText,
                              CbPlainText,
                              BCRYPT_BLOCK_PADDING);
      if not Succeeded(Status) then
        raise Exception.Create('BCryptDecrypt error: ' + IntToStr(Status));

    finally
      Key.Free;
    end;
  finally
    Algorithm.Free;
  end;
end;

procedure TCNGCrypt.DecryptFile(const InputFileName, OutputFileName: string);
var
  InputFile: TFileStream;
  OutputFile: TFileStream;
begin
  InputFile := TFileStream.Create(InputFileName, fmOpenRead);
  try
    OutputFile := TFileStream.Create(OutputFileName, fmCreate);
    try
      Decrypt(InputFile, OutputFile);
    finally
      OutputFile.Free;
    end;
  finally
    InputFile.Free;
  end;
end;

destructor TCNGCrypt.Destroy;
begin
  inherited;
end;

procedure TCNGCrypt.Encrypt(Input, Output: TStream);
var
  InputBuffer: TBytes;
  OutputBuffer: TBytes;
begin
  SetLength(InputBuffer, Input.Size);
  Input.Position := 0;
  Input.Read(InputBuffer[0], Input.Size);
  Encrypt(InputBuffer, OutputBuffer);
  Output.WriteBuffer(OutputBuffer[0], Length(OutputBuffer));
end;

procedure TCNGCrypt.Encrypt(Input: TBytes; var Output: TBytes);
var
  Status: Integer;
  CbPlainText: DWORD;
  CbData, CbCipherText: DWORD;
  Key: TKeyInfo;
  Algorithm: TAESAlgorithm;
begin
  Algorithm := TAESAlgorithm.Create;
  try
    if FPassword <> '' then
      GenerateKeys(Algorithm, Password);

    Key := TKeyInfo.Create(Algorithm, FKey, FIV);
    try
      FKey := Key.FKey;
      FIV := Key.FIV;
      CbPlainText := Length(Input);

      // Get the output buffer size.
      Status := BCryptEncrypt(Key.HAesKey,
                              Input,
                              CbPlainText,
                              nil,
                              Key.IVObject,
                              Algorithm.BlockLen,
                              nil,
                              0,
                              CbCipherText,
                              BCRYPT_BLOCK_PADDING);
      if not Succeeded(Status) then
        raise Exception.Create('BCryptEncrypt error: ' + IntToStr(Status));

      SetLength(Output, CbCipherText);

      // Use the key to encrypt the plaintext buffer.
      // For block sized messages, block padding will add an extra block.
      Status := BCryptEncrypt(Key.HAesKey,
                              Input,
                              CbPlainText,
                              nil,
                              Key.IVObject,
                              Algorithm.BlockLen,
                              Output,
                              CbCipherText,
                              CbData,
                              BCRYPT_BLOCK_PADDING);
      if not Succeeded(Status) then
        raise Exception.Create('BCryptEncrypt error: ' + IntToStr(Status));

      if UseIVBlock then
        Output := FIV + Output;

    finally
      Key.Free;
    end;
  finally
    Algorithm.Free;
  end;
end;

procedure TCNGCrypt.EncryptFile(const InputFileName, OutputFileName: string);
var
  InputFile: TFileStream;
  OutputFile: TFileStream;
begin
  InputFile := TFileStream.Create(InputFileName, fmOpenRead);
  try
    OutputFile := TFileStream.Create(OutputFileName, fmCreate);
    try
      Encrypt(InputFile, OutputFile);
    finally
      OutputFile.Free;
    end;
  finally
    InputFile.Free;
  end;
end;

procedure TCNGCrypt.GenerateKeys(Algorithm: TAESAlgorithm; const Password: string);
var
  I: Integer;
begin
  FKey := THashSHA2.GetHashBytes(Password);

  SetLength(FIV, Algorithm.BlockLen);
  for I := Low(FIV) to High(FIV) do
    FIV[I] := RandomRange(0, 255);
end;

{ TKeyInfo }

constructor TKeyInfo.Create(AAlgorithm: TAESAlgorithm; const AKey, AIV: TBytes);
begin
  FKey := AKey;
  FIV := AIV;
  FAlgorithm := AAlgorithm;
  CreateSymmetricKey;
  CreateIV(FIV, FAlgorithm.FBlockLen);
end;

procedure TKeyInfo.CreateIV(const IVData: TBytes; CbBlockLen: DWORD);
var
  IVLen: DWORD;
begin
  // Determine whether the cbBlockLen is not longer than the IV length.
  IVLen := Length(IVData);
  if IVLen < CbBlockLen then
    raise Exception.Create('Block length is longer than the provided IV length');

  // Allocate a buffer for the IV. The buffer is consumed during the
  // encrypt/decrypt process.
  FIVObject := HeapAlloc(GetProcessHeap, 0, CbBlockLen);
  if not Assigned(FIVObject) then
    raise Exception.Create('Memory allocation failed');
  ArrayMove(IVData, TBytes(FIVObject));
end;

procedure TKeyInfo.CreateSymmetricKey;
var
  Status: Integer;
begin
  // Allocate the key object on the heap.
  FKeyObject := HeapAlloc(GetProcessHeap, 0, FAlgorithm.KeyObjectLen);

  if not Assigned(FKeyObject) then
    raise Exception.Create('Memory allocation failed');

  // Generate the key from supplied input key bytes.
  Status := BCryptGenerateSymmetricKey(FAlgorithm.HAesAlg,
                                      FHAesKey,
                                      FKeyObject,
                                      FAlgorithm.KeyObjectLen,
                                      Pointer(FKey),
                                      Length(FKey),
                                      0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptGenerateSymmetricKey error: ' + IntToStr(Status));

end;

destructor TKeyInfo.Destroy;
begin
  if Assigned(FHAesKey) then
  begin
    BCryptDestroyKey(FHAesKey);
    FHAesKey := nil;
  end;
  if Assigned(FIVObject) then
  begin
    HeapFree(GetProcessHeap, 0, FIVObject);
    FIVObject := nil;
  end;
  if Assigned(FKeyObject) then
  begin
    HeapFree(GetProcessHeap, 0, FKeyObject);
    FKeyObject := nil;
  end;
  inherited;
end;

{ TAESAlgorithm }

constructor TAESAlgorithm.Create;
var
  Status: Integer;
  CbData: DWORD;
begin
  Status := BCryptOpenAlgorithmProvider(FHAesAlg, PChar(BCRYPT_AES_ALGORITHM), '', 0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptOpenAlgorithmProvider error: ' + IntToStr(Status));

  // Calculate the size of the buffer to hold the KeyObject.
  Status := BCryptGetProperty(FHAesAlg,
                              BCRYPT_OBJECT_LENGTH,
                              FKeyObjectLen,
                              SizeOf(DWORD),
                              CbData,
                              0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptGetProperty error: ' + IntToStr(Status));

  // Calculate the block length for the IV.
  Status := BCryptGetProperty(FHAesAlg,
                              BCRYPT_BLOCK_LENGTH,
                              FBlockLen,
                              SizeOf(DWORD),
                              CbData,
                              0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptGetProperty error: ' + IntToStr(Status));

  Status := BCryptSetProperty(FHAesAlg,
                              BCRYPT_CHAINING_MODE,
                              BCRYPT_CHAIN_MODE_CBC,
                              Length(BCRYPT_CHAIN_MODE_CBC),
                              0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptSetProperty error: ' + IntToStr(Status));
end;

destructor TAESAlgorithm.Destroy;
begin
  if Assigned(FHAesAlg) then
  begin
    BCryptCloseAlgorithmProvider(FHAesAlg, 0);
    FHAesAlg := nil;
  end;
  inherited;
end;

end.
