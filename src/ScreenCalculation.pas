unit ScreenCalculation;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

interface

uses
  Nullable;

type
  TFuncCalcMass = function(const HeightSerie: Integer): Double;

  TFilterProfile = record
    //Название профиля.
    Name: string;
    //Ширина профиля, м.
    Width: Double;
    //True - вставное полотно, False - сварное полотно.
    IsRemovable: Boolean;
    //Коэффициент формы.
    ShapeFactor: Double;
    //Вычиление массы исходя из типоразмера полотна.
    CalcMass: TFuncCalcMass;
  end;

  //Структура входных данных для расчета решетки.
  TInputData = record
    //Типоразмер решетки по ширине.
    ScreenWs: TNullableInt;
    //Типоразмер решетки по высоте.
    ScreenHs: TNullableInt;
    //Типоразмер полотна по высоте.
    GrateHs: TNullableInt;
    //Ширина канала, м.
    ChannelWidth: Double;
    //Глубина канала, м.
    ChannelHeight: Double;
    //Минимальная высота сброса, м.
    MinDischargeHeight: Double;
    //Тип фильтровального профиля.
    Fp: TFilterProfile;
    //Прозор полотна, м.
    Gap: Double;
    //Угол наклона, радианы.
    TiltAngle: Double;

    //Гидравлические параметры:
    //Расход воды, м3/с.
    WaterFlow: TNullableReal;
    //Уровень после решетки, м.
    FinalLevel: TNullableReal;
  end;

  //Основные характеристики привода.
  TDriveUnit = record
    Name: string;
    Mass: Double;
    Power: Double;
    OutputTorque: Double;
  end;

  TNullableDrive = specialize TNullable<TDriveUnit>;

  //Расчетные гидравлические параметры, зависящие от загрязнения полотна.
  THydraulic = record
    Pollution: Double;
    VelocityInGap: TNullableReal;
    RelativeFlowArea: Double;
    BlindingFactor: Double;
    LevelDiff: TNullableReal;
    StartLevel: TNullableReal;
    UpstreamFlowVelocity: TNullableReal;
  end;

  TPollutionLevels = 0..3;
  THydraulicArray = array [TPollutionLevels] of THydraulic;

  TBarScreen = record
    ScreenWs, ScreenHs, GrateHs, ChannelWs, StandHs, BackwallHs, WsDiff, CoverHs: Integer;
    IsSmall, IsHeavyVersion, IsStandardSerie: Boolean;
    ProfilesCount, RakesCount, CoversCount: Integer;
    Designation: string;
    Drive: TNullableDrive;

    DischargeFullHeight, DischargeHeight, InnerScreenWidth, ScreenPivotHeight,
    StandHeight, InnerScreenHeight, ChainLength, MinTorque, ScreenLength,
    FpLength, DischargeWidth: Double;

    //Гидравлический расчет:
    B, C: TNullableReal;
    Efficiency: Double;
    Hydraulics: THydraulicArray;
  end;

const
  DefaultDischargeHeight = 0.89;
  DefaultTiltAngle = 1.3962634015954636;
  ScreenWidthSeries = [5..30];
  StdGaps: array of Double = (
    0.005, 0.006, 0.008, 0.010, 0.012, 0.015, 0.016, 0.020, 0.025, 0.030, 0.040,
    0.050, 0.060, 0.070, 0.080, 0.090, 0.100);

var
  ScreenHeightSeries: array [0..47] of Integer;
  GrateHeightSeries: array [0..18] of Integer;
  FilterProfiles: array [0..5] of TFilterProfile;

procedure CalcBarScreen(const InputData: TInputData; out Error: string;
  out Scr: TBarScreen; out Mass: Double);

implementation

uses
  Math, CheckNum, MathUtils, Classes, SysUtils, Measurements,
  MassSmallCalculation, MassLargeCalculation;

