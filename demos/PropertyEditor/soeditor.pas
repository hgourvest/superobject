unit soeditor;

interface
uses superobject, classes, DesignIntf, DesignEditors;

type

  TSuperObjectProperty = class(TNestedProperty)
  private
    FName: string;
    FPath: ISuperObject;
    function GetNode: ISuperObject;
  public
    function GetName: string; override;
    constructor Create(Parent: TPropertyEditor; const name: string; const path: ISuperObject); reintroduce;
    function GetAttributes: TPropertyAttributes; override;
    function GetValue: string; override;
    procedure SetValue(const Value: string); override;
    procedure GetProperties(Proc: TGetPropProc); override;
    procedure GetValues(Proc: TGetStrProc); override;
  end;

procedure Register;

implementation
uses SysUtils;

procedure Register;
begin
  RegisterPropertyEditor(TypeInfo(ISuperObject), nil, '', TSuperObjectProperty);
end;

{ TSuperObjectProperty }

constructor TSuperObjectProperty.Create(Parent: TPropertyEditor; const name: string; const path: ISuperObject);
begin
  inherited Create(Parent);
  FName := name;
  FPath := path;
end;

function TSuperObjectProperty.GetAttributes: TPropertyAttributes;
var
  node: ISuperObject;
  count: Integer;
const
  common = [paValueEditable, paValueList, paRevertable];
begin
  node := GetNode;
  case ObjectGetType(node) of
    stObject: count := node.AsObject.count;
    stArray : count := node.AsArray.Length;
  else
    count := 0;
  end;
  if count > 0 then
    result := common + [paSubProperties, paVolatileSubProperties] else
    result := common;
end;

function TSuperObjectProperty.GetName: string;
begin
  if FName <> '' then
    Result := FName else
    Result := inherited;
end;

function TSuperObjectProperty.GetNode: ISuperObject;
var
  v: IInterface;
begin
  if FPath = nil then
  begin
    v := GetIntfValue;
    if v = nil then
      Result := TSuperObject.Create(stNull) else
      Result := v as ISuperObject;
  end else
    Result := FPath.N[FName];
end;

procedure TSuperObjectProperty.GetProperties(Proc: TGetPropProc);
var
  node: ISuperObject;
  entry: TSuperObjectIter;
  i: Integer;
  list: TStringList;
begin
  node := GetNode;
  case ObjectGetType(node) of
    stObject:
      begin
        list := TStringList.Create;
        try
          if ObjectFindFirst(node, entry) then
          repeat
            list.Add(entry.key);
          until not ObjectFindNext(entry);
          ObjectFindClose(entry);
          list.Sort;
          for i := 0 to list.Count - 1 do
            proc(TSuperObjectProperty.Create(Self, list[i], node) as IProperty);
        finally
          list.Free;
        end;
      end;
    stArray :
      for i := 0 to node.AsArray.Length - 1 do
        proc(TSuperObjectProperty.Create(Self, IntToStr(i), node) as IProperty);
  end;
end;

function TSuperObjectProperty.GetValue: string;
begin
  Result := GetNode.AsJSon(false, false);
end;

procedure TSuperObjectProperty.GetValues(Proc: TGetStrProc);
begin
  case GetNode.DataType of
    stNull, stDouble, stInt, stString, stObject, stArray:
      begin
        Proc('{}');
        Proc('[]');
        Proc('""');
        Proc('null');
        Proc('true');
        Proc('false');
        Proc('0');
        Proc('0.0');
      end;
    stBoolean:
      begin
        Proc('true');
        Proc('false');
      end;
  end;
end;

procedure TSuperObjectProperty.SetValue(const Value: string);
begin
  if FPath = nil then
    SetIntfValue(SO(Value)) else
    FPath[FName] := SO(Value);
  Modified;
end;

end.
