unit supertimezone;

{$IFDEF FPC}
  {$mode Delphi}
{$ENDIF}

interface

uses
  {$IFDEF MSWINDOWS}
  Windows,
  Registry,
  {$ELSE}
  System.Classes,
  {$ENDIF}
  System.SyncObjs,
  SysUtils, Math, Generics.Collections,
  supertypes;

type

  { TSuperTimeZone }

  TSuperSystemTime = record
    Year: Word;
    Month: Word;
    DayOfWeek: Word;
    Day: Word;
    Hour: Word;
    Minute: Word;
    Second: Word;
    Millisecond: Word;
  end;

  {$IFDEF LINUX}
  TSystemTime =  TSuperSystemTime;
  {$ENDIF}

  TSuperTimeZone = class
  private
    const
      TZ_TZI_KEY = '\SYSTEM\CurrentControlSet\Control\TimeZoneInformation'; { Vista and + }
      TZ_KEY     = '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\';
      TZ_KEYNAME = 'TimeZoneKeyName';
  private type
    TExpirable<T> = record
      Timestamp: TDateTime;
      Data: T;
      function IsValid: Boolean;
      class function Box(Data: T): TExpirable<T>; static;
    end;
  private
    FName: SOString;
    FDaylightDisabled: TExpirable<Boolean>;
    {$IFDEF MSWINDOWS}
    FCacheTZI: TDictionary<Word, TExpirable<TTimeZoneInformation>>;
    {$ENDIF}

    function GetName: SOString;

    { Windows Internals }
    {$IFDEF MSWINDOWS}
    function TzSpecificLocalTimeToSystemTime(
      const lpTimeZoneInformation: PTimeZoneInformation;
      var lpLocalTime, lpUniversalTime: TSystemTime): BOOL;

    function SystemTimeToTzSpecificLocalTime(
      const lpTimeZoneInformation: PTimeZoneInformation;
      var lpUniversalTime, lpLocalTime: TSystemTime): BOOL;

    function GetTimezoneBias(const pTZinfo: PTimeZoneInformation;
      lpFileTime: PFileTime; islocal: Boolean; pBias: PLongint): Boolean;

    function CompTimeZoneID(const pTZinfo: PTimeZoneInformation;
      lpFileTime: PFileTime; IsLocal: Boolean): FixedUInt;

    function DayLightCompareDate(const date: PSystemTime;
      const compareDate: PSystemTime): Integer;
    {$ENDIF}
  private
    class constructor Init;
    class destructor Finish;
    class var FCacheCS: TCriticalSection;
    class var FCache: TObjectDictionary<string, TSuperTimeZone>;
    class function GetSuperTimeZoneInstance(const Name: string): TSuperTimeZone; static;
    class function GetLocalSuperTimeZoneInstance: TSuperTimeZone; static;
  public
    constructor Create(const TimeZoneName: SOString = '');
    destructor Destroy; override;

    { ISO8601 formatted date Parser }
    class function ParseISO8601Date(const ISO8601Date: SOString;
      var st: TSystemTime; var dayofyear: Integer; var week: Word; var bias: Integer;
      var havetz, havedate: Boolean): Boolean;

    { Conversions }
    function LocalToUTC(const DelphiDateTime: TDateTime): TDateTime;
    function UTCToLocal(const DelphiDateTime: TDateTime): TDateTime;

    function JavaToDelphi(const JavaDateTime: Int64): TDateTime;
    function DelphiToJava(const DelphiDateTime: TDateTime): Int64;

    function JavaToISO8601(JavaDateTime: Int64): string;
    function DelphiToISO8601(DelphiDateTime: TDateTime): string;

    function ISO8601ToJava(const ISO8601Date: string; out JavaDateTime: Int64): Boolean;
    function ISO8601ToDelphi(const ISO8601Date: string; out DelphiDateTime: TDateTime): Boolean;

    { TZ Info }
    class function GetCurrentTimeZone: SOString;
    {$IFDEF MSWINDOWS}
    function GetTimeZoneInformation(Year: Word; var TZI: TTimeZoneInformation): Boolean;
    {$ENDIF}
    function GetDaylightDisabled: Boolean;
    property Name: SOString read GetName;

    { Builder }
    class property Local: TSuperTimeZone read GetLocalSuperTimeZoneInstance;
    class property Zone[const TimeZoneName: string]: TSuperTimeZone read GetSuperTimeZoneInstance;
  end;

{$IFDEF MSWINDOWS}
  {$WARN SYMBOL_PLATFORM OFF}

(* NOT DST Aware *)

{ Windows 2000+ }
function _SystemTimeToTzSpecificLocalTime(
  lpTimeZoneInformation: PTimeZoneInformation;
  var lpUniversalTime, lpLocalTime: TSystemTime): BOOL; stdcall; external kernel32 name 'SystemTimeToTzSpecificLocalTime'{$IFNDEF FPC} delayed{$ENDIF};

{ Windows XP+ }
function _TzSpecificLocalTimeToSystemTime(
  lpTimeZoneInformation: PTimeZoneInformation;
  var lpLocalTime, lpUniversalTime: TSystemTime): BOOL; stdcall; external kernel32 name 'TzSpecificLocalTimeToSystemTime'{$IFNDEF FPC} delayed{$ENDIF};

(* EXtended version - DST Aware *)