type
  TArrayDouble = array of Double;
  TDriveUnits = array of TDriveUnit;

  TSmallHeightSerie = record
    Serie: Integer;
    ChainLength: Double;
  end;

const
  MaxDiffScreenAndGrateHs = 9;
  MaxBigScreenWs = 24;
  MaxBigScreenHs = 30;
  SmallHeightSeries: array [0..4] of TSmallHeightSerie = (
    (Serie: 3; ChainLength: 3.528),
    (Serie: 6; ChainLength: 4.032),
    (Serie: 9; ChainLength: 4.662),
    (Serie: 12; ChainLength: 5.292),
    (Serie: 15; ChainLength: 5.922));

var
  DriveUnitsSmall, DriveUnitsBig: TDriveUnits;

function CalcMass3999(const GrateHs: Integer): Double;
begin
  Result := 0.1167 * GrateHs - 0.13;
end;

function CalcMass341(const GrateHs: Integer): Double;
begin
  Result := 0.0939 * GrateHs - 0.1067;
end;

function CalcMass777(const GrateHs: Integer): Double;
begin
  Result := 0.1887 * GrateHs - 0.194;
end;

function CalcMass1492(const GrateHs: Integer): Double;
begin
  Result := 0.2481 * GrateHs - 0.4829;
end;

function CalcMass6x30(const GrateHs: Integer): Double;
begin
  Result := 0.144 * GrateHs - 0.158;
end;

function CalcMass6x60(const GrateHs: Integer): Double;
begin
  Result := 0.2881 * GrateHs - 0.5529;
end;

//Решетка малая или большая?
function DefineIsSmall(const ScreenWs, ScreenHs: Integer): Boolean;
begin
  Result := ((ScreenWs <= 7) and (ScreenHs <= 15)) or
    ((ScreenWs <= 9) and (ScreenHs <= 12));
end;

//На 100 мм меньше, затем в меньшую сторону.
function CalcScreenWs(const ChannelWidth: Double): Integer;
begin
  Result := Trunc(RoundTo(ChannelWidth - 0.1, -3) * 10);
end;

//Типоразмер расчитывается по конструкции больших решеток.
//Малые решетки подгоняются под типоразмер.
function CalcDischargeFullHeight(const ScreenHs: Integer): Double;
const
  //Шаг цепи больших решеток.
  StepChain = 0.1;
var
  StepH: Double;
begin
  StepH := Sin(DefaultTiltAngle) * StepChain;
  Result := RoundTo(StepH * ScreenHs + 0.96109, -3);
end;

//TODO: Высота решетки - сделать подбор неограниченным.
procedure CalcScreenHs(const ChannelHeight, MinDischargeHeight: Double;
  out IsFound: Boolean; var ScreenHs: Integer);
var
  MinFullDischargeHeight: Double;
  I, Serie: Integer;
begin
  MinFullDischargeHeight := ChannelHeight + MinDischargeHeight;
  IsFound := False;
  I := -1;
  while (I < High(ScreenHeightSeries)) and not IsFound do
  begin
    Inc(I);
    Serie := ScreenHeightSeries[I];
    IsFound := IsMoreEq(CalcDischargeFullHeight(Serie), MinFullDischargeHeight);
  end;
  if IsFound then
    ScreenHs := Serie;
end;

function SelectStartLevels(const Hydraulics: THydraulicArray): TArrayDouble;
var
  I: THydraulic;
  J: Integer;
begin
  SetLength(Result, Length(Hydraulics));
  J := 0;
  for I in Hydraulics do
    if I.StartLevel.HasValue then
    begin
      Result[J] := I.StartLevel.Value;
      Inc(J);
    end;
  SetLength(Result, J);
end;

procedure CalcMinGrateHeight(const SomeLevel: TNullableReal; const ChannelHeight: Double;
  out MinGrateHeight: Double; out CanBeEqual: Boolean);
