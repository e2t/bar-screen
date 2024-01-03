unit UPresenter;

{$mode ObjFPC}{$H+}

interface

uses
  BaseCalcApp,
  Classes,
  L10n;

type
  {$interfaces CORBA}
  IView = interface(IBaseView)
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
  end;

  IViewPresenter = interface(IBaseViewPresenter)
  end;

  IModelPresenter = interface(IBaseModelPresenter)
    procedure AddPoll(const AText: String);
    procedure AddGapSpeed(SpecMap: TTranslate; const Args: array of const);
    procedure AddArea(const AText: String);
    procedure AddBlindFactor(const AText: String);
    procedure AddDiffLevel(SpecMap: TTranslate; const Args: array of const);
    procedure AddFrontLevel(SpecMap: TTranslate; const Args: array of const);
    procedure AddChnSpeed(SpecMap: TTranslate; const Args: array of const);
  end;

function NewPresenter(AView: IView): IViewPresenter;

implementation

uses
  FloatUtils,
  MeasurementUtils,
  Model,
  SysUtils,
  Texts,
  UMsgQueue;

type
  TPresenter = class sealed(TInterfacedObject, IViewPresenter, IModelPresenter,
    ICorePresenter)
  private
    FCore: ICore;
    FView: IView;
    FInputData: TInputData;
    FIsViewInitialised: Boolean;

    FPollColumn, FGapSpeedColumn, FAreaColumn, FBlindFactorColumn,
    FDiffLevelColumn, FFrontLevelColumn, FChnSpeedColumn: IMsgQueue;

    procedure TranslateHydrTable(ALang: TLanguage);
    { ICorePresenter }
    procedure DoInitView;
    procedure DoTranslateUi;
    procedure GetInputData;
    procedure Calculate;
    procedure PrintResults;
    procedure PrintErrors;
    procedure ClearQueues;
    { IViewPresenter }
    procedure InitView;
    procedure TranslateUi;
    procedure TranslateOut;
    procedure Run;
    { IModelPresenter }
    procedure LogError(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(SpecMap: TTranslate; const Args: array of const);
    procedure AddOutput(const AText: String);
    procedure AddPoll(const AText: String);
    procedure AddGapSpeed(SpecMap: TTranslate; const Args: array of const);
    procedure AddArea(const AText: String);
    procedure AddBlindFactor(const AText: String);
    procedure AddDiffLevel(SpecMap: TTranslate; const Args: array of const);
    procedure AddFrontLevel(SpecMap: TTranslate; const Args: array of const);
    procedure AddChnSpeed(SpecMap: TTranslate; const Args: array of const);
  public
    constructor Create(AView: IView);
  end;

const
  UiLangs: array of TLanguage = (Eng, Ukr, Lit);
  OutLangs: array of TLanguage = (Eng, Ukr, Rus);
  AppVersion = '24.1';

function AppVendor: String;
begin
  Result := 'Esmil';
end;

function AppName: String;
begin
  Result := 'BarScreen';
end;

function NewPresenter(AView: IView): IViewPresenter;
begin
  Result := TPresenter.Create(AView);
end;

{ TPresenter }

constructor TPresenter.Create(AView: IView);
begin
  FCore := NewCore(Self, AView, UiLangs, OutLangs, @AppName, @AppVendor,
    AppVersion, TextUiTitle);
  FView := AView;
  FIsViewInitialised := False;

  FPollColumn := NewMsgQueue(OutLangs);
  FGapSpeedColumn := NewMsgQueue(OutLangs);
  FAreaColumn := NewMsgQueue(OutLangs);
  FBlindFactorColumn := NewMsgQueue(OutLangs);
  FDiffLevelColumn := NewMsgQueue(OutLangs);
  FFrontLevelColumn := NewMsgQueue(OutLangs);
  FChnSpeedColumn := NewMsgQueue(OutLangs);
end;

procedure TPresenter.DoInitView;
var
  I: Integer;
  Sl: TStringList;
  F: ValReal;
  Sa: array [TProfileRange] of String;
begin
  FView.SetDropEntry(FStr(FromSI('mm', DefaultDischargeHeight)));

  Sl := TStringList.Create;
  for F in NominalGaps do
    Sl.Add(FStr(FromSI('mm', F)));
  FView.FillGaps(Sl);
  FView.SelectGap(0);

  Sl.Clear;
  Sl.Add('');
  for I in TWsData do
    Sl.Add(Format('%0.2d', [I]));
  FView.FillWidthSeries(Sl);
  FView.SelectWidthSerie(0);

  Sl.Clear;
  Sl.Add('');
  for I := 0 to HeightSeries.Count - 1 do
    Sl.Add(Format('%0.2d', [HeightSeries.Keys[I]]));
  FView.FillHeightSeries(Sl);
  FView.SelectHeightSerie(0);

  Sl.Clear;
  Sl.Add('');
  for I in GsData do
    Sl.Add(Format('%0.2d', [I]));
  FView.FillGateSeries(Sl);
  FView.SelectGateSerie(0);

  for I in TProfileRange do
    Sa[I] := Profiles[I].Name;
  FView.FillColProf(Sa);
  for I in TProfileRange do
    Sa[I] := FStr(Profiles[I].ShapeFactor);
  FView.FillColFactor(Sa);
  FView.SelectProfile(0);

  FView.SetAngleEntry(FStr(FromSI('deg', DefaultTiltAngle)));

  FreeAndNil(Sl);
end;

procedure TPresenter.DoTranslateUi;
var
  UiLang, OutLang: TLanguage;
  Auto: String;
  I: Integer;
  Sa: array [TProfileRange] of String;
begin
  UiLang := FCore.UiLang;
  FView.SetWchLabel(TextUiWid.KeyData[UiLang]);
  FView.SetDchLabel(TextUiDep.KeyData[UiLang]);
  FView.SetDropLabel(TextUiDrop.KeyData[UiLang]);
  FView.SetGapLabel(TextUiGap.KeyData[UiLang]);
  FView.SetWsLabel(TextUiWs.KeyData[UiLang]);
  FView.SetHsLabel(TextUiHs.KeyData[UiLang]);
  FView.SetGsLabel(TextUiGs.KeyData[UiLang]);
  FView.SetHydrLabel(TextUiHydr.KeyData[UiLang]);
  FView.SetFlowLabel(TextUiFlow.KeyData[UiLang]);
  FView.SetLevelLabel(TextUiLevel.KeyData[UiLang]);
  FView.SetAngleLabel(TextUiAngle.KeyData[UiLang]);

  FView.SetProfHeader(TextUiColName.KeyData[UiLang]);
  FView.SetMountHeader(TextUiColMount.KeyData[UiLang]);
  FView.SetFactorHeader(TextUiColFactor.KeyData[UiLang]);

  Auto := TextUiAuto.KeyData[UiLang];
  FView.SetWsSubItem(0, Auto);
  FView.SetHsSubItem(0, Auto);
  FView.SetGsSubItem(0, Auto);

  for I in TProfileRange do
    if Profiles[I].IsRemovable then
      Sa[I] := TextUiFpRemov.KeyData[UiLang]
    else
      Sa[I] := TextUiFpWeld.KeyData[UiLang];
  FView.FillColMount(Sa);

  if not FIsViewInitialised then
  begin
    OutLang := FCore.OutLang;
    TranslateHydrTable(OutLang);
    FIsViewInitialised := True;
  end;
end;

procedure TPresenter.TranslateHydrTable(ALang: TLanguage);
begin
  FView.SetPollHeader2(TextUiCol2Poll.KeyData[ALang]);
  FView.SetGapSpeedHeader2(TextUiCol2GapSpeed.KeyData[ALang]);
  FView.SetAreaHeader2(TextUiCol2Area.KeyData[ALang]);
  FView.SetBFactorHeader2(TextUiCol2BFactor.KeyData[ALang]);
  FView.SetDiffHeader2(TextUiCol2Diff.KeyData[ALang]);
  FView.SetFrontHeader2(TextUiCol2Front.KeyData[ALang]);
  FView.SetChnSpeedHeader2(TextUiCol2ChnSpeed.KeyData[ALang]);

  if not FGapSpeedColumn.IsEmpty then
    FView.FillCol2SpeedInGap(FGapSpeedColumn.StringArray(ALang));
  if not FDiffLevelColumn.IsEmpty then
    FView.FillCol2LevelDiff(FDiffLevelColumn.StringArray(ALang));
  if not FFrontLevelColumn.IsEmpty then
    FView.FillCol2FrontLevel(FFrontLevelColumn.StringArray(ALang));
  if not FChnSpeedColumn.IsEmpty then
    FView.FillCol2ChnSpeed(FChnSpeedColumn.StringArray(ALang));
end;

procedure TPresenter.GetInputData;
var
  Index: Integer;
  S: String;
begin
  FInputData := Default(TInputData);
  with FInputData do
  begin
    try
      Width := SI(AdvStrToFloat(FView.GetChannelWidth), 'mm');
    except
      on E: EConvertError do
        LogError(TextErrWidth, []);
    end;

    try
      Depth := SI(AdvStrToFloat(FView.GetChannelHeight), 'mm');
    except
      on E: EConvertError do
        LogError(TextErrDepth, []);
    end;

    try
      MinDrop := SI(AdvStrToFloat(FView.GetMinDropHeight), 'mm');
    except
      on E: EConvertError do
        LogError(TextErrDrop, []);
    end;

    Gap := NominalGaps[FView.GetGapSelected];

    Index := FView.GetWsSelected;
    if Index <> 0 then
      Ws := Low(TWsData) + Index - 1;

    Index := FView.GetHsSelected;
    if Index <> 0 then
      Hs := HeightSeries.Keys[Index - 1];

    Index := FView.GetGsSelected;
    if Index <> 0 then
      Gs := GsData[Index - 1];

    Fp := Profiles[FView.GetProfileSelected];

    S := FView.GetFlowRate;
    if S <> '' then
    try
      Flow := SI(AdvStrToFloat(S), 'mm');
    except
      on E: EConvertError do
        LogError(TextErrFlow, []);
    end;

    S := FView.GetWaterLevel;
    if S <> '' then
    try
      Level := SI(AdvStrToFloat(S), 'mm');
    except
      on E: EConvertError do
        LogError(TextErrLevel, []);
    end;

    S := FView.GetTiltAngle;
    if S <> '' then
    try
      Angle := SI(AdvStrToFloat(S), 'deg');
    except
      on E: EConvertError do
        LogError(TextErrAngle, []);
    end;
  end;
end;

procedure TPresenter.Calculate;
begin
  CalcBarScreen(FInputData, Self);
end;

procedure TPresenter.PrintResults;
var
  OutLang: TLanguage;
begin
  FCore.PrintPlainResults;

  OutLang := FCore.OutLang;
  FView.FillCol2Pollution(FPollColumn.StringArray(OutLang));
  FView.FillCol2Area(FAreaColumn.StringArray(OutLang));
  FView.FillCol2BFactor(FBlindFactorColumn.StringArray(OutLang));
  TranslateHydrTable(OutLang);
end;

procedure TPresenter.PrintErrors;
begin
  FCore.PrintErrorsOnly;
  FView.ClearHydrTable;
end;

procedure TPresenter.ClearQueues;
begin
  FCore.ClearQueues;

  FPollColumn.Clear;
  FGapSpeedColumn.Clear;
  FAreaColumn.Clear;
  FBlindFactorColumn.Clear;
  FDiffLevelColumn.Clear;
  FFrontLevelColumn.Clear;
  FChnSpeedColumn.Clear;
end;

{ delegation only }

procedure TPresenter.InitView;
begin
  FCore.InitView;
end;

procedure TPresenter.TranslateUi;
begin
  FCore.TranslateUi;
end;

procedure TPresenter.TranslateOut;
begin
  FCore.TranslateOut;
end;

procedure TPresenter.Run;
begin
  FCore.Run;
end;

procedure TPresenter.LogError(SpecMap: TTranslate; const Args: array of const);
begin
  FCore.LogError(SpecMap, Args);
end;

procedure TPresenter.AddOutput(SpecMap: TTranslate; const Args: array of const);
begin
  FCore.AddOutput(SpecMap, Args);
end;

procedure TPresenter.AddOutput(const AText: String);
begin
  FCore.AddOutput(AText);
end;

procedure TPresenter.AddPoll(const AText: String);
begin
  FPollColumn.Append(AText);
end;

procedure TPresenter.AddGapSpeed(SpecMap: TTranslate;
  const Args: array of const);
begin
  FGapSpeedColumn.Append(SpecMap, Args);
end;

procedure TPresenter.AddArea(const AText: String);
begin
  FAreaColumn.Append(AText);
end;

procedure TPresenter.AddBlindFactor(const AText: String);
begin
  FBlindFactorColumn.Append(AText);
end;

procedure TPresenter.AddDiffLevel(SpecMap: TTranslate;
  const Args: array of const);
begin
  FDiffLevelColumn.Append(SpecMap, Args);
end;

procedure TPresenter.AddFrontLevel(SpecMap: TTranslate;
  const Args: array of const);
begin
  FFrontLevelColumn.Append(SpecMap, Args);
end;

procedure TPresenter.AddChnSpeed(SpecMap: TTranslate;
  const Args: array of const);
begin
  FChnSpeedColumn.Append(SpecMap, Args);
end;

end.
