unit superdate;

interface

uses
  supertimezone;

function JavaToDelphiDateTime(const dt: Int64; const TimeZone: string = ''): TDateTime;
function DelphiToJavaDateTime(const dt: TDateTime; const TimeZone: string = ''): Int64;
function JavaDateTimeToISO8601Date(const dt: Int64; const TimeZone: string = ''): string;
function DelphiDateTimeToISO8601Date(const dt: TDateTime; const TimeZone: string = ''): string;
function ISO8601DateToJavaDateTime(const str: string; out ms: Int64; const TimeZone: string = ''): Boolean;
function ISO8601DateToDelphiDateTime(const str: string; out dt: TDateTime; const TimeZone: string = ''): Boolean;

implementation

function JavaToDelphiDateTime(const dt: Int64; const TimeZone: string = ''): TDateTime;
begin
  Result := TSuperTimeZone.Zone[TimeZone].JavaToDelphi(dt);
end;

function DelphiToJavaDateTime(const dt: TDateTime; const TimeZone: string = ''): Int64;
begin
  Result := TSuperTimeZone.Zone[TimeZone].DelphiToJava(dt);
end;

function JavaDateTimeToISO8601Date(const dt: Int64; const TimeZone: string = ''): string;
begin
  Result := TSuperTimeZone.Zone[TimeZone].JavaToISO8601(dt);
end;

function DelphiDateTimeToISO8601Date(const dt: TDateTime; const TimeZone: string = ''): string;
begin
  Result := TSuperTimeZone.Zone[TimeZone].DelphiToISO8601(dt);
end;

function ISO8601DateToJavaDateTime(const str: string; out ms: Int64; const TimeZone: string = ''): Boolean;
begin
  Result := TSuperTimeZone.Zone[TimeZone].ISO8601ToJava(str, ms);
end;

function ISO8601DateToDelphiDateTime(const str: string; out dt: TDateTime;  const TimeZone: string): Boolean;
begin
  Result := TSuperTimeZone.Zone[TimeZone].ISO8601ToDelphi(str, dt);
end;

end.
