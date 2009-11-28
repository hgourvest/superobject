program test_format;
{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils, superobject;

const
  data =
'/* more difficult test case */ { "glossary": { "title": "example glossary", "GlossDiv":'+
' { "title": "S", "GlossList": [ { "ID": "SGML", "SortAs": "SGML", "GlossTerm": "Standar'+
'd Generalized Markup Language", "Acronym": "SGML", "Abbrev": "ISO 8879:1986", "GlossDef'+
'": "A meta-markup language, used to create markup languages such as DocBook.", "GlossSe'+
'eAlso": ["GML", "XML", "markup"] } ] } } }';

var
  new_obj: ISuperObject;
begin
  new_obj := TSuperObject.ParseString(data);
  writeln('new_obj.AsJson=', new_obj.AsJson(true, false));
  new_obj := nil;
  writeln(#10'press enter ...');
  readln;
end.

