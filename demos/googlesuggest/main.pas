unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TSuggestForm = class(TForm)
    GSearch: TEdit;
    SuggestList: TListBox;
    procedure GSearchChange(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  SuggestForm: TSuggestForm;

implementation
uses msxml, superobject;

{$R *.dfm}

procedure window_google_ac_h(const This, Params: ISuperObject; var Result: ISuperObject);
var
  obj: ISuperObject;
begin
  with SuggestForm.SuggestList.Items do
  begin
    BeginUpdate;
    try
      Clear;
      for obj in Params['1'] do
        Add(obj.format('%0% (%1%)'));
    finally
      EndUpdate;
    end;
  end;
end;

procedure TSuggestForm.GSearchChange(Sender: TObject);
var
  req: IXMLHttpRequest;
  o: ISuperObject;
begin
  req := {$IFDEF VER210}CoXMLHTTP{$ELSE}CoXMLHTTPRequest{$ENDIF}.Create;
  req.open('GET', 'http://clients1.google.com/complete/search?hl=en&q='+ UTF8Encode(GSearch.Text), false, EmptyParam, EmptyParam);
  req.send(EmptyParam);
  o := so;
  o.M['window.google.ac.h'] := window_google_ac_h;
  o[req.responseText];
end;

end.
