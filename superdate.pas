unit superdate;

{$IFDEF FPC}
  {$MODE OBJFPC}{$H+}
{$ENDIF}

interface
uses
  supertypes;

function JavaToDelphiDateTime(const dt: Int64): TDateTime;
function DelphiToJavaDateTime(const dt: TDateTime): Int64;

function DelphiDateTimeToISO8601Date(dt: TDateTime): SOString;

function ISO8601DateToJavaDateTime(const str: SOString; var ms: Int64): Boolean;
function ISO8601DateToDelphiDateTime(const str: SOString; var dt: TDateTime): Boolean;

implementation

uses
  Windows, Registry, SysUtils, DateUtils, Math;

function GetTimeZoneInformationForYear(Year: Word; Dummy: Pointer; var TimeZoneInformation: TTimeZoneInformation): Boolean;
type
  TRegistryTZI = packed record
    Bias: LongInt;
    StandardBias: LongInt;
    DaylightBias: LongInt;
    StandardChangeTime: TSystemTime;
    DaylightChangeTime: TSystemTime;
  end;
var
  tzi: TRegistryTZI;
  ChangeYear: Word;
  LocalTimeZone: string;
const
  TZ_KEY = '\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones\';
begin
  FillChar(TimeZoneInformation, SizeOf(TimeZoneInformation), 0);
  with TRegistry.Create do
  try
    RootKey := HKEY_LOCAL_MACHINE;

    if OpenKeyReadOnly('\SYSTEM\CurrentControlSet\Control\TimeZoneInformation') then
      LocalTimeZone := Trim(ReadString('TimeZoneKeyName'))
    else
    begin
      Result := False;
      Exit;
    end;

    if KeyExists(TZ_KEY + LocalTimeZone) then
    begin
      ChangeYear := 0;
      if OpenKeyReadOnly(TZ_KEY + LocalTimeZone + '\Dynamic DST') then
      try
        ChangeYear := Year;
        if Year < ReadInteger('FirstEntry') then
          ChangeYear := ReadInteger('FirstEntry')
        else if Year > ReadInteger('LastEntry') then
          ChangeYear := ReadInteger('LastEntry');

        while (not ValueExists(IntToStr(ChangeYear))) and (ChangeYear > 0) do
          Dec(ChangeYear);

        if ChangeYear > 0 then
          ReadBinaryData(IntToStr(ChangeYear), tzi, SizeOf(TRegistryTZI));
      finally
        CloseKey;
      end;

      if (ChangeYear = 0) and OpenKeyReadOnly(TZ_KEY + LocalTimeZone) then
      try
        ReadBinaryData('TZI', tzi, SizeOf(TRegistryTZI));
      finally
        CloseKey;
      end;

      TimeZoneInformation.Bias         := tzi.Bias;
      TimeZoneInformation.StandardDate := tzi.StandardChangeTime;
      TimeZoneInformation.StandardBias := tzi.StandardBias;
      TimeZoneInformation.DaylightDate := tzi.DaylightChangeTime;
      TimeZoneInformation.DaylightBias := tzi.DaylightBias;

      Result := True;
    end
    else
      Result := False;
  finally
    Free;
  end;
end;

function DayLightCompareDate(const date: PSystemTime;
  const compareDate: PSystemTime): Integer;
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
      dec(limit_day, 7);
  end
  else
    limit_day := compareDate^.wDay;

  (* convert to seconds *)
  limit_day := ((limit_day * 24  + compareDate^.wHour) * 60 + compareDate^.wMinute ) * 60;
  dayinsecs := ((date^.wDay * 24  + date^.wHour) * 60 + date^.wMinute ) * 60 + date^.wSecond;
  (* and compare *)

  if dayinsecs < limit_day then
    Result :=  -1 else
    if dayinsecs > limit_day then
      Result :=  1 else
      Result :=  0; (* date is equal to the date limit. *)
end;

function CompTimeZoneID(const pTZinfo: PTimeZoneInformation;
  lpFileTime: PFileTime; islocal: Boolean): LongWord;
