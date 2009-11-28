unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ActnList, StdActns, VirtualTrees, SuperObject, superxmlparser,
  ComCtrls, ExtCtrls, StdCtrls, ExtActns;

type
  TMainForm = class(TForm)
    treeview: TVirtualStringTree;
    MainMenu: TMainMenu;
    ActionList: TActionList;
    acFileOpen: TFileOpen;
    mFile: TMenuItem;
    Open1: TMenuItem;
    StatusBar: TStatusBar;
    Memo: TMemo;
    Splitter1: TSplitter;
    Options1: TMenuItem;
    Action1: TAction;
    acPackxml: TMenuItem;
    Panel1: TPanel;
    edGetURL: TEdit;
    procedure acFileOpenAccept(Sender: TObject);
    procedure treeviewGetNodeDataSize(Sender: TBaseVirtualTree;
      var NodeDataSize: Integer);
{$IFDEF UNICODE}
    procedure treeviewGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: string);
{$ELSE}
    procedure treeviewGetText(Sender: TBaseVirtualTree; Node: PVirtualNode;
      Column: TColumnIndex; TextType: TVSTTextType;
      var CellText: widestring);
{$ENDIF}
    procedure treeviewFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure treeviewCompareNodes(Sender: TBaseVirtualTree; Node1,
      Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure treeviewHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure treeviewChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure Action1Execute(Sender: TObject);
    procedure edGetURLKeyPress(Sender: TObject; var Key: Char);
  private
    { Déclarations privées }
  public
    { Déclarations publiques }
    procedure UpdateRoot(const root: ISuperObject);
  end;

var
  MainForm: TMainForm;

implementation
uses msxml;
{$R *.dfm}

type
  PSuperNode = ^TSuperNode;
  TSuperNode = record
    index: Integer;
    name: string;
    obj: ISuperObject;
  end;

  function GetPath(treeview: TVirtualStringTree; n: PVirtualNode): string;
  var
    data, parent: PSuperNode;
  label root;
  begin
    Result := '';
    data := treeview.GetNodeData(n);
    if data = nil then exit;
    parent := treeview.GetNodeData(n.Parent);
    if parent = nil then goto root;

    if parent <> nil then
      case ObjectGetType(parent.obj) of
        stObject: Result := GetPath(treeview, n.Parent) + '.' + data.name;
        stArray: Result := GetPath(treeview, n.Parent) + '[' + data.name + ']';
      else
        Assert(false); // unexpected
      end;
    Exit;
  root:
    Result := data.name;
  end;

  function GetSource(treeview: TVirtualStringTree; n: PVirtualNode; format: boolean): string;
  var
    p: PSuperNode;
  begin
    Result := '';
    p := treeview.GetNodeData(n);
    if (p <> nil) then if (p.obj <> nil) then
      Result := p.obj.AsJSon(format, false) else
      Result := 'null';
  end;


procedure TMainForm.UpdateRoot(const root: ISuperObject);
  procedure ProcessNode(parent: PVirtualNode; const node: ISuperObject; const text: string; id: Integer = -1);
  var
    p: PVirtualNode;
    data: PSuperNode;
    i: Integer;
    iter: TSuperObjectIter;
  begin
    p := treeview.AddChild(parent);
    data := treeview.GetNodeData(p);
    data.name := text;
    data.obj := node;
    data.index := id;
    include(p.States, vsInitialized);
    case ObjectGetType(node) of
      stObject:
        begin
          include(p.States, vsExpanded);
          if ObjectFindFirst(node, iter) then
          repeat
            ProcessNode(p, iter.val, iter.key, -1);
          until not ObjectFindNext(iter);
          ObjectFindClose(iter);
        end;
      stArray:
        begin
          include(p.States, vsExpanded);
          for i := 0 to node.AsArray.Length - 1 do
            ProcessNode(p, node.AsArray[i], inttostr(i), i);
        end;
    end;
  end;
begin
  Memo.Clear;
  treeview.BeginUpdate;
  try
    treeview.Clear;
    ProcessNode(nil, root, 'root');
  finally
    treeview.EndUpdate;
  end;
end;

procedure TMainForm.Action1Execute(Sender: TObject);
begin
  TAction(Sender).Checked := not TAction(Sender).Checked;
end;

procedure TMainForm.edGetURLKeyPress(Sender: TObject; var Key: Char);
var
  req: IXMLHttpRequest;
begin
  if Key = #13 then
  begin
    req := {$IFDEF VER210}CoXMLHTTP{$ELSE}CoXMLHTTPRequest{$ENDIF}.Create;
    req.open('GET', edGetURL.Text, false, EmptyParam, EmptyParam);
    req.send(EmptyParam);
    UpdateRoot(SO(req.responseText));
    abort;
  end;
end;

procedure TMainForm.treeviewChange(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
begin
  StatusBar.SimpleText := GetPath(treeview, Node);
  Memo.Text := GetSource(treeview, Node, true);
end;

procedure TMainForm.treeviewCompareNodes(Sender: TBaseVirtualTree; Node1,
  Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  data1, data2, parent: PSuperNode;
begin
  case Column of
  0: begin
       data1 := treeview.GetNodeData(Node1);
       parent := treeview.GetNodeData(node1.Parent);
       if (parent <> nil) and ObjectIsType(parent.obj, stArray) then
         Result := node1.Index - node2.Index else
         begin
          data2 := treeview.GetNodeData(Node2);
          Result := CompareText(data1.name, data2.name);
         end;
     end;
  end;
end;

procedure TMainForm.treeviewFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  p: PSuperNode;
begin
  p := PSuperNode(treeview.GetNodeData(Node));
  p.name := '';
  p.obj := nil;
end;

procedure TMainForm.treeviewGetNodeDataSize(Sender: TBaseVirtualTree;
  var NodeDataSize: Integer);
begin
  NodeDataSize := SizeOf(TSuperNode);
end;

{$IFDEF UNICODE}
procedure TMainForm.treeviewGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
{$ELSE}
procedure TMainForm.treeviewGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: widestring);
{$ENDIF}
var
  data: PSuperNode;
begin
  data := treeview.GetNodeData(Node);
  case Column of
    0: CellText := data.name;
    1: case ObjectGetType(data.obj) of
         stObject: CellText := '';
         stArray: CellText := '';
         stNull: CellText := 'null';
       else
         CellText := data.obj.AsString;
       end;
  end;
end;

procedure TMainForm.treeviewHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
begin
  treeview.BeginUpdate;
  try
    Sender.SortDirection := TSortDirection(1- ord(Sender.SortDirection));
  finally
    treeview.EndUpdate;
  end;
end;

procedure TMainForm.acFileOpenAccept(Sender: TObject);
begin
  if LowerCase(ExtractFileExt(TFileOpen(sender).Dialog.FileName)) = '.xml' then
    UpdateRoot(XMLParseFile(TFileOpen(sender).Dialog.FileName, acPackxml.Checked)) else
    UpdateRoot(TSuperObject.ParseFile(TFileOpen(sender).Dialog.FileName, False));
end;

end.

