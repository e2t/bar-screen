unit Texts;

{$mode ObjFPC}{$H+}

interface

uses
  L10n,
  StringUtils;

var
  TextUiTitle, TextUiAuto, TextUiWs, TextUiHs, TextUiGs, TextUiWid, TextUiDep,
  TextUiDrop, TextUiGap, TextUiColName, TextUiColMount, TextUiColFactor,
  TextUiFpWeld, TextUiFpRemov, TextUiHydr, TextUiFlow, TextUiLevel,
  TextUiAngle, TextUiCol2Poll, TextUiCol2GapSpeed, TextUiCol2Area,
  TextUiCol2BFactor, TextUiCol2Diff, TextUiCol2Front,
  TextUiCol2ChnSpeed: TTranslate;

  TextErrWidth, TextErrDepth, TextErrDrop, TextErrFlow, TextErrLevel,
  TextErrAngle, TextErrTooHighHs, TextErrMinDrop, TextErrTooHighGs,
  TextErrDiffHsGs, TextErrTooNarrow, TextErrTooWide, TextErrTooSmall,
  TextErrBigGap, TextErrFinalAboveChn, TextErrFinalAboveGs,
  TextErrAngleDiapason: TTranslate;

  TextOutBigDsg, TextOutSmallDsg, TextOutWeight, TextOutWeightApprox,
  TextOutDrive, TextOutInnerWidth, TextOutInnerHeight, TextOutScrLength,
  TextOutChainLength, TextOutFpLength, TextOutFpCount, TextOutRakeCount,
  TextOutDropWidth, TextOutDropAboveTop, TextOutDropAboveBottom, TextOutHydrMm,
  TextOutHydrMs, TextOutWarningOverflow, TextOutWarningDiff, TextOutMinTorque,
  TextOutGap, TextOutSpring, TextOutEquationFile,
  TextOutForDesigner: TTranslate;

implementation

uses
  SysUtils;

