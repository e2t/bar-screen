unit Model;

{$mode ObjFPC}{$H+}

interface

uses
  Errors,
  Fgl,
  Nullable,
  UPresenter;

type
  TCalcProfileMass = function(Gs: Integer): ValReal;

  TFilterProfile = record
    Name: String;
    Width, ShapeFactor: ValReal;
    IsRemovable: Boolean;
    CalcMass: TCalcProfileMass;
  end;

  TInputData = record
    Width, Depth, MinDrop, Gap, Angle: ValReal;
    Ws, Hs, Gs: specialize TNullable<Integer>;
    Flow, Level: specialize TNullable<ValReal>;
    Fp: TFilterProfile;
  end;

  THsData = record
    FullDropHeight: ValReal;
  end;

  TWsData = 5..30;
  TProfileRange = 0..5;

var
  HeightSeries: specialize TFPGMap<Integer, THsData>;
  GsData: array [0..18] of Integer;
  NominalGaps: array [0..16] of ValReal;
  DefaultDischargeHeight, DefaultTiltAngle: ValReal;
  Profiles: array [TProfileRange] of TFilterProfile;

procedure CalcBarScreen(const Inp: TInputData; Prs: IModelPresenter);

implementation

uses
  FloatUtils,
  L10n,
  Math,
  MathUtils,
  MeasurementUtils,
  SysUtils,
  Texts;

type
  TDrive = record
    Designation: String;
    Weight, Power, Torque, Speed: ValReal;
  end;

  TSpring = record
    Designation: String;
    R: ValReal;
  end;

  { Расчетные гидравлические параметры, зависящие от загрязнения полотна. }
  THydraulic = record
    Pollution, RelativeFlowArea, BlindingFactor: ValReal;

    VelocityInGap, LevelDiff, StartLevel,
    UpstreamFlowVelocity: specialize TNullable<ValReal>;
  end;

  TDriveAndSpring = record
    Drive: TDrive;
    Spring: TSpring;
  end;

  IMassCalculator = interface
    function CalcMassGridBalk: ValReal;
    function CalcMassGridScrew: ValReal;
    function CalcMass: ValReal;
  end;

  TBarScreen = class sealed
  private
    FPresenter: IModelPresenter;
    FFp: TFilterProfile;
    FDrive: TDrive;
    FSpring: TSpring;
    FWaterFlow, FFinalLevel: specialize TNullable<ValReal>;
    FIsSmall, FIsHeavy, FIsStandardSerie, FIsDrivePassed: Boolean;
    FHydraulics: array of THydraulic;
    FWeightCalculator: IMassCalculator;

    FWs, FHs, FGs, FFpCount, FChannelWs, FStandHs, FRakeCount, FWsDiff,
    FBackwallHs, FCoverHs, FCoverCount: Integer;

    FDepth, FMinDrop, FNominalGap, FAngle, FChannelWidth, FFullDrop, FDrop,
    FInnerWidth, FStep, FGap, FB, FC, FEfficiency, FStandHeight, FInnerHeight,
    FChainLength, FLength, FMinTorque, FSpringPreload, FFpLength, FDropWidth,
    FWeight: ValReal;

    function CalcOptimalHs: Integer;
    function CalcOptimalGs: Integer;
    function CalcFpCount: Integer;
    function CalcStandHs: Integer;
    function CalcHydraulic(APollution: ValReal): THydraulic;
    function CalcInnerScreenHeight(Gs: Integer): ValReal;
    function CalcMinTorque: ValReal;
    procedure CalcDrive;
    function CalcSpringLoad: ValReal;
  public
    constructor Create(const Inp: TInputData; APresenter: IModelPresenter);
  end;

  TMassLarge = class sealed(TInterfacedObject, IMassCalculator)
  private
    FScr: TBarScreen;

    function CalcMassRke0102ad: ValReal;
    function CalcMassRke0104ad: ValReal;
    function CalcMassRke010101ad: ValReal;
    function CalcMassRke010111ad: ValReal;
    function CalcMassRke010102ad: ValReal;
    function CalcMassRke010103ad: ValReal;
    function CalcMassRke010104ad: ValReal;
    function CalcMassRke010105ad: ValReal;
    function CalcMassRke010107ad: ValReal;
    function CalcMassRke010108ad: ValReal;
    function CalcMassRke010109ad: ValReal;
    function CalcMassRke0101ad: ValReal;
    function CalcMassRke01ad: ValReal;
    function CalcMassRke02ad: ValReal;
    function CalcMassRke03ad: ValReal;
    function CalcMassRke04ad: ValReal;
    function CalcMassRke05ad: ValReal;
    function CalcMassRke06ad: ValReal;
    function CalcMassRke08ad: ValReal;
    function CalcMassRke09ad: ValReal;
    function CalcMassRke10ad: ValReal;
    function CalcMassRke13ad: ValReal;
    function CalcMassRke19ad: ValReal;
    function CalcChainMassMs56r100: ValReal;
    { IMassCalculator }
    function CalcMassGridBalk: ValReal;
    function CalcMassGridScrew: ValReal;
    function CalcMass: ValReal;
  public
    constructor Create(AScr: TBarScreen);
  end;

  TMassSmall = class sealed(TInterfacedObject, IMassCalculator)
  private
    FScr: TBarScreen;

    function CalcMassFrame: ValReal;
    function CalcMassBackwall: ValReal;
    function CalcMassTray: ValReal;
    function CalcMassCover: ValReal;
    function CalcChainMassMs28r63: ValReal;
    function CalcMassRake: ValReal;
    function CalcChainWithRakesMass: ValReal;
    function CalcMassDischarge: ValReal;
    function CalcMassTopCover: ValReal;
    function CalcMassDriveAsm: ValReal;
    function CalcMassEjector: ValReal;
    function CalcMassFrameLoop: ValReal;
    function CalcMassSupport: ValReal;
    function CalcMassSideScreen: ValReal;
    function CalcMassBody: ValReal;
    { IMassCalculator }
    function CalcMassGridBalk: ValReal;
    function CalcMassGridScrew: ValReal;
    function CalcMass: ValReal;
  public
    constructor Create(AScr: TBarScreen);
  end;