begin
  if SomeLevel.HasValue and IsLess(SomeLevel.Value, ChannelHeight) then
  begin
    MinGrateHeight := SomeLevel.Value;
    CanBeEqual := False;
  end
  else
  begin
    MinGrateHeight := ChannelHeight;
    CanBeEqual := True;
  end;
end;

//Высота просвета решетки.
//ВНИМАНИЕ: Не учитывается высота лотка.
function CalcInnerScreenHeight(const GrateHs: Integer): Double;
begin
  Result := RoundTo((98.481 * GrateHs - 173.215) / 1e3, -3);
end;

procedure CalcGrateHs(const Hydraulics: THydraulicArray; const FinalLevel: TNullableReal;
  const ChannelHeight: Double; out IsFound: Boolean; var GrateHs: Integer);
var
  StartLevels: array of Double;
  MinGrateHeight, GrateHeight: Double;
  CanBeEqual: Boolean;
  SomeLevel: TNullableReal;
  I: Integer;
begin
  StartLevels := SelectStartLevels(Hydraulics);
  if Length(StartLevels) > 0 then
    SomeLevel.Value := MaxValue(StartLevels)
  else
    SomeLevel := FinalLevel;
  CalcMinGrateHeight(SomeLevel, ChannelHeight, MinGrateHeight, CanBeEqual);

  IsFound := False;
  I := -1;
  while (I < High(GrateHeightSeries)) and not IsFound do
  begin
    Inc(I);
    GrateHeight := CalcInnerScreenHeight(GrateHeightSeries[I]);
    IsFound := IsMore(GrateHeight, MinGrateHeight) or
      (CanBeEqual and IsEqual(GrateHeight, MinGrateHeight));
  end;
  if IsFound then
    GrateHs := GrateHeightSeries[I];
end;

function CalcScreenLength(const IsSmall: Boolean; const ChainLength: Double;
  const ScreenHs: Integer): Double;
begin
  if IsSmall then
    Result := ChainLength / 2 + 0.38
  else
    Result := (100 * ScreenHs + 1765) / 1e3;
end;

function CalcFpLength(const IsFpRemovable: Boolean; const GrateHs: Integer): Double;
begin
  if IsFpRemovable then
    Result := (100 * GrateHs - 175) / 1e3
  else
    Result := (100 * GrateHs - 106) / 1e3;
end;

function CalcDischargeHeight(const DischargeFullHeight, ChannelHeight: Double): Double;
begin
  Result := DischargeFullHeight - ChannelHeight;
end;

function CalcBHydraulic(const FinalLevel: TNullableReal): TNullableReal;
begin
  Result := Default(TNullableReal);
  if FinalLevel.HasValue then
    Result.Value := 2 * FinalLevel.Value;
end;

function CalcCHydraulic(const FinalLevel: TNullableReal): TNullableReal;
begin
  Result := Default(TNullableReal);
  if FinalLevel.HasValue then
    Result.Value := Sqr(FinalLevel.Value);
end;

function CalcRelativeFlowArea(const Blinding, Gap, FpWidth: Double): Double;
begin
  Result := Gap / (Gap + FpWidth) - Blinding * Gap / (FpWidth + Gap);
end;

//В расчете не были указаны единицы измерения (будто это коэффициент),
//но по всему видно, что это должна быть длина.
function CalcBlindingFactor(const RelativeFlowArea, Gap, FpWidth: Double): Double;
begin
  Result := Gap - RelativeFlowArea * (Gap + FpWidth);
end;

//Неизвестны единицы измерения и вообще суть параметра.
function CalcDHydraulic(const Blinding, BlindingFactor, InnerScreenWidth,
  Efficiency, TiltAngle, FpShapeFactor, FpWidth, Gap: Double;
  const WaterFlow: TNullableReal): TNullableReal;
begin
  Result := Default(TNullableReal);
  if WaterFlow.HasValue then
    Result.Value := (
      Sqr(WaterFlow.Value / InnerScreenWidth / (Efficiency * (1 - Blinding)))
      / (2 * GravAcc)) * Sin(TiltAngle) * FpShapeFactor
      * Power((FpWidth + BlindingFactor) / (Gap - BlindingFactor), 4 / 3);
