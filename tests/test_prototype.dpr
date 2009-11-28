program test_prototype;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils,
  superobject;

var
  proto, obj: ISuperObject;

procedure class1_display(const This, Params: ISuperObject; var Result: ISuperObject);
begin
  if Params <> nil then
    writeln(Params.asString);
end;

procedure class_new(const This, Params: ISuperObject; var Result: ISuperObject);
begin
  Result := SO;
  Result['class'] := this;
  Result.Merge(Params, true);
end;

procedure class1_new(const This, Params: ISuperObject; var Result: ISuperObject);
begin
  class_new(This, Params, Result); // inherited
  Result.M['display'] := @class1_display;
end;

begin
  try
    proto := SO('{}');
    proto.M['class.new'] := @class_new;
    proto.M['class1.new'] := @class1_new;

    obj := proto['class1.new({name: "foo", bool: true})'];
    try
      obj['display([name, bool])'];
      readln;
    finally
      obj := nil;
      proto.Clear(true); // for circular references
      proto := nil;
    end;
  except
    on E: Exception do
      writeln(E.Message)
  end;
end.