initialization
  TextUiTitle := TTranslate.Create;
  TextUiTitle.Add(Eng, 'RKE calculation');
  TextUiTitle.Add(Ukr, 'Розрахунок РКЕ');
  TextUiTitle.Add(Rus, 'Расчет РКЭ');
  TextUiTitle.Add(Lit, 'RKE skaičiavimas');

  TextUiAuto := TTranslate.Create;
  TextUiAuto.Add(Eng, 'Auto');
  TextUiAuto.Add(Ukr, 'Авто');
  TextUiAuto.Add(Rus, 'Авто');
  TextUiAuto.Add(Lit, 'Auto');

  TextUiWs := TTranslate.Create;
  TextUiWs.Add(Eng, 'Width (series):');
  TextUiWs.Add(Ukr, 'Ширина (серія):');
  TextUiWs.Add(Rus, 'Ширина (серия):');
  TextUiWs.Add(Lit, 'Plotis (serija):');

  TextUiHs := TTranslate.Create;
  TextUiHs.Add(Eng, 'Height (series):');
  TextUiHs.Add(Ukr, 'Висота (серія):');
  TextUiHs.Add(Rus, 'Высота (серия):');
  TextUiHs.Add(Lit, 'Aukštis (serija):');

  TextUiGs := TTranslate.Create;
  TextUiGs.Add(Eng, 'Mesh (series):');
  TextUiGs.Add(Ukr, 'Полотно (серія):');
  TextUiGs.Add(Rus, 'Полотно (серия):');
  TextUiGs.Add(Lit, 'Grotelės (serija):');

  TextUiWid := TTranslate.Create;
  TextUiWid.Add(Eng, 'Channel width (mm):');
  TextUiWid.Add(Ukr, 'Ширина каналу (мм):');
  TextUiWid.Add(Rus, 'Ширина канала (мм):');
  TextUiWid.Add(Lit, 'Kanalo plotis (mm):');

  TextUiDep := TTranslate.Create;
  TextUiDep.Add(Eng, 'Channel depth (mm):');
  TextUiDep.Add(Ukr, 'Глибина каналу (мм):');
  TextUiDep.Add(Rus, 'Глубина канала (мм):');
  TextUiDep.Add(Lit, 'Kanalo gylis (mm):');

  TextUiDrop := TTranslate.Create;
  TextUiDrop.Add(Eng, 'Min. drop height (mm):');
  TextUiDrop.Add(Ukr, 'Мін. висота скидання (мм):');
  TextUiDrop.Add(Rus, 'Мин. высота сброса (мм):');
  TextUiDrop.Add(Lit, 'Min. kritimo aukštis (mm):');

  TextUiGap := TTranslate.Create;
  TextUiGap.Add(Eng, 'Nominal gap (mm):');
  TextUiGap.Add(Ukr, 'Номінальний прозор (мм):');
  TextUiGap.Add(Rus, 'Номинальный прозор (мм):');
  TextUiGap.Add(Lit, 'Nominalus protarpis (mm):');

  TextUiColName := TTranslate.Create;
  TextUiColName.Add(Eng, 'Profile');
  TextUiColName.Add(Ukr, 'Профіль');
  TextUiColName.Add(Rus, 'Профиль');
  TextUiColName.Add(Lit, 'Profilis');

  TextUiColMount := TTranslate.Create;
  TextUiColMount.Add(Eng, 'Mounting');
  TextUiColMount.Add(Ukr, 'Кріплення');
  TextUiColMount.Add(Rus, 'Крепление');
  TextUiColMount.Add(Lit, 'Taisymas');

  TextUiColFactor := TTranslate.Create;
  TextUiColFactor.Add(Eng, 'Factor');
  TextUiColFactor.Add(Ukr, 'Коефіцієнт');
  TextUiColFactor.Add(Rus, 'Коэффициент');
  TextUiColFactor.Add(Lit, 'Veiksnys');

  TextUiFpWeld := TTranslate.Create;
  TextUiFpWeld.Add(Eng, 'welded');
  TextUiFpWeld.Add(Ukr, 'зварний');
  TextUiFpWeld.Add(Rus, 'сварной');
  TextUiFpWeld.Add(Lit, 'suvirintas');

  TextUiFpRemov := TTranslate.Create;
  TextUiFpRemov.Add(Eng, 'removable');
  TextUiFpRemov.Add(Ukr, 'знімний');
  TextUiFpRemov.Add(Rus, 'съемный');
  TextUiFpRemov.Add(Lit, 'nuimamas');

  TextUiHydr := TTranslate.Create;
  TextUiHydr.Add(Eng, 'Hydraulics (optional):');
  TextUiHydr.Add(Ukr, 'Гідравліка (необов''язково):');
  TextUiHydr.Add(Rus, 'Гидравлика (необязательно):');
  TextUiHydr.Add(Lit, 'Hidraulika (pasirinktinai):');

  TextUiFlow := TTranslate.Create;
  TextUiFlow.Add(Eng, 'Water flow rate (l/s):');
  TextUiFlow.Add(Ukr, 'Витрата води (л/с):');
  TextUiFlow.Add(Rus, 'Расход воды (л/с):');
  TextUiFlow.Add(Lit, 'Vandens srautas (l/s):');

  TextUiLevel := TTranslate.Create;
  TextUiLevel.Add(Eng, 'Level behind screen (mm):');
  TextUiLevel.Add(Ukr, 'Рівень за решіткою (мм):');
  TextUiLevel.Add(Rus, 'Уровень за решеткой (мм):');
  TextUiLevel.Add(Lit, 'Lygis už ekrano (mm):');

  TextUiAngle := TTranslate.Create;
  TextUiAngle.Add(Eng, 'Tilt angle (°):');
  TextUiAngle.Add(Ukr, 'Кут нахилу (°):');
  TextUiAngle.Add(Rus, 'Угол наклона (°):');
  TextUiAngle.Add(Lit, 'Pakreipimo kampas (°):');

  TextUiCol2Poll := TTranslate.Create;
  TextUiCol2Poll.Add(Eng, 'Pollution');
  TextUiCol2Poll.Add(Ukr, 'Забруднення');
  TextUiCol2Poll.Add(Rus, 'Загрязнение');
  TextUiCol2Poll.Add(Lit, 'Tarša');

  TextUiCol2GapSpeed := TTranslate.Create;
  TextUiCol2GapSpeed.Add(Eng, 'Speed in the gaps');
  TextUiCol2GapSpeed.Add(Ukr, 'Швидкість у прозорах');
  TextUiCol2GapSpeed.Add(Rus, 'Скорость в прозорах');
  TextUiCol2GapSpeed.Add(Lit, 'Greitis tarpuose');

  TextUiCol2Area := TTranslate.Create;
  TextUiCol2Area.Add(Eng, 'Flowing area');
  TextUiCol2Area.Add(Ukr, 'Віднос. площа потоку');
  TextUiCol2Area.Add(Rus, 'Относ. площадь потока');
  TextUiCol2Area.Add(Lit, 'Srauto plotas');

  TextUiCol2BFactor := TTranslate.Create;
  TextUiCol2BFactor.Add(Eng, 'Blinding factor');
  TextUiCol2BFactor.Add(Ukr, 'Blinding factor');
  TextUiCol2BFactor.Add(Rus, 'Blinding factor');
  TextUiCol2BFactor.Add(Lit, 'Blinding factor');

  TextUiCol2Diff := TTranslate.Create;
  TextUiCol2Diff.Add(Eng, 'Level difference');
  TextUiCol2Diff.Add(Ukr, 'Різниця рівнів');
  TextUiCol2Diff.Add(Rus, 'Разность уровней');
  TextUiCol2Diff.Add(Lit, 'Lygių skirtumas');

  TextUiCol2Front := TTranslate.Create;
  TextUiCol2Front.Add(Eng, 'Front level');
  TextUiCol2Front.Add(Ukr, 'Рівень до решітки');
  TextUiCol2Front.Add(Rus, 'Уровень до решетки');
  TextUiCol2Front.Add(Lit, 'Priekinis lygis');

  TextUiCol2ChnSpeed := TTranslate.Create;
  TextUiCol2ChnSpeed.Add(Eng, 'Channel speed');
  TextUiCol2ChnSpeed.Add(Ukr, 'Швидкість у каналі');
  TextUiCol2ChnSpeed.Add(Rus, 'Скорость в канале');
  TextUiCol2ChnSpeed.Add(Lit, 'Kanalo greitis');

  { Errors }

  TextErrWidth := TTranslate.Create;
  TextErrWidth.Add(Eng, 'Wrong channel width!');
  TextErrWidth.Add(Ukr, 'Неправильна ширина каналу!');
  TextErrWidth.Add(Rus, 'Неправильная ширина канала!');
  TextErrWidth.Add(Lit, 'Neteisingas kanalo plotis!');

  TextErrDepth := TTranslate.Create;
  TextErrDepth.Add(Eng, 'Wrong channel depth!');
  TextErrDepth.Add(Ukr, 'Неправильна глибина каналу!');
  TextErrDepth.Add(Rus, 'Неправильная глубина канала!');
  TextErrDepth.Add(Lit, 'Neteisingas kanalo gylis!');

  TextErrDrop := TTranslate.Create;
  TextErrDrop.Add(Eng, 'Wrong drop height!');
  TextErrDrop.Add(Ukr, 'Неправильна висота скидання!');
  TextErrDrop.Add(Rus, 'Неправильная высота сброса!');
  TextErrDrop.Add(Lit, 'Neteisingas kritimo aukštis!');

  TextErrFlow := TTranslate.Create;
  TextErrFlow.Add(Eng, 'Wrong water flow!');
  TextErrFlow.Add(Ukr, 'Неправильна витрата води!');
  TextErrFlow.Add(Rus, 'Неправильный расход воды!');
  TextErrFlow.Add(Lit, 'Neteisingas vandens suvartojimas!');

  TextErrLevel := TTranslate.Create;
  TextErrLevel.Add(Eng, 'Wrong level after the screen!');
  TextErrLevel.Add(Ukr, 'Неправильний рівень за решіткою!');
  TextErrLevel.Add(Rus, 'Неправильный уровень за решеткой!');
  TextErrLevel.Add(Lit, 'Neteisingas lygis po ekranu!');

  TextErrAngle := TTranslate.Create;
  TextErrAngle.Add(Eng, 'Wrong angle!');
  TextErrAngle.Add(Ukr, 'Неправильний кут нахилу!');
  TextErrAngle.Add(Rus, 'Неправильный угол наклона!');
  TextErrAngle.Add(Lit, 'Neteisingas pasvirimo kampas!');

  TextErrTooHighHs := TTranslate.Create;
  TextErrTooHighHs.Add(Eng, 'The screen is too high.');
  TextErrTooHighHs.Add(Ukr, 'Занадто висока решітка.');
  TextErrTooHighHs.Add(Rus, 'Слишком высокая решетка.');
  TextErrTooHighHs.Add(Lit, 'Ekranas yra per aukštai.');

  TextErrMinDrop := TTranslate.Create;
  TextErrMinDrop.Add(
    Eng, 'Discharge height is less than the specified minimum height.');
  TextErrMinDrop.Add(
    Ukr, 'Висота скидання менша за вказану мінімальну висоту.');
  TextErrMinDrop.Add(
    Rus, 'Высота сброса меньше указанной минимальной высоты.');
  TextErrMinDrop.Add(
    Lit, 'Išleidimo aukštis yra mažesnis už nurodytą minimalų aukštį.');

  TextErrTooHighGs := TTranslate.Create;
  TextErrTooHighGs.Add(Eng, 'The grate is too high.');
  TextErrTooHighGs.Add(Ukr, 'Занадто високе полотно.');
  TextErrTooHighGs.Add(Rus, 'Слишком высокое полотно.');
  TextErrTooHighGs.Add(Lit, 'Tinklelis yra per aukštas.');

  TextErrDiffHsGs := TTranslate.Create;
  TextErrDiffHsGs.Add(
    Eng, 'The height difference between the grate and the screen is too big.');
  TextErrDiffHsGs.Add(
    Ukr, 'Занадто велика різниця висоти полотна і решітки.');
  TextErrDiffHsGs.Add(
    Rus, 'Слишком большая разница высоты полотна и решетки.');
  TextErrDiffHsGs.Add(
    Lit, 'Aukščio skirtumas tarp grotelių ir ekrano yra per didelis.');

  TextErrTooNarrow := TTranslate.Create;
  TextErrTooNarrow.Add(Eng, 'The channel is too narrow.');
  TextErrTooNarrow.Add(Ukr, 'Занадто вузький канал.');
  TextErrTooNarrow.Add(Rus, 'Слишком узкий канал.');
  TextErrTooNarrow.Add(Lit, 'Kanalas yra per siauras.');

  TextErrTooWide := TTranslate.Create;
  TextErrTooWide.Add(Eng, 'The channel is too wide.');
  TextErrTooWide.Add(Ukr, 'Занадто широкий канал.');
  TextErrTooWide.Add(Rus, 'Слишком широкий канал.');
  TextErrTooWide.Add(Lit, 'Kanalas yra per platus.');

  TextErrTooSmall := TTranslate.Create;
  TextErrTooSmall.Add(Eng, 'Too little support.');
  TextErrTooSmall.Add(Ukr, 'Занадто маленька опора.');
  TextErrTooSmall.Add(Rus, 'Слишком маленькая опора.');
  TextErrTooSmall.Add(Lit, 'Parama yra per maža.');

  TextErrBigGap := TTranslate.Create;
  TextErrBigGap.Add(Eng, 'The gap is too big.');
  TextErrBigGap.Add(Ukr, 'Занадто великий прозор.');
  TextErrBigGap.Add(Rus, 'Слишком большой прозор.');
  TextErrBigGap.Add(Lit, 'Atotrūkis yra per didelis.');

  TextErrFinalAboveChn := TTranslate.Create;
  TextErrFinalAboveChn.Add(Eng, 'The water level is above the channel.');
  TextErrFinalAboveChn.Add(Ukr, 'Рівень води вище за канал.');
  TextErrFinalAboveChn.Add(Rus, 'Уровень воды выше канала.');
  TextErrFinalAboveChn.Add(Lit, 'Vandens lygis yra aukščiau kanalo.');

  TextErrFinalAboveGs := TTranslate.Create;
  TextErrFinalAboveGs.Add(Eng, 'The water level is above the grid.');
  TextErrFinalAboveGs.Add(Ukr, 'Рівень води вище полотна.');
  TextErrFinalAboveGs.Add(Rus, 'Уровень воды выше полотна.');
  TextErrFinalAboveGs.Add(Lit, 'Vandens lygis yra virš grotelių.');

  TextErrAngleDiapason := TTranslate.Create;
  TextErrAngleDiapason.Add(Eng, 'The angle %s+/-%s° is allowed.');
  TextErrAngleDiapason.Add(Ukr, 'Допускається кут %s+/-%s°.');
  TextErrAngleDiapason.Add(Rus, 'Допускается угол %s+/-%s°');
  TextErrAngleDiapason.Add(Lit, 'Leidžiamas kampas %s+/-%s°');

  { Result }

  TextOutBigDsg := TTranslate.Create;
  TextOutBigDsg.Add(Eng, 'RKE %0.2d%0.2d%s-%s-%s');
  TextOutBigDsg.Add(Ukr, 'РКЕ %0.2d%0.2d%s-%s-%s');
  TextOutBigDsg.Add(Rus, 'РКЭ %0.2d%0.2d%s-%s-%s');

  TextOutSmallDsg := TTranslate.Create;
  TextOutSmallDsg.Add(Eng, 'RKEm %0.2d%0.2d%s-%s-%s');
  TextOutSmallDsg.Add(Ukr, 'РКЕм %0.2d%0.2d%s-%s-%s');
  TextOutSmallDsg.Add(Rus, 'РКЭм %0.2d%0.2d%s-%s-%s');

  TextOutWeight := TTranslate.Create;
  TextOutWeight.Add(Eng, 'Weight %s kg');
  TextOutWeight.Add(Ukr, 'Маса %s кг');
  TextOutWeight.Add(Rus, 'Масса %s кг');

  TextOutWeightApprox := TTranslate.Create;
  TextOutWeightApprox.Add(Eng, 'Weight %s kg (approx.)');
  TextOutWeightApprox.Add(Ukr, 'Вага %s кг (приблизно)');
  TextOutWeightApprox.Add(Rus, 'Вес %s кг (примерно)');

  TextOutDrive := TTranslate.Create;
  TextOutDrive.Add(Eng, 'Gearmotor «%s», %s kW, %s Nm, %s rpm');
  TextOutDrive.Add(Ukr, 'Мотор-редуктор «%s», %s кВт, %s Нм, %s об/хв');
  TextOutDrive.Add(Rus, 'Мотор-редуктор «%s», %s кВт, %s Нм, %s об/мин');

  TextOutInnerWidth := TTranslate.Create;
  TextOutInnerWidth.Add(Eng, 'Section width %s mm');
  TextOutInnerWidth.Add(Ukr, 'Ширина просвіту %s мм');
  TextOutInnerWidth.Add(Rus, 'Ширина просвета %s мм');

  TextOutInnerHeight := TTranslate.Create;
  TextOutInnerHeight.Add(
    Eng, 'Section height (above the channel bottom) %s mm');
  TextOutInnerHeight.Add(
    Ukr, 'Висота просвіту (над дном каналу) %s мм');
  TextOutInnerHeight.Add(
    Rus, 'Высота просвета (над дном канала) %s мм');

  TextOutScrLength := TTranslate.Create;
  TextOutScrLength.Add(Eng, 'Screen length %s mm');
  TextOutScrLength.Add(Ukr, 'Довжина решітки %s мм');
  TextOutScrLength.Add(Rus, 'Длина решетки %s мм');

  TextOutChainLength := TTranslate.Create;
  TextOutChainLength.Add(Eng, 'Chain length %s mm');
  TextOutChainLength.Add(Ukr, 'Довжина ланцюга %s мм');
  TextOutChainLength.Add(Rus, 'Длина цепи %s мм');

  TextOutFpLength := TTranslate.Create;
  TextOutFpLength.Add(Eng, 'Profile length %s mm');
  TextOutFpLength.Add(Ukr, 'Довжина профілю %s мм');
  TextOutFpLength.Add(Rus, 'Длина профиля %s мм');

  TextOutFpCount := TTranslate.Create;
  TextOutFpCount.Add(Eng, 'Number of profiles %d ± 1 pc.');
  TextOutFpCount.Add(Ukr, 'Кількість профілів %d ± 1 шт.');
  TextOutFpCount.Add(Rus, 'Количество профилей %d ± 1 шт.');

  TextOutRakeCount := TTranslate.Create;
  TextOutRakeCount.Add(Eng, 'Number of rakes %d pcs.');
  TextOutRakeCount.Add(Ukr, 'Кількість граблин %d шт.');
  TextOutRakeCount.Add(Rus, 'Количество граблин %d шт.');

  TextOutDropWidth := TTranslate.Create;
  TextOutDropWidth.Add(Eng, 'Discharge width %s mm');
  TextOutDropWidth.Add(Ukr, 'Ширина скидання %s мм');
  TextOutDropWidth.Add(Rus, 'Ширина сброса %s мм');

  TextOutDropAboveTop := TTranslate.Create;
  TextOutDropAboveTop.Add(
    Eng, 'Discharge height (above the channel surface) %s%s mm');
  TextOutDropAboveTop.Add(
    Ukr, 'Висота скидання (над поверхнею каналом) %s%s мм');
  TextOutDropAboveTop.Add(
    Rus, 'Высота сброса (над поверхностью каналом) %s%s мм');

  TextOutDropAboveBottom := TTranslate.Create;
  TextOutDropAboveBottom.Add(
    Eng, 'Discharge height (above the channel bottom) %s%s mm');
  TextOutDropAboveBottom.Add(
    Ukr, 'Висота скидання (над дном каналу) %s%s мм');
  TextOutDropAboveBottom.Add(
    Rus, 'Высота сброса (над дном канала) %s%s мм');

  TextOutHydrMm := TTranslate.Create;
  TextOutHydrMm.Add(Eng, '%s mm');
  TextOutHydrMm.Add(Ukr, '%s мм');
  TextOutHydrMm.Add(Rus, '%s мм');
  TextOutHydrMm.Add(Lit, '%s mm');

  TextOutHydrMs := TTranslate.Create;
  TextOutHydrMs.Add(Eng, '%s m/s');
  TextOutHydrMs.Add(Ukr, '%s м/с');
  TextOutHydrMs.Add(Rus, '%s м/с');
  TextOutHydrMs.Add(Lit, '%s m/s');

  TextOutWarningOverflow := TTranslate.Create;
  TextOutWarningOverflow.Add(Eng, '%.0f%% - channel overflow');
  TextOutWarningOverflow.Add(Ukr, '%.0f%% - переповнення каналу');
  TextOutWarningOverflow.Add(Rus, '%.0f%% - переполнение канала');

  TextOutWarningDiff := TTranslate.Create;
  TextOutWarningDiff.Add(Eng, '%.0f%% - level above the grid (by %s mm)');
  TextOutWarningDiff.Add(Ukr, '%.0f%% - рівень вище полотна (на %s мм)');
  TextOutWarningDiff.Add(Rus, '%.0f%% - уровень выше полотна (на %s мм)');

  TextOutMinTorque := TTranslate.Create;
  TextOutMinTorque.Add(Eng, 'Minimum torque %s Nm');
  TextOutMinTorque.Add(Ukr, 'Мінімальний обертаючий момент %s Нм');
  TextOutMinTorque.Add(Rus, 'Минимальный крутящий момент %s Нм');

  TextOutGap := TTranslate.Create;
  TextOutGap.Add(Eng, 'Actual gap %s mm');
  TextOutGap.Add(Ukr, 'Фактичний прозор %s мм');
  TextOutGap.Add(Rus, 'Фактический прозор %s мм');

  TextOutSpring := TTranslate.Create;
  TextOutSpring.Add(Eng, 'Spring «%s»; pre-compression %s mm');
  TextOutSpring.Add(Ukr, 'Пружина «%s»; попередній стиск %s мм');
  TextOutSpring.Add(Rus, 'Пружина «%s»; предварительное сжатие %s мм');

  TextOutEquationFile := TTranslate.Create;
  TextOutEquationFile.Add(Eng, Heading('Equation file'));
  TextOutEquationFile.Add(Ukr, Heading('Файл рівнянь'));
  TextOutEquationFile.Add(Rus, Heading('Файл уравнений'));

  TextOutForDesigner := TTranslate.Create;
  TextOutForDesigner.Add(Eng, Heading('For designer'));
  TextOutForDesigner.Add(Ukr, Heading('Для конструктора'));
  TextOutForDesigner.Add(Rus, Heading('Для конструктора'));