var
  ret: Integer;
  beforeStandardDate, afterDaylightDate: Boolean;
  llTime: Int64;
  SysTime: TSystemTime;
  ftTemp: TFileTime;
begin
  llTime := 0;

  if (pTZinfo^.DaylightDate.wMonth <> 0) then
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

    if (not islocal) then
    begin
      llTime := PInt64(lpFileTime)^;
      dec(llTime, Int64(pTZinfo^.Bias + pTZinfo^.DaylightBias) * 600000000);
      PInt64(@ftTemp)^ := llTime;
      lpFileTime := @ftTemp;
    end;

    FileTimeToSystemTime(lpFileTime^, SysTime);

    (* check for daylight savings *)
    ret := DayLightCompareDate(@SysTime, @pTZinfo^.StandardDate);
    if (ret = -2) then
    begin
      Result := TIME_ZONE_ID_INVALID;
      Exit;
    end;

    beforeStandardDate := ret < 0;

    if (not islocal) then
    begin
      dec(llTime, Int64(pTZinfo^.StandardBias - pTZinfo^.DaylightBias) * 600000000);
      PInt64(@ftTemp)^ := llTime;
      FileTimeToSystemTime(lpFileTime^, SysTime);
    end;

    ret := DayLightCompareDate(@SysTime, @pTZinfo^.DaylightDate);
    if (ret = -2) then
    begin
      Result := TIME_ZONE_ID_INVALID;
      Exit;
    end;

    afterDaylightDate := ret >= 0;

    Result := TIME_ZONE_ID_STANDARD;
    if( pTZinfo^.DaylightDate.wMonth < pTZinfo^.StandardDate.wMonth ) then
    begin
      (* Northern hemisphere *)
      if( beforeStandardDate and afterDaylightDate) then
        Result := TIME_ZONE_ID_DAYLIGHT;
    end else    (* Down south *)
      if( beforeStandardDate or afterDaylightDate) then
        Result := TIME_ZONE_ID_DAYLIGHT;
  end else
    (* No transition date *)
    Result := TIME_ZONE_ID_UNKNOWN;
end;

function GetTimezoneBias(const pTZinfo: PTimeZoneInformation;
  lpFileTime: PFileTime; islocal: Boolean; pBias: PLongint): Boolean;
var
  bias: LongInt;
  tzid: LongWord;
begin
  bias := pTZinfo^.Bias;
  tzid := CompTimeZoneID(pTZinfo, lpFileTime, islocal);

  if( tzid = TIME_ZONE_ID_INVALID) then
  begin
    Result := False;
    Exit;
  end;
  if (tzid = TIME_ZONE_ID_DAYLIGHT) then
    inc(bias, pTZinfo^.DaylightBias)
  else if (tzid = TIME_ZONE_ID_STANDARD) then
    inc(bias, pTZinfo^.StandardBias);
  pBias^ := bias;
  Result := True;
end;

function SystemTimeToTzSpecificLocalTime(
  lpTimeZoneInformation: PTimeZoneInformation;
  lpUniversalTime, lpLocalTime: PSystemTime): BOOL;
var
  ft: TFileTime;
  lBias: LongInt;
  llTime: Int64;
  tzinfo: TTimeZoneInformation;
begin
  if (lpTimeZoneInformation <> nil) then
    tzinfo := lpTimeZoneInformation^ else
    if not GetTimeZoneInformationForYear(lpUniversalTime^.wYear, nil, tzinfo) then
    begin
      Result := False;
      Exit;
    end;

  if (not SystemTimeToFileTime(lpUniversalTime^, ft)) then
  begin
    Result := False;
    Exit;
  end;
  llTime := PInt64(@ft)^;
  if (not GetTimezoneBias(@tzinfo, @ft, False, @lBias)) then
  begin
    Result := False;
    Exit;
  end;
  (* convert minutes to 100-nanoseconds-ticks *)
  dec(llTime, Int64(lBias) * 600000000);
  PInt64(@ft)^ := llTime;
  Result := FileTimeToSystemTime(ft, lpLocalTime^);
