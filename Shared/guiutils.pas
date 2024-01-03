unit GuiUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  ComCtrls,
  Menus;

type
  TSubMenuEvent = procedure(Sender: TObject) of object;

procedure AddSubMenuInto(AMenu: TMenuItem; const AItems: TStrings;
  AEvent: TSubMenuEvent);

function GetSelectedSubMenuOf(AMenu: TMenuItem): Integer;

procedure FillColumn(Table: TListView; Col: Integer;
  const AItems: array of String);

implementation

procedure AddSubMenuInto(AMenu: TMenuItem; const AItems: TStrings;
  AEvent: TSubMenuEvent);
var
  I: Integer;
  X: array of TMenuItem = nil;
begin
  SetLength(X, AItems.Count);
  for I := Low(X) to High(X) do
  begin
    X[I] := TMenuItem.Create(AMenu);
    X[I].Caption := AItems[I];
    X[I].RadioItem := True;
    X[I].AutoCheck := True;
    X[I].OnClick := AEvent;
  end;
  AMenu.Add(X);
end;

function GetSelectedSubMenuOf(AMenu: TMenuItem): Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to AMenu.Count - 1 do
    if AMenu.Items[I].Checked then
    begin
      Result := I;
      break;
    end;
end;

procedure FillColumn(Table: TListView; Col: Integer;
  const AItems: array of String);
var
  I: Integer;
  Row: TListItem;
  RowCount, SubCol: Integer;
begin
  RowCount := Length(AItems);
  while RowCount > Table.Items.Count do
    Table.Items.Add;

  for I := 0 to High(AItems) do
  begin
    Row := Table.Items[I];
    if Col = 0 then
      Row.Caption := AItems[I]
    else
    begin
      SubCol := Col - 1;
      while SubCol >= Row.SubItems.Count do
        Row.SubItems.Add('');
      Row.SubItems[SubCol] := AItems[I];
    end;
  end;
end;

end.
