program test_usage;
{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
  SysUtils,
  superobject;

var
  my_string, my_int, my_object, my_array: ISuperObject;
  new_obj: ISuperObject;
  j: integer;
  ite: TSuperObjectIter;

begin
  try
    my_string := TSuperObject.Create(#9);
    writeln('my_string=', my_string.AsString);
    writeln('my_string.AsJSon=', my_string.AsJSon);

    my_string := TSuperObject.Create('foo');
    writeln('my_string=', my_string.AsString);
    writeln('my_string.AsJson=', my_string.AsJson);

    my_int := TSuperObject.Create(9);
    writeln('my_int=', my_int.AsInteger);
    writeln('my_int.AsJson=', my_int.AsJson);

    my_array := TSuperObject.Create(stArray);
    my_array.I[''] := 1; // append
    my_array.I[''] := 2; // append
    my_array.I[''] := 3; // append
    my_array.I['4'] := 5;
    writeln('my_array=');
    with my_array.AsArray do
    for j := 0 to Length - 1 do
      if O[j] = nil then
        writeln(#9'[', j,']=', 'null') else
        writeln(#9'[', j,']=', O[j].AsJson);
    writeln('my_array.AsJson=', my_array.AsJson);

    my_object := TSuperObject.Create(stObject);
    my_object.I['abc'] := 12;
   // my_object.S['path.to.foo[5]'] := 'bar';
    my_object.B['bool0'] := false;
    my_object.B['bool1'] := true;
    my_object.S['baz'] := 'bang';
    my_object.S['baz'] := 'fark';
    my_object.AsObject.Delete('baz');
    my_object['arr'] := my_array;
    writeln('my_object=');
    if ObjectFindFirst(my_object, ite) then
    repeat
      writeln(#9,ite.key,': ', ite.val.AsJson);
    until not ObjectFindNext(ite);
    ObjectFindClose(ite);
    writeln('my_object.AsJson=', my_object.AsJson);

    new_obj := SO('"003"');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('/* hello */"foo"');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('// hello'#10'"foo"');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('"\u0041\u0042\u0043"');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('null');
    if new_obj = nil then
      writeln('new_obj.AsJson=', 'null');

    new_obj := SO('true');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('12');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('12.3');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('["\n"]');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('["\nabc\n"]');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('[null]');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('[]');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('["abc",null,"def",12]');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('{}');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('{ "foo": "bar" }');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('{ "foo": "bar", "baz": null, "bool0": true }');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('{ "foo": [null, "foo"] }');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    new_obj := SO('{ "abc": 12, "foo": "bar", "bool0": false, "bool1": true, "arr": [ 1, 2, 3, null, 5 ] }');
    writeln('new_obj.AsJson=', new_obj.AsJson);

    try
      new_obj := SO('{ foo }');
    except
      writeln('got error as expected');
    end;

    my_string := nil;
    my_int := nil;
    my_object := nil;
    my_array := nil;
    new_obj := nil;


    writeln(#10'press enter ...');
    readln;
  except
    on E: Exception do
      writeln(E.Message)
  end;
end.