end;

//Эффективная поверхность решетки.
function CalcEfficiency(const Gap, FpWidth: Double): Double;
begin
  Result := Gap / (Gap + FpWidth);
end;

function CalcLevelDiff(const B, C, D: TNullableReal): TNullableReal;
var
  A1, A2, B1, C1, C2: Double;
begin
  Result := Default(TNullableReal);
  if D.HasValue and B.HasValue and C.HasValue then
  begin
    A1 := 27 * Sqr(D.Value) + 18 * B.Value * C.Value * D.Value + 4 * Power(C.Value, 3)
      - 4 * Power(B.Value, 3) * D.Value - Sqr(B.Value) * Sqr(C.Value);
    A2 := 27 * D.Value + 9 * B.Value * C.Value - 2 * Power(B.Value, 3)
      + 5.19615 * Sqrt(A1);
    B1 := 2187 * C.Value - 729 * Sqr(B.Value);
    C1 := 27 * Sqr(D.Value) + 18 * B.Value * C.Value * D.Value + 4 * Power(C.Value, 3)
      - 4 * Power(B.Value, 3) * D.Value - Sqr(B.Value) * Sqr(C.Value);
    C2 := 27 * D.Value + 9 * B.Value * C.Value - 2 * Power(B.Value, 3)
      + 5.19615 * Sqrt(C1);
    Result.Value := 0.264567 * Power(A2, 1 / 3) - 0.000576096 * B1 / Power(C2, 1 / 3)
      - 0.333333 * B.Value;
  end;
end;

function CalcStartLevel(const LevelDiff, FinalLevel: TNullableReal): TNullableReal;
begin
  Result := Default(TNullableReal);
  if FinalLevel.HasValue and LevelDiff.HasValue then
    Result.Value := FinalLevel.Value + LevelDiff.Value;
end;

function CalcUpstreamFlowVelocity(const StartLevel, WaterFlow: TNullableReal;
  const ChannelWidth: Double): TNullableReal;
begin
  Result := Default(TNullableReal);
  if WaterFlow.HasValue and StartLevel.HasValue then
    Result.Value := WaterFlow.Value / (ChannelWidth * StartLevel.Value);
end;

function CalcVelocityInGap(const StartLevel, WaterFlow: TNullableReal;
  const Blinding, InnerScreenWidth, Efficiency: Double): TNullableReal;
begin
  Result := Default(TNullableReal);
  if WaterFlow.HasValue and StartLevel.HasValue then
    Result.Value := WaterFlow.Value / (InnerScreenWidth * StartLevel.Value
      * Efficiency * (1 - Blinding));
end;

function CalcHydraulic(
  const InnerScreenWidth, Efficiency, TiltAngle, FpShapeFactor, FpWidth, Gap,
  ChannelWidth: Double; const WaterFlow, B, C, FinalLevel: TNullableReal): THydraulicArray;
const
  //Разные уровни загрязнения
  Pollutions: array [TPollutionLevels] of Double = (0.1, 0.2, 0.3, 0.4);
var
  I: Integer;
  RelativeFlowArea, BlindingFactor: Double;
  UpstreamFlowVelocity, LevelDiff, D, StartLevel, VelocityInGap: TNullableReal;
