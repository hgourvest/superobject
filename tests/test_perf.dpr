program test_perf;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ELSE}
  {$APPTYPE CONSOLE}
{$ENDIF}

uses
{$IFNDEF UNIX}
  windows,
{$ENDIF}
  sysutils,
  superobject;

{$IFDEF UNIX}
function GetTickCount: Cardinal;
var
  h, m, s, s1000: word;
begin
  decodetime(time, h, m, s, s1000);
  Result := Cardinal(h * 3600000 + m * 60000 + s * 1000 + s1000);
end;
{$ENDIF}

var
  js: ISuperObject;
  xs: ISuperObject;
  i,l: Integer;
  k: cardinal;
  s: SOString;
  ts: TSuperTableString;
  pb: TSuperWriterString;
begin
  Randomize;
  js := TSuperObject.Create;
  ts := js.AsObject;
  k := GetTickCount;
  for i := 1 to 50000 do
    begin
      l := random(9999999);
      s := 'param' + IntToStr(l);
      ts.S[s] := s;
      s := 'int' + IntToStr(l);
      ts.I[s] := i;
    end;
  k := GetTickCount-k;
  writeln('records inserted:',js.AsObject.Count);
  writeln('time for insert:',k);

  k := GetTickCount;
  pb := TSuperWriterString.Create;
  js.write(pb, false, true, 0);
  writeln('text length:',pb.position);
  k := GetTickCount-k;
  writeln('release memory...');
  js := nil;

  writeln('time for gentext:',k);

  k := GetTickCount;
  xs := TSuperObject.ParseString(pb.Data);

  k := GetTickCount-k;
  writeln('time for parse:',k);

  writeln('press enter...');
  readln;
  writeln(xs.AsJson);
  xs := nil;
  pb.Free;
  writeln('press enter...');
  s := '';
  readln;
end.
