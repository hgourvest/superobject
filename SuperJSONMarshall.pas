unit SuperJSONMarshall;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  SuperObject,
  TypInfo,
  IntfInfo;

type


  TAccessStyle = (asFieldData, asAccessor, asIndexedAccessor);

  TSuperJSONMarshall = class
  private
   class function GetDynArrayLength(P: Pointer): Integer;
   class procedure SetDynArrayProp(Instance: TObject;PropInfo: PPropInfo; const Value: Pointer);
   class function GetDynArrayProp(Instance: TObject; PropInfo: PPropInfo): Pointer;
   class function GetAccessToProperty(Instance: TObject; PropInfo: PPropInfo;
     AccessorProc: Longint; out FieldData: Pointer;out Accessor: TMethod): TAccessStyle;
  private
    // Serialize methods 
    class procedure SerializeByteArray(const ASuperArray : TSuperArray;
                                       const ADynArrayLowBound:Pointer);

    class procedure SerializeBoolArray(const ASuperArray : TSuperArray;
                                       const ADynArrayLowBound:Pointer);

    class procedure SerializeIntArray( const ASuperArray : TSuperArray;
                                       const ADynArrayLowBound:Pointer);

    class procedure SerializeInt64Array(const ASuperArray : TSuperArray;
                                        const ADynArrayLowBound:Pointer);

    class procedure SerializeFloatArray(const ASuperArray : TSuperArray;
                                       const ADynArrayLowBound:Pointer);

    class procedure SerializeStringArray(const ASuperArray : TSuperArray;
                                         const ADynArrayLowBound:Pointer);

    class procedure SerializeWStringArray(const ASuperArray : TSuperArray;
                                          const ADynArrayLowBound:Pointer);

    class procedure SerializeClassArray(const ASuperArray : TSuperArray;
                                        const ADynArrayLowBound:Pointer);
  private
   // De-Serizalie methods
   class procedure DeSerializeByteArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeBoolArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeIntArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeInt64Array(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeFloatArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeStringArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeWStringArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);

   class procedure DeSerializeClassArray(const ASuperArray:TSuperArray;
                                        const AObject:TObject;
                                        const APropInfo:PPropInfo);
  private
    class function GetObjectClassFromTypeInfo(ATypeInfo: PTypeInfo) : TClass;
  private
    class procedure SerializeDynamicArray(const ADynArrayLowBound : Pointer;
                                          const ASuperObject: ISuperObject;
                                          const APropInfo: PPropInfo);

    class procedure DeSerializeDynamicArray(const ASuperArray:TSuperArray;
                                            const AObject:TObject;
                                            const APropInfo:PPropInfo);
                                            
  private
    class function DeSerializeObject(const AObject: TObject; const ASuperObject: ISuperObject):TObject;
    class function SerializeObject(const AObject:TObject; ASuperObject:ISuperObject):ISuperObject;
  public
    class function Serialize(const AObject:TObject):string;
    class function DeSerialize(const AClass: TClass; const AJson: string):TObject;
  end;

  TArrayOfObject = array of TObject;

function ArrayToJson(const AnArray:array of Byte):string; overload;
function ArrayToJson(const AnArray:array of Boolean):string; overload;
function ArrayToJson(const AnArray:array of Integer):string;overload;
function ArrayToJson(const AnArray:array of Int64):string; overload;
function ArrayToJson(const AnArray:array of Double):string; overload;
function ArrayToJson(const AnArray:array of WideString):string; overload;
function ArrayToJson(const AnArray:array of string):string; overload;
function ArrayToJson(const AnArray:TArrayOfObject):string; overload;

function ObjectToJson(const AObject:TObject):string;
function JsonToObject(const AClassOfResultObject: TClass; const AJson: string):Pointer;


implementation

function ArrayToJson(const AnArray:array of Byte):string;
var
 ASuperObject : ISuperObject;
begin
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeByteArray(SA([]).AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:array of Boolean):string;
var
 ASuperObject : ISuperObject;
begin
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeBoolArray(SA([]).AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:array of Integer):string;
var
 ASuperObject : ISuperObject;
begin
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeIntArray(SA([]).AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:array of Int64):string;
var
 ASuperObject : ISuperObject;
begin
 ASuperObject := SA([]);
 TSuperJSONMarshall.SerializeInt64Array(ASuperObject.AsArray,@AnArray[Low(AnArray)]);
 Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:array of Double):string;
