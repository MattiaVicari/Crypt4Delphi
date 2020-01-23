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

unit CNGCrypt.Utils;

interface

uses
  System.SysUtils, Winapi.Windows;

type
  TUtils = class
  public
    class procedure ReverseMemCopy(const Source; var Dest; Count: Integer);
  end;

implementation

{ TUtils }

class procedure TUtils.ReverseMemCopy(const Source; var Dest; Count: Integer);
var
  I: Integer;
  S, D: PByte;
begin
  S := PByte(@Source);
  D := PByte(@Dest);
  for I := 0 to Count - 1 do
    D[Count - 1 - I] := S[I];
end;

end.