begin
  for I in TPollutionLevels do
  begin
    RelativeFlowArea := CalcRelativeFlowArea(Pollutions[I], Gap, FpWidth);
    BlindingFactor := CalcBlindingFactor(RelativeFlowArea, Gap, FpWidth);
    D := CalcDHydraulic(Pollutions[I], BlindingFactor, InnerScreenWidth,
      Efficiency, TiltAngle, FpShapeFactor, FpWidth, Gap, WaterFlow);
    LevelDiff := CalcLevelDiff(B, C, D);
    StartLevel := CalcStartLevel(LevelDiff, FinalLevel);
    UpstreamFlowVelocity := CalcUpstreamFlowVelocity(StartLevel, WaterFlow, ChannelWidth);
    VelocityInGap := CalcVelocityInGap(StartLevel, WaterFlow, Pollutions[I],
      InnerScreenWidth, Efficiency);

    Result[I].Pollution := Pollutions[I];
    Result[I].VelocityInGap := VelocityInGap;
    Result[I].RelativeFlowArea := RelativeFlowArea;
    Result[I].BlindingFactor := BlindingFactor;
    Result[I].LevelDiff := LevelDiff;
    Result[I].StartLevel := StartLevel;
    Result[I].UpstreamFlowVelocity := UpstreamFlowVelocity;
  end;
end;

//Ширина сброса. Подходит для больших и малых решеток.
function CalcDischargeWidth(const ScreenWs: Integer): Double;
begin
  Result := (100 * ScreenWs - 129) / 1e3;
end;

//Подбор мощности привода.
function CalcDrive(const IsSmall: Boolean; const MinTorque: Double): TNullableDrive;
var
  Drives: ^TDriveUnits;
  I: Integer;
  IsFound: Boolean;
begin
  if IsSmall then
    Drives := @DriveUnitsSmall
  else
    Drives := @DriveUnitsBig;
  IsFound := False;
  I := -1;
  while (I < High(Drives^)) and not IsFound do
  begin
    Inc(I);
    IsFound := IsLessEq(MinTorque, Drives^[I].OutputTorque);
  end;
  if IsFound then
    Result.Value := Drives^[I];
end;

//Расчет крутящего момента привода.
function CalcMinTorque(const InnerScreenWidth: Double; const RakesCount: Integer;
  const IsSmall: Boolean): Double;
const
  //кг/м граблины
  SpecificGarbageLoad = 90;
var
  RackLen, Load, LeverArm: Double;
  LoadedRackCount: Integer;
begin
  //условно
  RackLen := InnerScreenWidth;
  LoadedRackCount := Ceil(RakesCount / 2);
  Load := SpecificGarbageLoad * RackLen * LoadedRackCount;
  if IsSmall then
    //126 мм - диаметр дел. окружности звездочки РКЭм
    LeverArm := 0.063
  else
    //261,31 мм - диаметр дел. окружности звездочки РКЭ
    LeverArm := 0.131;
  Result := Load * GravAcc * LeverArm;
end;

//Проверка, входит ли решетка в стандартный типоряд.
function CheckStandardSerie(const ScreenWs, ScreenHs: Integer): Boolean;
begin
  Result := (ScreenWs <= MaxBigScreenWs) and (ScreenHs <= MaxBigScreenHs);
end;

//Обозначение решетки.
function CreateDesignation(const ScreenWs, ScreenHs, ChannelWs, GrateHs: Integer;
  const IsSmall: Boolean; const FpName: string; const Gap: Double): string;
var
  Abbr: string;
  Dsg: TStringList;
begin
  Dsg := TStringList.Create;
  if IsSmall then
    Abbr := 'РКЭм'
  else
    Abbr := 'РКЭ';
  Dsg.Add(Format('%s %.02d%.02d', [Abbr, ScreenWs, ScreenHs]));
  if (ChannelWs <> ScreenWs) or (GrateHs <> ScreenHs) then
  begin
    Dsg.Add('(');
    if ChannelWs = ScreenWs then
      Dsg.Add('00')
    else
      Dsg.Add(Format('%.02d', [ChannelWs]));
    if GrateHs = ScreenHs then
      Dsg.Add('00')
    else
      Dsg.Add(Format('%.02d', [GrateHs]));
    Dsg.Add(')');
  end;
  Dsg.Add(
    Format('.%s.%s', [FpName, FormatFloat('0.#', ToMm(Gap))]));
  Result := String.Join('', Dsg.ToStringArray);
  Dsg.Free;
end;