finalization
  FreeAndNil(TextUiTitle);
  FreeAndNil(TextUiAuto);
  FreeAndNil(TextUiWs);
  FreeAndNil(TextUiHs);
  FreeAndNil(TextUiGs);
  FreeAndNil(TextUiWid);
  FreeAndNil(TextUiDep);
  FreeAndNil(TextUiDrop);
  FreeAndNil(TextUiGap);
  FreeAndNil(TextUiColName);
  FreeAndNil(TextUiColMount);
  FreeAndNil(TextUiColFactor);
  FreeAndNil(TextUiFpWeld);
  FreeAndNil(TextUiFpRemov);
  FreeAndNil(TextUiHydr);
  FreeAndNil(TextUiFlow);
  FreeAndNil(TextUiLevel);
  FreeAndNil(TextUiAngle);
  FreeAndNil(TextUiCol2Poll);
  FreeAndNil(TextUiCol2GapSpeed);
  FreeAndNil(TextUiCol2Area);
  FreeAndNil(TextUiCol2BFactor);
  FreeAndNil(TextUiCol2Diff);
  FreeAndNil(TextUiCol2Front);
  FreeAndNil(TextUiCol2ChnSpeed);

  FreeAndNil(TextErrWidth);
  FreeAndNil(TextErrDepth);
  FreeAndNil(TextErrDrop);
  FreeAndNil(TextErrFlow);
  FreeAndNil(TextErrLevel);
  FreeAndNil(TextErrAngle);
  FreeAndNil(TextErrTooHighHs);
  FreeAndNil(TextErrMinDrop);
  FreeAndNil(TextErrTooHighGs);
  FreeAndNil(TextErrDiffHsGs);
  FreeAndNil(TextErrTooNarrow);
  FreeAndNil(TextErrTooWide);
  FreeAndNil(TextErrTooSmall);
  FreeAndNil(TextErrBigGap);
  FreeAndNil(TextErrFinalAboveChn);
  FreeAndNil(TextErrFinalAboveGs);
  FreeAndNil(TextErrAngleDiapason);

  FreeAndNil(TextOutBigDsg);
  FreeAndNil(TextOutSmallDsg);
  FreeAndNil(TextOutWeight);
  FreeAndNil(TextOutWeightApprox);
  FreeAndNil(TextOutDrive);
  FreeAndNil(TextOutInnerWidth);
  FreeAndNil(TextOutInnerHeight);
  FreeAndNil(TextOutScrLength);
  FreeAndNil(TextOutChainLength);
  FreeAndNil(TextOutFpLength);
  FreeAndNil(TextOutFpCount);
  FreeAndNil(TextOutRakeCount);
  FreeAndNil(TextOutDropWidth);
  FreeAndNil(TextOutDropAboveTop);
  FreeAndNil(TextOutDropAboveBottom);
  FreeAndNil(TextOutHydrMm);
  FreeAndNil(TextOutHydrMs);
  FreeAndNil(TextOutWarningOverflow);
  FreeAndNil(TextOutWarningDiff);
  FreeAndNil(TextOutMinTorque);
  FreeAndNil(TextOutGap);
  FreeAndNil(TextOutSpring);
  FreeAndNil(TextOutEquationFile);
  FreeAndNil(TextOutForDesigner);
end.
