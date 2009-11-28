program test_rpc;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils, superobject;

procedure controler_method1(const This, Params: ISuperObject; var Result: ISuperObject);
begin
  write('action called with params ');
  writeln(Params.AsJSon);
end;

var
  s: ISuperObject;
begin
  s := TSuperObject.Create;
  s.M['controler.action1'] := @controler_method1;
  try
    s.call('controler.action1', '{"a": [1,2,3], "b": null}');
    s['controler.action1([123, "foo"])'];
  finally
    s := nil;
    writeln('Press enter ...');
    readln;
  end;
end.