function CalcInnerScreenWidth(const IsSmall: Boolean; const ScreenWs: Integer): Double;
begin
  if IsSmall then
    Result := 0.1 * ScreenWs - 0.128
  else
    Result := 0.1 * ScreenWs - 0.132;
end;

//Примерное (теоретическое) количество, конструктор может менять шаг.
function CalcProfilesCount(const InnerScreenWidth, Gap, FpWidth: Double): Integer;
begin
  Result := Ceil((InnerScreenWidth - Gap) / (FpWidth + Gap));
end;

function CalcChainLength(const IsSmall: Boolean; const ScreenHs: Integer): Double;
var
  I: Integer;
  IsFound: Boolean;
begin
  if IsSmall then
  begin
    IsFound := False;
    I := -1;
    while (I < High(SmallHeightSeries)) and not IsFound do
    begin
      Inc(I);
      IsFound := SmallHeightSeries[I].Serie = ScreenHs;
    end;
    Assert(IsFound);
    Result := SmallHeightSeries[I].ChainLength;
  end
  else
    Result := 0.2 * ScreenHs + 3.2;
end;

function CalcRakesCount(const ChainLength: Double): Integer;
begin
  Result := Round(ChainLength / 0.825);
end;

function CalcChannelWs(const ChannelWidth: Double): Integer;
begin
  Result := Round((ChannelWidth - 0.1) / 0.1);
end;

function CalcScreenPivotHeight(const ScreenHs: Integer): Double;
begin
  Result := 0.0985 * ScreenHs + 1.0299;
end;

function CalcStandHeight(const ScreenPivotHeight, ChannelHeight: Double): Double;
begin
  Result := ScreenPivotHeight - ChannelHeight;
end;

//Типоразмер подставки на пол.
procedure CalcStandHs(const StandHeight: Double; out IsFound: Boolean;
  var StandHs: Integer);
begin
  IsFound := True;
  if IsLessEq(0.4535, StandHeight) and IsLess(StandHeight, 0.6035) then
    StandHs := 6
  else if IsLessEq(0.6035, StandHeight) and IsLess(StandHeight, 0.8535) then
    StandHs := 7
  else if IsMoreEq(StandHeight, 0.8535) then
    StandHs := Round((StandHeight - 1.0035) / 0.3) * 3 + 10
  else
    IsFound := False;
end;

function CalcBackwallHs(const ScreenHs, GrateHs: Integer): Integer;
begin
  Result := ScreenHs - GrateHs + 10;
end;

function CalcWsDiff(const ChannelWs, ScreenWs: Integer): Integer;
begin
  Result := ChannelWs - ScreenWs;
end;

function CalcCoversCount(const ScreenWs: Integer): Integer;
begin
  if ScreenWs <= 10 then
    Result := 2
  else
    Result := 4;
end;

function CalcCoverHs(const BackwallHs, StandHs: Integer): Integer;
begin
  Result := Min(BackwallHs, StandHs);
end;

procedure CalcBarScreen(const InputData: TInputData; out Error: string;
  out Scr: TBarScreen; out Mass: Double);
var
  IsFound: Boolean;
