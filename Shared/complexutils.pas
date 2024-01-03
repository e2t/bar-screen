unit ComplexUtils;

{$mode ObjFPC}{$H+}

interface

uses
  FloatUtils,
  Math,
  SysUtils,
  UComplex;

function ComplexToStr(const C: Complex;
  Digits: TRoundToRange = MaxDigits): String;

implementation

function ComplexToStr(const C: Complex;
  Digits: TRoundToRange = MaxDigits): String;
var
  ImagZero: TValueRelationship;
  ImSign: String = '';
begin
  ImagZero := CompareValue(C.im, 0, MaxAccuracy);
  if ImagZero = 0 then
    Result := FStr(C.re, Digits)
  else if IsEqual(C.re, 0) then
    Result := FStr(C.im, Digits) + 'i'
  else
  begin
    if ImagZero > 0 then
      ImSign := '+';
    Result := FStr(C.re, Digits) + ImSign + FStr(C.im, Digits) + 'i';
  end;
end;

end.
