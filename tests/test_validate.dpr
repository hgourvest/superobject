program test_validate;
{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}  
{$ENDIF}


uses
  SysUtils, superobject;

procedure onerror(sender: Pointer; error: TSuperValidateError; const path: SOString);
const
  errors: array[TSuperValidateError] of string =
   ('RuleMalformated',
    'FieldIsRequired',
    'InvalidDataType',
    'FieldNotFound',
    'UnexpectedField',
    'DuplicateEntry',
    'ValueNotInEnum',
    'InvalidLengthRule',
    'InvalidRange');

begin
  writeln(errors[error], ' -> ', path)
end;


procedure Validate(const d, r, f: SOString);
var
  o: ISuperObject;
begin
  o := TSuperObject.ParseString(PSOChar(d));
  case o.Validate(r, f, @onerror) of
    true: writeln('valid');
    false: writeln('invalid');
  end;
  o := nil;
end;


begin
  try
    // unique field
    Validate('[{name: a}, {name: b}]',
             '{type: seq, sequence: {type: map, mapping: {name: {type: str, unique: true}}}}}', '');

    // unique object
    Validate('[{n: 1, name: a}, {name: a, n: 2}]',
             '{type: seq, sequence: {type: map, unique: true, mapping: {name: {type: str}, n: {type: int}}}}}', '');

    // inherited fields
    Validate('{'+
                 'x1: {f1: foo},'+
                 'x2: {f1: foo, f2: foo},'+
                 'x3: {f1: foo, f2: foo, f3: foo},'+
                 'x4: {f1: 123, f2: foo, f3: foo}'+
             '}',
             '{type: map, mapping: {'+
                    'x1: {type: map, name: n1, mapping: {f1: {type: str}}},'+
                    'x2: {name: n2, inherit: n1, mapping: {f2: {type: str}}},'+ // inherit
                    'x3: {name: n3, inherit: n2, mapping: {f3: {type: str}}},'+ // inherit
                    'x4: {name: n4, inherit: n3, mapping: {f1: {type: int}}}'+  // overide
             '}}', '');

    // additionnal shemat
    Validate('{'+
                 'x1: {f1: foo},'+
                 'x2: {f1: foo, f2: foo},'+
                 'x3: {f1: foo, f2: foo, f3: foo},'+
                 'x4: {f1: 123, f2: foo, f3: foo}'+
             '}',
             '{type: map, mapping: {'+
                    'x1: {inherit: n1},'+
                    'x2: {inherit: n2},'+
                    'x3: {inherit: n3},'+
                    'x4: {inherit: n4}'+
             '}}',

                   '[{type: map, name: n1, mapping: {f1: {type: str}}},'+
                    '{name: n2, inherit: n1, mapping: {f2: {type: str}}},'+
                    '{name: n3, inherit: n2, mapping: {f3: {type: str}}},'+
                    '{name: n4, inherit: n3, mapping: {f1: {type: int}}}]'
    );


    // enum
    Validate('b', '{type: str, enum: [a,b,c]}', '');
    Validate('2', '{type: int, enum: [1,2,3]}', '[]');

    // length
    Validate('"123456789"', '{type: str, length: {max: 9}}', '');
    Validate('[1,2,3,4,5,6,7,8,9]', '{type: seq, sequence: {type: int}, length: {max: 9}}', '');
    Validate('123456789', '{type: text, length: {max: 9}}', '');

    // range
    Validate('5', '{type: int, range: {min: 5, max: 5, minex: 4, maxex: 6}}', '');
    Validate('abc', '{type: str, range: {min: ab, max: abcd}}', '');

  except
    on E: Exception do
      Writeln(E.message);
  end;
  writeln('press enter ...');
  readln;
end.

