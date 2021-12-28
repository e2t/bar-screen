unit MassCalculation;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

interface

uses
  ScreenCalculation;

type
  TMassCalculator = class
  protected
    FMass: Double;
    function CalcMassGrid(const Scr: TBarScreen; const InputData: TInputData): Double;
    function CalcMassFp(const Scr: TBarScreen; const InputData: TInputData): Double;
    function CalcMassGridBalk(const Scr: TBarScreen): Double; virtual; abstract;
    function CalcMassGridScrew: Double; virtual; abstract;
  public
    property Mass: Double read FMass;
    constructor Create(
      const Scr: TBarScreen; const InputData: TInputData); virtual; abstract;
  end;

implementation

function TMassCalculator.CalcMassGrid(
  const Scr: TBarScreen; const InputData: TInputData): Double;
var
  MassGridBalk, MassFp, MassGridScrew: Double;
begin
  MassGridBalk := CalcMassGridBalk(Scr);
  MassFp := CalcMassFp(Scr, InputData);
  MassGridScrew := CalcMassGridScrew;
  Result := MassGridBalk * 2 + MassFp * Scr.ProfilesCount + MassGridScrew * 4;
end;

function TMassCalculator.CalcMassFp(
  const Scr: TBarScreen; const InputData: TInputData): Double;
begin
  Result := InputData.Fp.CalcMass(Scr.GrateHs);
end;

end.
