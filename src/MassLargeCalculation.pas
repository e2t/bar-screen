unit MassLargeCalculation;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

interface

uses
  ScreenCalculation, MassCalculation;

type
  TMassLarge = class(TMassCalculator)
  public
    constructor Create(const Scr: TBarScreen; const InputData: TInputData); override;
  protected
    function CalcMassGridBalk(const Scr: TBarScreen): Double; override;
    function CalcMassGridScrew: Double; override;
  end;

implementation

function CalcMassRke0102ad(const Scr: TBarScreen): Double;
begin
  Result := 1.5024 * Scr.ScreenWs - 0.1065;
end;

function CalcMassRke0104ad(const Scr: TBarScreen): Double;
begin
  Result := 0.2886 * Scr.BackwallHs * Scr.ScreenWs - 0.2754 * Scr.BackwallHs
    + 2.2173 * Scr.ScreenWs - 2.6036;
end;

function CalcMassRke010101ad(const Scr: TBarScreen): Double;
begin
  Result := 2.7233 * Scr.ScreenHs + 46.32;
end;

function CalcMassRke010111ad(const Scr: TBarScreen): Double;
begin
  Result := 2.7467 * Scr.ScreenHs + 46.03;
end;

function CalcMassRke010102ad(const Scr: TBarScreen): Double;
begin
  Result := 0.5963 * Scr.ScreenWs - 0.3838;
end;

function CalcMassRke010103ad(const Scr: TBarScreen): Double;
begin
  Result := 0.5881 * Scr.ScreenWs + 0.4531;
end;

function CalcMassRke010104ad(const Scr: TBarScreen): Double;
begin
  Result := 0.8544 * Scr.ScreenWs - 0.1806;
end;

function CalcMassRke010105ad(const Scr: TBarScreen): Double;
begin
  Result := 0.6313 * Scr.ScreenWs + 0.1013;
end;

function CalcMassRke010107ad(const Scr: TBarScreen): Double;
begin
  Result := 0.605 * Scr.WsDiff + 3.36;
end;

function CalcMassRke010108ad(const Scr: TBarScreen): Double;
begin
  Result := 0.445 * Scr.ScreenWs - 0.245;
end;

function CalcMassRke010109ad(const Scr: TBarScreen): Double;
begin
  if Scr.ScreenWs <= 10 then
    Result := 0.136 * Scr.ScreenWs + 0.13
  else
    Result := 0.1358 * Scr.ScreenWs + 0.2758;
end;

function CalcMassRke0101ad(const Scr: TBarScreen): Double;
const
  Fasteners = 2.22;
  MassRke0101ad02 = 0.42;
begin
  Result := CalcMassRke010101ad(Scr)
    + CalcMassRke010111ad(Scr)
    + CalcMassRke010102ad(Scr) * 2
    + CalcMassRke010103ad(Scr)
    + CalcMassRke010104ad(Scr)
    + CalcMassRke010105ad(Scr)
    + CalcMassRke010107ad(Scr) * 2
    + CalcMassRke010108ad(Scr)
    + CalcMassRke010109ad(Scr)
    + MassRke0101ad02 * 2
    + Fasteners;
end;

function CalcMassRke01ad(const Scr: TBarScreen; const MassGrid: Double): Double;
const
  Fasteners = 1.07;
  MassRke01ad01 = 0.62;
begin
  Result := CalcMassRke0101ad(Scr)
    + CalcMassRke0102ad(Scr)
    + MassGrid
    + CalcMassRke0104ad(Scr)
    + MassRke01ad01 * 2
    + Fasteners;
end;

function CalcMassRke02ad(const Scr: TBarScreen): Double;
begin
  Result := 1.85 * Scr.ScreenWs + 97.28;
  if Scr.IsHeavyVersion then
    Result := Result + 2.29;
end;

function CalcMassRke03ad(const Scr: TBarScreen): Double;
begin
  Result := 0.12 * Scr.WsDiff * Scr.GrateHs + 2.12 * Scr.WsDiff
    + 0.4967 * Scr.GrateHs - 1.32;
