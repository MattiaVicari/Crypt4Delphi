unit SignCNGTest;

interface

uses
  System.SysUtils, System.IOUtils,
  DUnitX.TestFramework,
  CNGCrypt.Sign;

type
  [TestFixture]
  TSignCNGTest = class(TObject)
  private
    FCNGSign: TCNGSign;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure TestSignWithPKCS8Key;
  end;

implementation

{ TSignCNGTest }

procedure TSignCNGTest.Setup;
begin
  FCNGSign := TCNGSign.Create;
end;

procedure TSignCNGTest.TearDown;
begin
  FreeAndNil(FCNGSign);
end;

procedure TSignCNGTest.TestSignWithPKCS8Key;
var
  Key, Signature, Data, TestSignature: TBytes;
  BasePath: string;
begin
  BasePath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data');
  Key := TFile.ReadAllBytes(BasePath + PathDelim + 'key1.pem');
  Data := TFile.ReadAllBytes(BasePath + PathDelim + 'data.txt');
  TestSignature := TFile.ReadAllBytes(BasePath + PathDelim + 'data1.signature');
  FCNGSign.Sign(Data, Signature, Key);
  Assert.AreEqual(Signature, TestSignature);
end;

initialization
  TDUnitX.RegisterTestFixture(TSignCNGTest);

end.
