unit superdate;

interface

{$if defined(VER210) or defined(VER220)}
  {$define VER210ORGREATER}
{$ifend}

{$if defined(VER230) or defined(VER240)  or defined(VER250) or
     defined(VER260) or defined(VER270)  or defined(VER280) or
     defined(VER290)}
  {$define VER210ORGREATER}
  {$define VER230ORGREATER}
{$ifend}

{$if defined(VER210ORGREATER)}
  {$define HAVE_CLASS_CONSTRUCTOR}
{$ifend}

uses
  supertypes, supertimezone;

function JavaToDelphiDateTime(const dt: Int64; const TimeZone: SOString = ''): TDateTime;
function DelphiToJavaDateTime(const dt: TDateTime; const TimeZone: SOString = ''): Int64;
function JavaDateTimeToISO8601Date(const dt: Int64; const TimeZone: SOString = ''): SOString;
function DelphiDateTimeToISO8601Date(const dt: TDateTime; const TimeZone: SOString = ''): SOString;
function ISO8601DateToJavaDateTime(const str: SOString; var ms: Int64; const TimeZone: SOString = ''): Boolean;
function ISO8601DateToDelphiDateTime(const str: SOString; var dt: TDateTime; const TimeZone: SOString = ''): Boolean;

implementation

function JavaToDelphiDateTime(const dt: Int64; const TimeZone: SOString = ''): TDateTime;
begin
  {$IFDEF HAVE_CLASS_CONSTRUCTOR}
  Result := TSuperTimeZone.Zone[TimeZone].JavaToDelphi(dt);
  {$ELSE}
  Result := LocalSuperTimeZone.JavaToDelphi(dt);
  {$ENDIF}
end;

function DelphiToJavaDateTime(const dt: TDateTime; const TimeZone: SOString = ''): Int64;
begin
  {$IFDEF HAVE_CLASS_CONSTRUCTOR}
  Result := TSuperTimeZone.Zone[TimeZone].DelphiToJava(dt);
  {$ELSE}
  Result := LocalSuperTimeZone.DelphiToJava(dt);
  {$ENDIF}
end;

function JavaDateTimeToISO8601Date(const dt: Int64; const TimeZone: SOString = ''): SOString;
begin
  {$IFDEF HAVE_CLASS_CONSTRUCTOR}
  Result := TSuperTimeZone.Zone[TimeZone].JavaToISO8601(dt);
  {$ELSE}
  Result := LocalSuperTimeZone.JavaToISO8601(dt);
  {$ENDIF}
end;

function DelphiDateTimeToISO8601Date(const dt: TDateTime; const TimeZone: SOString = ''): SOString;
begin
  {$IFDEF HAVE_CLASS_CONSTRUCTOR}
  Result := TSuperTimeZone.Zone[TimeZone].DelphiToISO8601(dt);
  {$ELSE}
  Result := LocalSuperTimeZone.DelphiToISO8601(dt);
  {$ENDIF}
end;

function ISO8601DateToJavaDateTime(const str: SOString; var ms: Int64; const TimeZone: SOString = ''): Boolean;
begin
  {$IFDEF HAVE_CLASS_CONSTRUCTOR}
  Result := TSuperTimeZone.Zone[TimeZone].ISO8601ToJava(str, ms);
  {$ELSE}
  Result := LocalSuperTimeZone.ISO8601ToJava(str, ms);
  {$ENDIF}
end;

function ISO8601DateToDelphiDateTime(const str: SOString; var dt: TDateTime; const TimeZone: SOString = ''): Boolean;
begin
  {$IFDEF HAVE_CLASS_CONSTRUCTOR}
  Result := TSuperTimeZone.Zone[TimeZone].ISO8601ToDelphi(str, dt);
  {$ELSE}
  Result := LocalSuperTimeZone.ISO8601ToDelphi(str, dt);
  {$ENDIF}
end;

end.