{ Windows 7+ }
function _TzSpecificLocalTimeToSystemTimeEx(
  const lpTimeZoneInformation: PDynamicTimeZoneInformation;
  const lpLocalTime: PSystemTime; var lpUniversalTime: TSystemTime): BOOL; stdcall; external kernel32 name 'TzSpecificLocalTimeToSystemTimeEx'{$IFNDEF FPC} delayed{$ENDIF};

{ Windows 7+ }
function _SystemTimeToTzSpecificLocalTimeEx(
  const lpTimeZoneInformation: PDynamicTimeZoneInformation;
   const lpUniversalTime: PSystemTime; var lpLocalTime: TSystemTime): BOOL; stdcall; external kernel32 name 'SystemTimeToTzSpecificLocalTimeEx'{$IFNDEF FPC} delayed{$ENDIF};

{ Convert Local <=> UTC for specific time-zones using the Windows API only. NOT Guaranteed to work }

function _ConvertLocalDateTimeToUTC(const TimeZoneName: SOString;
  const Local: TDateTime; var UTC: TDateTime): Boolean;

function _ConvertUTCDateTimeToLocal(const TimeZoneName: SOString;
  const UTC: TDateTime; var Local: TDateTime): Boolean;

  {$WARN SYMBOL_PLATFORM ON}
{$ENDIF}

implementation

{$IFDEF MSWINDOWS}

{ Convert Local -> UTC for specific time-zones using the Windows API only. NOT Guaranteed to work }

function _ConvertLocalDateTimeToUTC(const TimeZoneName: SOString;
  const Local: TDateTime; var UTC: TDateTime): Boolean;
{$IFNDEF FPC}
var
  DTZI: TDynamicTimeZoneInformation;
  local_st, utc_st: TSystemTime;
{$ENDIF}
begin
  if not CheckWin32Version(6, 1) then
  begin
    Result := False;
    Exit;
  end;

  {$IFNDEF FPC}
  { We work with system times }
  DateTimeToSystemTime(Local, local_st);

  { Get current Dynamic TimeZone Information }
  FillChar(DTZI, SizeOf(TDynamicTimeZoneInformation), 0);
  GetDynamicTimeZoneInformation(DTZI);

  { Replaces the TimeZoneKeyName member with specified TimeZoneName }
  Move(TimeZoneName[1], DTZI.TimeZoneKeyName, (Length(TimeZoneName) + 1) * SizeOf(SOChar));

  { Retrieves the TimeZoneInformation structure and convert the local time to utc }
  if _TzSpecificLocalTimeToSystemTimeEx(@DTZI, @local_st, utc_st) then
  begin
    { We really want Delphi TDateTime }
    UTC := SystemTimeToDateTime(utc_st);
    Result := True;
  end
  else
    Result := False;
  {$ENDIF}
end;

{ Convert UTC -> Local for specific time-zones using the Windows API only. NOT Guaranteed to work }

function _ConvertUTCDateTimeToLocal(const TimeZoneName: SOString;
  const UTC: TDateTime; var Local: TDateTime): Boolean;
{$IFNDEF FPC}
var
  DTZI: TDynamicTimeZoneInformation;
  utc_st, local_st: TSystemTime;
{$ENDIF}
begin
  if not CheckWin32Version(6, 1) then
  begin
    Result := False;
    Exit;
  end;

  {$IFNDEF FPC}
  { We work with system times }
  DateTimeToSystemTime(UTC, utc_st);

  { Get current Dynamic TimeZone Information }
  FillChar(DTZI, SizeOf(TDynamicTimeZoneInformation), 0);
  GetDynamicTimeZoneInformation(DTZI);

  { Replaces the TimeZoneKeyName member with specified TimeZoneName }
  Move(TimeZoneName[1], DTZI.TimeZoneKeyName[0], Length(TimeZoneName) * SizeOf(SOChar));

  { Retrieves the TimeZoneInformation structure and convert the local time to utc }
  if _SystemTimeToTzSpecificLocalTimeEx(@DTZI, @utc_st, local_st) then
  begin
    { We really want Delphi TDateTime }
    Local := SystemTimeToDateTime(local_st);
    Result := True;
  end
  else
    Result := False;
  {$ENDIF}
end;
{$ENDIF}

{ TSuperDate }

class constructor TSuperTimeZone.Init;
begin
  FCacheCS := TCriticalSection.Create;
  FCache := TObjectDictionary<string, TSuperTimeZone>.Create([doOwnsValues]);
end;

class destructor TSuperTimeZone.Finish;
begin
  FCache.Free;
  FCacheCS.Free;
end;

class function TSuperTimeZone.GetSuperTimeZoneInstance(
  const Name: string): TSuperTimeZone;
begin
  FCacheCS.Enter;
  try
    if not FCache.TryGetValue(Name, Result) then
    begin
      Result := TSuperTimeZone.Create(Name);
      FCache.Add(Name, Result);
    end;
  finally
    FCacheCS.Leave;
  end;
end;

class function TSuperTimeZone.GetLocalSuperTimeZoneInstance: TSuperTimeZone;
begin
  Result := TSuperTimeZone.GetSuperTimeZoneInstance('');
end;