const
  Pollutions: array of ValReal = (0.1, 0.2, 0.3, 0.4);
  MaxDiffScreenAndGrateHs = 9;

var
  AngleDiff, MinTiltAngle, MaxTiltAngle, ChainStep, ChainStepY: ValReal;
  SmallDrivesAndSprings: array [0..0] of TDriveAndSpring;
  BigDrivesAndSprings: array [0..3] of TDriveAndSpring;
  SmallChains: specialize TFPGMap<Integer, ValReal>;

function NewHsData(FullDropHeight: ValReal): THsData;
begin
  Result.FullDropHeight := FullDropHeight;
end;

function CalcMass3999(Gs: Integer): ValReal;
begin
  Result := 0.1167 * Gs - 0.13;
end;

function CalcMass341(Gs: Integer): ValReal;
begin
  Result := 0.0939 * Gs - 0.1067;
end;

function CalcMass777(Gs: Integer): ValReal;
begin
  Result := 0.1887 * Gs - 0.194;
end;

function CalcMass1492(Gs: Integer): ValReal;
begin
  Result := 0.2481 * Gs - 0.4829;
end;

function CalcMass6x30(Gs: Integer): ValReal;
begin
  Result := 0.144 * Gs - 0.158;
end;

function CalcMass6x60(Gs: Integer): ValReal;
begin
  Result := 0.2881 * Gs - 0.5529;
end;

function CalcLevelDiff(B, C, D: ValReal): ValReal;
var
  A1, A2, B1, C1, C2: ValReal;
begin
  A1 := 27 * Sqr(D) + 18 * B * C * D + 4 * Power(C, 3) - 4 * Power(B, 3) * D -
    Sqr(B) * Sqr(C);
  A2 := 27 * D + 9 * B * C - 2 * Power(B, 3) + 5.19615 * Sqrt(A1);
  B1 := 2187 * C - 729 * Sqr(B);
  C1 := 27 * Sqr(D) + 18 * B * C * D + 4 * Power(C, 3) - 4 * Power(B, 3) * D -
    Sqr(B) * Sqr(C);
  C2 := 27 * D + 9 * B * C - 2 * Power(B, 3) + 5.19615 * Sqrt(C1);
  Result := 0.264567 * Power(A2, 1 / 3) - 0.000576096 * B1 / Power(C2, 1 / 3) -
    0.333333 * B;
end;

function CalcMassGrid(const Mc: IMassCalculator;
  const Scr: TBarScreen): ValReal;
begin
  Result := Mc.CalcMassGridBalk * 2 + Scr.FFp.CalcMass(Scr.FGs) * Scr.FFpCount +
    Mc.CalcMassGridScrew * 4;
end;

procedure CalcBarScreen(const Inp: TInputData; Prs: IModelPresenter);
var
  Scr: TBarScreen;
  Add1: String = '00';
  Add2: String = '00';
  AddDsg: String = '';
  Prefix: String = '';
  IsScrChnDiff, IsHsGsDiff: Boolean;
  HasWarnings: Boolean = False;
  Dsg, Weight: TTranslate;
  H: THydraulic;
  Poll, Diff: ValReal;
