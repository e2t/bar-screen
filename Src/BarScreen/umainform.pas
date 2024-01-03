unit UMainForm;

{$mode objfpc}{$H+}

interface

uses
  ButtonPanel,
  Classes,
  ComCtrls,
  Controls,
  Dialogs,
  Forms,
  Graphics,
  Menus,
  StdCtrls,
  SysUtils,
  UPresenter;

type

  { TMainForm }

  TMainForm = class(TForm, IView)
    FlowBox: TEdit;
    LevelBox: TEdit;
    AngleBox: TEdit;
    GsBox: TComboBox;
    HsBox: TComboBox;
    HydrLabel: TLabel;
    FlowLabel: TLabel;
    LevelLabel: TLabel;
    AngleLabel: TLabel;
    HydrTable: TListView;
    MemoOutput: TMemo;
    ProfTable: TListView;
    WsBox: TComboBox;
    GapBox: TComboBox;
    DchLabel: TLabel;
    DchBox: TEdit;
    DropLabel: TLabel;
    DropBox: TEdit;
    GapLabel: TLabel;
    HsLabel: TLabel;
    GsLabel: TLabel;
    WsLabel: TLabel;
    WchBox: TEdit;
    WchLabel: TLabel;
    MainButtonPanel: TButtonPanel;
    MainMenu1: TMainMenu;
    GuiMenu: TMenuItem;
    OutMenu: TMenuItem;
    procedure OKButtonClick(Sender: TObject);
  private
    FPresenter: IViewPresenter;
    procedure CallTranslateUi(Sender: TObject);
    procedure CallTranslateOut(Sender: TObject);
    { IBaseView }
    procedure PrintText(const AText: String);
    procedure SetTitle(const AText: String);
    procedure SetRunLabel(const AText: String);
    procedure SetUiMenuLabel(const AText: String);
    procedure SetOutMenuLabel(const AText: String);
    procedure AddUiSubMenu(AItems: TStrings);
    procedure SelectUiSubMenu(AIndex: Integer);
    function GetUiSubMenuSelected: Integer;
    procedure AddOutSubMenu(AItems: TStrings);
    procedure SelectOutSubMenu(AIndex: Integer);
    function GetOutSubMenuSelected: Integer;
    { IView }
    procedure SetWchLabel(const AText: String);
    procedure SetDchLabel(const AText: String);
    procedure SetDropLabel(const AText: String);
    procedure SetGapLabel(const AText: String);
    procedure SetWsLabel(const AText: String);
    procedure SetHsLabel(const AText: String);
    procedure SetGsLabel(const AText: String);
    procedure SetHydrLabel(const AText: String);
    procedure SetFlowLabel(const AText: String);
    procedure SetLevelLabel(const AText: String);
    procedure SetAngleLabel(const AText: String);
    procedure FillGaps(ASeries: TStrings);
    procedure FillWidthSeries(ASeries: TStrings);
    procedure FillHeightSeries(ASeries: TStrings);
    procedure FillGateSeries(ASeries: TStrings);
    procedure SelectGap(AIndex: Integer);
    procedure SelectWidthSerie(AIndex: Integer);
    procedure SelectHeightSerie(AIndex: Integer);
    procedure SelectGateSerie(AIndex: Integer);
    procedure SetDropEntry(const AText: String);
    procedure SetAngleEntry(const AText: String);
    procedure SetWsSubItem(AIndex: Integer; const AText: String);
    procedure SetHsSubItem(AIndex: Integer; const AText: String);
    procedure SetGsSubItem(AIndex: Integer; const AText: String);
    procedure SetProfHeader(const AText: String);
    procedure SetMountHeader(const AText: String);
    procedure SetFactorHeader(const AText: String);
    procedure FillColProf(const AItems: array of String);
    procedure FillColMount(const AItems: array of String);
    procedure FillColFactor(const AItems: array of String);
    procedure SelectProfile(AIndex: Integer);
    procedure SetPollHeader2(const AText: String);
    procedure SetGapSpeedHeader2(const AText: String);
    procedure SetAreaHeader2(const AText: String);
    procedure SetBFactorHeader2(const AText: String);
    procedure SetDiffHeader2(const AText: String);
    procedure SetFrontHeader2(const AText: String);
    procedure SetChnSpeedHeader2(const AText: String);
    function GetChannelWidth: String;
    function GetChannelHeight: String;
    function GetMinDropHeight: String;
    function GetGapSelected: Integer;
    function GetWsSelected: Integer;
    function GetHsSelected: Integer;
    function GetGsSelected: Integer;
    function GetProfileSelected: Integer;
    function GetFlowRate: String;
    function GetWaterLevel: String;
    function GetTiltAngle: String;
    procedure ClearHydrTable;
    procedure FillCol2Pollution(const AItems: array of String);
    procedure FillCol2SpeedInGap(const AItems: array of String);
    procedure FillCol2Area(const AItems: array of String);
    procedure FillCol2BFactor(const AItems: array of String);
    procedure FillCol2LevelDiff(const AItems: array of String);
    procedure FillCol2FrontLevel(const AItems: array of String);
    procedure FillCol2ChnSpeed(const AItems: array of String);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  GuiUtils;

