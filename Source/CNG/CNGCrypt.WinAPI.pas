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

implementation

end.
