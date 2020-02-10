program DemoCNGSign;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  CNGCrypt.Sign in '..\..\Source\CNG\CNGCrypt.Sign.pas',
  CNGCrypt.CAPI in '..\..\Source\CAPI\CNGCrypt.CAPI.pas',
  CNGCrypt.Utils in '..\..\Source\CNGCrypt.Utils.pas',
  CNGCrypt.WinAPI in '..\..\Source\CNG\CNGCrypt.WinAPI.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