const
  ColProf = 0;
  ColMount = 1;
  ColFactor = 2;

  Col2Poll = 0;
  Col2GapSpeed = 1;
  Col2Area = 2;
  Col2BFactor = 3;
  Col2Diff = 4;
  Col2Front = 5;
  Col2ChnSpeed = 6;

constructor TMainForm.Create(TheOwner: TComponent);
begin
  inherited;
  FPresenter := NewPresenter(self);
  FPresenter.InitView;
end;

destructor TMainForm.Destroy;
begin
  FPresenter.Free;
  inherited;
end;

procedure TMainForm.OKButtonClick(Sender: TObject);
begin
  FPresenter.Run;
end;

procedure TMainForm.CallTranslateUi(Sender: TObject);
begin
  FPresenter.TranslateUi;
end;

procedure TMainForm.CallTranslateOut(Sender: TObject);
begin
  FPresenter.TranslateOut;
end;

procedure TMainForm.PrintText(const AText: String);
begin
  MemoOutput.Text := AText;
end;

procedure TMainForm.SetTitle(const AText: String);
begin
  Caption := AText;
  Application.Title := AText;
end;

procedure TMainForm.SetRunLabel(const AText: String);
begin
  MainButtonPanel.OKButton.Caption := AText;
end;

procedure TMainForm.SetUiMenuLabel(const AText: String);
begin
  GuiMenu.Caption := AText;
end;

procedure TMainForm.SetOutMenuLabel(const AText: String);
begin
  OutMenu.Caption := AText;
end;

procedure TMainForm.AddUiSubMenu(AItems: TStrings);
begin
  AddSubMenuInto(GuiMenu, AItems, @CallTranslateUi);
end;

procedure TMainForm.SelectUiSubMenu(AIndex: Integer);
begin
  GuiMenu.Items[AIndex].Checked := True;
end;

function TMainForm.GetUiSubMenuSelected: Integer;
begin
  Result := GetSelectedSubMenuOf(GuiMenu);
end;

procedure TMainForm.AddOutSubMenu(AItems: TStrings);
begin
  AddSubMenuInto(OutMenu, AItems, @CallTranslateOut);
end;

procedure TMainForm.SelectOutSubMenu(AIndex: Integer);
begin
  OutMenu.Items[AIndex].Checked := True;
end;

function TMainForm.GetOutSubMenuSelected: Integer;
begin
  Result := GetSelectedSubMenuOf(OutMenu);
end;

procedure TMainForm.SetWchLabel(const AText: String);
begin
  WchLabel.Caption := AText;
end;

procedure TMainForm.SetDchLabel(const AText: String);
begin
  DchLabel.Caption := AText;
end;

procedure TMainForm.SetDropLabel(const AText: String);
begin
  DropLabel.Caption := AText;
end;

procedure TMainForm.SetGapLabel(const AText: String);
begin
  GapLabel.Caption := AText;
end;

procedure TMainForm.SetWsLabel(const AText: String);
begin
  WsLabel.Caption := AText;
end;

procedure TMainForm.SetHsLabel(const AText: String);
begin
  HsLabel.Caption := AText;
end;

procedure TMainForm.SetGsLabel(const AText: String);
begin
  GsLabel.Caption := AText;
end;

procedure TMainForm.SetHydrLabel(const AText: String);
begin
  HydrLabel.Caption := AText;
end;

procedure TMainForm.SetFlowLabel(const AText: String);
begin
  FlowLabel.Caption := AText;
end;

procedure TMainForm.SetLevelLabel(const AText: String);
begin
  LevelLabel.Caption := AText;
end;

procedure TMainForm.SetAngleLabel(const AText: String);
begin
  AngleLabel.Caption := AText;
end;

procedure TMainForm.FillGaps(ASeries: TStrings);
begin
  GapBox.Items := ASeries;
end;

procedure TMainForm.FillWidthSeries(ASeries: TStrings);
begin
  WsBox.Items := ASeries;
end;

procedure TMainForm.FillHeightSeries(ASeries: TStrings);
begin
  HsBox.Items := ASeries;
end;

procedure TMainForm.FillGateSeries(ASeries: TStrings);
begin
  GsBox.Items := ASeries;
end;

procedure TMainForm.SelectGap(AIndex: Integer);
begin
  GapBox.ItemIndex := AIndex;
end;

procedure TMainForm.SelectWidthSerie(AIndex: Integer);
begin
  WsBox.ItemIndex := AIndex;
end;

