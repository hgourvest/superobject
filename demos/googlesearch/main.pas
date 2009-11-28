unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TSearchForm = class(TForm)
    GSearch: TEdit;
    go: TButton;
    ResultList: TListBox;
    procedure goClick(Sender: TObject);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
  end;

var
  SearchForm: TSearchForm;

implementation
uses msxml, superobject;

{$R *.dfm}

// http://code.google.com/intl/fr-FR/apis/ajaxsearch/documentation/reference.html#_class_GSearch

procedure response(const This, Params: ISuperObject; var Result: ISuperObject);
var
  obj: ISuperObject;
begin
  with SearchForm.ResultList.Items do
  begin
    BeginUpdate;
    try
      Clear;
      case Params.I['responseStatus'] of
        200:
          for obj in Params['responseData.results'] do
            Add(obj.Format('%visibleUrl% - (%unescapedUrl%)'));
        else
          Add(Params.S['responseDetails']);
      end;
    finally
      EndUpdate;
    end;
  end;
end;

procedure TSearchForm.goClick(Sender: TObject);
var
  req: IXMLHttpRequest;
  o: ISuperObject;
begin
  req := {$IFDEF VER210}CoXMLHTTP{$ELSE}CoXMLHTTPRequest{$ENDIF}.Create;
  req.open('GET', 'http://www.google.com/uds/GwebSearch?callback=response&rsz=large&v=1.0&q='+ UTF8Encode(GSearch.Text), false, EmptyParam, EmptyParam);
  req.send(EmptyParam);
  o := so;
  o.M['response'] := response;
  o[req.responseText];
end;

end.