begin
  Scr := Default(TBarScreen);
  Error := '';

  if InputData.ScreenWs.HasValue then
    Scr.ScreenWs := InputData.ScreenWs.Value
  else
    Scr.ScreenWs := CalcScreenWs(InputData.ChannelWidth);
  if InputData.ScreenHs.HasValue then
    Scr.ScreenHs := InputData.ScreenHs.Value
  else
  begin
    CalcScreenHs(InputData.ChannelHeight, InputData.MinDischargeHeight, IsFound,
      Scr.ScreenHs);
    if not IsFound then
    begin
      Error := 'Не удается подобрать высоту решетки из стандартного ряда.';
      Exit;
    end;
  end;
  Scr.IsSmall := DefineIsSmall(Scr.ScreenWs, Scr.ScreenHs);
  Scr.DischargeFullHeight := CalcDischargeFullHeight(Scr.ScreenHs);
  Scr.DischargeHeight := CalcDischargeHeight(Scr.DischargeFullHeight,
    InputData.ChannelHeight);

  if IsLess(Scr.DischargeHeight, InputData.MinDischargeHeight) then
  begin
    Error := 'Высота сброса меньше указанной минимальной высоты.';
    Exit;
  end;
  Scr.InnerScreenWidth := CalcInnerScreenWidth(Scr.IsSmall, Scr.ScreenWs);

  //Гидравлический расчет:
  Scr.B := CalcBHydraulic(InputData.FinalLevel);
  Scr.C := CalcCHydraulic(InputData.FinalLevel);
  Scr.Efficiency := CalcEfficiency(InputData.Gap, InputData.Fp.Width);
  Scr.Hydraulics := CalcHydraulic(Scr.InnerScreenWidth, Scr.Efficiency,
    InputData.TiltAngle, InputData.Fp.ShapeFactor, InputData.Fp.Width,
    InputData.Gap, InputData.ChannelWidth, InputData.WaterFlow, Scr.B, Scr.C,
    InputData.FinalLevel);

  if InputData.GrateHs.HasValue then
    Scr.GrateHs := InputData.GrateHs.Value
  else
  begin
    CalcGrateHs(Scr.Hydraulics, InputData.FinalLevel, InputData.ChannelHeight,
      IsFound, Scr.GrateHs);
    if not IsFound then
    begin
      Error := 'Не удается подобрать высоту полотна из стандартного ряда.';
      Exit;
    end;
  end;
  if (Scr.ScreenHs - Scr.GrateHs) < -MaxDiffScreenAndGrateHs then
  begin
    Error := Format('Полотно больше решетки более чем на %d типоразмеров.',
      [MaxDiffScreenAndGrateHs]);
    Exit;
  end;

  Scr.ChannelWs := CalcChannelWs(InputData.ChannelWidth);
  if (Scr.ChannelWs - Scr.ScreenWs) < 0 then
  begin
    Error := 'Слишком узкий канал.';
    Exit;
  end;
  if (Scr.ChannelWs - Scr.ScreenWs) > 2 then
  begin
    Error := 'Слишком широкий канал.';
  end;

  Scr.IsHeavyVersion := Scr.ScreenHs >= 21;
  Scr.ScreenPivotHeight := CalcScreenPivotHeight(Scr.ScreenHs);
  Scr.StandHeight := CalcStandHeight(Scr.ScreenPivotHeight, InputData.ChannelHeight);

  CalcStandHs(Scr.StandHeight, IsFound, Scr.StandHs);
  if not IsFound then
  begin
    Error := 'Слишком маленькая опора.';
    Exit;
  end;

  Scr.ProfilesCount := CalcProfilesCount(Scr.InnerScreenWidth, InputData.Gap,
    InputData.Fp.Width);
  if Scr.ProfilesCount < 2 then
  begin
    Error := 'Слишком большой прозор.';
    Exit;
  end;

  Scr.InnerScreenHeight := CalcInnerScreenHeight(Scr.GrateHs);

  if InputData.FinalLevel.HasValue then
  begin
    if IsMoreEq(InputData.FinalLevel.Value, InputData.ChannelHeight) then
    begin
      Error := 'Уровень воды выше канала.';
      Exit;
    end;
    if IsMoreEq(InputData.FinalLevel.Value, Scr.InnerScreenHeight) then
    begin
      Error := 'Уровень воды выше полотна.';
      Exit;
    end;
  end;

  if IsLess(InputData.TiltAngle, DegToRad(45))
    or IsMore(InputData.TiltAngle, DegToRad(90)) then
  begin
    Error := Format('Недопустимый угол. Стандартный: %d+-5.', [ToDeg(DefaultTiltAngle)]);
    Exit;
  end;

  Scr.ChainLength := CalcChainLength(Scr.IsSmall, Scr.ScreenHs);
  Scr.RakesCount := CalcRakesCount(Scr.ChainLength);
  Scr.Designation := CreateDesignation(Scr.ScreenWs, Scr.ScreenHs, Scr.ChannelWs,
    Scr.GrateHs, Scr.IsSmall, InputData.Fp.Name, InputData.Gap);
  Scr.IsStandardSerie := CheckStandardSerie(Scr.ScreenWs, Scr.ScreenHs);
  Scr.MinTorque := CalcMinTorque(Scr.InnerScreenWidth, Scr.RakesCount, Scr.IsSmall);
  Scr.Drive := CalcDrive(Scr.IsSmall, Scr.MinTorque);

  //после длины цепи
  Scr.ScreenLength := CalcScreenLength(Scr.IsSmall, Scr.ChainLength, Scr.ScreenHs);

  Scr.FpLength := CalcFpLength(InputData.Fp.IsRemovable, Scr.GrateHs);
  Scr.DischargeWidth := CalcDischargeWidth(Scr.ScreenWs);
  Scr.WsDiff := CalcWsDiff(Scr.ChannelWs, Scr.ScreenWs);
  Scr.BackwallHs := CalcBackwallHs(Scr.ScreenHs, Scr.GrateHs);
  Scr.CoverHs := CalcCoverHs(Scr.BackwallHs, Scr.StandHs);
  Scr.CoversCount := CalcCoversCount(Scr.ScreenWs);

  //в самом конце
  if Scr.IsSmall then
    Mass := TMassSmall.Create(Scr, InputData).Mass
  else
    Mass := TMassLarge.Create(Scr, InputData).Mass;