procedure TMainForm.SelectHeightSerie(AIndex: Integer);
begin
  HsBox.ItemIndex := AIndex;
end;

procedure TMainForm.SelectGateSerie(AIndex: Integer);
begin
  GsBox.ItemIndex := AIndex;
end;

procedure TMainForm.SetDropEntry(const AText: String);
begin
  DropBox.Text := AText;
end;

procedure TMainForm.SetAngleEntry(const AText: String);
begin
  AngleBox.Text := AText;
end;

procedure TMainForm.SetWsSubItem(AIndex: Integer; const AText: String);
begin
  WsBox.Items[AIndex] := AText;
end;

procedure TMainForm.SetHsSubItem(AIndex: Integer; const AText: String);
begin
  HsBox.Items[AIndex] := AText;
end;

procedure TMainForm.SetGsSubItem(AIndex: Integer; const AText: String);
begin
  GsBox.Items[AIndex] := AText;
end;

procedure TMainForm.SetProfHeader(const AText: String);
begin
  ProfTable.Column[ColProf].Caption := AText;
end;

procedure TMainForm.SetMountHeader(const AText: String);
begin
  ProfTable.Column[ColMount].Caption := AText;
end;

procedure TMainForm.SetFactorHeader(const AText: String);
begin
  ProfTable.Column[ColFactor].Caption := AText;
end;

procedure TMainForm.FillColProf(const AItems: array of String);
begin
  FillColumn(ProfTable, ColProf, AItems);
end;

procedure TMainForm.FillColMount(const AItems: array of String);
begin
  FillColumn(ProfTable, ColMount, AItems);
end;

procedure TMainForm.FillColFactor(const AItems: array of String);
begin
  FillColumn(ProfTable, ColFactor, AItems);
end;

procedure TMainForm.SelectProfile(AIndex: Integer);
begin
  ProfTable.ItemIndex := AIndex;
end;

procedure TMainForm.SetPollHeader2(const AText: String);
begin
  HydrTable.Column[Col2Poll].Caption := AText;
end;

procedure TMainForm.SetGapSpeedHeader2(const AText: String);
begin
  HydrTable.Column[Col2GapSpeed].Caption := AText;
end;

procedure TMainForm.SetAreaHeader2(const AText: String);
begin
  HydrTable.Column[Col2Area].Caption := AText;
end;

procedure TMainForm.SetBFactorHeader2(const AText: String);
begin
  HydrTable.Column[Col2BFactor].Caption := AText;
end;

procedure TMainForm.SetDiffHeader2(const AText: String);
begin
  HydrTable.Column[Col2Diff].Caption := AText;
end;

procedure TMainForm.SetFrontHeader2(const AText: String);
begin
  HydrTable.Column[Col2Front].Caption := AText;
end;

procedure TMainForm.SetChnSpeedHeader2(const AText: String);
begin
  HydrTable.Column[Col2ChnSpeed].Caption := AText;
end;

function TMainForm.GetChannelWidth: String;
begin
  Result := WchBox.Text;
end;

function TMainForm.GetChannelHeight: String;
begin
  Result := DchBox.Text;
end;

function TMainForm.GetMinDropHeight: String;
begin
  Result := DropBox.Text;
end;

function TMainForm.GetGapSelected: Integer;
begin
  Result := GapBox.ItemIndex;
end;

function TMainForm.GetWsSelected: Integer;
begin
  Result := WsBox.ItemIndex;
end;

function TMainForm.GetHsSelected: Integer;
begin
  Result := HsBox.ItemIndex;
end;

function TMainForm.GetGsSelected: Integer;
begin
  Result := GsBox.ItemIndex;
end;

function TMainForm.GetProfileSelected: Integer;
begin
  Result := ProfTable.ItemIndex;
end;

function TMainForm.GetFlowRate: String;
begin
  Result := FlowBox.Text;
end;

function TMainForm.GetWaterLevel: String;
begin
  Result := LevelBox.Text;
end;

function TMainForm.GetTiltAngle: String;
begin
  Result := AngleBox.Text;
end;

procedure TMainForm.ClearHydrTable;
begin
  HydrTable.Clear;
end;

procedure TMainForm.FillCol2Pollution(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2Poll, AItems);
end;

procedure TMainForm.FillCol2SpeedInGap(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2GapSpeed, AItems);
end;

procedure TMainForm.FillCol2Area(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2Area, AItems);
end;

procedure TMainForm.FillCol2BFactor(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2BFactor, AItems);
end;

procedure TMainForm.FillCol2LevelDiff(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2Diff, AItems);
end;

procedure TMainForm.FillCol2FrontLevel(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2Front, AItems);
end;

procedure TMainForm.FillCol2ChnSpeed(const AItems: array of String);
begin
  FillColumn(HydrTable, Col2ChnSpeed, AItems);
end;

end.