constructor TSuperTimeZone.Create(const TimeZoneName: SOString);
begin
  inherited Create;
  FName := TimeZoneName;
  FDaylightDisabled := TExpirable<Boolean>.Box(GetDaylightDisabled);
  {$IFDEF MSWINDOWS}
  FCacheTZI := TDictionary<Word, TExpirable<TTimeZoneInformation>>.Create;
  {$ENDIF}
end;

destructor TSuperTimeZone.Destroy;
begin
  {$IFDEF MSWINDOWS}
  FCacheTZI.Free;
  {$ENDIF}
end;

function TSuperTimeZone.LocalToUTC(const DelphiDateTime: TDateTime): TDateTime;
{$IFDEF MSWINDOWS}
var
  local, utc: TSystemTime;
  tzi: TTimeZoneInformation;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  DateTimeToSystemTime(DelphiDateTime, local);
  if GetTimeZoneInformation(local.wYear, tzi) and TzSpecificLocalTimeToSystemTime(@tzi, local, utc) then
    Result := SystemTimeToDateTime(utc)
  else
  {$ENDIF}
    Result := DelphiDateTime;
end;

function TSuperTimeZone.UTCToLocal(const DelphiDateTime: TDateTime): TDateTime;
{$IFDEF MSWINDOWS}
var
  utc, local: TSystemTime;
  tzi: TTimeZoneInformation;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  DateTimeToSystemTime(DelphiDateTime, utc);
  if GetTimeZoneInformation(utc.wYear, tzi) and SystemTimeToTzSpecificLocalTime(@tzi, utc, local) then
    Result := SystemTimeToDateTime(local)
  else
  {$ENDIF}
    Result := DelphiDateTime;
end;

function TSuperTimeZone.DelphiToJava(const DelphiDateTime: TDateTime): Int64;
{$IFDEF MSWINDOWS}
var
  local, utc, st: TSystemTime;
  tzi: TTimeZoneInformation;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  DateTimeToSystemTime(DelphiDateTime, local);
  if GetTimeZoneInformation(local.wYear, tzi) and TzSpecificLocalTimeToSystemTime(@tzi, local, utc) then
    st := utc
  else
    st := local;
  Result := Round((SystemTimeToDateTime(st) - 25569) * 86400000);
  {$ENDIF}
end;

function TSuperTimeZone.JavaToDelphi(const JavaDateTime: Int64): TDateTime;
{$IFDEF MSWINDOWS}
var
  utc, local: TSystemTime;
  tzi: TTimeZoneInformation;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  DateTimeToSystemTime(25569 + (JavaDateTime / 86400000), utc);
  if GetTimeZoneInformation(utc.wYear, tzi) and SystemTimeToTzSpecificLocalTime(@tzi, utc, local) then
    Result := SystemTimeToDateTime(local)
  else
    Result := SystemTimeToDateTime(utc);
  {$ENDIF}
end;

function TSuperTimeZone.DelphiToISO8601(
  DelphiDateTime: TDateTime): string;
const
  ISO_Fmt = '%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%d';
  TZ_Fmt  = '%s%.2d:%.2d';
var
  {$IFDEF MSWINDOWS}
  local, utc: TSystemTime;
  tzi: TTimeZoneInformation;
  bias: TDateTime;
  h, m, d: Word;
  {$ENDIF}
  iso: SOString;
begin
  {$IFDEF MSWINDOWS}
  DateTimeToSystemTime(DelphiDateTime, local);
  iso := Format(ISO_Fmt, [
    local.wYear, local.wMonth, local.wDay,
    local.wHour, local.wMinute, local.wSecond, local.wMilliseconds]);
  if GetTimeZoneInformation(local.wYear, tzi) and TzSpecificLocalTimeToSystemTime(@tzi, local, utc) then
  begin
    bias := SystemTimeToDateTime(local) - SystemTimeToDateTime(utc);
    DecodeTime(bias, h, m, d, d);
    case Sign(bias) of
    -1: Result := iso + Format(TZ_Fmt, [ '-', h, m ]);
     0: Result := iso + 'Z';
    +1: Result := iso + Format(TZ_Fmt, [ '+', h, m ]);
    end;
  end
  else
  {$ENDIF}
    Result := iso;
end;

function TSuperTimeZone.JavaToISO8601(JavaDateTime: Int64): string;
begin
  Result := DelphiToISO8601(JavaToDelphi(JavaDateTime));
end;

function TSuperTimeZone.ISO8601ToDelphi(const ISO8601Date: string; out DelphiDateTime: TDateTime): Boolean;
var
  JavaDateTime: Int64;
begin
  Result := ISO8601ToJava(ISO8601Date, JavaDateTime);
  if Result then
    DelphiDateTime := JavaToDelphi(JavaDateTime);
end;

