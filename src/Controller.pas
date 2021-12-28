unit Controller;

{$MODE OBJFPC}
{$LONGSTRINGS ON}
{$ASSERTIONS ON}
{$RANGECHECKS ON}
{$BOOLEVAL OFF}

interface

procedure Run();
procedure MainFormInit();

implementation

uses
  ProgramInfo, GuiMainForm, GuiHelper, Measurements, Classes, SysUtils,
  ScreenCalculation, StrConvert, Nullable, ComCtrls, Math, CheckNum;

type
  THydraulicColumns = 0..6;
  THydraulicOutput = array [TPollutionLevels, THydraulicColumns] of string;

const
  AutoChoice = 'Авто';

procedure MainFormInit();
var
  Gap: Double;
  I: Integer;
  Fp: TFilterProfile;
  Row: TListItem;
begin
  MainForm.Caption := GetProgramTitle;
  MainForm.EditMinDischargeHeight.Text := FormatFloat('0.#', ToMm(DefaultDischargeHeight));
  MainForm.EditTiltAngle.Text := FormatFloat('0.#', ToDeg(DefaultTiltAngle));
  for Gap in StdGaps do
    MainForm.ComboBoxGap.Items.Add(Format('%.0f', [ToMm(Gap)]));

  MainForm.ComboBoxScreenWs.Items.Add(AutoChoice);
  for I in ScreenWidthSeries do
    MainForm.ComboBoxScreenWs.Items.Add(Format('%.2d', [I]));
  MainForm.ComboBoxScreenWs.ItemIndex := 0;

  MainForm.ComboBoxScreenHs.Items.Add(AutoChoice);
  for I in ScreenHeightSeries do
    MainForm.ComboBoxScreenHs.Items.Add(Format('%.2d', [I]));
  MainForm.ComboBoxScreenHs.ItemIndex := 0;

  MainForm.ComboBoxGrateHs.Items.Add(AutoChoice);
  for I in GrateHeightSeries do
    MainForm.ComboBoxGrateHs.Items.Add(Format('%.2d', [I]));
  MainForm.ComboBoxGrateHs.ItemIndex := 0;

  for Fp in FilterProfiles do
  begin
    Row := MainForm.ListViewFp.Items.Add;
    Row.Caption := Fp.Name;
    if Fp.IsRemovable then
      Row.SubItems.Add('съемный')
    else
      Row.SubItems.Add('сварной');
    Row.SubItems.Add(FormatFloat('0.0#', Fp.ShapeFactor));
  end;
  MainForm.ListViewFp.ItemIndex := 0;
end;

procedure CreateInputData(out InputData: TInputData; out Error: string);
const
  SIncorrectValue = ' - неправильное значение.';
var
  IsValid: Boolean;
  InputValue: Double;
  Serie: Integer;