begin
  Scr := TBarScreen.Create(Inp, Prs);

  IsScrChnDiff := Scr.FChannelWs <> Scr.FWs;
  IsHsGsDiff := Scr.FGs <> Scr.FHs;
  if IsScrChnDiff or IsHsGsDiff then
  begin
    if IsScrChnDiff then
      Add1 := Format('%0.2d', [Scr.FChannelWs]);
    if IsHsGsDiff then
      Add2 := Format('%0.2d', [Scr.FGs]);
    AddDsg := '(' + Add1 + Add2 + ')';
  end;
  if Scr.FIsSmall then
    Dsg := TextOutSmallDsg
  else
    Dsg := TextOutBigDsg;
  Prs.AddOutput(Dsg, [Scr.FWs, Scr.FHs, AddDsg, Scr.FFp.Name,
    FStr(FromSI('mm', Scr.FNominalGap))]);

  if Scr.FIsStandardSerie then
    Weight := TextOutWeight
  else
    Weight := TextOutWeightApprox;
  Prs.AddOutput(Weight, [FStr(Scr.FWeight, 0)]);

  with Scr.FDrive do
    Prs.AddOutput(TextOutDrive, [Designation, FStr(FromSI('kW', Power)),
      FStr(Torque), FStr(FromSI('rpm', Speed))]);

  Prs.AddOutput('');
  if Scr.FIsSmall then
    Prefix := '≈';
  Prs.AddOutput(TextOutInnerWidth, [FStr(FromSI('mm', Scr.FInnerWidth), 0)]);
  Prs.AddOutput(TextOutInnerHeight, [FStr(FromSI('mm', Scr.FInnerHeight), 0)]);
  Prs.AddOutput(TextOutScrLength, [FStr(FromSI('mm', Scr.FLength), 0)]);
  Prs.AddOutput(TextOutChainLength, [FStr(FromSI('mm', Scr.FChainLength), 0)]);
  Prs.AddOutput(TextOutFpLength, [FStr(FromSI('mm', Scr.FFpLength), 0)]);
  Prs.AddOutput(TextOutFpCount, [Scr.FFpCount]);
  Prs.AddOutput(TextOutRakeCount, [Scr.FRakeCount]);
  Prs.AddOutput(TextOutDropWidth, [FStr(FromSI('mm', Scr.FDropWidth), 0)]);
  Prs.AddOutput(TextOutDropAboveTop,
    [Prefix, FStr(FromSI('mm', Scr.FDrop), 0)]);
  Prs.AddOutput(TextOutDropAboveBottom,
    [Prefix, FStr(FromSI('mm', Scr.FFullDrop), 0)]);

  Prs.AddOutput('');
  for H in Scr.FHydraulics do
  begin
    Poll := Round(H.Pollution * 100);
    Prs.AddPoll(Format('%.0f%%', [Poll]));
    if H.VelocityInGap.HasValue then
      Prs.AddGapSpeed(TextOutHydrMs, [FStr(H.VelocityInGap, -2)]);
    Prs.AddArea(FStr(H.RelativeFlowArea, -2));
    Prs.AddBlindFactor(FStr(H.BlindingFactor * 1000, -1));
    if H.LevelDiff.HasValue then
      Prs.AddDiffLevel(TextOutHydrMm, [FStr(FromSI('mm', H.LevelDiff), 0)]);
    if H.StartLevel.HasValue then
    begin
      Prs.AddFrontLevel(TextOutHydrMm, [FStr(FromSI('mm', H.StartLevel), 0)]);
      if IsGreater(H.StartLevel, Scr.FDepth) then
      begin
        Prs.AddOutput(TextOutWarningOverflow, [Poll]);
        HasWarnings := True;
      end;
      Diff := RoundTo(H.StartLevel.Value - Scr.FInnerHeight, -3);
      if IsGreaterOrEqual(Diff, 0) then
      begin
        Prs.AddOutput(TextOutWarningDiff, [Poll, FStr(FromSI('mm', Diff), 0)]);
        HasWarnings := True;
      end;
    end;
    if H.UpstreamFlowVelocity.HasValue then
      Prs.AddChnSpeed(TextOutHydrMs, [FStr(H.UpstreamFlowVelocity, -2)]);
  end;

  if HasWarnings then
    Prs.AddOutput('');
  Prs.AddOutput(TextOutForDesigner, []);
  Prs.AddOutput('');
  Prs.AddOutput(TextOutMinTorque, [FStr(Scr.FMinTorque, 0)]);
  Prs.AddOutput(TextOutGap, [FStr(FromSI('mm', Scr.FGap), -2)]);
  Prs.AddOutput(TextOutSpring, [Scr.FSpring.Designation,
    FStr(FromSI('mm', Scr.FSpringPreload))]);

  Prs.AddOutput('');
  Prs.AddOutput(TextOutEquationFile, []);

  Prs.AddOutput('');
  Prs.AddOutput(Format('"count" = %d  ''''Кількість прутів полотна',
    [Scr.FFpCount]));
  Prs.AddOutput(Format('"step" = %.3f  ''''Крок прутів полотна',
    [FromSI('mm', Scr.FStep)]));

  FreeAndNil(Scr);
end;

{ TBarScreen }

constructor TBarScreen.Create(const Inp: TInputData;
  APresenter: IModelPresenter);
var
  I: Integer;
  PivotHeight: ValReal;