function TSuperTimeZone.ISO8601ToJava(const ISO8601Date: string;
  out JavaDateTime: Int64): Boolean;
{$IFDEF MSWINDOWS}
var
  st: TSystemTime;
  dayofyear: Integer;
  week: Word;
  bias: Integer;
  havetz, havedate: Boolean;
  tzi: TTimeZoneInformation;
  utc: TSystemTime;
  m: Word;
  DayTable: PDayTable;
{$ENDIF}
begin
  {$IFDEF MSWINDOWS}
  if ParseISO8601Date(ISO8601Date, st, dayofyear, week, bias, havetz, havedate) then
  begin
    if (not havetz) and GetTimeZoneInformation(st.wYear, tzi) and TzSpecificLocalTimeToSystemTime(@tzi, st, utc) then
      bias := Round((SystemTimeToDateTime(utc) - SystemTimeToDateTime(st)) * MinsPerDay);
    JavaDateTime := st.wMilliseconds + st.wSecond * 1000 + (st.wMinute + bias) * 60000 + st.wHour * 3600000;
    if havedate then
    begin
      DayTable := @MonthDays[IsLeapYear(st.wYear)];
      if st.wMonth <> 0 then
      begin
        if not (st.wMonth in [1..12]) or (DayTable^[st.wMonth] < st.wDay) then
        begin
          Result := False;
          Exit;
        end;
        for m := 1 to st.wMonth - 1 do
          Inc(JavaDateTime, Int64(DayTable^[m]) * 86400000);
      end;
      Dec(st.wYear);
      Inc(JavaDateTime, Int64(
        (st.wYear * 365) + (st.wYear div 4) - (st.wYear div 100) +
        (st.wYear div 400) + st.wDay + dayofyear - 719163) * 86400000);
    end;
    Result := True;
  end
  else
  {$ENDIF}
    Result := False;
end;

function TSuperTimeZone.GetName: SOString;
begin
  if FName <> '' then
    Result := FName
  else
    Result := GetCurrentTimeZone;
end;