begin
  InputData := Default(TInputData);
  Error := '';

  MainForm.EditChannelWidth.GetRealMin(0, IsValid, InputValue);
  if IsValid then
    InputData.ChannelWidth := Mm(InputValue)
  else
  begin
    Error := 'Ширина канала' + SIncorrectValue;
    Exit;
  end;

  MainForm.EditChannelHeight.GetRealMin(0, IsValid, InputValue);
  if IsValid then
    InputData.ChannelHeight := Mm(InputValue)
  else
  begin
    Error := 'Глубина канала' + SIncorrectValue;
    Exit;
  end;

  MainForm.EditMinDischargeHeight.GetRealMin(0, IsValid, InputValue);
  if IsValid then
    InputData.MinDischargeHeight := Mm(InputValue)
  else
  begin
    Error := 'Мин. высота сброса' + SIncorrectValue;
    Exit;
  end;

  MainForm.ComboBoxGap.GetRealMin(0, IsValid, InputValue);
  if IsValid then
    InputData.Gap := Mm(InputValue)
  else
  begin
    Error := 'Прозор' + SIncorrectValue;
    Exit;
  end;

  if MainForm.EditWaterFlow.Text <> '' then
  begin
    MainForm.EditWaterFlow.GetRealMin(0, IsValid, InputValue);
    if IsValid then
      InputData.WaterFlow.Value := LitrePerSec(InputValue)
    else
    begin
      Error := 'Расход воды' + SIncorrectValue;
      Exit;
    end;
  end;

  if MainForm.EditFinalLevel.Text <> '' then
  begin
    MainForm.EditFinalLevel.GetRealMin(0, IsValid, InputValue);
    if IsValid then
      InputData.FinalLevel.Value := Mm(InputValue)
    else
    begin
      Error := 'Уровень за решеткой' + SIncorrectValue;
      Exit;
    end;
  end;

  MainForm.EditTiltAngle.GetRealMin(0, IsValid, InputValue);
  if IsValid then
    InputData.TiltAngle := Deg(InputValue)
  else
  begin
    Error := 'Угол' + SIncorrectValue;
    Exit;
  end;

  if MainForm.ComboBoxScreenWs.ItemIndex <> 0 then
  begin
    MainForm.ComboBoxScreenWs.GetIntMin(0, IsValid, Serie);
    Assert(IsValid);
    InputData.ScreenWs.Value := Serie;
  end;

  if MainForm.ComboBoxScreenHs.ItemIndex <> 0 then
  begin
    MainForm.ComboBoxScreenHs.GetIntMin(0, IsValid, Serie);
    Assert(IsValid);
    InputData.ScreenHs.Value := Serie;
  end;

  if MainForm.ComboBoxGrateHs.ItemIndex <> 0 then
  begin
    MainForm.ComboBoxGrateHs.GetIntMin(0, IsValid, Serie);
    Assert(IsValid);
    InputData.GrateHs.Value := Serie;
  end;

  InputData.Fp := FilterProfiles[MainForm.ListViewFp.ItemIndex];
end;

procedure CreateOutput(const Scr: TBarScreen; const Mass: Double;
  const InputData: TInputData; out Output: string; out Hydraulic: THydraulicOutput);
var
  Lines, Warnings: TStringList;
  Diff: Double;
  Drive, MassSufix, DischargeHeightPrefix, BlindingPct: string;
  I: Integer;
  HaveWarnings: Boolean;
