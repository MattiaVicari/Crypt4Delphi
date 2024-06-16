unit CryptCNGTest;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  CNGCrypt.Core;

type
  [TestFixture]
  TCryptCNGTest = class(TObject)
  private
    FCNGCrypt: TCNGCrypt;
    function GetArray<T>(const AArray: array of T; ACount: Integer): TArray<T>;
    function GetOutputSizeAES128(const AData: TBytes): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestEncryptDecryptWithPassword;
    [Test]
    procedure TestEncryptDecryptWithPasswordAndIV;
    [Test]
    procedure TestEncryptDecryptWithKeyStoreIV;
    [Test]
    procedure TestEncryptDecryptWithKeyNoStoreIV;
    [Test]
    procedure TestEncryptDecryptLongText;
    [Test]
    procedure TestEncryptDecryptCheckBlockSize;
  end;

implementation

function TCryptCNGTest.GetArray<T>(const AArray: array of T; ACount: Integer): TArray<T>;
begin
  SetLength(Result, ACount);
  Move(AArray, Result[0], ACount);
end;

function TCryptCNGTest.GetOutputSizeAES128(const AData: TBytes): Integer;
const
  BlockSize = 16; // AES 128bit
var
  Len, NumBlocks: Integer;
begin
  Len := Length(AData);
  NumBlocks := Len div BlockSize;
  if Len mod BlockSize > 0 then
    Inc(NumBlocks);
  Result := NumBlocks * BlockSize;
end;

procedure TCryptCNGTest.Setup;
begin
  FCNGCrypt := TCNGCrypt.Create;
end;

procedure TCryptCNGTest.TearDown;
begin
  FreeAndNil(FCNGCrypt);
end;

procedure TCryptCNGTest.TestEncryptDecryptCheckBlockSize;
const
  Password = 'aksdm2349idASDç23498sakj1ASDsòdès';
  PlainText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus tristique neque eu commodo ornare. ' +
    'Sed eget mi vel lectus consequat condimentum. Quisque quis scelerisque libero. Aenean justo lacus, ' +
    'elementum eu finibus hendrerit, aliquam nec enim. Curabitur a ante et est congue suscipit. ' +
    'Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; ' +
    'Cras lacinia enim a felis euismod, in volutpat elit facilisis. Suspendisse mollis libero et odio lobortis, id gravida odio dictum. ' +
    'Nulla rutrum leo ac felis maximus cursus. Morbi nec arcu quis justo semper vulputate ut ut nibh. Aliquam placerat tristique orci. ' +
    'Nullam arcu erat, pretium in mattis ac, lacinia non eros. Morbi eu neque elit. Integer sit amet tristique nisi, lacinia euismod ante.';
var
  CipherData, PlainData: TBytes;
  Len: Integer;
begin
  FCNGCrypt.Password := Password;

  FCNGCrypt.Encrypt(TEncoding.UTF8.GetBytes(PlainText), CipherData);
  FCNGCrypt.Decrypt(CipherData, PlainData);

  Len := Length(PlainData);
  Assert.AreEqual(Len, GetOutputSizeAES128(TEncoding.UTF8.GetBytes(PlainText)));
end;

procedure TCryptCNGTest.TestEncryptDecryptLongText;
const
  Password = 'aksdm2349idASDç23498sakj1ASDsòdès';
  PlainText =
    'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus tristique neque eu commodo ornare. ' +
    'Sed eget mi vel lectus consequat condimentum. Quisque quis scelerisque libero. Aenean justo lacus, ' +
    'elementum eu finibus hendrerit, aliquam nec enim. Curabitur a ante et est congue suscipit. ' +
    'Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia Curae; ' +
    'Cras lacinia enim a felis euismod, in volutpat elit facilisis. Suspendisse mollis libero et odio lobortis, id gravida odio dictum. ' +
    'Nulla rutrum leo ac felis maximus cursus. Morbi nec arcu quis justo semper vulputate ut ut nibh. Aliquam placerat tristique orci. ' +
    'Nullam arcu erat, pretium in mattis ac, lacinia non eros. Morbi eu neque elit. Integer sit amet tristique nisi, lacinia euismod ante.';
var
  CipherData, PlainData, PlainTestData: TBytes;
begin
  FCNGCrypt.Password := Password;

  FCNGCrypt.Encrypt(TEncoding.UTF8.GetBytes(PlainText), CipherData);
  FCNGCrypt.Decrypt(CipherData, PlainData);

  // There are some zeros on the right.
  // It depends on the algorithm block size
  SetLength(PlainTestData, Length(PlainData));
  TEncoding.UTF8.GetBytes(PlainText, Low(PlainText), Length(PlainText), PlainTestData, 0);

  Assert.AreEqual(PlainData, PlainTestData);
