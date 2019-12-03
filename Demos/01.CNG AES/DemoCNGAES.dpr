program DemoCNGAES;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  CNGCrypt.Core in '..\..\Source\CNG\CNGCrypt.Core.pas',
  CNGCrypt.WinAPI in '..\..\Source\CNG\CNGCrypt.WinAPI.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
