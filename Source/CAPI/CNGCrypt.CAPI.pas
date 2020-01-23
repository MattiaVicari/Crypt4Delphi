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

unit CNGCrypt.CAPI;

interface

uses
  WinApi.Windows;

const
  // dwFlags has the following defines
  // certenrolld_begin -- CRYPT_STRING_*
  CRYPT_STRING_BASE64HEADER           = $00000000;
  CRYPT_STRING_BASE64                 = $00000001;
  CRYPT_STRING_BINARY                 = $00000002;
  CRYPT_STRING_BASE64REQUESTHEADER    = $00000003;
  CRYPT_STRING_HEX                    = $00000004;
  CRYPT_STRING_HEXASCII               = $00000005;
  CRYPT_STRING_BASE64_ANY             = $00000006;
  CRYPT_STRING_ANY                    = $00000007;
  CRYPT_STRING_HEX_ANY                = $00000008;
  CRYPT_STRING_BASE64X509CRLHEADER    = $00000009;
  CRYPT_STRING_HEXADDR                = $0000000A;
  CRYPT_STRING_HEXASCIIADDR           = $0000000B;
  CRYPT_STRING_HEXRAW                 = $0000000C;
  CRYPT_STRING_BASE64URI              = $0000000D;

  CRYPT_STRING_PERCENTESCAPE          = $08000000;	// base64 formats only
  CRYPT_STRING_HASHDATA               = $10000000;
  CRYPT_STRING_STRICT                 = $20000000;
  CRYPT_STRING_NOCRLF                 = $40000000;
  CRYPT_STRING_NOCR                   = $80000000;

  // Message encoding types
  CRYPT_ASN_ENCODING   = $00000001;
  CRYPT_NDR_ENCODING   = $00000002;
  X509_ASN_ENCODING    = $00000001;
  X509_NDR_ENCODING    = $00000002;
  PKCS_7_ASN_ENCODING  = $00010000;
  PKCS_7_NDR_ENCODING  = $00020000;

  // Data structures for private keys
  PKCS_RSA_PRIVATE_KEY             = PChar(43);
  PKCS_PRIVATE_KEY_INFO            = PChar(44);
  PKCS_ENCRYPTED_PRIVATE_KEY_INFO  = PChar(45);

function CryptStringToBinaryW(
  pszString: PWideChar;
  cchString: DWORD;
  dwFlags: DWORD;
  pbBinary: Pointer;
  var pcbBinary: DWORD;
  var pdwSkip: DWORD;
  var pdwFlags: DWORD
): Integer; stdcall; external 'Crypt32.dll';

function CryptDecodeObjectEx(
  dwCertEncodingType: DWORD;
  lpszStructType: Pointer;
  pbEncoded: Pointer;
  cbEncoded: DWORD;
  dwFlags: DWORD;
  pDecodePara: Pointer;
  pvStructInfo: Pointer;
  var pcbStructInfo: DWORD
): Integer; stdcall; external 'Crypt32.dll';

implementation

end.
