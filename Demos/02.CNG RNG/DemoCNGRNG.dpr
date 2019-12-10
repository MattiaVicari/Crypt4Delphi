program DemoCNGRNG;

uses
  Vcl.Forms,
  MainFrm in 'MainFrm.pas' {frmMain},
  CNGCrypt.WinAPI in '..\..\Source\CNG\CNGCrypt.WinAPI.pas',
  CNGCrypt.Rng in '..\..\Source\CNG\CNGCrypt.Rng.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
