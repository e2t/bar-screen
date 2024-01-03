unit MathUtils;

{$mode ObjFPC}{$H+}

interface

const
  GravAcc = 9.80665;  // Metre/sec2
  SteelElast = 2.0e11;  // Pa

function MRound(Value, Base: ValReal): ValReal;

implementation

function MRound(Value, Base: ValReal): ValReal;
begin
  Result := Round(Value / Base) * Base;
end;

end.