begin
  FPresenter := APresenter;

  if IsLessOrEqual(Inp.Width, 0) then
  begin
    FPresenter.LogError(TextErrWidth, []);
    raise ELoggedError.Create('Channel width <= 0');
  end;
  if IsLessOrEqual(Inp.Depth, 0) then
  begin
    FPresenter.LogError(TextErrDepth, []);
    raise ELoggedError.Create('Channel depth <= 0');
  end;
  if IsLessOrEqual(Inp.MinDrop, 0) then
  begin
    FPresenter.LogError(TextErrDrop, []);
    raise ELoggedError.Create('Min drop <= 0');
  end;
  if Inp.Flow.HasValue then
    if IsLessOrEqual(Inp.Flow, 0) then
    begin
      FPresenter.LogError(TextErrFlow, []);
      raise ELoggedError.Create('Flow rate <= 0');
    end;
  if Inp.Level.HasValue then
    if IsLessOrEqual(Inp.Level, 0) then
    begin
      FPresenter.LogError(TextErrLevel, []);
      raise ELoggedError.Create('Water level <= 0');
    end;
  if IsLess(Inp.Angle, MinTiltAngle) or IsGreater(Inp.Angle, MaxTiltAngle) then
  begin
    FPresenter.LogError(TextErrAngleDiapason,
      [FStr(FromSI('deg', DefaultTiltAngle)), FStr(FromSI('deg', AngleDiff))]);
    raise ELoggedError.Create('Angle is not in allowed range');
  end;

  FChannelWidth := Inp.Width;
  FDepth := Inp.Depth;
  FMinDrop := Inp.MinDrop;
  FFp := Inp.Fp;
  FWaterFlow := Inp.Flow;
  FFinalLevel := Inp.Level;
  FNominalGap := Inp.Gap;
  FAngle := Inp.Angle;

  if Inp.Ws.HasValue then
    FWs := Inp.Ws
  else
  begin
    FWs := SafeTrunc((Inp.Width - SI(100, 'mm')) * 10);
    if FWs < Low(TWsData) then
      FWs := Low(TWsData);
  end;

  if Inp.Hs.HasValue then
    FHs := Inp.Hs
  else
    FHs := CalcOptimalHs;

  FFullDrop := HeightSeries.KeyData[FHs].FullDropHeight;
  FIsSmall := ((FWs <= 7) and (FHs <= 15)) or ((FWs <= 9) and (FHs <= 12));
  FDrop := FFullDrop - FDepth;
  if Inp.Hs.HasValue and IsLess(FDrop, FMinDrop) then
  begin
    FPresenter.LogError(TextErrMinDrop, []);
    raise ELoggedError.Create('Drop < MinDrop');
  end;
  if FIsSmall then
    FInnerWidth := 0.1 * FWs - 0.128
  else
    FInnerWidth := 0.1 * FWs - 0.132;
  FFpCount := CalcFpCount;
  FStep := (FInnerWidth + FFp.Width) / (FFpCount + 1);
  FGap := FStep - FFp.Width;

  { Гидравлический расчет }
  if FFinalLevel.HasValue then
  begin
    FB := 2 * FFinalLevel.Value;
    FC := Sqr(FFinalLevel);
  end;
  FEfficiency := FGap / (FGap + FFp.Width);
  SetLength(FHydraulics, Length(Pollutions));
  for I := Low(Pollutions) to High(Pollutions) do
    FHydraulics[I] := CalcHydraulic(Pollutions[I]);

  if Inp.Gs.HasValue then
    FGs := Inp.Gs
  else
    FGs := CalcOptimalGs;
  if FHs - FGs < -MaxDiffScreenAndGrateHs then
  begin
    FPresenter.LogError(TextErrDiffHsGs, []);
    raise ELoggedError.Create('Diff Hs Gs');
  end;

  FChannelWs := Round((FChannelWidth - 0.1) / 0.1);
  if FChannelWs - FWs < 0 then
  begin
    FPresenter.LogError(TextErrTooNarrow, []);
    raise ELoggedError.Create('Channel is too narrow');
  end;
  if FChannelWs - FWs > 2 then
  begin
    FPresenter.LogError(TextErrTooWide, []);
    raise ELoggedError.Create('Channel is too wode');
  end;

  FIsHeavy := FHs >= 21;
  PivotHeight := 0.0985 * FHs + 1.0299;
  FStandHeight := PivotHeight - FDepth;
  FStandHs := CalcStandHs;

  if FFpCount < 2 then
  begin
    FPresenter.LogError(TextErrBigGap, []);
    raise ELoggedError.Create('Too big gap');
  end;

  FInnerHeight := CalcInnerScreenHeight(FGs);
  if FFinalLevel.HasValue then
  begin
    if IsGreaterOrEqual(FFinalLevel, FDepth) then
    begin
      FPresenter.LogError(TextErrFinalAboveChn, []);
      raise ELoggedError.Create('FINAL_ABOVE_CHN');
    end;
    if IsGreaterOrEqual(FFinalLevel, FInnerHeight) then
    begin
      FPresenter.LogError(TextErrFinalAboveGs, []);
      raise ELoggedError.Create('FINAL_ABOVE_GS');
    end;
  end;

  if FIsSmall then
  begin
    FChainLength := SmallChains.KeyData[FHs];
    FLength := FChainLength / 2 + 0.38;
  end
  else
  begin
    FChainLength := 0.2 * FHs + 3.2;
    FLength := 0.1 * FHs + 1.765;
  end;

  FRakeCount := Round(FChainLength / 0.825);
  FIsStandardSerie := (FWs <= 24) and (FHs <= 30);
  FMinTorque := CalcMinTorque;
  CalcDrive;
  FSpringPreload := CalcSpringLoad;
  if Inp.Fp.IsRemovable then
    FFpLength := 0.1 * FGs - 0.175
  else
    FFpLength := 0.1 * FGs - 0.106;
  FDropWidth := 0.1 * FWs - 0.129;
  FWsDiff := FChannelWs - FWs;
  FBackwallHs := FHs - FGs + 10;
  FCoverHs := Min(FBackwallHs, FStandHs);
  if FWs <= 10 then
    FCoverCount := 2
  else
    FCoverCount := 4;
  if FIsSmall then
    FWeightCalculator := TMassSmall.Create(Self)
  else
    FWeightCalculator := TMassLarge.Create(Self);
  FWeight := FWeightCalculator.CalcMass;
end;