end;

var
  I: Integer;

initialization
  for I := 0 to High(ScreenHeightSeries) do
    ScreenHeightSeries[I] := 3 + 3 * I;
  for I := 0 to High(GrateHeightSeries) do
    GrateHeightSeries[I] := 6 + 3 * I;

  with FilterProfiles[0] do
  begin
    Name := '3999';
    Width := 0.0095;
    IsRemovable := False;
    ShapeFactor := 1.5;
    CalcMass := @CalcMass3999;
  end;

  with FilterProfiles[1] do
  begin
    Name := '341';
    Width := 0.0055;
    IsRemovable := False;
    ShapeFactor := 0.95;
    CalcMass := @CalcMass341;
  end;

  with FilterProfiles[2] do
  begin
    Name := '777';
    Width := 0.0078;
    IsRemovable := False;
    ShapeFactor := 0.95;
    CalcMass := @CalcMass777;
  end;

  with FilterProfiles[3] do
  begin
    Name := '1492';
    Width := 0.008;
    IsRemovable := True;
    ShapeFactor := 0.95;
    CalcMass := @CalcMass1492;
  end;

  with FilterProfiles[4] do
  begin
    Name := '6x30';
    Width := 0.006;
    IsRemovable := False;
    ShapeFactor := 2.42;
    CalcMass := @CalcMass6x30;
  end;

  with FilterProfiles[5] do
  begin
    Name := '6x60';
    Width := 0.006;
    IsRemovable := True;
    ShapeFactor := 2.42;
    CalcMass := @CalcMass6x60;
  end;

  SetLength(DriveUnitsSmall, 1);

  with DriveUnitsSmall[0] do
  begin
    Name := 'SK 12080AZBHVL-71LP/4 TF';
    Mass := 38;
    Power := 370;
    OutputTorque := 680;
  end;

  SetLength(DriveUnitsBig, 2);

  with DriveUnitsBig[0] do
  begin
    Name := 'SK 32100AZBHVL-80LP/4 TF';
    Mass := 67;
    Power := 750;
    OutputTorque := 1663;
  end;

  with DriveUnitsBig[1] do
  begin
    Name := 'SK 43125AZBHVL-90SP/4 TF';
    Mass := 129;
    Power := 1100;
    OutputTorque := 3052;
  end;
end.
