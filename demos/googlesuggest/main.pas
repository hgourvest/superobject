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

procedure TSuggestForm.GSearchChange(Sender: TObject);
var
  req: IXMLHttpRequest;
  o: ISuperObject;
begin
  req := CoXMLHTTP.Create;
  req.open('GET', 'http://www.google.com/s?output=search&client=psy-ab&q='+ UTF8Encode(GSearch.Text), false, EmptyParam, EmptyParam);
  req.send(EmptyParam);
  SuggestList.Clear;
  for o in SO(req.responseText).AsArray[1] do
    SuggestList.Items.Add(o.AsArray.S[0])
end;

end.
