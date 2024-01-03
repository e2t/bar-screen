unit L10n;

{$mode ObjFPC}{$H+}

interface

uses
  Fgl;

type
  TLanguage = (Eng, Ukr, Rus, Lit);
  TTranslate = specialize TFPGMap<TLanguage, String>;

var
  LangNames, LangCodes, TextUiRun, TextUiMenu, TextOutMenu: TTranslate;

function StrToLanguage(const Code: String; Fallback: TLanguage): TLanguage;

implementation

uses
  SysUtils;

function StrToLanguage(const Code: String; Fallback: TLanguage): TLanguage;
var
  I: Integer;
begin
  Result := Fallback;
  for I := 0 to LangCodes.Count - 1 do
    if CompareText(LangCodes.Data[I], Code) = 0 then
    begin
      Result := LangCodes.Keys[I];
      break;
    end;
end;

initialization
  LangNames := TTranslate.Create;
  LangNames.Add(Eng, 'English');
  LangNames.Add(Ukr, 'Українська');
  LangNames.Add(Rus, 'Русский');
  LangNames.Add(Lit, 'Lietuvių');

  LangCodes := TTranslate.Create;
  LangCodes.Add(Eng, 'Eng');
  LangCodes.Add(Ukr, 'Ukr');
  LangCodes.Add(Rus, 'Rus');
  LangCodes.Add(Lit, 'Lit');

  TextUiRun := TTranslate.Create;
  TextUiRun.Add(Eng, 'Run');
  TextUiRun.Add(Ukr, 'Рахувати');
  TextUiRun.Add(Rus, 'Расчет');
  TextUiRun.Add(Lit, 'Skaičiuoti');

  TextUiMenu := TTranslate.Create;
  TextUiMenu.Add(Eng, 'Interface');
  TextUiMenu.Add(Ukr, 'Інтерфейс');
  TextUiMenu.Add(Rus, 'Интерфейс');
  TextUiMenu.Add(Lit, 'Sąsaja');

  TextOutMenu := TTranslate.Create;
  TextOutMenu.Add(Eng, 'Calculation');
  TextOutMenu.Add(Ukr, 'Розрахунок');
  TextOutMenu.Add(Rus, 'Расчет');
  TextOutMenu.Add(Lit, 'Skaičiavimas');

finalization
  FreeAndNil(LangNames);
  FreeAndNil(LangCodes);
  FreeAndNil(TextUiRun);
  FreeAndNil(TextUiMenu);
  FreeAndNil(TextOutMenu);
end.
