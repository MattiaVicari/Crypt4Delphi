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

unit CNGCrypt.Rng;

interface

uses
  Winapi.Windows, System.Classes, System.SysUtils;

type
  TRNGAlgorithm = class(TObject)
  private
    FHAesAlg: Pointer;
  public
    property HAesAlg: Pointer read FHAesAlg;
    constructor Create;
    destructor Destroy; override;
  end;

  TCNGCryptRng = class
  public
    procedure GetRandom(var Output: TBytes);
    function GetRandomNumber: Integer; overload;
    function GetRandomNumber(MinValue, MaxValue: UINT): Integer; overload;
    function GetRandomString(Len: Integer): string; overload;
    function GetRandomString(Len: Integer; FromChar, ToChar: Byte): string; overload;
  end;

implementation

uses
  CNGCrypt.WinAPI;

function ExtractFromRange(RangeLowerValue, RangeUpperValue, Value, MaxValue: Integer): Integer;
var
  Range: Integer;
begin
  Range := RangeUpperValue - RangeLowerValue;
  Result := RangeLowerValue + Round(((1.0 * Value) / (1.0 * MaxValue)) * Range);
end;

procedure ForcePositiveIntegerFromBytes(var NumberAsBytes: TBytes);
begin
  if Length(NumberAsBytes) = 4 then
  begin
    if NumberAsBytes[0] > $7F then
      NumberAsBytes[0] := NumberAsBytes[0] - $7F;
  end;
end;

function BytesToInt(var Buffer: TBytes; ForcePositive: Boolean = True): Integer;
var
  I, NumBytes: Integer;
begin
  Result := 0;
  NumBytes := Length(Buffer);
  if ForcePositive then
    ForcePositiveIntegerFromBytes(Buffer);
  for I := 0 to NumBytes - 1 do
  begin
    Inc(Result, (Buffer[I] shl (8 * (NumBytes - I - 1))));
  end;
end;

{ TCNGCryptRng }

procedure TCNGCryptRng.GetRandom(var Output: TBytes);
var
  Algorithm: TRNGAlgorithm;
  Status: Integer;
begin
  Algorithm := TRNGAlgorithm.Create;
  try
    Status := BCryptGenRandom(Algorithm.HAesAlg, Output, Length(Output), 0);
    if not Succeeded(Status) then
      raise Exception.Create('BCryptGenRandom error: ' + IntToStr(Status));
  finally
    Algorithm.Free;
  end;
end;

function TCNGCryptRng.GetRandomNumber: Integer;
var
  Output: TBytes;
begin
  SetLength(Output, 4); // 32 bit
  GetRandom(Output);
  // I want only positive number: if the lower bit is 1, then the number is negative.
  Result := BytesToInt(Output, True);
end;

function TCNGCryptRng.GetRandomNumber(MinValue, MaxValue: UINT): Integer;
var
  Temp, MidValue, NumBytes: Integer;
  MaxValueByNumBytes: DWORD;
  Output: TBytes;
begin
  MidValue := MaxValue - MinValue;

  NumBytes := -1;
  MaxValueByNumBytes := 0;
  Temp := MidValue;
  repeat
  begin
    Inc(NumBytes);
    Temp := Temp shr 4;
    if Temp > 0 then
      MaxValueByNumBytes := MaxValueByNumBytes + ($FF shl (8 * NumBytes));
  end;
  until Temp = 0;

  if NumBytes = 0 then
  begin
    NumBytes := 1;
    MaxValueByNumBytes := $FF;
  end;

  SetLength(Output, NumBytes);
  GetRandom(Output);

  Temp := BytesToInt(Output, True);
  Result := ExtractFromRange(MinValue, MaxValue, Temp, MaxValueByNumBytes);
end;

function TCNGCryptRng.GetRandomString(Len: Integer; FromChar,
  ToChar: Byte): string;
const
  MaxValueOneByte = $FF;
var
  Output: TBytes;
  I: Integer;
begin
  SetLength(Output, Len);
  GetRandom(Output);
  for I := 0 to Len - 1 do
  begin
    if (Output[I] < FromChar) or (Output[I] > ToChar) then
      Output[I] := ExtractFromRange(FromChar, ToChar, Output[I], MaxValueOneByte);
  end;

  Result := TEncoding.ANSI.GetString(Output);
end;

function TCNGCryptRng.GetRandomString(Len: Integer): string;
const
  RangeLowerValue = $21;
  RangeUpperValue = $7E;
begin
  Result := GetRandomString(Len, RangeLowerValue, RangeUpperValue);
end;

{ TRNGAlgorithm }

constructor TRNGAlgorithm.Create;
var
  Status: Integer;
begin
  Status := BCryptOpenAlgorithmProvider(FHAesAlg, PChar(BCRYPT_RNG_ALGORITHM), '', 0);
  if not Succeeded(Status) then
    raise Exception.Create('BCryptOpenAlgorithmProvider error: ' + IntToStr(Status));
end;

destructor TRNGAlgorithm.Destroy;
begin
  if Assigned(FHAesAlg) then
  begin
    BCryptCloseAlgorithmProvider(FHAesAlg, 0);
    FHAesAlg := nil;
  end;
  inherited;
end;

end.
