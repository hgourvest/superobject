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

type
  TResult = record
    title: string;
    url: string;
    titleNoFormatting: string;
    cacheUrl: string;
    GsearchResultClass: string;
    visibleUrl: string;
    content: string;
    unescapedUrl: string;
  end;

  TResultList = array of TResult;

procedure TSearchForm.goClick(Sender: TObject);
var
  req: IXMLHttpRequest;
  ctx: TSuperRttiContext;
  response: ISuperObject;
  result: TResultList;
  i: Integer;
begin
  ResultList.Clear;
  ctx := TSuperRttiContext.Create;
  try
    req := CoXMLHTTP.Create;
    req.open('GET', 'http://www.google.com/uds/GwebSearch?rsz=large&v=1.0&q='+ UTF8Encode(GSearch.Text), false, EmptyParam, EmptyParam);
    req.send(EmptyParam);
    response := SO(req.responseText);
    if response.I['responseStatus'] = 200 then
    begin
      result := ctx.AsType<TResultList>(response['responseData.results']);
      for i := 0 to Length(result) - 1 do
        ResultList.Items.Add(result[i].visibleUrl + ' - ' + result[i].unescapedUrl);
    end;
  finally
    ctx.Free;
  end;
end;

end.