class function TSuperTimeZone.GetCurrentTimeZone: SOString;
begin
  {$IFDEF MSWINDOWS}
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    if OpenKeyReadOnly(TZ_TZI_KEY) and ValueExists(TZ_KEYNAME) then
      { Windows Vista+ }
      Result := Trim(ReadString(TZ_KEYNAME))
    else
    begin
      { Windows 2000/XP }
      CloseKey;
      RootKey := HKEY_CURRENT_USER;
      if OpenKeyReadOnly(TZ_KEY) and ValueExists(TZ_KEYNAME) then
        Result := Trim(ReadString(TZ_KEYNAME))
      else
      begin
        CloseKey;
        RootKey := HKEY_USERS;
        if OpenKeyReadOnly('.DEFAULT\' + TZ_KEY) and ValueExists(TZ_KEYNAME) then
          Result := Trim(ReadString(TZ_KEYNAME))
        else
          Result := '';
      end;
    end;
  finally
    CloseKey;
    Free;
  end;
  {$ELSE}
  Result := '';
  {$ENDIF}
end;

function TSuperTimeZone.GetDaylightDisabled: Boolean;
var
  KeyName: SOString;
begin
  if FDaylightDisabled.IsValid then
    Exit(FDaylightDisabled.Data);
  Result := False;
  KeyName := TZ_KEY + Name;
  {$IFDEF MSWINDOWS}
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    if OpenKeyReadOnly(KeyName) then
    begin
      if ValueExists('IsObsolete') then
        Result := ReadBool('IsObsolete');
      CloseKey;
    end;
    FDaylightDisabled := TExpirable<Boolean>.Box(Result);
  finally
    Free;
  end;
  {$ENDIF}
end;

{$IFDEF MSWINDOWS}
function TSuperTimeZone.GetTimeZoneInformation(Year: Word;
  var TZI: TTimeZoneInformation): Boolean;
type
  TRegistryTZI = packed record
    Bias: LongInt;
    StandardBias: LongInt;
    DaylightBias: LongInt;
    StandardChangeTime: TSystemTime;
    DaylightChangeTime: TSystemTime;
  end;
var
  RegTZI: TRegistryTZI;
  KeyName: SOString;
  FirstYear, LastYear, ChangeYear: Word;
  Retry: Boolean;
  CachedData: TExpirable<TTimeZoneInformation>;
begin
  if FCacheTZI.TryGetValue(Year, CachedData) and CachedData.IsValid then
  begin
    TZI := CachedData.Data;
    Exit(True);
  end;

  FillChar(TZI, SizeOf(TZI), 0);
  KeyName := TZ_KEY + Name;
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;
    if not KeyExists(KeyName) then
    begin
      Result := False;
      Exit;
    end;

    ChangeYear := 0;
    if OpenKeyReadOnly(KeyName + '\Dynamic DST') then
    try
      FirstYear := ReadInteger('FirstEntry');
      LastYear  := ReadInteger('LastEntry');

      if (Year >= FirstYear) and (Year <= LastYear) then
        ChangeYear := Year
      else
        ChangeYear := 0;

      Retry := False;
      repeat
        while (ChangeYear > 0) and (not ValueExists(IntToStr(ChangeYear))) do
        begin
          Dec(ChangeYear);
          if ChangeYear < FirstYear then
            ChangeYear := 0;
        end;

        if ChangeYear > 0 then
        begin
          ReadBinaryData(IntToStr(ChangeYear), RegTZI, SizeOf(TRegistryTZI));
          if RegTZI.DaylightChangeTime.wMonth > RegTZI.StandardChangeTime.wMonth then
          begin
            Dec(ChangeYear);
            Retry := not Retry;
          end;
        end;
      until not Retry;
    finally
      CloseKey;
    end;

    if (ChangeYear = 0) and OpenKeyReadOnly(KeyName) then
    try
      ReadBinaryData('TZI', RegTZI, SizeOf(TRegistryTZI));
    finally
      CloseKey;
    end;

    TZI.Bias         := RegTZI.Bias;
    TZI.StandardDate := RegTZI.StandardChangeTime;
    TZI.StandardBias := RegTZI.StandardBias;
    TZI.DaylightDate := RegTZI.DaylightChangeTime;
    TZI.DaylightBias := RegTZI.DaylightBias;

    Result := True;

    FCacheTZI.AddOrSetValue(Year, TExpirable<TTimeZoneInformation>.Box(TZI));
  finally
    Free;
  end;
end;

function TSuperTimeZone.TzSpecificLocalTimeToSystemTime(
  const lpTimeZoneInformation: PTimeZoneInformation;
  var lpLocalTime, lpUniversalTime: TSystemTime): BOOL;
var
  ft: TFileTime;
  lBias: LongInt;
  t: Int64;
begin
  Assert(lpTimeZoneInformation <> nil);
  if (not SystemTimeToFileTime(lpLocalTime, ft)) then
  begin
    Result := False;
    Exit;
  end;
  t := PInt64(@ft)^;
  if (not GetTimezoneBias(lpTimeZoneInformation, @ft, True, @lBias)) then
  begin
    Result := False;
    Exit;
  end;
  (* convert minutes to 100-nanoseconds-ticks *)
  Inc(t, Int64(lBias) * 600000000);
  PInt64(@ft)^ := t;
  Result := FileTimeToSystemTime(ft, lpUniversalTime);
end;

function TSuperTimeZone.GetTimezoneBias(const pTZinfo: PTimeZoneInformation;
  lpFileTime: PFileTime; islocal: Boolean; pBias: PLongint): Boolean;
var
  bias: LongInt;
  tzid: FixedUInt;
begin
  bias := pTZinfo^.Bias;
  tzid := CompTimeZoneID(pTZinfo, lpFileTime, islocal);

  if( tzid = TIME_ZONE_ID_INVALID) then
  begin
    Result := False;
    Exit;
  end;
  if (tzid = TIME_ZONE_ID_DAYLIGHT) then
    Inc(bias, pTZinfo^.DaylightBias)
  else if (tzid = TIME_ZONE_ID_STANDARD) then
    Inc(bias, pTZinfo^.StandardBias);
  pBias^ := bias;
  Result := True;
end;

function TSuperTimeZone.CompTimeZoneID(const pTZinfo: PTimeZoneInformation;
  lpFileTime: PFileTime; IsLocal: Boolean): FixedUInt;
var
  Ret: Integer;
  BeforeStandardDate, AfterDaylightDate: Boolean;
  llTime: Int64;
  SysTime: TSystemTime;
  ftTemp: TFileTime;
  year: Word;
begin
  llTime := 0;
  if (not GetDaylightDisabled) and (pTZinfo^.DaylightDate.wMonth <> 0) then
  begin
    (* if year is 0 then date is in day-of-week format, otherwise
     * it's absolute date.
     *)
    if ((pTZinfo^.StandardDate.wMonth = 0) or
        ((pTZinfo^.StandardDate.wYear = 0) and
        ((pTZinfo^.StandardDate.wDay < 1) or
        (pTZinfo^.StandardDate.wDay > 5) or
        (pTZinfo^.DaylightDate.wDay < 1) or
        (pTZinfo^.DaylightDate.wDay > 5)))) then
    begin
      SetLastError(ERROR_INVALID_PARAMETER);
      Result := TIME_ZONE_ID_INVALID;
      Exit;
    end;

    if (not IsLocal) then
    begin
      llTime := PInt64(lpFileTime)^;
      Dec(llTime, Int64(pTZinfo^.Bias) * 600000000);
      PInt64(@ftTemp)^ := llTime;
      lpFileTime := @ftTemp;
    end;

    FileTimeToSystemTime(lpFileTime^, SysTime);
    year := SysTime.wYear;

    if (not IsLocal) then
    begin
      Dec(llTime, Int64(pTZinfo^.DaylightBias) * 600000000);
      PInt64(@ftTemp)^ := llTime;
      FileTimeToSystemTime(lpFileTime^, SysTime);
    end;

    (* check for daylight savings *)
    if (year = SysTime.wYear) then
    begin
      ret := DayLightCompareDate(@SysTime, @pTZinfo.StandardDate);
      if (ret = -2) then
      begin
        Result := TIME_ZONE_ID_INVALID;
        Exit;
      end;
      beforeStandardDate := ret < 0;
    end else
      beforeStandardDate := SysTime.wYear < year;

    if (not islocal) then
    begin
      Dec(llTime, (pTZinfo.StandardBias - pTZinfo.DaylightBias) * 600000000);
      PInt64(@ftTemp)^ := llTime;
      FileTimeToSystemTime(lpFileTime^, SysTime);
    end;

    if (year = SysTime.wYear) then
    begin
      ret := DayLightCompareDate(@SysTime, @pTZinfo.DaylightDate);
      if (ret = -2) then
      begin
        Result := TIME_ZONE_ID_INVALID;
        Exit;
      end;
      afterDaylightDate := ret >= 0;
    end else
      afterDaylightDate := SysTime.wYear > year;

    Result := TIME_ZONE_ID_STANDARD;
    if pTZinfo^.DaylightDate.wMonth < pTZinfo^.StandardDate.wMonth then
    begin
      (* Northern hemisphere *)
      if BeforeStandardDate and AfterDaylightDate then
        Result := TIME_ZONE_ID_DAYLIGHT;
    end
    else
    begin
      (* Down south *)
      if BeforeStandardDate or AfterDaylightDate then
        Result := TIME_ZONE_ID_DAYLIGHT;
    end;
  end
  else
    (* No transition date *)
    Result := TIME_ZONE_ID_UNKNOWN;
end;

function TSuperTimeZone.DayLightCompareDate(const date, compareDate: PSystemTime): Integer;
var
  limit_day, dayinsecs, weekofmonth: Integer;
  First: Word;
begin
  if (date^.wMonth < compareDate^.wMonth) then
  begin
    Result := -1; (* We are in a month before the date limit. *)
    Exit;
  end;

  if (date^.wMonth > compareDate^.wMonth) then
  begin
    Result := 1; (* We are in a month after the date limit. *)
    Exit;
  end;

  (* if year is 0 then date is in day-of-week format, otherwise
   * it's absolute date.
   *)
  if (compareDate^.wYear = 0) then
  begin
    (* compareDate.wDay is interpreted as number of the week in the month
     * 5 means: the last week in the month *)
    weekofmonth := compareDate^.wDay;
    (* calculate the day of the first DayOfWeek in the month *)
    First := (6 + compareDate^.wDayOfWeek - date^.wDayOfWeek + date^.wDay) mod 7 + 1;
    limit_day := First + 7 * (weekofmonth - 1);
    (* check needed for the 5th weekday of the month *)
    if (limit_day > MonthDays[(date^.wMonth=2) and IsLeapYear(date^.wYear)][date^.wMonth]) then
      Dec(limit_day, 7);
  end
  else
    limit_day := compareDate^.wDay;

  (* convert to seconds *)
  limit_day := ((limit_day * 24  + compareDate^.wHour) * 60 + compareDate^.wMinute ) * 60;
  dayinsecs := ((date^.wDay * 24  + date^.wHour) * 60 + date^.wMinute ) * 60 + date^.wSecond;

  (* and compare *)
  if dayinsecs < limit_day then
    Result :=  -1
  else if dayinsecs > limit_day then
    Result :=  1
  else
    Result :=  0; (* date is equal to the date limit. *)
end;

function TSuperTimeZone.SystemTimeToTzSpecificLocalTime(
  const lpTimeZoneInformation: PTimeZoneInformation;
  var lpUniversalTime, lpLocalTime: TSystemTime): BOOL;
var
  ft: TFileTime;
  lBias: LongInt;
  llTime: Int64;
begin
  Assert(lpTimeZoneInformation <> nil);
  if (not SystemTimeToFileTime(lpUniversalTime, ft)) then
  begin
    Result := False;
    Exit;
  end;
  llTime := PInt64(@ft)^;
  if (not GetTimezoneBias(lpTimeZoneInformation, @ft, False, @lBias)) then
  begin
    Result := False;
    Exit;
  end;
  (* convert minutes to 100-nanoseconds-ticks *)
  Dec(llTime, Int64(lBias) * 600000000);
  PInt64(@ft)^ := llTime;
  Result := FileTimeToSystemTime(ft, lpLocalTime);
end;
{$ENDIF}

class function TSuperTimeZone.ParseISO8601Date(const ISO8601Date: SOString;
  var st: TSystemTime; var dayofyear: Integer; var week: Word;
  var bias: Integer; var havetz, havedate: Boolean): Boolean;

  function get(var v: Word; c: SOChar): Boolean; {$IFDEF HAVE_INLINE} inline; {$ENDIF}
  begin
    if (c < #256) and (AnsiChar(c) in ['0' .. '9']) then
    begin
      Result := True;
      v := v * 10 + Ord(c) - Ord('0');
    end
    else
      Result := False;
  end;

type
  TState = (stStart, stYear, stMonth, stWeek, stWeekDay, stDay, stDayOfYear,
    stHour, stMin, stSec, stMs, stUTC, stGMTH, stGMTM, stGMTend, stEnd);
  TPerhaps = (yes, no, perhaps);
var
  p: PSOChar;
  sep: TPerhaps;
  state: TState;
  pos, v: Word;
  inctz: Boolean;
  st1: TSuperSystemTime absolute st;
label
  error;
begin
  p := PSOChar(ISO8601Date);
  sep := perhaps;
  state := stStart;
  pos := 0;
  inctz := False;

  FillChar(st, SizeOf(st), 0);
  dayofyear := 0;
  week := 0;
  bias := 0;
  havedate := True;
  havetz := False;

  while True do
    case state of
      stStart:
        case p^ of
          '0' .. '9':
            state := stYear;
          'T', 't':
            begin
              state := stHour;
              pos := 0;
              Inc(p);
              havedate := False;
            end;
        else
          goto error;
        end;
      stYear:
        case pos of
          0 .. 1, 3:
            if get(st1.Year, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else
              goto error;
          2:
            case p^ of
              '0' .. '9':
                begin
                  st1.Year := st1.Year * 10 + Ord(p^) - Ord('0');
                  Inc(pos);
                  Inc(p);
                end;
              ':':
                begin
                  havedate := False;
                  st1.Hour := st1.Year;
                  st1.Year := 0;
                  Inc(p);
                  pos := 0;
                  state := stMin;
                  sep := yes;
                end;
            else
              goto error;
            end;
          4:
            case p^ of
              '-':
                begin
                  pos := 0;
                  Inc(p);
                  sep := yes;
                  state := stMonth;
                end;
              '0' .. '9':
                begin
                  sep := no;
                  pos := 0;
                  state := stMonth;
                end;
              'W', 'w':
                begin
                  pos := 0;
                  Inc(p);
                  state := stWeek;
                end;
              'T', 't', ' ':
                begin
                  state := stHour;
                  pos := 0;
                  Inc(p);
                  st1.Month := 1;
                  st1.Day := 1;
                end;
              #0:
                begin
                  st1.Month := 1;
                  st1.Day := 1;
                  state := stEnd;
                end;
            else
              goto error;
            end;
        end;
      stMonth:
        case pos of
          0:
            case p^ of
              '0' .. '9':
                begin
                  st1.Month := Ord(p^) - Ord('0');
                  Inc(pos);
                  Inc(p);
                end;
              'W', 'w':
                begin
                  pos := 0;
                  Inc(p);
                  state := stWeek;
                end;
            else
              goto error;
            end;
          1:
            if get(st1.Month, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else
              goto error;
          2:
            case p^ of
              '-':
                if (sep in [yes, perhaps]) then
                begin
                  pos := 0;
                  Inc(p);
                  state := stDay;
                  sep := yes;
                end
                else
                  goto error;
              '0' .. '9':
                if sep in [no, perhaps] then
                begin
                  pos := 0;
                  state := stDay;
                  sep := no;
                end
                else
                begin
                  dayofyear := st1.Month * 10 + Ord(p^) - Ord('0');
                  st1.Month := 0;
                  Inc(p);
                  pos := 3;
                  state := stDayOfYear;
                end;
              'T', 't', ' ':
                begin
                  state := stHour;
                  pos := 0;
                  Inc(p);
                  st1.Day := 1;
                end;
              #0:
                begin
                  st1.Day := 1;
                  state := stEnd;
                end;
            else
              goto error;
            end;
        end;
      stDay:
        case pos of
          0:
            if get(st1.Day, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else
              goto error;
          1:
            if get(st1.Day, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else if sep in [no, perhaps] then
            begin
              dayofyear := st1.Month * 10 + st1.Day;
              st1.Day := 0;
              st1.Month := 0;
              state := stDayOfYear;
            end
            else
              goto error;
          2:
            case p^ of
              'T', 't', ' ':
                begin
                  pos := 0;
                  Inc(p);
                  state := stHour;
                end;
              #0:
                state := stEnd;
            else
              goto error;
            end;
        end;
      stDayOfYear:
        begin
          if (dayofyear <= 0) then
            goto error;
          case p^ of
            'T', 't', ' ':
              begin
                pos := 0;
                Inc(p);
                state := stHour;
              end;
            #0:
              state := stEnd;
          else
            goto error;
          end;
        end;
      stWeek:
        begin
          case pos of
            0 .. 1:
              if get(week, p^) then
              begin
                Inc(pos);
                Inc(p);
              end
              else
                goto error;
            2:
              case p^ of
                '-':
                  if (sep in [yes, perhaps]) then
                  begin
                    Inc(p);
                    state := stWeekDay;
                    sep := yes;
                  end
                  else
                    goto error;
                '1' .. '7':
                  if sep in [no, perhaps] then
                  begin
                    state := stWeekDay;
                    sep := no;
                  end
                  else
                    goto error;
              else
                goto error;
              end;
          end;
        end;
      stWeekDay:
        begin
          if (week > 0) and get(st1.DayOfWeek, p^) then
          begin
            Inc(p);
            v := st1.Year - 1;
            v := ((v * 365) + (v div 4) - (v div 100) + (v div 400)) mod 7 + 1;
            dayofyear := (st1.DayOfWeek - v) + ((week) * 7) + 1;
            if v <= 4 then
              Dec(dayofyear, 7);
            case p^ of
              'T', 't', ' ':
                begin
                  pos := 0;
                  Inc(p);
                  state := stHour;
                end;
              #0:
                state := stEnd;
            else
              goto error;
            end;
          end
          else
            goto error;
        end;
      stHour:
        case pos of
          0:
            case p^ of
              '0' .. '9':
                if get(st1.Hour, p^) then
                begin
                  Inc(pos);
                  Inc(p);
                end
                else
                  goto error;
              '-':
                begin
                  Inc(p);
                  state := stMin;
                end;
            else
              goto error;
            end;
          1:
            if get(st1.Hour, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else
              goto error;
          2:
            case p^ of
              ':':
                if sep in [yes, perhaps] then
                begin
                  sep := yes;
                  pos := 0;
                  Inc(p);
                  state := stMin;
                end
                else
                  goto error;
              ',', '.':
                begin
                  Inc(p);
                  state := stMs;
                end;
              '+':
                if havedate then
                begin
                  state := stGMTH;
                  pos := 0;
                  v := 0;
                  Inc(p);
                end
                else
                  goto error;
              '-':
                if havedate then
                begin
                  state := stGMTH;
                  pos := 0;
                  v := 0;
                  Inc(p);
                  inctz := True;
                end
                else
                  goto error;
              'Z', 'z':
                if havedate then
                  state := stUTC
                else
                  goto error;
              '0' .. '9':
                if sep in [no, perhaps] then
                begin
                  pos := 0;
                  state := stMin;
                  sep := no;
                end
                else
                  goto error;
              #0:
                state := stEnd;
            else
              goto error;
            end;
        end;
      stMin:
        case pos of
          0:
            case p^ of
              '0' .. '9':
                if get(st1.Minute, p^) then
                begin
                  Inc(pos);
                  Inc(p);
                end
                else
                  goto error;
              '-':
                begin
                  Inc(p);
                  state := stSec;
                end;
            else
              goto error;
            end;
          1:
            if get(st1.Minute, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else
              goto error;
          2:
            case p^ of
              ':':
                if sep in [yes, perhaps] then
                begin
                  pos := 0;
                  Inc(p);
                  state := stSec;
                  sep := yes;
                end
                else
                  goto error;
              ',', '.':
                begin
                  Inc(p);
                  state := stMs;
                end;
              '+':
                if havedate then
                begin
                  state := stGMTH;
                  pos := 0;
                  v := 0;
                  Inc(p);
                end
                else
                  goto error;
              '-':
                if havedate then
                begin
                  state := stGMTH;
                  pos := 0;
                  v := 0;
                  Inc(p);
                  inctz := True;
                end
                else
                  goto error;
              'Z', 'z':
                if havedate then
                  state := stUTC
                else
                  goto error;
              '0' .. '9':
                if sep in [no, perhaps] then
                begin
                  pos := 0;
                  state := stSec;
                end
                else
                  goto error;
              #0:
                state := stEnd;
            else
              goto error;
            end;
        end;
      stSec:
        case pos of
          0 .. 1:
            if get(st1.Second, p^) then
            begin
              Inc(pos);
              Inc(p);
            end
            else
              goto error;
          2:
            case p^ of
              ',', '.':
                begin
                  Inc(p);
                  state := stMs;
                end;
              '+':
                if havedate then
                begin
                  state := stGMTH;
                  pos := 0;
                  v := 0;
                  Inc(p);
                end
                else
                  goto error;
              '-':
                if havedate then
                begin
                  state := stGMTH;
                  pos := 0;
                  v := 0;
                  Inc(p);
                  inctz := True;
                end
                else
                  goto error;
              'Z', 'z':
                if havedate then
                  state := stUTC
                else
                  goto error;
              #0:
                state := stEnd;
            else
              goto error;
            end;
        end;
      stMs:
        case p^ of
          '0' .. '9':
            begin
              st1.MilliSecond := st1.MilliSecond * 10 + Ord(p^) - Ord('0');
              Inc(p);
            end;
          '+':
            if havedate then
            begin
              state := stGMTH;
              pos := 0;
              v := 0;
              Inc(p);
            end
            else
              goto error;
          '-':
            if havedate then
            begin
              state := stGMTH;
              pos := 0;
              v := 0;
              Inc(p);
              inctz := True;
            end
            else
              goto error;
          'Z', 'z':
            if havedate then
              state := stUTC
            else
              goto error;
          #0:
            state := stEnd;
        else
          goto error;
        end;
      stUTC: // = GMT 0
        begin
          havetz := True;
          Inc(p);
          if p^ = #0 then
            Break
          else
            goto error;
        end;
      stGMTH:
        begin
          havetz := True;
          case pos of
            0 .. 1:
              if get(v, p^) then
              begin
                Inc(p);
                Inc(pos);
              end
              else
                goto error;
            2:
              begin
                bias := v * 60;
                case p^ of
                  ':': // if sep in [yes, perhaps] then
                    begin
                      state := stGMTM;
                      Inc(p);
                      pos := 0;
                      v := 0;
                      sep := yes;
                    end; // else goto error;
                  '0' .. '9':
                    // if sep in [no, perhaps] then
                    begin
                      state := stGMTM;
                      pos := 1;
                      sep := no;
                      Inc(p);
                      v := Ord(p^) - Ord('0');
                    end; // else goto error;
                  #0:
                    state := stGMTend;
                else
                  goto error;
                end;

              end;
          end;
        end;
      stGMTM:
        case pos of
          0 .. 1:
            if get(v, p^) then
            begin
              Inc(p);
              Inc(pos);
            end
            else
              goto error;
          2:
            case p^ of
              #0:
                begin
                  state := stGMTend;
                  Inc(bias, v);
                end;
            else
              goto error;
            end;
        end;
      stGMTend:
        begin
          if not inctz then
            bias := -bias;
          Break;
        end;
      stEnd:
        begin

          Break;
        end;
    end;

  if (st1.Hour >= 24) or (st1.Minute >= 60) or (st1.Second >= 60) or
    (st1.MilliSecond >= 1000) or (week > 53) then
    goto error;

  Result := True;
  Exit;
error:
  Result := False;
end;

{$IFNDEF FPC}
{ TSuperTimeZone.TExpirable<T> }

class function TSuperTimeZone.TExpirable<T>.Box(Data: T): TExpirable<T>;
begin
  Result.Data := Data;
  Result.Timestamp := Now;
end;

function TSuperTimeZone.TExpirable<T>.IsValid: Boolean;
begin
  Result := Trunc(Self.Timestamp) = Trunc(Now);
end;
{$ENDIF}

end.
