unit FloatUtils;

{$mode ObjFPC}{$H+}

interface

uses
  Math;

const
  MaxDigits = -6;
  MaxAccuracy = 1e-6;  { 10^MaxDigits }

function IsEqual(A, B: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
function IsGreater(Larger, Smaller: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
function IsGreaterOrEqual(Larger, Smaller: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
function IsLess(Smaller, Larger: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
function IsLessOrEqual(Smaller, Larger: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;

function FStr(X: ValReal; Digits: TRoundToRange = MaxDigits): String;
function AdvStrToFloat(const S: String): ValReal;
function SafeTrunc(Value: ValReal): Integer;

implementation

uses
  SysUtils;

function IsEqual(A, B: ValReal; Accuracy: ValReal = MaxAccuracy): Boolean;
begin
  Result := CompareValue(A, B, Accuracy) = 0;
end;

function IsGreater(Larger, Smaller: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
begin
  Result := CompareValue(Larger, Smaller, Accuracy) > 0;
end;

function IsGreaterOrEqual(Larger, Smaller: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
begin
  Result := CompareValue(Larger, Smaller, Accuracy) >= 0;
end;

function IsLess(Smaller, Larger: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
begin
  Result := CompareValue(Smaller, Larger, Accuracy) < 0;
end;

function IsLessOrEqual(Smaller, Larger: ValReal;
  Accuracy: ValReal = MaxAccuracy): Boolean;
begin
  Result := CompareValue(Smaller, Larger, Accuracy) <= 0;
end;

function FStr(X: ValReal; Digits: TRoundToRange = MaxDigits): String;
const
  Spec: array [MaxDigits..0] of String = (
    '0.######', '0.#####', '0.####', '0.###', '0.##', '0.#', '0');
begin
  Result := FormatFloat(Spec[Digits], RoundTo(X, Digits));
end;

function AdvStrToFloat(const S: String): ValReal;
begin
  Result := StrToFloat(StringReplace(S, ',', '.', []));
end;

function SafeTrunc(Value: ValReal): Integer;
begin
  Result := Trunc(RoundTo(Value, MaxDigits));
end;

end.
