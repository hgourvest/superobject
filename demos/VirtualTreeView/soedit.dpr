program soedit;

uses
  Forms,
  main in 'main.pas' {MainForm},
  superobject in '..\..\superobject.pas',
  superxmlparser in '..\..\superxmlparser.pas';

{$R *.res}

begin
  Application.Initialize;
{$IFDEF UNICODE}
  Application.MainFormOnTaskbar := True;
{$ENDIF}  
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