var
 ASuperObject : ISuperObject;
begin
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeFloatArray(ASuperObject.AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:array of WideString):string;
var
 ASuperObject : ISuperObject;
begin
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeWStringArray(ASuperObject.AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:array of string):string;
var
 ASuperObject : ISuperObject;
begin
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeStringArray(ASuperObject.AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;

function ArrayToJson(const AnArray:TArrayOfObject):string;
var                       
 ASuperObject : ISuperObject;
begin
  Result := EmptyStr;
  if not Assigned(AnArray) then
   Exit;
   
  ASuperObject := SA([]);
  TSuperJSONMarshall.SerializeClassArray(ASuperObject.AsArray,@AnArray[Low(AnArray)]);
  Result := ASuperObject.AsJSon();
end;


function ObjectToJson(const AObject:TObject):string;
begin
  Result := TSuperJSONMarshall.Serialize(AObject);
end;

function JsonToObject(const AClassOfResultObject: TClass; const AJson: string):Pointer;
begin
  Result := Pointer(TSuperJSONMarshall.DeSerialize(AClassOfResultObject,AJson));
end;


class function TSuperJSONMarshall.GetAccessToProperty(Instance: TObject; PropInfo: PPropInfo;
  AccessorProc: Longint; out FieldData: Pointer;out Accessor: TMethod): TAccessStyle;
begin
  if (AccessorProc and $FF000000) = $FF000000 then
  begin  // field - Getter is the field's offset in the instance data
    FieldData := Pointer(Integer(Instance) + (AccessorProc and $00FFFFFF));
    Result := asFieldData;
  end
  else
  begin

    if (AccessorProc and $FF000000) = $FE000000 then
      // virtual method  - Getter is a signed 2 byte integer VMT offset
      Accessor.Code := Pointer(PInteger(PInteger(Instance)^ + SmallInt(AccessorProc))^)
    else
      // static method - Getter is the actual address
      Accessor.Code := Pointer(AccessorProc);

    Accessor.Data := Instance;
    if PropInfo^.Index = Integer($80000000) then  // no index

      Result := asAccessor
    else
      Result := asIndexedAccessor;
  end;
end;


class function TSuperJSONMarshall.GetDynArrayProp(Instance: TObject; PropInfo: PPropInfo): Pointer;
type
  { Need a(ny) dynamic array type to force correct call setup.
    (Address of result passed in EDX) }
  TDynamicArray = array of Byte;
type
  TDynArrayGetProc = function: TDynamicArray of object;
  TDynArrayIndexedGetProc = function (Index: Integer): TDynamicArray of object;
var
  M: TMethod;
begin
  case GetAccessToProperty(Instance, PropInfo, Longint(PropInfo^.GetProc),
    Result, M) of

    asFieldData:
      Result := PPointer(Result)^;

    asAccessor:
      Result := Pointer(TDynArrayGetProc(M)());

    asIndexedAccessor:
      Result := Pointer(TDynArrayIndexedGetProc(M)(PropInfo^.Index));
  end;
end;


class procedure TSuperJSONMarshall.SetDynArrayProp(Instance: TObject;
  PropInfo: PPropInfo; const Value: Pointer);
type
  TDynArraySetProc = procedure (const Value: Pointer) of object;
  TDynArrayIndexedSetProc = procedure (Index: Integer;
                                       const Value: Pointer) of object;
var
  P: Pointer;
  M: TMethod;
begin
  case GetAccessToProperty(Instance, PropInfo, Longint(PropInfo^.SetProc), P, M) of

    asFieldData:
      asm
        MOV    ECX, PropInfo
        MOV    ECX, [ECX].TPropInfo.PropType
        MOV    ECX, [ECX]

        MOV    EAX, [P]
        MOV    EDX, Value
        CALL   System.@DynArrayAsg
      end;

    asAccessor:
      TDynArraySetProc(M)(Value);

    asIndexedAccessor:
      TDynArrayIndexedSetProc(M)(PropInfo^.Index, Value);
  end;
end;


class function TSuperJSONMarshall.GetDynArrayLength(P: Pointer): Integer;
begin
  asm
    MOV  EAX, DWORD PTR P
    CALL System.@DynArrayLength
    MOV DWORD PTR [Result], EAX
  end;
end;


class procedure TSuperJSONMarshall.SerializeByteArray(const ASuperArray : TSuperArray;
                                                      const ADynArrayLowBound:Pointer);

type
 TDynByteArray = array of Byte;
var
 I: Integer;
 ADynArray : TDynByteArray;
begin                                
  ADynArray := TDynByteArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;


class procedure TSuperJSONMarshall.SerializeBoolArray(const ASuperArray : TSuperArray;
                                                      const ADynArrayLowBound:Pointer);
type
 TDynBooleanArray = array of Boolean;
var
 I : Integer;
 ADynArray : TDynBooleanArray;
begin
  ADynArray := TDynBooleanArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;

class procedure TSuperJSONMarshall.SerializeIntArray(const ASuperArray : TSuperArray;
                                                    const ADynArrayLowBound:Pointer);
type
 TDynIntArray = array of Integer;
var
 I : Integer;
 ADynArray : TDynIntArray;
begin
  ADynArray := TDynIntArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;

class procedure TSuperJSONMarshall.SerializeInt64Array(const ASuperArray : TSuperArray;
                                                       const ADynArrayLowBound:Pointer);
type
 TDynInt64Array = array of Int64;
var
 I : Integer;
 ADynArray : TDynInt64Array;
begin
  ADynArray := TDynInt64Array(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;

class procedure TSuperJSONMarshall.SerializeFloatArray(const ASuperArray : TSuperArray;
                                                       const ADynArrayLowBound:Pointer);
type
 TDynFloatArray = array of Double;
var
 I : Integer;
 ADynArray : TDynFloatArray;
begin
  ADynArray := TDynFloatArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;


class procedure TSuperJSONMarshall.SerializeStringArray(const ASuperArray : TSuperArray;
                                                        const ADynArrayLowBound:Pointer);
type
 TDynStringArray = array of string;
var
 I :Integer;
 ADynArray : TDynStringArray;
begin
  ADynArray := TDynStringArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;

class procedure TSuperJSONMarshall.SerializeWStringArray(const ASuperArray : TSuperArray;
                                                         const ADynArrayLowBound:Pointer);
type
 TDynStringArray = array of WideString;
var
 I :Integer;
 ADynArray : TDynStringArray;
begin
  ADynArray := TDynStringArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
    ASuperArray.Add(ADynArray[I]);
end;


class procedure TSuperJSONMarshall.SerializeClassArray(const ASuperArray : TSuperArray;
                                                       const ADynArrayLowBound:Pointer);
type
 TDynObjectArray = array of TObject;
var
 AnArrayElement : TObject;
 ASuperObjectAsArrayElement: ISuperObject;

 I: Integer;
 ADynArray : TDynObjectArray;
begin
  ADynArray := TDynObjectArray(ADynArrayLowBound);
  for  I:=Low(ADynArray)  to High(ADynArray) do
  begin
     AnArrayElement := ADynArray[I];
     if Assigned(AnArrayElement) then
     begin
        ASuperObjectAsArrayElement := SerializeObject(AnArrayElement,SO());
        ASuperArray.Add(ASuperObjectAsArrayElement);
     end;
  end;
end;



class procedure TSuperJSONMarshall.DeSerializeByteArray(const ASuperArray:TSuperArray;
                                                        const AObject:TObject;
                                                        const APropInfo:PPropInfo);
type
 TDynByteArray = array of Byte;
var
 I : Integer;
 ADynArray : TDynByteArray;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
   ADynArray[I] := ASuperArray.I[I];

 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;


class procedure TSuperJSONMarshall.DeSerializeBoolArray(const ASuperArray:TSuperArray;
                                                        const AObject:TObject;
                                                        const APropInfo:PPropInfo);
type
 TDynBooleanArray = array of Boolean;
var
 I : Integer;
 ADynArray : TDynBooleanArray;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
   ADynArray[I] := ASuperArray.B[I];

 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;

class procedure TSuperJSONMarshall.DeSerializeIntArray(const ASuperArray:TSuperArray;
                                                       const AObject:TObject;
                                                       const APropInfo:PPropInfo);
type
 TDynIntegerArray = array of Integer;
var
 I : Integer;
 ADynArray : TDynIntegerArray;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
   ADynArray[I] := ASuperArray.I[I];

 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;

class procedure TSuperJSONMarshall.DeSerializeInt64Array(const ASuperArray:TSuperArray;
                                                        const AObject:TObject;
                                                        const APropInfo:PPropInfo);
type
 TDynInt64Array = array of Int64;
var
 I : Integer;
 ADynArray : TDynInt64Array;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
   ADynArray[I] := ASuperArray.I[I];

 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;


class procedure TSuperJSONMarshall.DeSerializeFloatArray(const ASuperArray:TSuperArray;
                                                         const AObject:TObject;
                                                         const APropInfo:PPropInfo);
type
 TDynFloatArray = array of Double;
var
 I : Integer;
 ADynArray : TDynFloatArray;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
 begin
   ADynArray[I] := ASuperArray.C[I];
 end;

 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;


class procedure TSuperJSONMarshall.DeSerializeStringArray(const ASuperArray:TSuperArray;
                                                          const AObject:TObject;
                                                          const APropInfo:PPropInfo);
type
 TDynStringArray = array of string;
var
 I : Integer;
 ADynArray : TDynStringArray;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
   ADynArray[I] := ASuperArray.S[I];


 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;


class procedure TSuperJSONMarshall.DeSerializeWStringArray(const ASuperArray:TSuperArray;
                                                           const AObject:TObject;
                                                           const APropInfo:PPropInfo);
type
 TDynWStringArray = array of WideString;
var
 I : Integer;
 ADynArray : TDynWStringArray;
begin
 if ASuperArray.Length = 0 then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
   ADynArray[I] := ASuperArray.S[I];

 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;


class procedure TSuperJSONMarshall.DeSerializeClassArray(const ASuperArray:TSuperArray;
                                                         const AObject:TObject;
                                                         const APropInfo:PPropInfo);
type
 TDynObjectArray = array of TObject;
var
 I : Integer;
 
 ATypeData: PTypeData;
 ADynArray : TDynObjectArray;

 AnArrayElement :  TObject;
 AClassOfArrayElement : TClass;
begin
 if ASuperArray.Length = 0 then
   Exit;

 ATypeData := GetTypeData(APropInfo^.PropType^);
 if not Assigned(ATypeData) then
   Exit;

 // Array element'in sýnýf tipini buluyoruz.
 AClassOfArrayElement := GetObjectClassFromTypeInfo(ATypeData^.elType2^);
 if not Assigned(AClassOfArrayElement) then
   Exit;

 SetLength(ADynArray, ASuperArray.Length);
 for  I:= 0 to Pred(ASuperArray.Length) do
 begin
    AnArrayElement := AClassOfArrayElement.Create;
    ADynArray[I] := DeSerializeObject(AnArrayElement,ASuperArray.O[I]);
 end;
 SetDynArrayProp(AObject,APropInfo,Pointer(ADynArray));
end;


class function TSuperJSONMarshall.GetObjectClassFromTypeInfo(ATypeInfo: PTypeInfo) : TClass;
var
 ATypeData : PTypeData;
begin
 Result := nil;
 ATypeData := GetTypeData(ATypeInfo);
 if Assigned(ATypeData) then
   if Assigned(ATypeData^.ClassType) then
      Result := ATypeData^.ClassType;
end;


class function TSuperJSONMarshall.Serialize(const AObject:TObject):string;
var
 ASuperObject : ISuperObject;
begin
 ASuperObject := SO();
 Result := SerializeObject(AObject,ASuperObject).AsJSon(true);
end;


class function TSuperJSONMarshall.DeSerialize(const AClass: TClass; const AJson: string):TObject;
var
 AObject : TObject;
 ASuperObject : ISuperObject;
begin
 Result := nil;
 if not Assigned(AClass) then
  raise Exception.Create('AClass parameter is NIL');

 if not AClass.InheritsFrom(TPersistent) then
  raise Exception.Create('RTTI Information Not Found');
                                     
 AObject := AClass.Create;
 ASuperObject := SO(AJson);
 Result := DeSerializeObject(AObject,ASuperObject);
end;

class function TSuperJSONMarshall.DeSerializeObject(const AObject: TObject; const ASuperObject: ISuperObject):TObject;
var
 I: Integer;

 APropInfo: PPropInfo;

 ANames,
 AValues : ISuperObject;

 APropertyName: string;
 ANamesSuperArray: TSuperArray;

 AObjectOfProperty:TObject;
 AClassOfProperty: TClass;
begin
  if ASuperObject.IsType(stObject) then
  begin
     ANames := ASuperObject.AsObject.GetNames();
     AValues := ASuperObject.AsObject.GetValues();
  
     ANamesSuperArray := ANames.AsArray;
     for  I:= 0  to Pred(ANamesSuperArray.Length) do
     begin
       APropertyName := ANamesSuperArray[I].AsString;
       APropInfo := GetPropInfo(AObject,APropertyName);
       if not Assigned(APropInfo) then
         continue;

       case AValues.AsArray[I].DataType of
        stNull    : ;
        stBoolean : SetPropValue(AObject,APropertyName,AValues.AsArray[I].AsBoolean);
        stDouble  : SetFloatProp(AObject,APropertyName,AValues.AsArray[I].AsDouble);
        stCurrency: ;
        stInt     : SetInt64Prop(AObject,APropertyName,AValues.AsArray[I].AsInteger);
        stObject  :
           begin
              AClassOfProperty := GetObjectPropClass(AObject,APropertyName);
              if Assigned(AClassOfProperty) then
              begin
                 AObjectOfProperty := AClassOfProperty.Create;
                 SetObjectProp(AObject,APropertyName,AObjectOfProperty);
                 DeSerializeObject(AObjectOfProperty, AValues.AsArray.O[I]);
              end;
           end;
        stArray   : DeSerializeDynamicArray(AValues.AsArray[I].AsArray,AObject,APropInfo);
        stString  : SetStrProp(AObject,APropertyName,AValues.AsArray[I].AsString);
       end;
     end;
  end;
  Result := AObject;
end;


class procedure TSuperJSONMarshall.SerializeDynamicArray(const ADynArrayLowBound : Pointer;
                                                         const ASuperObject: ISuperObject;
                                                         const APropInfo: PPropInfo);
var
  ATypeData: PTypeData;
  ASuperArray : TSuperArray;
begin
  if not Assigned(APropInfo) then
   Exit;
   
  ATypeData := GetTypeData(APropInfo^.PropType^);
  if not Assigned(ATypeData) then
   Exit;

   
  ASuperObject.O[APropInfo^.Name] := SA([]);
  ASuperArray := ASuperObject.A[APropInfo^.Name];
  if not Assigned(ADynArrayLowBound) then
    Exit;

  case ATypeData^.elType2^.Kind of // dinamik array'in element veri tipine bakýyoruz.
    tkUnknown     : ;
    tkInteger     :
      begin
         if (ATypeData^.elSize = SizeOf(Byte)) then
           SerializeByteArray(ASuperArray,ADynArrayLowBound);

         if (ATypeData^.elSize = SizeOf(Integer)) then
           SerializeIntArray(ASuperArray,ADynArrayLowBound);
       end;
    tkChar        : SerializeStringArray(ASuperArray,ADynArrayLowBound);
    tkEnumeration : SerializeBoolArray(ASuperArray,ADynArrayLowBound);
    tkFloat       : SerializeFloatArray(ASuperArray,ADynArrayLowBound);
    tkString      : SerializeStringArray(ASuperArray,ADynArrayLowBound);
    tkSet         : ;
    tkClass       : SerializeClassArray(ASuperArray,ADynArrayLowBound);
    tkMethod      : ;
    tkWChar       : SerializeWStringArray(ASuperArray,ADynArrayLowBound);
    tkLString     : SerializeStringArray(ASuperArray,ADynArrayLowBound);
    tkWString     : SerializeWStringArray(ASuperArray,ADynArrayLowBound);
    tkVariant     : ;
    tkArray       : ;
    tkRecord      : ;
    tkInterface   : ;
    tkInt64       : SerializeInt64Array(ASuperArray,ADynArrayLowBound);
    tkDynArray    : ;
  end;
end;

class procedure TSuperJSONMarshall.DeSerializeDynamicArray(const ASuperArray:TSuperArray;
                                                           const AObject:TObject;
                                                           const APropInfo:PPropInfo);
var
 ATypeData : PTypeData;
 AnElementTypeOfSuperArray : TSuperType;
begin
   if not Assigned(ASuperArray) then
     Exit;

   if not Assigned(APropInfo) then
     Exit;

   if not (APropInfo^.PropType^.Kind = tkDynArray) then
     Exit;

   if ASuperArray.Length = 0 then
     Exit;

   AnElementTypeOfSuperArray := ASuperArray[0].DataType;
   case AnElementTypeOfSuperArray of
    stNull    : ;
    stBoolean : DeSerializeBoolArray(ASuperArray,AObject,APropInfo);
    stDouble  : DeSerializeFloatArray(ASuperArray,AObject,APropInfo);
    stCurrency: ;
    stInt     :
      begin
        ATypeData := GetTypeData(APropInfo^.PropType^);
        if Assigned(ATypeData) then
        begin
          if ATypeData^.elType2^.Kind = tkInt64 then
            DeSerializeInt64Array(ASuperArray,AObject,APropInfo);

          if ATypeData^.elType2^.Kind = tkInteger then
            DeSerializeIntArray(ASuperArray,AObject,APropInfo);

          if ATypeData^.elSize = SizeOf(Byte) then
            DeSerializeByteArray(ASuperArray,AObject,APropInfo);
        end;
      end;
    stObject  : DeSerializeClassArray(ASuperArray,AObject,APropInfo);
    stArray   : ;
    stString  :
      begin
        ATypeData := GetTypeData(APropInfo^.PropType^);
        if Assigned(ATypeData) then
        begin
           if (ATypeData^.elType2^.Kind = tkString) or
              (ATypeData^.elType2^.Kind = tkLString) then
             DeSerializeStringArray(ASuperArray,AObject,APropInfo);

           if ATypeData^.elType2^.Kind = tkWString then
             DeSerializeWStringArray(ASuperArray,AObject,APropInfo);
        end;
      end;
   end;
end;

class function TSuperJSONMarshall.SerializeObject(const AObject:TObject; ASuperObject:ISuperObject):ISuperObject;
var
 I: Integer;

 APropInfo: PPropInfo;
 ATypeInfo : PPTypeInfo;
 PropertyCount : Integer;
 PropertyList : TPropList;
 APropertyName : string;

 ADynArrayLowBound : Pointer;

 APropInfoObject: PPropInfo;
 APropObject : TObject;
begin
 if not Assigned(AObject) then
   raise Exception.Create('AObject parameter is NIL');

 PropertyCount := GetPropList(AObject.ClassInfo, tkAny, @PropertyList);
 for  I:= 0  to Pred(PropertyCount) do
 begin
    APropInfo := PropertyList[I];
    if not Assigned(APropInfo) then
     continue;

    ATypeInfo := APropInfo^.PropType;
    if not Assigned(ATypeInfo) then
     continue;

    APropertyName := APropInfo^.Name;

    case ATypeInfo^.Kind of
      tkUnknown     : ;
      tkInteger     : ASuperObject.I[APropertyName] := GetInt64Prop(AObject,APropertyName);
      tkChar        : ASuperObject.S[APropertyName] := GetWideStrProp(AObject,APropertyName);
      tkEnumeration : ASuperObject.B[APropertyName] := GetOrdProp(AObject,APropertyName) = 1;
      tkFloat       : ASuperObject.D[APropertyName] := GetFloatProp(AObject, APropertyName);
      tkString      : ASuperObject.S[APropertyName] := GetStrProp(AObject,APropertyName);
      tkSet         : ;
      tkClass       :
         begin
           APropObject := GetObjectProp(AObject, APropInfo);
           if Assigned(APropObject) then
           begin
             ASuperObject.O[APropertyName] := SO();
             SerializeObject(APropObject, ASuperObject.O[APropertyName]);
           end;
         end;
      tkMethod      : ;
      tkWChar       : ASuperObject.S[APropertyName] := GetWideStrProp(AObject,APropertyName);
      tkLString     : ASuperObject.S[APropertyName] := GetWideStrProp(AObject,APropertyName);
      tkWString     : ASuperObject.S[APropertyName] := GetWideStrProp(AObject,APropertyName);
      tkVariant     : ASuperObject.S[APropertyName] := GetWideStrProp(AObject,APropertyName);
      tkArray       : ;
      tkRecord      : ;
      tkInterface   : ;
      tkInt64       : ASuperObject.I[APropertyName] := GetInt64Prop(AObject,APropertyName);
      tkDynArray    :
        begin
            //ADynArrayLength := GetDynArrayLength(ADynArrayLowBound);
            ADynArrayLowBound := GetDynArrayProp(AObject,APropInfo);
            SerializeDynamicArray(ADynArrayLowBound,ASuperObject,APropInfo);
        end;
    end;
 end;
 Result := ASuperObject;
end;


end.
