program suggest;

uses
  Forms,
  main in 'main.pas' {SuggestForm},
  superobject in '..\..\superobject.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSuggestForm, SuggestForm);
  Application.Run;
end.
