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

unit CNGCrypt.WinAPI;

interface

uses
  WinApi.Windows;

const
  // https://docs.microsoft.com/it-it/windows/win32/seccng/cng-algorithm-identifiers
  BCRYPT_AES_ALGORITHM = 'AES';
  BCRYPT_RNG_ALGORITHM = 'RNG';
  BCRYPT_RSA_ALGORITHM = 'RSA';
  BCRYPT_SHA256_ALGORITHM = 'SHA256';

  BCRYPT_PAD_NONE  = $00000001;
  BCRYPT_PAD_PKCS1 = $00000002;  // BCryptEncrypt/Decrypt BCryptSignHash/VerifySignature
  BCRYPT_PAD_OAEP  = $00000004;  // BCryptEncrypt/Decrypt
  BCRYPT_PAD_PSS   = $00000008;  // BCryptSignHash/VerifySignature

  // https://docs.microsoft.com/en-us/windows/win32/seccng/cng-property-identifiers
  BCRYPT_OBJECT_LENGTH = 'ObjectLength';
  BCRYPT_BLOCK_LENGTH = 'BlockLength';

  BCRYPT_CHAINING_MODE = 'ChainingMode';
  BCRYPT_CHAIN_MODE_CBC = 'ChainingModeCBC';
  BCRYPT_CHAIN_MODE_CCM = 'ChainingModeCCM';
  BCRYPT_CHAIN_MODE_CFB = 'ChainingModeCFB';
  BCRYPT_CHAIN_MODE_ECB = 'ChainingModeECB';
  BCRYPT_CHAIN_MODE_GCM = 'ChainingModeGCM';
  BCRYPT_CHAIN_MODE_NA = 'ChainingModeN/A';

  // See https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptexportkey
  BCRYPT_OPAQUE_KEY_BLOB = 'OpaqueKeyBlob';

  // See https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptencrypt
  BCRYPT_BLOCK_PADDING = 1;

  // The BCRYPT_RSAPUBLIC_BLOB and BCRYPT_RSAPRIVATE_BLOB blob types are used
  // to transport plaintext RSA keys. These blob types will be supported by
  // all RSA primitive providers.
  // The BCRYPT_RSAPRIVATE_BLOB includes the following values:
  // Public Exponent
  // Modulus
  // Prime1
  // Prime2
  BCRYPT_RSAPUBLIC_BLOB  = 'RSAPUBLICBLOB';
  BCRYPT_RSAPRIVATE_BLOB = 'RSAPRIVATEBLOB';
  BCRYPT_RSAFULLPRIVATE_BLOB = 'RSAFULLPRIVATEBLOB';
  LEGACY_RSAPUBLIC_BLOB  = 'CAPIPUBLICBLOB';
  LEGACY_RSAPRIVATE_BLOB = 'CAPIPRIVATEBLOB';

  BCRYPT_RSAPUBLIC_MAGIC  = $31415352;      // RSA1
  BCRYPT_RSAPRIVATE_MAGIC = $32415352;      // RSA2
  BCRYPT_RSAFULLPRIVATE_MAGIC = $33415352;  // RSA3

  // Microsoft built-in providers.
  MS_PRIMITIVE_PROVIDER       = 'Microsoft Primitive Provider';
  MS_PLATFORM_CRYPTO_PROVIDER = '"Microsoft Platform Crypto Provider';

type
  BCRYPT_PKCS1_PADDING_INFO = record
    pszAlgId: PWideChar;
  end;

  // https://docs.microsoft.com/it-it/windows/win32/api/bcrypt/ns-bcrypt-bcrypt_rsakey_blob
  BCRYPT_RSAKEY_BLOB = record
    Magic: ULONG;
    BitLength: ULONG;
    cbPublicExp: ULONG;
    cbModulus: ULONG;
    cbPrime1: ULONG;
    cbPrime2: ULONG;
  end;


function BCryptOpenAlgorithmProvider(
  var phAlgorithm: Pointer;
  pszAlgId: PWideChar;
  pszImplementation: PWideChar;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptCloseAlgorithmProvider(
  hAlgorithm: Pointer;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptGetProperty(
  hObject: Pointer;
  pszProperty: PWideChar;
  var pbOutput: DWORD;
  cbOutput: ULONG;
  var pcbResult: ULONG;
  dwFlagd: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptSetProperty(
  hObject: Pointer;
  pszProperty: PWideChar;
  pbInput: PWideChar;
  cbInput: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptGenerateSymmetricKey(
  hAlgorithm: Pointer;
  var phKey: Pointer;
  pbKeyObject: Pointer;
  cbKeyObject: ULONG;
  pbSecret: Pointer;
  cbSecret: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptDestroyKey(
  hKey: Pointer
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptEncrypt(
  hKey: Pointer;
  pbInput: Pointer;
  cbInput: ULONG;
  pPaddingInfo: Pointer;
  pbIV: Pointer;
  cbIV: ULONG;
  pbOutput: Pointer;
  cbOutput: ULONG;
  var pcbResult: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptDecrypt(
  hKey: Pointer;
  pbInput: Pointer;
  cbInput: ULONG;
  pPaddingInfo: Pointer;
  pbIV: Pointer;
  cbIV: ULONG;
  pbOutput: Pointer;
  cbOutput: ULONG;
  var pcbResult: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptGenRandom(
  phAlgorithm: Pointer;
  pbBuffer: Pointer;
  cbBuffer: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptSignHash(
  hKey: Pointer;
  pPaddingInfo: Pointer;
  pbInput: Pointer;
  cbInput: ULONG;
  pbOutput: Pointer;
  cbOutput: ULONG;
  var pcbResult: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptGenerateKeyPair(
  hAlgorithm: Pointer;
  var phKey: Pointer;
  dwLength: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptFinalizeKeyPair(
  hKey: Pointer;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

function BCryptImportKeyPair(
  hAlgorithm: Pointer;
  hImportKey: Pointer;
  pszBlobType: PWideChar;
  phKey: Pointer;
  pbInput: Pointer;
  cbInput: ULONG;
  dwFlags: ULONG
): Integer; stdcall; external 'Bcrypt.dll';

implementation

end.