end;

function TzSpecificLocalTimeToSystemTime(
    const lpTimeZoneInformation: PTimeZoneInformation;
    const lpLocalTime: PSystemTime; lpUniversalTime: PSystemTime): BOOL;
var
  ft: TFileTime;
  lBias: LongInt;
  t: Int64;
  tzinfo: TTimeZoneInformation;
begin
  if (lpTimeZoneInformation <> nil) then
    tzinfo := lpTimeZoneInformation^
  else
    if not GetTimeZoneInformationForYear(lpLocalTime^.wYear, nil, tzinfo) then
    begin
      Result := False;
      Exit;
    end;

  if (not SystemTimeToFileTime(lpLocalTime^, ft)) then
  begin
    Result := False;
    Exit;
  end;
  t := PInt64(@ft)^;
  if (not GetTimezoneBias(@tzinfo, @ft, True, @lBias)) then
  begin
    Result := False;
    Exit;
  end;
  (* convert minutes to 100-nanoseconds-ticks *)
  inc(t, Int64(lBias) * 600000000);
  PInt64(@ft)^ := t;
  Result := FileTimeToSystemTime(ft, lpUniversalTime^);
end;

function JavaToDelphiDateTime(const dt: Int64): TDateTime;
var
  utc, local: TSystemTime;
  tzi: TTimeZoneInformation;
begin
  DateTimeToSystemTime(25569 + (dt / 86400000), utc);
  if GetTimeZoneInformationForYear(utc.wYear, nil, tzi) and
     SystemTimeToTzSpecificLocalTime(@tzi, @utc, @local) then
    Result := SystemTimeToDateTime(local)
  else
    Result := SystemTimeToDateTime(utc);
end;

function DelphiToJavaDateTime(const dt: TDateTime): Int64;
var
  local, utc, st: TSystemTime;
  tzi: TTimeZoneInformation;
begin
  DateTimeToSystemTime(dt, local);
  if GetTimeZoneInformationForYear(local.wYear, nil, tzi) and
     TzSpecificLocalTimeToSystemTime(@tzi, @local, @utc) then
    st := utc
  else
    st := local;
  Result := Round((SystemTimeToDateTime(st) - 25569) * 86400000);
end;

function DelphiDateTimeToISO8601Date(dt: TDateTime): SOString;
const
  Signs: array[TValueSign] of String = ('', '', '+');
var
  local, utc: TSystemTime;
  tzi: TTimeZoneInformation;
  bias: TDateTime;
  h, m, d: Word;
begin
  DateTimeToSystemTime(dt, local);
  if GetTimeZoneInformationForYear(local.wYear, nil, tzi) and
    TzSpecificLocalTimeToSystemTime(@tzi, @local, @utc) then
  begin
    Bias := SystemTimeToDateTime(local) - SystemTimeToDateTime(utc);
    DecodeTime(Bias, h, m, d, d);
    Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%d%s%.2d:%.2d', [
      local.wYear, local.wMonth, local.wDay,
      local.wHour, local.wMinute, local.wSecond, local.wMilliseconds,
      Signs[Sign(h)], h, m
    ]);
  end
  else
    Result := Format('%.4d-%.2d-%.2dT%.2d:%.2d:%.2d.%d', [
      local.wYear, local.wMonth, local.wDay,
      local.wHour, local.wMinute, local.wSecond, local.wMilliseconds
    ]);
end;

{ iso -> java }

function ISO8601DateToJavaDateTime(const str: SOString; var ms: Int64): Boolean;
type
  TState = (
    stStart, stYear, stMonth, stWeek, stWeekDay, stDay, stDayOfYear,
    stHour, stMin, stSec, stMs, stUTC, stGMTH, stGMTM,
    stGMTend, stEnd);
  TPerhaps = (yes, no, perhaps);