end;

//Тип полотна и прозор игнорируются.
function CalcMassRke04ad(const Scr: TBarScreen): Double;
begin
  Result := 0.5524 * Scr.ScreenWs + 0.2035;
end;

function CalcMassRke05ad(const Scr: TBarScreen): Double;
begin
  Result := 0.8547 * Scr.ScreenWs + 1.4571;
end;

function CalcMassRke06ad(const Scr: TBarScreen): Double;
begin
  Result := 0.5218 * Scr.ScreenWs + 0.6576;
end;

//Масса подставки на пол.
function CalcMassRke08ad(const Scr: TBarScreen): Double;
begin
  Assert(Scr.StandHs >= 6);
  case Scr.StandHs of
    6: Result := 17.81;
    7: Result := 21.47;
    else
      Result := 1.8267 * Scr.StandHs + 8.0633
  end;
end;

function CalcMassRke09ad(const Scr: TBarScreen): Double;
begin
  Result := 1.7871 * Scr.ScreenWs - 0.4094;
end;

function CalcMassRke10ad(const Scr: TBarScreen): Double;
begin
  if Scr.ScreenWs <= 10 then
    Result := 0.06 * Scr.CoverHs * Scr.ScreenWs - 0.055 * Scr.CoverHs
      + 0.3167 * Scr.ScreenWs + 0.3933
  else
    Result := 0.03 * Scr.CoverHs * Scr.ScreenWs - 0.0183 * Scr.CoverHs
      + 0.1582 * Scr.ScreenWs + 0.6052;
end;

//TODO: Возможно рамку нужно делать по высоте канала, а не полотна.
function CalcMassRke13ad(const Scr: TBarScreen): Double;
begin
  Result := 0.1811 * Scr.GrateHs + 0.49 * Scr.ScreenWs + 0.7867;
end;

function CalcMassRke19ad(const Scr: TBarScreen): Double;
begin
  Result := 0.0161 * Scr.GrateHs + 0.2067;
end;

function CalcChainMassMs56r100(const Scr: TBarScreen): Double;
begin
  Result := 4.18 * Scr.ChainLength;
end;

constructor TMassLarge.Create(const Scr: TBarScreen; const InputData: TInputData);
const
  Fasteners = 1.24;
  MassRke07ad = 1.08;
  MassRke11ad = 0.42;
  MassRke12ad = 0.16;
  MassRke18ad = 1.13;
  MassRke00ad05 = 0.87;
  MassRke00ad09 = 0.01;
  MassRke00ad13 = 0.15;
var
  MassGrid: Double;
begin
  MassGrid := CalcMassGrid(Scr, InputData);
  FMass := CalcMassRke01ad(Scr, MassGrid)
    + CalcMassRke02ad(Scr)
    + CalcMassRke03ad(Scr) * 2
    + CalcMassRke04ad(Scr) * Scr.RakesCount
    + CalcMassRke05ad(Scr)
    + CalcMassRke06ad(Scr)
    + MassRke07ad
    + CalcMassRke08ad(Scr) * 2
    + CalcMassRke09ad(Scr)
    + CalcMassRke10ad(Scr) * Scr.CoversCount
    + MassRke11ad * 2
    + MassRke12ad * 2
    + CalcMassRke13ad(Scr)
    + MassRke18ad * 2
    + CalcMassRke19ad(Scr)
    + MassRke00ad05 * 4
    + MassRke00ad09 * 2
    + MassRke00ad13 * 2
    + CalcChainMassMs56r100(Scr) * 2
    + Fasteners;
end;

function TMassLarge.CalcMassGridBalk(const Scr: TBarScreen): Double;
begin
  Result := 0.6919 * Scr.ScreenWs - 0.7431;
end;

function TMassLarge.CalcMassGridScrew: Double;
begin
  Result := 0.16;
end;

end.
