unit MassSmallCalculation;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

interface

uses
  ScreenCalculation, MassCalculation;

type
  TMassSmall = class(TMassCalculator)
  public
    constructor Create(const Scr: TBarScreen; const InputData: TInputData); override;
  protected
    function CalcMassGridBalk(const Scr: TBarScreen): Double; override;
    function CalcMassGridScrew: Double; override;
  end;

implementation

//Рама
function CalcMassFrame(const Scr: TBarScreen): Double;
begin
  Result := 1.95 * Scr.ScreenWs + 3.18 * Scr.ScreenHs + 50.02;
end;

//Стол
function CalcMassBackwall(const Scr: TBarScreen): Double;
begin
  Result := 0.2358 * Scr.ScreenWs * Scr.BackwallHs + 1.3529 * Scr.ScreenWs
    - 0.0383 * Scr.BackwallHs - 0.8492;
end;

//Лоток
function CalcMassTray(const Scr: TBarScreen): Double;
begin
  Result := 0.7575 * Scr.ScreenWs - 0.225;
end;

//Облицовка
function CalcMassCover(const Scr: TBarScreen): Double;
begin
  Result := 0.1175 * Scr.ScreenWs * Scr.CoverHs + 0.8413 * Scr.ScreenWs
    - 0.085 * Scr.CoverHs + 0.0125;
end;

//Масса цепи (1 шт.)
function CalcChainMassMs28r63(const Scr: TBarScreen): Double;
begin
  Result := 4.5455 * Scr.ChainLength;
end;

//Граблина
function CalcMassRake(const Scr: TBarScreen): Double;
begin
  Result := 0.47 * Scr.ScreenWs - 0.06;
end;

//Цепь в сборе
function CalcChainWithRakesMass(const Scr: TBarScreen): Double;
const
  Fasteners = 0.12;
begin
  Result := CalcChainMassMs28r63(Scr) * 2 + CalcMassRake(Scr) * Scr.RakesCount
    + Fasteners;
end;

//Кожух сброса
function CalcMassDischarge(const Scr: TBarScreen): Double;
begin
  Result := 1.3 * Scr.ScreenWs + 0.75;
end;

//Верхняя крышка (на петлях)
function CalcMassTopCover(const Scr: TBarScreen): Double;
begin
  Result := 0.2775 * Scr.ScreenWs + 0.655;
end;

//Узел привода (в сборе с валом, подшипниками и т.д.)
function CalcMassDriveAsm(const Scr: TBarScreen): Double;
begin
  Result := 1.2725 * Scr.ScreenWs + 15.865;
end;

//Сбрасыватель
function CalcMassEjector(const Scr: TBarScreen): Double;
begin
  Result := 0.475 * Scr.ScreenWs + 0.47;
end;

//Рамка из прутка
function CalcMassFrameLoop(const Scr: TBarScreen): Double;
begin
  Result := 0.34 * Scr.ScreenWs + 0.2883 * Scr.GrateHs - 1.195;
end;

//Опора решетки (на канал)
function CalcMassSupport(const Scr: TBarScreen): Double;
begin
  Result := 1.07 * Scr.StandHs + 11.91;
end;

//Защитный экран
function CalcMassSideScreen(const Scr: TBarScreen): Double;
begin
  Result := 0.1503 * Scr.WsDiff * Scr.GrateHs + 0.7608 * Scr.WsDiff
    + 0.4967 * Scr.GrateHs - 2.81;
end;

//Корпус
function CalcMassBody(const Scr: TBarScreen; const MassGrid: Double): Double;
const
  Fasteners = 1.02;
  //Лыжа
  MassSki = 0.45;
  //Серьга разрезная
  MassLug = 0.42;
begin
  Result := CalcMassFrame(Scr)
    + CalcMassBackwall(Scr)
    + CalcMassTray(Scr)
    + MassSki * 2
    + MassLug * 2
    + MassGrid
    + Fasteners;
end;

constructor TMassSmall.Create(const Scr: TBarScreen; const InputData: TInputData);
const
  Other = 3.57;
var
  MassGrid: Double;
begin
  MassGrid := CalcMassGrid(Scr, InputData);
  FMass := CalcMassBody(Scr, MassGrid)
    + CalcMassCover(Scr)
    + CalcChainWithRakesMass(Scr)
    + CalcMassDischarge(Scr)
    + CalcMassTopCover(Scr)
    + CalcMassDriveAsm(Scr)
    + CalcMassEjector(Scr)
    + CalcMassFrameLoop(Scr)
    + CalcMassSupport(Scr) * 2
    + CalcMassSideScreen(Scr) * 2
    + Other;
end;

function TMassSmall.CalcMassGridBalk(const Scr: TBarScreen): Double;
begin
  Result := 0.3825 * Scr.ScreenWs - 0.565;
end;

function TMassSmall.CalcMassGridScrew: Double;
begin
  Result := 0.08;
end;

end.
