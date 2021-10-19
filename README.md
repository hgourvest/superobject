## This project is not maintained!

# SuperObject

This version is compatible with Delphi and FPC complilers. Also it has Windows/Linux compatibility. Tested with FPC Version 3.0.4, 3.1.1 and last 3.3.1.

## What is JSON ?

- JSON (JavaScript Object Notation) is a lightweight data-interchange format.
- It is easy for humans to read and write.
- It is easy for machines to parse and generate.
- It is based on a subset of the JavaScript Programming Language, Standard ECMA-262 3rd Edition - December 1999.
- JSON is a text format that is completely language independent but uses conventions that are familiar to programmers.
- These properties make JSON an ideal data-interchange language.
- You can get more informations on [json.org](http://www.json.org).

```js
{
  "name": "Jon Snow", /* this is a comment */
  "dead": true,
  "telephones": ["000000000", "111111111111"],
  "age": 33,
  "size": 1.83,
  "adresses": [
    {
      "adress": "foo",
      "city": "The wall",
      "pc": 57000
    },
    {
      "adress": "foo",
      "city": "Winterfell",
      "pc": 44000
    }
  ]
}

```
## Parsing a JSON data structure

```pas
var
  obj: ISuperObject;
begin
  obj := SO('{"foo": true}');
  obj := TSuperObject.ParseString('{"foo": true}');
  obj := TSuperObject.ParseStream(stream);
  obj := TSuperObject.ParseFile(FileName);
end;
```

## Accessing data

There isn't individual datastructure for each supported data types.
They are all an object: the ISuperObject.

```pas
  val := obj.AsString;
  val := obj.AsInteger;
  val := obj.AsBoolean;
  val := obj.AsDouble;
  val := obj.AsArray;
  val := obj.AsObject;
  val := obj.AsMethod;
```

## How to read a property value of an object ?

```pas
  val := obj.AsObject.S['foo']; // get a string
  val := obj.AsObject.I['foo']; // get an Int64
  val := obj.AsObject.B['foo']; // get a Boolean
  val := obj.AsObject.D['foo']; // get a Double
  val := obj.AsObject.O['foo']; // get an Object (default)
  val := obj.AsObject.M['foo']; // get a Method
  val := obj.AsObject.N['foo']; // get a null object
```

## How to read a value from an array ?

```pas
  // the advanced way
  val := obj.AsArray.S[0]; // get a string
  val := obj.AsArray.I[0]; // get an Int64
  val := obj.AsArray.B[0]; // get a Boolean
  val := obj.AsArray.D[0]; // get a Double
  val := obj.AsArray.O[0]; // get an Object (default)
  val := obj.AsArray.M[0]; // get a Method
  val := obj.AsArray.N[0]; // get a null object
```

## Using paths

Using paths is a very productive method to find an object when you know where is it.
This is some usage cases:

```pas
  obj['foo']; // get a property
  obj['123']; // get an item array
  obj['foo.list']; // get a property from an object
  obj['foo[123]']; // get an item array from an object
  obj['foo(1,2,3)']; // call a method
  obj['foo[]'] := value; // add an item array
```

you also can encapsulate paths:

```pas
  obj := so('{"index": 1, "items": ["item 1", "item 2", "item 3"]}');
  obj['items[index]'] // return "item 2"
```

or recreate a new data structure from another:

```pas
  obj := so('{"index": 1, "items": ["item 1", "item 2", "item 3"]}');
  obj['{"item": items[index], "index": index}'] // return {"item": "item 2", "index": 1}
```

## Browsing data structure
### Using Delphi enumerator.

Using Delphi enumerator you can browse item's array or property's object value in the same maner.

```pas
var
  item: ISuperObject;
begin
  for item in obj['items'] do ...
```

you can also browse the keys and values of an object like this:

```pas
var
  item: TSuperAvlEntry;
begin
  for item in obj.AsObject do ...
  begin
    item.Name;
    item.Value;
  end;
```

### Browsing object properties without enumerator

```pas
var
  item: TSuperObjectIter;
begin
  if ObjectFindFirst(obj, item) then
  repeat
    item.key;
    item.val;
  until not ObjectFindNext(item);
  ObjectFindClose(item);
```

### Browsing array items without enumerator

```pas
var
  item: Integer;
begin
  for item := 0 to obj.AsArray.Length - 1 do
    obj.AsArray[item]
```

## RTTI & marshalling in Delphi 2010

```pas
type
  TData = record
    str: string;
    int: Integer;
    bool: Boolean;
    flt: Double;
  end;
var
  ctx: TSuperRttiContext;
  data: TData;
  obj: ISuperObject;
begin
  ctx := TSuperRttiContext.Create;
  try
    data := ctx.AsType<TData>(SO('{str: "foo", int: 123, bool: true, flt: 1.23}'));
    obj := ctx.AsJson<TData>(data);
  finally
    ctx.Free;
  end;
end;
```

## Saving data

```pas
  obj.AsJSon(options);
  obj.SaveTo(stream);
  obj.SaveTo(filename);
```

## Helpers

```pas
  SO(['prop1', true, 'prop2', 123]); // return an object {"prop1": true, "prop2": 123}
  SA([true, 123]); // return an array [true, 123]
```

## Non canonical forms

The SuperObject is able to parse non canonical forms.

```pas
// unquoted identifiers
SO('{foo: true}');
// unescaped or unquoted strings
SO('{собственность: bla bla bla}');
// excadecimal
SO('{foo: \xFF}');
```
## Additional examples

Get a Json string:

     function TDataModule3.GetSearchLostStatus: string;
     var
      X: ISuperObject;
     begin
      X := SO;
      with FServiceThread do
      begin
       X.B['NowSearchForFile'] := NowSearchForFile;
       X.S['LastLostFile'] := LastLostFile;
       X.B['NowSearchForRec'] := NowSearchForRec;
       X.S['LostRecProgress'] := LostRecProgress;
      end;
      Result := X.AsJSON;
     end;

Get data back from the Json string:

     procedure TForm2.SetSearchLostStatus(const Params: string);
     var
      s: string;
      X: ISuperObject;
     begin
      X := TSuperObject.ParseString(PChar(Params), True);
      FNowSearchForFile := not X.B['NowSearchForFile'];
      FLastLostFile := X.S['LastLostFile'];
      FNowSearchForRec := X.B['NowSearchForRec'];
      FLostRecProgress := X.I['LostRecProgress'];
     end;

An array usage:

     procedure TForm4.SetQueueStatus(const Params: string);
     var
      j: integer;
      X:  ISuperObject;
      X1: TSuperArray;
      s: string;
     begin
      X  := TSuperObject.ParseString(PChar(s), True);
      X1 := X.A['Queues'];
      StringGrid1.RowCount := X1.Length + 1;
      for j := 0 to X1.Length - 1 do
       with StringGrid1, X1[j] do
       begin
        Cells[0, j + 1] := S['NAME'];
        if j = 0 then
         Cells[1, j + 1] := S['FILES_QUEUED1'] + ' + ' + S['FILES_QUEUED2']
        else
         Cells[1, j + 1] := S['FILES_QUEUED'];
        Cells[2, j + 1] := S['STATUS'];
        Cells[3, j + 1] := S['FILES_DONE'];
        Cells[4, j + 1] := S['FILES_SKIPPED'];
       end;
     end;

Path usage:

     var s: string; json, field: iSuperObject;
     ....
      field := json.O['Document.CurrentItems.DocumentItem.Fields.FieldValue[1].Value'];
      s := json.O['Value'].AsString;