var
  p: PSOChar;
  state: TState;
  pos, v: Word;
  sep: TPerhaps;
  inctz, havetz, havedate: Boolean;
  st: TSystemTime;
  dayofyear: Integer;
  week: Word;
  bias: Integer;
  DayTable: PDayTable;
  tzi: TTimeZoneInformation;
  utc: TSystemTime;

  function get(var v: Word; c: SOChar): Boolean; {$IFDEF HAVE_INLINE} inline;{$ENDIF}
  begin
    if (c < #256) and (AnsiChar(c) in ['0'..'9']) then
    begin
      Result := True;
      v := v * 10 + Ord(c) - Ord('0');
    end else
      Result := False;
  end;

label
  error;
begin
  p := PSOChar(str);
  sep := perhaps;
  state := stStart;
  pos := 0;
  FillChar(st, SizeOf(st), 0);
  dayofyear := 0;
  bias := 0;
  week := 0;
  havedate := True;
  inctz := False;
  havetz := False;

  while true do
  case state of
    stStart:
      case p^ of
        '0'..'9': state := stYear;
        'T', 't':
          begin
            state := stHour;
            pos := 0;
            inc(p);
            havedate := False;
          end;
      else
        goto error;
      end;
    stYear:
      case pos of
        0..1,3:
              if get(st.wYear, p^) then
              begin
                Inc(pos);
                Inc(p);
              end else
                goto error;
        2:    case p^ of
                '0'..'9':
                  begin
                    st.wYear := st.wYear * 10 + ord(p^) - ord('0');
                    Inc(pos);
                    Inc(p);
                  end;
                ':':
                  begin
                    havedate := false;
                    st.wHour := st.wYear;
                    st.wYear := 0;
                    inc(p);
                    pos := 0;
                    state := stMin;
                    sep := yes;
                  end;
              else
                goto error;
              end;
        4: case p^ of
             '-': begin
                    pos := 0;
                    Inc(p);
                    sep := yes;
                    state := stMonth;
                  end;
             '0'..'9':
                  begin
                    sep := no;
                    pos := 0;
                    state := stMonth;
                  end;
             'W', 'w' :
                  begin
                    pos := 0;
                    Inc(p);
                    state := stWeek;
                  end;
             'T', 't', ' ':
                  begin
                    state := stHour;
                    pos := 0;
                    inc(p);
                    st.wMonth := 1;
                    st.wDay := 1;
                  end;
             #0:
                  begin
                    st.wMonth := 1;
                    st.wDay := 1;
                    state := stEnd;
                  end;
           else
             goto error;
           end;
      end;
    stMonth:
      case pos of
        0:  case p^ of
              '0'..'9':
                begin
                  st.wMonth := ord(p^) - ord('0');
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
        1:  if get(st.wMonth, p^) then
            begin
              Inc(pos);
              Inc(p);
            end else
              goto error;
        2: case p^ of
             '-':
                  if (sep in [yes, perhaps])  then
                  begin
                    pos := 0;
                    Inc(p);
                    state := stDay;
                    sep := yes;
                  end else
                    goto error;
             '0'..'9':
                  if sep in [no, perhaps] then
                  begin
                    pos := 0;
                    state := stDay;
                    sep := no;
                  end else
                  begin
                    dayofyear := st.wMonth * 10 + Ord(p^) - Ord('0');
                    st.wMonth := 0;
                    inc(p);
                    pos := 3;
                    state := stDayOfYear;
                  end;
             'T', 't', ' ':
                  begin
                    state := stHour;
                    pos := 0;
                    inc(p);
                    st.wDay := 1;
                 end;
             #0:
               begin
                 st.wDay := 1;
                 state := stEnd;
               end;
           else
             goto error;
           end;
      end;
    stDay:
      case pos of
        0:  if get(st.wDay, p^) then
            begin
              Inc(pos);
              Inc(p);
            end else
              goto error;
        1:  if get(st.wDay, p^) then
            begin
              Inc(pos);
              Inc(p);
            end else
            if sep in [no, perhaps] then
            begin
              dayofyear := st.wMonth * 10 + st.wDay;
              st.wDay := 0;
              st.wMonth := 0;
              state := stDayOfYear;
            end else
              goto error;

        2: case p^ of
             'T', 't', ' ':
                  begin
                    pos := 0;
                    Inc(p);
                    state := stHour;
                  end;
             #0:  state := stEnd;
           else
             goto error;
           end;
      end;
    stDayOfYear:
      begin
        if (dayofyear <= 0) then goto error;
        case p^ of
          'T', 't', ' ':
               begin
                 pos := 0;
                 Inc(p);
                 state := stHour;
               end;
          #0:  state := stEnd;
        else
          goto error;
        end;
      end;
    stWeek:
      begin
        case pos of
          0..1: if get(week, p^) then
                begin
                  inc(pos);
                  inc(p);
                end else
                  goto error;
          2: case p^ of
               '-': if (sep in [yes, perhaps]) then
                    begin
                      Inc(p);
                      state := stWeekDay;
                      sep := yes;
                    end else
                      goto error;
               '1'..'7':
                    if sep in [no, perhaps] then
                    begin
                      state := stWeekDay;
                      sep := no;
                    end else
                      goto error;
             else
               goto error;
             end;
        end;
      end;
    stWeekDay:
      begin
        if (week > 0) and get(st.wDayOfWeek, p^) then
        begin
          inc(p);
          v := st.wYear - 1;
          v := ((v * 365) + (v div 4) - (v div 100) + (v div 400)) mod 7 + 1;
          dayofyear := (st.wDayOfWeek - v) + ((week) * 7) + 1;
          if v <= 4 then dec(dayofyear, 7);
          case p^ of
            'T', 't', ' ':
                 begin
                   pos := 0;
                   Inc(p);
                   state := stHour;
                 end;
            #0:  state := stEnd;
          else
            goto error;
          end;
        end else
          goto error;
      end;
    stHour:
      case pos of
        0:    case p^ of
                '0'..'9':
                    if get(st.wHour, p^) then
                    begin
                      inc(pos);
                      inc(p);
                      end else
                        goto error;
                '-':
                  begin
                    inc(p);
                    state := stMin;
                  end;
              else
                goto error;
              end;
        1:    if get(st.wHour, p^) then
              begin
                inc(pos);
                inc(p);
              end else
                goto error;
        2: case p^ of
             ':': if sep in [yes, perhaps] then
                  begin
                    sep := yes;
                    pos := 0;
                    Inc(p);
                    state := stMin;
                  end else
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
                 inc(p);
               end else
                 goto error;
             '-':
               if havedate then
               begin
                 state := stGMTH;
                 pos := 0;
                 v := 0;
                 inc(p);
                 inctz := True;
               end else
                 goto error;
             'Z', 'z':
                  if havedate then
                    state := stUTC else
                    goto error;
             '0'..'9':
                  if sep in [no, perhaps] then
                  begin
                    pos := 0;
                    state := stMin;
                    sep := no;
                  end else
                    goto error;
             #0:  state := stEnd;
           else
             goto error;
           end;
      end;
    stMin:
      case pos of
        0: case p^ of
             '0'..'9':
                if get(st.wMinute, p^) then
                begin
                  inc(pos);
                  inc(p);
                end else
                  goto error;
             '-':
                begin
                  inc(p);
                  state := stSec;
                end;
           else
             goto error;
           end;
        1: if get(st.wMinute, p^) then
           begin
             inc(pos);
             inc(p);
           end else
             goto error;
        2: case p^ of
             ':': if sep in [yes, perhaps] then
                  begin
                    pos := 0;
                    Inc(p);
                    state := stSec;
                    sep := yes;
                  end else
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
                 inc(p);
               end else
                 goto error;
             '-':
               if havedate then
               begin
                 state := stGMTH;
                 pos := 0;
                 v := 0;
                 inc(p);
                 inctz := True;
               end else
                 goto error;
             'Z', 'z':
                  if havedate then
                    state := stUTC else
                    goto error;
             '0'..'9':
                  if sep in [no, perhaps] then
                  begin
                    pos := 0;
                    state := stSec;
                  end else
                    goto error;
             #0:  state := stEnd;
           else
             goto error;
           end;
      end;
    stSec:
      case pos of
        0..1: if get(st.wSecond, p^) then
              begin
                inc(pos);
                inc(p);
              end else
                goto error;
        2:    case p^ of
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
                   inc(p);
                 end else
                   goto error;
               '-':
                 if havedate then
                 begin
                   state := stGMTH;
                   pos := 0;
                   v := 0;
                   inc(p);
                   inctz := True;
                 end else
                   goto error;
               'Z', 'z':
                    if havedate then
                      state := stUTC else
                      goto error;
               #0: state := stEnd;
              else
               goto error;
              end;
      end;
    stMs:
      case p^ of
        '0'..'9':
        begin
          st.wMilliseconds := st.wMilliseconds * 10 + ord(p^) - ord('0');
          inc(p);
        end;
        '+':
          if havedate then
          begin
            state := stGMTH;
            pos := 0;
            v := 0;
            inc(p);
          end else
            goto error;
        '-':
          if havedate then
          begin
            state := stGMTH;
            pos := 0;
            v := 0;
            inc(p);
            inctz := True;
          end else
            goto error;
        'Z', 'z':
             if havedate then
               state := stUTC else
               goto error;
        #0: state := stEnd;
      else
        goto error;
      end;
    stUTC: // = GMT 0
      begin
        havetz := True;
        inc(p);
        if p^ = #0 then
          Break else
          goto error;
      end;
    stGMTH:
      begin
        havetz := True;
        case pos of
          0..1: if get(v, p^) then
                begin
                  inc(p);
                  inc(pos);
                end else
                  goto error;
          2:
            begin
              bias := v * 60;
              case p^ of
                ':': if sep in [yes, perhaps] then
                     begin
                       state := stGMTM;
                       inc(p);
                       pos := 0;
                       v := 0;
                       sep := yes;
                     end else
                       goto error;
                '0'..'9':
                     if sep in [no, perhaps] then
                     begin
                       state := stGMTM;
                       pos := 1;
                       sep := no;
                       inc(p);
                       v := ord(p^) - ord('0');
                     end else
                       goto error;
                #0: state := stGMTend;
              else
                goto error;
              end;

            end;
        end;
      end;
    stGMTM:
      case pos of
        0..1:  if get(v, p^) then
               begin
                 inc(p);
                 inc(pos);
               end else
                 goto error;
        2:  case p^ of
              #0:
                begin
                  state := stGMTend;
                  inc(bias, v);
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

  if (st.wHour >= 24) or (st.wMinute >= 60) or (st.wSecond >= 60) or (st.wMilliseconds >= 1000) or (week > 53)
    then goto error;

  if not havetz then
  begin
    if GetTimeZoneInformationForYear(st.wYear, nil, tzi) and
      TzSpecificLocalTimeToSystemTime(@tzi, @st, @utc) then
      bias := Trunc((SystemTimeToDateTime(st) - SystemTimeToDateTime(utc)) * MinsPerDay);
  end;

  ms := st.wMilliseconds + st.wSecond * 1000 + (st.wMinute + bias) * 60000 + st.wHour * 3600000;
  if havedate then
  begin
    DayTable := @MonthDays[IsLeapYear(st.wYear)];
    if st.wMonth <> 0 then
    begin
      if not (st.wMonth in [1..12]) or (DayTable^[st.wMonth] < st.wDay) then
        goto error;

      for v := 1 to  st.wMonth - 1 do
        Inc(ms, Int64(DayTable^[v]) * 86400000);
    end;
    dec(st.wYear);

    Inc(ms, (Int64((st.wYear * 365) + (st.wYear div 4) - (st.wYear div 100) + (st.wYear div 400) +
      st.wDay + dayofyear - 719163) * 86400000));
  end;

 Result := True;
 Exit;
error:
  Result := False;
end;

function ISO8601DateToDelphiDateTime(const str: SOString; var dt: TDateTime): Boolean;
var
  ms: Int64;
begin
  Result := ISO8601DateToJavaDateTime(str, ms);
  if Result then
    dt := JavaToDelphiDateTime(ms)
end;

end.
