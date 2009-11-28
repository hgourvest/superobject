program rttisearch;

uses
  Forms,
  main in 'main.pas' {SearchForm},
  superobject in '..\..\superobject.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TSearchForm, SearchForm);
  Application.Run;
end.