end;

procedure TCryptCNGTest.TestEncryptDecryptWithKeyNoStoreIV;
const
  Key: array[0..15] of Byte = (
    $00, $01, $02, $03, $04, $05, $06, $07,
    $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
  );
  IV: array[0..15] of Byte = (
    $10, $11, $12, $13, $14, $15, $16, $17,
    $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
  );
  PlainText = 'This is a message';
var
  CipherData, PlainData, PlainTestData: TBytes;
begin
  FCNGCrypt.UseIVBlock := False;
  FCNGCrypt.Key := GetArray(Key, Length(Key));
  FCNGCrypt.IV := GetArray(IV, Length(IV));

  FCNGCrypt.Encrypt(TEncoding.UTF8.GetBytes(PlainText), CipherData);
  FCNGCrypt.Decrypt(CipherData, PlainData);

  // There are some zeros on the right.
  // It depends on the algorithm block size
  SetLength(PlainTestData, Length(PlainData));
  TEncoding.UTF8.GetBytes(PlainText, Low(PlainText), Length(PlainText), PlainTestData, 0);

  Assert.AreEqual(PlainData, PlainTestData);
end;

procedure TCryptCNGTest.TestEncryptDecryptWithKeyStoreIV;
const
  Key: array[0..15] of Byte = (
    $00, $01, $02, $03, $04, $05, $06, $07,
    $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
  );
  IV: array[0..15] of Byte = (
    $10, $11, $12, $13, $14, $15, $16, $17,
    $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
  );
  PlainText = 'This is a message';
var
  CipherData, PlainData, PlainTestData: TBytes;
  EmptyIV: TBytes;
begin
  FCNGCrypt.UseIVBlock := True;
  FCNGCrypt.Key := GetArray(Key, Length(Key));
  FCNGCrypt.IV := GetArray(IV, Length(IV));

  FCNGCrypt.Encrypt(TEncoding.UTF8.GetBytes(PlainText), CipherData);
  SetLength(EmptyIV, 0);
  FCNGCrypt.IV := EmptyIV;
  FCNGCrypt.Decrypt(CipherData, PlainData);

  // There are some zeros on the right.
  // It depends on the algorithm block size
  SetLength(PlainTestData, Length(PlainData));
  TEncoding.UTF8.GetBytes(PlainText, Low(PlainText), Length(PlainText), PlainTestData, 0);

  Assert.AreEqual(PlainData, PlainTestData);
end;

procedure TCryptCNGTest.TestEncryptDecryptWithPassword;
const
  Password = 'MyPassword';
  PlainText = 'This is a message';
var
  CipherData, PlainData, PlainTestData: TBytes;
begin
  FCNGCrypt.Password := Password;

  FCNGCrypt.Encrypt(TEncoding.UTF8.GetBytes(PlainText), CipherData);
  FCNGCrypt.Decrypt(CipherData, PlainData);

  // There are some zeros on the right.
  // It depends on the algorithm block size
  SetLength(PlainTestData, Length(PlainData));
  TEncoding.UTF8.GetBytes(PlainText, Low(PlainText), Length(PlainText), PlainTestData, 0);

  Assert.AreEqual(PlainData, PlainTestData);
end;

procedure TCryptCNGTest.TestEncryptDecryptWithPasswordAndIV;
const
  IV: array[0..15] of Byte = (
    $10, $11, $12, $13, $14, $15, $16, $17,
    $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
  );
  Password = 'MyPassword';
  PlainText = 'This is a message';
var
  CipherData, PlainData, PlainTestData: TBytes;
begin
  FCNGCrypt.UseIVBlock := False;
  FCNGCrypt.Password := Password;
  FCNGCrypt.IV := GetArray(IV, Length(IV));

  FCNGCrypt.Encrypt(TEncoding.UTF8.GetBytes(PlainText), CipherData);
  FCNGCrypt.Decrypt(CipherData, PlainData);

  // There are some zeros on the right.
  // It depends on the algorithm block size
  SetLength(PlainTestData, Length(PlainData));
  TEncoding.UTF8.GetBytes(PlainText, Low(PlainText), Length(PlainText), PlainTestData, 0);

  Assert.AreEqual(PlainData, PlainTestData);
end;

initialization
  TDUnitX.RegisterTestFixture(TCryptCNGTest);
end.