begin
  if Scr.IsStandardSerie then
    MassSufix := ''
  else
    MassSufix := ' (примерно)';

  if Scr.Drive.HasValue then
    Drive := Format('«%s»  %s кВт, %.0f Нм', [Scr.Drive.Value.Name,
      FormatFloat('0.###', ToKw(Scr.Drive.Value.Power)), Scr.Drive.Value.OutputTorque])
  else
    Drive := 'нестандартный';

  if Scr.IsSmall then
    DischargeHeightPrefix := '≈'
  else
    DischargeHeightPrefix := '';

  Lines := TStringList.Create;
  Lines.AddStrings([Scr.Designation,
    Format('Масса %.0f кг%s', [Mass, MassSufix]),
    Format('Привод %s', [Drive]),
    '',
    Format('Ширина просвета %.0f мм', [ToMm(Scr.InnerScreenWidth)]),
    Format('Высота просвета (от дна) %.0f мм', [ToMm(Scr.InnerScreenHeight)]),
    Format('Длина решетки %.0f мм', [ToMm(Scr.ScreenLength)]),
    Format('Длина цепи %.0f мм', [ToMm(Scr.ChainLength)]),
    Format('Длина профиля %.0f мм', [ToMm(Scr.FpLength)]),
    Format('Количество профилей %d ± 1 шт.', [Scr.ProfilesCount]),
    Format('Количество граблин %d шт.', [Scr.RakesCount]),
    Format('Ширина сброса %.0f мм', [ToMm(Scr.DischargeWidth)]),
    Format('Высота сброса (над каналом) %s%.0f мм', [DischargeHeightPrefix,
    ToMm(Scr.DischargeHeight)]),
    Format('Высота сброса (до дна) %s%.0f мм', [DischargeHeightPrefix,
    ToMm(Scr.DischargeFullHeight)]),
    '']);

  HaveWarnings := False;
  Warnings := TStringList.Create;
  for I in TPollutionLevels do
  begin
    BlindingPct := Format('%.0f%%', [ToPct(Scr.Hydraulics[I].Pollution)]);
    Hydraulic[I, 0] := BlindingPct;
    if Scr.Hydraulics[I].VelocityInGap.HasValue then
      Hydraulic[I, 1] := Format('%.2f м/с', [Scr.Hydraulics[I].VelocityInGap.Value]);
    Hydraulic[I, 2] := Format('%.2f', [Scr.Hydraulics[I].RelativeFlowArea]);
    Hydraulic[I, 3] := Format('%.1f', [Scr.Hydraulics[I].BlindingFactor * 1e3]);
    if Scr.Hydraulics[I].LevelDiff.HasValue then
      Hydraulic[I, 4] := Format('%.0f мм', [ToMm(Scr.Hydraulics[I].LevelDiff.Value)]);
    if Scr.Hydraulics[I].StartLevel.HasValue then
    begin
      Hydraulic[I, 5] := Format('%.0f мм', [ToMm(Scr.Hydraulics[I].StartLevel.Value)]);
      if Scr.Hydraulics[I].StartLevel.Value > InputData.ChannelHeight then
        Warnings.Add('переполнение канала');
      Diff := RoundTo(Scr.Hydraulics[I].StartLevel.Value - Scr.InnerScreenHeight, -3);
      if IsMoreEq(Diff, 0) then
        Warnings.Add(Format('уровень выше полотна (на %.0f мм)', [ToMm(Diff)]));
      if Warnings.Count > 0 then
      begin
        HaveWarnings := True;
        Lines.Add(BlindingPct + ' - ' + String.Join(', ', Warnings.ToStringArray));
        Warnings.Clear;
      end;
    end;
    if Scr.Hydraulics[I].UpstreamFlowVelocity.HasValue then
      Hydraulic[I, 6] := Format('%.2f  м/с', [Scr.Hydraulics[I].UpstreamFlowVelocity.Value]);
  end;
  if HaveWarnings then
    Lines.Add('');
  Lines.Add(Format('Минимальный крутящий момент %.0f Нм', [Scr.MinTorque]));

  Output := Lines.Text;
  Warnings.Free;
  Lines.Free;
end;

procedure PrintOutput(const Text: string);
begin
  MainForm.ListViewHydraulic.Clear;
  MainForm.MemoOutput.Clear;
  MainForm.MemoOutput.Text := Text;
  MainForm.MemoOutput.SelStart := 0;
end;

procedure PrintOutputWithTable(const Text: string; const Hydraulic: THydraulicOutput);
var
  Row: TListItem;
  I, J: Integer;
begin
  PrintOutput(Text);
  for I in TPollutionLevels do
  begin
    Row := MainForm.ListViewHydraulic.Items.Add;
    Row.Caption := Hydraulic[I, 0];
    for J := 1 to High(THydraulicColumns) do
      Row.SubItems.Add(Hydraulic[I, J]);
  end;
end;

procedure Run();
var
  InputData: TInputData;
  InputDataError, CalcError, Output: string;
  Scr: TBarScreen;
  Mass: Double;
  Hydraulic: THydraulicOutput;
begin
  CreateInputData(InputData, InputDataError);
  if InputDataError = '' then
  begin
    CalcBarScreen(InputData, CalcError, Scr, Mass);
    if CalcError = '' then
    begin
      CreateOutput(Scr, Mass, InputData, Output, Hydraulic);
      PrintOutputWithTable(Output, Hydraulic);
    end
    else
      PrintOutput(CalcError);
  end
  else
    PrintOutput(InputDataError);
end;

end.