{ From Luk'yanenko }
function TBarScreen.CalcSpringLoad: ValReal;
var
  MaxDeltaSensor, SensorDelta, AxesDistance, MaxSpringLoad: ValReal;
begin
  MaxDeltaSensor := SI(9.5, 'mm');
  SensorDelta := SI(15.5, 'mm');
  if FIsSmall then
    AxesDistance := 0.2
  else
    AxesDistance := 0.195;
  MaxSpringLoad := FMinTorque / AxesDistance * 0.9;
  Result := MRound(MaxSpringLoad / FSpring.R - SensorDelta, SI(0.5, 'mm'));
  if not FIsDrivePassed and IsGreater(Result, MaxDeltaSensor) then
    Result := MaxDeltaSensor;
end;

procedure TBarScreen.CalcDrive;
var
  DrivesAndSprings: array of TDriveAndSpring;
  I, Last: TDriveAndSpring;
begin
  if FIsSmall then
    DrivesAndSprings := SmallDrivesAndSprings
  else
    DrivesAndSprings := BigDrivesAndSprings;
  for I in DrivesAndSprings do
    if IsLessOrEqual(FMinTorque, I.Drive.Torque) then
    begin
      FDrive := I.Drive;
      FSpring := I.Spring;
      FIsDrivePassed := True;
      exit;
    end;

  { From Luk'yanenko
    before it was: return None }
  Last := DrivesAndSprings[High(DrivesAndSprings)];
  FDrive := Last.Drive;
  FSpring := Last.Spring;
  FIsDrivePassed := False;
end;

function TBarScreen.CalcMinTorque: ValReal;
const
  SpecificGarbageLoad = 90;  { kg/m, from Luk'yanenko }
  PowerMargin = 1.2;
var
  LeverArm, RakePitch: ValReal;
begin
  { радиус дел. окружности звездочки }
  if FIsSmall then
    LeverArm := SI(63, 'mm')
  else
    LeverArm := SI(130.655, 'mm');
  RakePitch := SI(0.8, 'meter');
  Result := SpecificGarbageLoad * GravAcc * PowerMargin * LeverArm *
    Ceil(FChainLength / RakePitch / 2) * (FWs / 10 - 0.126);
end;

function TBarScreen.CalcStandHs: Integer;
const
  A1 = 0.4535; // meter
  A2 = 0.6035; // meter
  A3 = 0.8535; // meter
begin
  if IsLessOrEqual(A1, FStandHeight) and IsLess(FStandHeight, A2) then
  begin
    Result := 6;
    exit;
  end;
  if IsLessOrEqual(A2, FStandHeight) and IsLess(FStandHeight, A3) then
  begin
    Result := 7;
    exit;
  end;
  if IsGreaterOrEqual(FStandHeight, A3) then
  begin
    Result := Round((FStandHeight - 1.0035) / 0.3) * 3 + 10;
    exit;
  end;
  FPresenter.LogError(TextErrTooSmall, []);
  raise ELoggedError.Create('Too small');
end;

function TBarScreen.CalcOptimalGs: Integer;
var
  StartLevels: array of ValReal = nil;
  I, Gs: Integer;
  SomeLevel: specialize TNullable<ValReal>;
  MinGrateHeight, GrateHeight: ValReal;
  CanBeEqual: Boolean;
begin
  if FHydraulics[0].StartLevel.HasValue then
  begin
    SetLength(StartLevels, Length(FHydraulics));
    for I := Low(FHydraulics) to High(FHydraulics) do
      StartLevels[I] := FHydraulics[I].StartLevel;
    SomeLevel := MaxValue(StartLevels);
  end
  else
    SomeLevel := FFinalLevel;
  if SomeLevel.HasValue and IsLess(SomeLevel, FDepth) then
  begin
    MinGrateHeight := SomeLevel;
    CanBeEqual := False;
  end
  else
  begin
    MinGrateHeight := FDepth;
    CanBeEqual := True;
  end;
  for Gs in GsData do
  begin
    GrateHeight := CalcInnerScreenHeight(Gs);
    if IsGreater(GrateHeight, MinGrateHeight) or
      (CanBeEqual and IsEqual(GrateHeight, MinGrateHeight)) then
    begin
      Result := Gs;
      exit;
    end;
  end;
  FPresenter.LogError(TextErrTooHighGs, []);
  raise ELoggedError.Create('Too high gs');
end;

{ ВНИМАНИЕ: Не учитывается высота лотка. }
function TBarScreen.CalcInnerScreenHeight(Gs: Integer): ValReal;
begin
  Result := RoundTo((98.481 * Gs - 173.215) / 1000, -3);
end;

function TBarScreen.CalcHydraulic(APollution: ValReal): THydraulic;
var
  D: ValReal;
begin
  Result.Pollution := APollution;
  Result.RelativeFlowArea := FGap / (FGap + FFp.Width) -
    APollution * FGap / (FFp.Width + FGap);
  Result.BlindingFactor := FGap - Result.RelativeFlowArea * (FGap + FFp.Width);
  if FWaterFlow.HasValue then
  begin
    D := Sqr(FWaterFlow.Value / FInnerWidth / (FEfficiency *
      (1 - APollution))) / (2 * GravAcc) * Sin(FAngle) * FFp.ShapeFactor *
      Power((FFp.Width + Result.BlindingFactor) /
      (FGap - Result.BlindingFactor), 4 / 3);
    if FFinalLevel.HasValue then
    begin
      Result.LevelDiff := CalcLevelDiff(FB, FC, D);
      Result.StartLevel := FFinalLevel.Value + Result.LevelDiff.Value;
      Result.UpstreamFlowVelocity := FWaterFlow.Value / FChannelWidth /
        Result.StartLevel.Value;
      Result.VelocityInGap := FWaterFlow.Value / FInnerWidth /
        Result.StartLevel.Value / FEfficiency / (1 - APollution);
    end;
  end;
end;

function TBarScreen.CalcFpCount: Integer;
var
  NominalStep: ValReal;
begin
  NominalStep := FNominalGap + FFp.Width;
  Result := SafeTrunc((FInnerWidth + FFp.Width) / NominalStep) - 1;
end;

function TBarScreen.CalcOptimalHs: Integer;
var
  MinFullDrop: ValReal;
  I: Integer;
begin
  MinFullDrop := FDepth + FMinDrop;
  for I := 0 to HeightSeries.Count - 1 do
    if IsGreaterOrEqual(HeightSeries.Data[I].FullDropHeight, MinFullDrop) then
    begin
      Result := HeightSeries.Keys[I];
      exit;
    end;
  FPresenter.LogError(TextErrTooHighHs, []);
  raise ELoggedError.Create('Too High Hs');
end;

{ TMassLarge }

constructor TMassLarge.Create(AScr: TBarScreen);
begin
  FScr := AScr;
end;

function TMassLarge.CalcMassRke0102ad: ValReal;
begin
  Result := 1.5024 * FScr.FWs - 0.1065;
end;

function TMassLarge.CalcMassRke0104ad: ValReal;
begin
  Result := 0.2886 * FScr.FBackwallHs * FScr.FWs -
    0.2754 * FScr.FBackwallHs +
    2.2173 * FScr.FWs -
    2.6036;
end;

function TMassLarge.CalcMassRke010101ad: ValReal;
begin
  Result := 2.7233 * FScr.FHs + 46.32;
end;

function TMassLarge.CalcMassRke010111ad: ValReal;
begin
  Result := 2.7467 * FScr.FHs + 46.03;
end;

function TMassLarge.CalcMassRke010102ad: ValReal;
begin
  Result := 0.5963 * FScr.FWs - 0.3838;
end;

function TMassLarge.CalcMassRke010103ad: ValReal;
begin
  Result := 0.5881 * FScr.FWs + 0.4531;
end;

function TMassLarge.CalcMassRke010104ad: ValReal;
begin
  Result := 0.8544 * FScr.FWs - 0.1806;
end;

function TMassLarge.CalcMassRke010105ad: ValReal;
begin
  Result := 0.6313 * FScr.FWs + 0.1013;
end;

function TMassLarge.CalcMassRke010107ad: ValReal;
begin
  Result := 0.605 * FScr.FWsDiff + 3.36;
end;

function TMassLarge.CalcMassRke010108ad: ValReal;
begin
  Result := 0.445 * FScr.FWs - 0.245;
end;

function TMassLarge.CalcMassRke010109ad: ValReal;
begin
  if FScr.FWs <= 10 then
    Result := 0.136 * FScr.FWs + 0.13
  else
    Result := 0.1358 * FScr.FWs + 0.2758;
end;

function TMassLarge.CalcMassRke0101ad: ValReal;
const
  Fasteners = 2.22;
  MassRke0101ad02 = 0.42;
begin
  Result := CalcMassRke010101ad +
    CalcMassRke010111ad +
    CalcMassRke010102ad * 2 +
    CalcMassRke010103ad +
    CalcMassRke010104ad +
    CalcMassRke010105ad +
    CalcMassRke010107ad * 2 +
    CalcMassRke010108ad +
    CalcMassRke010109ad +
    MassRke0101ad02 * 2 +
    Fasteners;
end;

function TMassLarge.CalcMassRke01ad: ValReal;
const
  Fasteners = 1.07;
  MassRke01ad01 = 0.62;
begin
  Result := CalcMassRke0101ad +
    CalcMassRke0102ad +
    CalcMassGrid(Self, FScr) +
    CalcMassRke0104ad +
    MassRke01ad01 * 2 +
    Fasteners;
end;

function TMassLarge.CalcMassRke02ad: ValReal;
var
  A: ValReal = 0;
begin
  if FScr.FIsHeavy then
    A := 2.29;
  Result := 1.85 * FScr.FWs + 97.28 + A;
end;

function TMassLarge.CalcMassRke03ad: ValReal;
begin
  Result := 0.12 * FScr.FWsDiff * FScr.FGs +
    2.12 * FScr.FWsDiff +
    0.4967 * FScr.FGs -
    1.32;
end;

function TMassLarge.CalcMassRke04ad: ValReal;
begin
  Result := 0.5524 * FScr.FWs + 0.2035;
end;

function TMassLarge.CalcMassRke05ad: ValReal;
begin
  Result := 0.8547 * FScr.FWs + 1.4571;
end;

function TMassLarge.CalcMassRke06ad: ValReal;
begin
  Result := 0.5218 * FScr.FWs + 0.6576;
end;

{ Масса подставки на пол }
function TMassLarge.CalcMassRke08ad: ValReal;
begin
  Assert(FScr.FStandHs >= 6);
  if FScr.FStandHs = 6 then
    Result := 17.81
  else if FScr.FStandHs = 7 then
    Result := 21.47
  else
    Result := 1.8267 * FScr.FStandHs + 8.0633;
end;

function TMassLarge.CalcMassRke09ad: ValReal;
begin
  Result := 1.7871 * FScr.FWs - 0.4094;
end;

function TMassLarge.CalcMassRke10ad: ValReal;
begin
  if FScr.FWs <= 10 then
    Result := 0.06 * FScr.FCoverHs * FScr.FWs -
      0.055 * FScr.FCoverHs +
      0.3167 * FScr.FWs +
      0.3933
  else
    Result := 0.03 * FScr.FCoverHs * FScr.FWs -
      0.0183 * FScr.FCoverHs +
      0.1582 * FScr.FWs +
      0.6052;
end;

{ TODO: Возможно рамку нужно делать по высоте канала, а не полотна. }
function TMassLarge.CalcMassRke13ad: ValReal;
begin
  Result := 0.1811 * FScr.FGs + 0.49 * FScr.FWs + 0.7867;
end;

function TMassLarge.CalcMassRke19ad: ValReal;
begin
  Result := 0.0161 * FScr.FGs + 0.2067;
end;

function TMassLarge.CalcChainMassMs56r100: ValReal;
begin
  Result := 4.18 * FScr.FChainLength;
end;

function TMassLarge.CalcMassGridBalk: ValReal;
begin
  Result := 0.6919 * FScr.FWs - 0.7431;
end;

function TMassLarge.CalcMassGridScrew: ValReal;
begin
  Result := 0.16;
end;

function TMassLarge.CalcMass: ValReal;
const
  Fasteners = 1.24;
  MassRke07ad = 1.08;
  MassRke11ad = 0.42;
  MassRke12ad = 0.16;
  MassRke18ad = 1.13;
  MassRke00ad05 = 0.87;
  MassRke00ad09 = 0.01;
  MassRke00ad13 = 0.15;
begin
  Result := CalcMassRke01ad +
    CalcMassRke02ad +
    CalcMassRke03ad * 2 +
    CalcMassRke04ad * FScr.FRakeCount +
    CalcMassRke05ad +
    CalcMassRke06ad +
    MassRke07ad +
    CalcMassRke08ad * 2 +
    CalcMassRke09ad +
    CalcMassRke10ad * FScr.FCoverCount +
    MassRke11ad * 2 +
    MassRke12ad * 2 +
    CalcMassRke13ad +
    MassRke18ad * 2 +
    CalcMassRke19ad +
    MassRke00ad05 * 4 +
    MassRke00ad09 * 2 +
    MassRke00ad13 * 2 +
    CalcChainMassMs56r100 * 2 +
    Fasteners;
end;

{ TMassSmall }

constructor TMassSmall.Create(AScr: TBarScreen);
begin
  FScr := AScr;
end;

{ Рама }
function TMassSmall.CalcMassFrame: ValReal;
begin
  Result := 1.95 * FScr.FWs + 3.18 * FScr.FHs + 50.02;
end;

{ Стол }
function TMassSmall.CalcMassBackwall: ValReal;
begin
  Result := 0.2358 * FScr.FWs * FScr.FBackwallHs +
    1.3529 * FScr.FWs -
    0.0383 * FScr.FBackwallHs -
    0.8492;
end;

{ Лоток }
function TMassSmall.CalcMassTray: ValReal;
begin
  Result := 0.7575 * FScr.FWs - 0.225;
end;

{ Облицовка }
function TMassSmall.CalcMassCover: ValReal;
begin
  Result := 0.1175 * FScr.FWs * FScr.FCoverHs +
    0.8413 * FScr.FWs -
    0.085 * FScr.FCoverHs +
    0.0125;
end;

{ Масса цепи (1 шт.) }
function TMassSmall.CalcChainMassMs28r63: ValReal;
begin
  Result := 4.5455 * FScr.FChainLength;
end;

{ Граблина }
function TMassSmall.CalcMassRake: ValReal;
begin
  Result := 0.47 * FScr.FWs - 0.06;
end;

{ Цепь в сборе }
function TMassSmall.CalcChainWithRakesMass: ValReal;
const
  Fasteners = 0.12;
begin
  Result := CalcChainMassMs28r63 * 2 +
    CalcMassRake * FScr.FRakeCount +
    Fasteners;
end;

{ Кожух сброса }
function TMassSmall.CalcMassDischarge: ValReal;
begin
  Result := 1.3 * FScr.FWs + 0.75;
end;

{ Верхняя крышка (на петлях) }
function TMassSmall.CalcMassTopCover: ValReal;
begin
  Result := 0.2775 * FScr.FWs + 0.655;
end;

{ Узел привода (в сборе с валом, подшипниками и т.д.) }
function TMassSmall.CalcMassDriveAsm: ValReal;
begin
  Result := 1.2725 * FScr.FWs + 15.865;
end;

{ Сбрасыватель }
function TMassSmall.CalcMassEjector: ValReal;
begin
  Result := 0.475 * FScr.FWs + 0.47;
end;

{ Рамка из прутка }
function TMassSmall.CalcMassFrameLoop: ValReal;
begin
  Result := 0.34 * FScr.FWs + 0.2883 * FScr.FGs - 1.195;
end;

{ Опора решетки (на канал) }
function TMassSmall.CalcMassSupport: ValReal;
begin
  Result := 1.07 * FScr.FStandHs + 11.91;
end;

{ Защитный экран }
function TMassSmall.CalcMassSideScreen: ValReal;
begin
  Result := 0.1503 * FScr.FWsDiff * FScr.FGs +
    0.7608 * FScr.FWsDiff +
    0.4967 * FScr.FGs -
    2.81;
end;

{ Корпус }
function TMassSmall.CalcMassBody: ValReal;
const
  Fasteners = 1.02;
  { Лыжа }
  MassSki = 0.45;
  { Серьга разрезная }
  MassLug = 0.42;
begin
  Result := CalcMassFrame +
    CalcMassBackwall +
    CalcMassTray +
    MassSki * 2 +
    MassLug * 2 +
    CalcMassGrid(Self, FScr) +
    Fasteners;
end;

function TMassSmall.CalcMassGridBalk: ValReal;
begin
  Result := 0.3825 * FScr.FWs - 0.565;
end;

function TMassSmall.CalcMassGridScrew: ValReal;
begin
  Result := 0.08;
end;

function TMassSmall.CalcMass: ValReal;
const
  Other = 3.57;
begin
  Result := CalcMassBody +
    CalcMassCover +
    CalcChainWithRakesMass +
    CalcMassDischarge +
    CalcMassTopCover +
    CalcMassDriveAsm +
    CalcMassEjector +
    CalcMassFrameLoop +
    CalcMassSupport * 2 +
    CalcMassSideScreen * 2 +
    Other;
end;

var
  Hs, I: Integer;

initialization
  ChainStep := SI(100, 'mm');
  DefaultDischargeHeight := SI(890, 'mm');
  DefaultTiltAngle := SI(80, 'deg');
  AngleDiff := SI(5, 'deg');

  MinTiltAngle := DefaultTiltAngle - AngleDiff;
  MaxTiltAngle := DefaultTiltAngle + AngleDiff;
  ChainStepY := Sin(DefaultTiltAngle) * ChainStep;

  HeightSeries := specialize TFPGMap<Integer, THsData>.Create;
  Hs := 3;
  while Hs <= 171 do
  begin
    HeightSeries.Add(Hs, NewHsData(RoundTo(ChainStepY * Hs + 0.96109, -3)));
    Inc(Hs, 3);
  end;

  for I := Low(GsData) to High(GsData) do
    GsData[I] := 3 * (I + 2);

  NominalGaps[0] := SI(5, 'mm');
  NominalGaps[1] := SI(6, 'mm');
  NominalGaps[2] := SI(8, 'mm');
  NominalGaps[3] := SI(10, 'mm');
  NominalGaps[4] := SI(12, 'mm');
  NominalGaps[5] := SI(15, 'mm');
  NominalGaps[6] := SI(16, 'mm');
  NominalGaps[7] := SI(20, 'mm');
  NominalGaps[8] := SI(25, 'mm');
  NominalGaps[9] := SI(30, 'mm');
  NominalGaps[10] := SI(40, 'mm');
  NominalGaps[11] := SI(50, 'mm');
  NominalGaps[12] := SI(60, 'mm');
  NominalGaps[13] := SI(70, 'mm');
  NominalGaps[14] := SI(80, 'mm');
  NominalGaps[15] := SI(90, 'mm');
  NominalGaps[16] := SI(100, 'mm');

  with Profiles[0] do
  begin
    Name := '3999';
    Width := SI(9.5, 'mm');
    IsRemovable := False;
    ShapeFactor := 1.5;
    CalcMass := @CalcMass3999;
  end;
  with Profiles[1] do
  begin
    Name := '341';
    Width := SI(5.5, 'mm');
    IsRemovable := False;
    ShapeFactor := 0.95;
    CalcMass := @CalcMass341;
  end;
  with Profiles[2] do
  begin
    Name := '777';
    Width := SI(7.8, 'mm');
    IsRemovable := False;
    ShapeFactor := 0.95;
    CalcMass := @CalcMass777;
  end;
  with Profiles[3] do
  begin
    Name := '1492';
    Width := SI(8, 'mm');
    IsRemovable := True;
    ShapeFactor := 0.95;
    CalcMass := @CalcMass1492;
  end;
  with Profiles[4] do
  begin
    Name := '6x30';
    Width := SI(6, 'mm');
    IsRemovable := False;
    ShapeFactor := 2.42;
    CalcMass := @CalcMass6x30;
  end;
  with Profiles[5] do
  begin
    Name := '6x60';
    Width := SI(6, 'mm');
    IsRemovable := True;
    ShapeFactor := 2.42;
    CalcMass := @CalcMass6x60;
  end;

  with SmallDrivesAndSprings[0] do
  begin
    Drive.Designation := 'SK 12080 AZBHVL-63LP/4';
    Drive.Weight := SI(35, 'kg');
    Drive.Power := SI(0.18, 'kW');
    Drive.Torque := SI(244, 'Nm');
    Drive.Speed := SI(4.8, 'rpm');
    Spring.Designation := '1L38151 IMPEX-READY s.c.';
    Spring.R := 16.3e3;
  end;

  with BigDrivesAndSprings[0] do
  begin
    Drive.Designation := 'SK 32100 AZBHVL-71LP/4';
    Drive.Weight := SI(64, 'kg');
    Drive.Power := SI(0.37, 'kW');
    Drive.Torque := SI(826, 'Nm');
    Drive.Speed := SI(2.2, 'rpm');
    Spring.Designation := '1S51151 IMPEX-READY s.c.';
    Spring.R := 60e3;
  end;
  with BigDrivesAndSprings[1] do
  begin
    Drive.Designation := 'SK 32100 AZBHVL-80LP/4';
    Drive.Weight := SI(67, 'kg');
    Drive.Power := SI(0.75, 'kW');
    Drive.Torque := SI(1663, 'Nm');
    Drive.Speed := SI(2.2, 'rpm');
    Spring.Designation := '3S51151 IMPEX-READY s.c.';
    Spring.R := 154e3;
  end;
  with BigDrivesAndSprings[2] do
  begin
    Drive.Designation := 'SK 43125 AZBHVL-90SP/4';
    Drive.Weight := SI(129, 'kg');
    Drive.Power := SI(1.1, 'kW');
    Drive.Torque := SI(3052, 'Nm');
    Drive.Speed := SI(2.4, 'rpm');
    Spring.Designation := '4S63151 IMPEX-READY s.c.';
    Spring.R := 396e3;
  end;
  with BigDrivesAndSprings[3] do
  begin
    Drive.Designation := 'SK 9053.1 AZBH-90SP/4';
    Drive.Weight := SI(214, 'kg');
    Drive.Power := SI(1.1, 'kW');
    Drive.Torque := SI(4265, 'Nm');
    Drive.Speed := SI(2.5, 'rpm');
    Spring.Designation := '5S63152 IMPEX-READY s.c.';
    Spring.R := 801e3;
  end;

  SmallChains := specialize TFPGMap<Integer, ValReal>.Create;
  SmallChains.Add(3, SI(3.528, 'meter'));
  SmallChains.Add(6, SI(4.032, 'meter'));
  SmallChains.Add(9, SI(4.662, 'meter'));
  SmallChains.Add(12, SI(5.292, 'meter'));
  SmallChains.Add(15, SI(5.922, 'meter'));

finalization
  FreeAndNil(HeightSeries);
  FreeAndNil(SmallChains);
end.
