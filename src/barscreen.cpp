#include "../dry/wxgui.h"
#include "barscreen.h"

#define ADD_STEP(format, ...)                                                  \
do                                                                             \
{                                                                              \
    wxString step;                                                             \
    step.Printf(format, ##__VA_ARGS__);                                        \
    m_order.Add(step);                                                         \
}                                                                              \
while ( 0 )

wxString BarScreen::GetDesignation()
{
    return m_designation.value();
}

Mass BarScreen::GetMass()
{
    return m_mass.value();
}

bool BarScreen::IsStandardSize()
{
    return m_isStandardSize.value();
}

wxString BarScreen::GetError()
{
    return m_error;
}

void BarScreen::ThrowInputDataError(const wxString& errorMessage)
{
    m_error = errorMessage;
    throw std::invalid_argument("Input data error.");
}

BarScreen::BarScreen(const InputData& inputData, wxString& error,
                     wxArrayString& order) :
        m_error(error), m_order(order)
{
    m_inputData = inputData;
    m_order.Clear();

    if ( m_inputData.screenHss - m_inputData.grateHss < -3 )
    {
        ThrowInputDataError(wxT("Слишком высокое полотно."));
    }
    m_channelWss = CalcChannelWss();
    if ( m_channelWss.value() - m_inputData.screenWss < 0 )
    {
        ThrowInputDataError(wxT("Слишком узкий канал."));
    }
    if ( m_channelWss.value() - m_inputData.screenWss > 2 )
    {
        ThrowInputDataError(wxT("Слишком широкий канал."));
    }
    m_screenPivotHeight = CalcScreenPivotHeight();
    m_standHeight = CalcStandHeight();
    m_standHss = CalcStandHss();
    if ( m_standHss.value() < 7 )
    {
        ThrowInputDataError(wxT("Слишком глубокий канал."));
    }
    m_innerScreenWidth = CalcInnerScreenWidth();
    m_fpWidth = CalcFilterProfileWidth();
    m_profilesCount = CalcProfilesCount();
    if ( m_profilesCount.value() < 2 )
    {
        ThrowInputDataError(wxT("Слишком большой прозор."));
    }
    m_wssDiff = CalcWssDiff();
    m_backwallHss = CalcBackwallHss();
    m_coverHss = CalcCoverHss();
    m_chainLength = CalcChainLength();
    m_rakesCount = CalcRakesCount();
    m_coversCount = CalcCoversCount();

    m_mass_Rke010101Ad = CalcMass_Rke010101Ad();
    m_mass_Rke010111Ad = CalcMass_Rke010111Ad();
    m_mass_Rke010102Ad = CalcMass_Rke010102Ad();
    m_mass_Rke010103Ad = CalcMass_Rke010103Ad();
    m_mass_Rke010104Ad = CalcMass_Rke010104Ad();
    m_mass_Rke010105Ad = CalcMass_Rke010105Ad();
    m_mass_Rke010107Ad = CalcMass_Rke010107Ad();
    m_mass_Rke010108Ad = CalcMass_Rke010108Ad();
    m_mass_Rke010109Ad = CalcMass_Rke010109Ad();
    m_mass_Rke0101Ad02 = CalcMass_Rke0101Ad02();
    m_fastenersMass_Rke0101Ad = CalcFastenersMass_Rke0101Ad();
    m_mass_Rke0101Ad = CalcMass_Rke0101Ad();
    m_mass_Rke0102Ad = CalcMass_Rke0102Ad();
    m_mass_Rke010301Ad = CalcMass_Rke010301Ad();
    m_mass_Rke0103Ad01 = CalcMass_Rke0103Ad01();
    m_mass_Rke0103Ad02 = CalcMass_Rke0103Ad02();
    m_mass_Rke0103Ad = CalcMass_Rke0103Ad();
    m_mass_Rke0104Ad = CalcMass_Rke0104Ad();
    m_mass_Rke01Ad01 = CalcMass_Rke01Ad01();
    m_fastenersMass_Rke01Ad = CalcFastenersMass_Rke01Ad();
    m_mass_Rke01Ad = CalcMass_Rke01Ad();
    m_mass_Rke02Ad = CalcMass_Rke02Ad();
    m_mass_Rke03Ad = CalcMass_Rke03Ad();
    m_mass_Rke04Ad = CalcMass_Rke04Ad();
    m_mass_Rke05Ad = CalcMass_Rke05Ad();
    m_mass_Rke06Ad = CalcMass_Rke06Ad();
    m_mass_Rke07Ad = CalcMass_Rke07Ad();
    m_mass_Rke08Ad = CalcMass_Rke08Ad();
    m_mass_Rke09Ad = CalcMass_Rke09Ad();
    m_mass_Rke10Ad = CalcMass_Rke10Ad();
    m_mass_Rke11Ad = CalcMass_Rke11Ad();
    m_mass_Rke12Ad = CalcMass_Rke12Ad();
    m_mass_Rke13Ad = CalcMass_Rke13Ad();
    m_mass_Rke18Ad = CalcMass_Rke18Ad();
    m_mass_Rke19Ad = CalcMass_Rke19Ad();
    m_mass_Rke00Ad05 = CalcMass_Rke00Ad05();
    m_mass_Rke00Ad09 = CalcMass_Rke00Ad09();
    m_mass_Rke00Ad13 = CalcMass_Rke00Ad13();
    m_chainMass_Ms56r100 = CalcChainMass_Ms56r100();
    m_fastenersMass_Rke00Ad = CalcFastenersMass_Rke00Ad();
    m_mass = CalcMass_Rke00Ad();

    m_designation = CreateDesignation();
    m_isStandardSize = CheckStandardSize();
}

// Проверка, входит ли решетка в стандартный типоряд.
bool BarScreen::CheckStandardSize()
{
    return (m_inputData.screenWss <= maxScreenWss) and
           (m_inputData.screenHss <= maxScreenHss);
}

// Обозначение решетки.
wxString BarScreen::CreateDesignation()
{
    wxString dsg = wxT("РКЭ ");
    dsg << wxString::Format(wxT("%02i"), m_inputData.screenWss)
                  << wxString::Format(wxT("%02i"), m_inputData.screenHss);
    if ( m_channelWss.value() != m_inputData.screenWss
         or m_inputData.grateHss != m_inputData.screenHss )
    {
        dsg << wxT("(");
        if ( m_channelWss.value() == m_inputData.screenWss )
        {
            dsg << wxT("00");
        }
        else
        {
            dsg << wxString::Format(wxT("%02i"), m_channelWss.value());
        }
        if ( m_inputData.grateHss == m_inputData.screenHss )
        {
            dsg << wxT("00");
        }
        else
        {
            dsg << wxString::Format(wxT("%02i"), m_inputData.grateHss);
        }
        dsg << wxT(")");
    }
    dsg << wxT(".");
    switch ( m_inputData.fp )
    {
        case fp3999:
            dsg << wxT("3999");
            break;
        case fp6x30:
            dsg << wxT("6x30");
            break;
        case fp777:
            dsg << wxT("777");
            break;
    }
    dsg << wxT(".") << m_inputData.gap * 1000;
    return dsg;
}

WidthStdSize BarScreen::CalcWssDiff()
{
    WidthStdSize result = m_channelWss.value() - m_inputData.screenWss;
    ADD_STEP(wxT("Разность типоразмеров ширины канала и решетки: %d"), result);
    return result;
}

Distance BarScreen::CalcStandHeight()
{
    Distance result = m_screenPivotHeight.value() - m_inputData.channelHeight;
    ADD_STEP(wxT("Высота опоры от поверхности канала до оси поворота решетки: "
                 "%.3f м"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke00Ad()
{
    Mass result = m_mass_Rke01Ad.value() * 1
                + m_mass_Rke02Ad.value() * 1
                + m_mass_Rke03Ad.value() * 2
                + m_mass_Rke04Ad.value() * m_rakesCount.value()
                + m_mass_Rke05Ad.value() * 1
                + m_mass_Rke06Ad.value() * 1
                + m_mass_Rke07Ad.value() * 1
                + m_mass_Rke08Ad.value() * 2
                + m_mass_Rke09Ad.value() * 1
                + m_mass_Rke10Ad.value() * m_coversCount.value()
                + m_mass_Rke11Ad.value() * 2
                + m_mass_Rke12Ad.value() * 2
                + m_mass_Rke13Ad.value() * 1
                + m_mass_Rke18Ad.value() * 2
                + m_mass_Rke19Ad.value() * 1
                + m_mass_Rke00Ad05.value() * 4
                + m_mass_Rke00Ad09.value() * 2
                + m_mass_Rke00Ad13.value() * 2
                + m_chainMass_Ms56r100.value() * 2
                + m_fastenersMass_Rke00Ad.value();
    ADD_STEP(wxT("Масса решетки: %.1f кг"), result);
    return result;
}

WidthStdSize BarScreen::CalcChannelWss()
{
    WidthStdSize result = round((m_inputData.channelWidth - 0.1) / 0.1);
    ADD_STEP(wxT("Типоразмер ширины канала: %d"), result);
    return result;
}

HeightStdSize BarScreen::CalcBackwallHss()
{
    HeightStdSize result = m_inputData.screenHss - m_inputData.grateHss + 10;
    ADD_STEP(wxT("Типоразмер высоты стола: %d"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke0102Ad()
{
    Mass result = 1.5024 * m_inputData.screenWss - 0.1065;
    ADD_STEP(wxT("Масса узла РКЭ-01.02.00.00.v01 СБ Лоток: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke010301Ad()
{
    Mass result = 0.6919 * m_inputData.screenWss - 0.7431;
    ADD_STEP(wxT("Масса узла РКЭ-01.03.01.00-(...).v01 СБ Балка вставного "
                 "полотна: %.1f кг"), result);
    return result;
}

Distance BarScreen::CalcInnerScreenWidth()
{
    Distance result = 0.1 * m_inputData.screenWss - 0.132;
    ADD_STEP(wxT("Внутренняя ширина решетки (просвет): %.3f м"), result);
    return result;
}

Distance BarScreen::CalcFilterProfileWidth()
{
    Distance result;
    switch ( m_inputData.fp )
    {
        case fp6x30:
            result = 0.006;
            break;
        case fp777:
            result = 0.0078;
            break;
        case fp3999:
            result = 0.0095;
            break;
    }
    ADD_STEP(wxT("Ширина одного фильтровального профиля: %.4f м"), result);
    return result;
}

int BarScreen::CalcProfilesCount()
{
    int result = ceil((m_innerScreenWidth.value() - m_inputData.gap) /
                      (m_fpWidth.value() + m_inputData.gap));
    ADD_STEP(wxT("Количество профилей фильтровального полотна: %d"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke0103Ad01()
{
    Mass result;
    switch ( m_inputData.fp )
    {
        case fp6x30:
            result = 0.144 * m_inputData.grateHss - 0.158;
            break;
        case fp777:
            result = 0.1887 * m_inputData.grateHss - 0.194;
            break;
        case fp3999:
            result = 0.1167 * m_inputData.grateHss - 0.13;
            break;
    }
    ADD_STEP(wxT("Масса детали РКЭ-01.03.00.01-(...).v01 (профиль): %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke0103Ad02()
{
    Mass result = 0.16;
    ADD_STEP(wxT("Масса детали РКЭ-01.03.00.02.v01 Винт установочный: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke0103Ad()
{
    Mass result = m_mass_Rke010301Ad.value() * 2
                + m_mass_Rke0103Ad01.value() * m_profilesCount.value()
                + m_mass_Rke0103Ad02.value() * 4;
    ADD_STEP(wxT("Масса узла РКЭ-01.03.00.00-(...).v01 СБ Полотно "
                 "вставное: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke0104Ad()
{
    Mass result = 0.2886 * m_backwallHss.value() * m_inputData.screenWss
                - 0.2754 * m_backwallHss.value()
                + 2.2173 * m_inputData.screenWss - 2.6036;
    ADD_STEP(wxT("Масса узла РКЭ-01.04.00.00-(...).v01 СБ Стол: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke01Ad01()
{
    Mass result = 0.62;
    ADD_STEP(wxT("Масса детали РКЭ-01.00.00.01.v01 Лыжа: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcFastenersMass_Rke01Ad()
{
    Mass result = 1.07;
    ADD_STEP(wxT("Масса крепежа узла РКЭ (...)-01.00.00.00 СБ Корпус: "
                 "%.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke010101Ad()
{
    Mass result = 2.7233 * m_inputData.screenHss + 46.32;
    ADD_STEP(wxT("Масса узла (...)-01.01.01.00 СБ Боковина: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke010111Ad()
{
    Mass result = 2.7467 * m_inputData.screenHss + 46.03;
    ADD_STEP(wxT("Масса узла (...)-01.01.11.00 СБ Боковина: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke010102Ad()
{
    Mass result = 0.5963 * m_inputData.screenWss - 0.3838;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.02.00.v01 СБ Балка: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke010103Ad()
{
    Mass result = 0.5881 * m_inputData.screenWss + 0.4531;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.03.00.v01 СБ Балка оси вращения: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke010104Ad()
{
    Mass result = 0.8544 * m_inputData.screenWss - 0.1806;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.04.00.v01 СБ Балка верхняя: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke010105Ad()
{
    Mass result = 0.6313 * m_inputData.screenWss + 0.1013;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.05.00.v01 СБ Балка средняя: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke010107Ad()
{
    Mass result = 0.605 * m_wssDiff.value() + 3.36;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.07.00.v02 СБ Шарнир: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke010108Ad()
{
    Mass result = 0.445 * m_inputData.screenWss - 0.245;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.08.00.v01 СБ Балка распорная: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke010109Ad()
{
    Mass result = (m_inputData.screenWss <= 10)
                ? 0.136 * m_inputData.screenWss + 0.13
                : 0.1358 * m_inputData.screenWss + 0.2758;
    ADD_STEP(wxT("Масса узла РКЭ-01.01.09.00.v01 СБ Балка под 4 облицовки: "
                 "%.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke0101Ad02()
{
    Mass result = 0.42;
    ADD_STEP(wxT("Масса детали РКЭ-01.01.00.02.v01 Серьга разрезная: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcFastenersMass_Rke0101Ad()
{
    Mass result = 2.22;
    ADD_STEP(wxT("Масса крепежа узла РКЭ (...)-01.01.00.00 СБ Рама: "
                 "%.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke0101Ad()
{
    Mass result = m_mass_Rke010101Ad.value() * 1
                + m_mass_Rke010111Ad.value() * 1
                + m_mass_Rke010102Ad.value() * 2
                + m_mass_Rke010103Ad.value() * 1
                + m_mass_Rke010104Ad.value() * 1
                + m_mass_Rke010105Ad.value() * 1
                + m_mass_Rke010107Ad.value() * 2
                + m_mass_Rke010108Ad.value() * 1
                + m_mass_Rke010109Ad.value() * 1
                + m_mass_Rke0101Ad02.value() * 2
                + m_fastenersMass_Rke0101Ad.value();
    ADD_STEP(wxT("Масса узла РКЭ (...)-01.01.00.00 СБ Рама: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke01Ad()
{
    Mass result = m_mass_Rke0101Ad.value() * 1
                + m_mass_Rke0102Ad.value() * 1
                + m_mass_Rke0103Ad.value() * 1
                + m_mass_Rke0104Ad.value() * 1
                + m_mass_Rke01Ad01.value() * 2
                + m_fastenersMass_Rke01Ad.value();
    ADD_STEP(wxT("Масса узла (...)-01.00.00.00 СБ Корпус: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke02Ad()
{
    Mass result = 1.85 * m_inputData.screenWss + 97.28
                + (m_isHeavyVersion ? 2.29 : 0);
    ADD_STEP(wxT("Масса узла РКЭ-02.00.00.00.v01 СБ Привод: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke03Ad()
{
    Mass result = 0.12 * m_wssDiff.value() * m_inputData.grateHss
                + 2.12 * m_wssDiff.value() + 0.4967 * m_inputData.grateHss
                - 1.32;
    ADD_STEP(wxT("Масса узла РКЭ-03.00.00.00.v02 СБ Экран: %.1f кг"), result);
    return result;
}

// Тип полотна и прозор игнорируются.
Mass BarScreen::CalcMass_Rke04Ad()
{
    Mass result = 0.5524 * m_inputData.screenWss + 0.2035;
    ADD_STEP(wxT("Масса узла РКЭ-04.00.00.00-(...).v01 СБ Граблина: %.1f кг"),
             result);
    return result;
}

Distance BarScreen::CalcChainLength()
{
    Distance result;
    switch ( m_inputData.screenHss )
    {
        case 6:
            result = 3.528;
            break;
        case 7:
            result = 4.158;
            break;
        case 9:
            result = 4.662;
            break;
        default:
            result = 0.2 * m_inputData.screenHss + 3.2;
            break;
    }
    ADD_STEP(wxT("Длина цепи: %.3f м"), result);
    return result;
}

int BarScreen::CalcRakesCount()
{
    int result = round(m_chainLength.value() / 0.825);
    ADD_STEP(wxT("Количество граблин: %d"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke05Ad()
{
    Mass result = 0.8547 * m_inputData.screenWss + 1.4571;
    ADD_STEP(wxT("Масса узла РКЭ-05.00.00.00.v01 СБ Сбрасыватель: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke06Ad()
{
    Mass result = 0.5218 * m_inputData.screenWss + 0.6576;
    ADD_STEP(wxT("Масса узла РКЭ-06.00.00.00.v01 СБ Крышка: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke07Ad()
{
    Mass result = 1.08;
    ADD_STEP(wxT("Масса узла РКЭ-07.00.00.00.v01 СБ Ключ торцевой: %.1f кг"),
             result);
    return result;
}

Distance BarScreen::CalcScreenPivotHeight()
{
    Distance result = 0.0985 * m_inputData.screenHss + 1.0299;
    ADD_STEP(wxT("Высота от дна канала до оси поворота решетки: %.3f м"), result);
    return result;
}

HeightStdSize BarScreen::CalcStandHss()
{
    HeightStdSize result = round((m_standHeight.value() - 1.0035) / 0.3) * 3
                         + 10;
    ADD_STEP(wxT("Типоразмер высоты опоры решетки: %d"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke08Ad()
{
    Mass result = 1.8267 * m_standHss.value() + 8.0633;
    ADD_STEP(wxT("Масса узла РКЭ-08.00.00.00.v01 СБ Подставка на пол: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke09Ad()
{
    Mass result = 1.7871 * m_inputData.screenWss - 0.4094;
    ADD_STEP(wxT("Масса узла РКЭ-09.00.00.00.v01 СБ Склиз+кожух выброса: "
                 "%.1f кг"), result);
    return result;
}

int BarScreen::CalcCoversCount()
{
    int result = (m_inputData.screenWss <= 10) ? 2 : 4;
    ADD_STEP(wxT("Количество крышек передней облицовки: %d"), result);
    return result;
}

HeightStdSize BarScreen::CalcCoverHss()
{
    HeightStdSize result = wxMin(m_backwallHss.value(), m_standHss.value());
    ADD_STEP(wxT("Типоразмер высоты облицовки: %d"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke10Ad()
{
    Mass result = (m_inputData.screenWss <= 10)
                ? (0.06 * m_coverHss.value() * m_inputData.screenWss
                   - 0.055 * m_coverHss.value()
                   + 0.3167 * m_inputData.screenWss + 0.3933)
                : (0.03 * m_coverHss.value() * m_inputData.screenWss
                   - 0.0183 * m_coverHss.value()
                   + 0.1582 * m_inputData.screenWss + 0.6052);
    ADD_STEP(wxT("Масса узла РКЭ-10.00.00.00-10.v01 СБ Облицовка: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke11Ad()
{
    Mass result = 0.42;
    ADD_STEP(wxT("Масса узла РКЭ-11.00.00.00.v01 СБ Крышка боковая: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke12Ad()
{
    Mass result = 0.16;
    ADD_STEP(wxT("Масса узла РКЭ-12.00.00.00.v01 СБ Упор сбрасывателя: %.1f кг"),
             result);
    return result;
}

// TODO: Возможно рамку нужно делать по высоте канала, а не полотна.
Mass BarScreen::CalcMass_Rke13Ad()
{
    Mass result = 0.1811 * m_inputData.grateHss + 0.49 * m_inputData.screenWss
         + 0.7867;
    ADD_STEP(wxT("Масса узла РКЭ-13.00.00.00-(...).v01 СБ Рамка с прутка: "
                 "%.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke18Ad()
{
    Mass result = 1.13;
    ADD_STEP(wxT("Масса узла РКЭ-18.00.00.00.v01 СБ Ползун: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke19Ad()
{
    Mass result = 0.0161 * m_inputData.grateHss + 0.2067;
    ADD_STEP(wxT("Масса узла РКЭ-19.00.00.00.v01 СБ Датчик штыревой: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke00Ad05()
{
    Mass result = 0.87;
    ADD_STEP(wxT("Масса детали РКЭ-00.00.00.05.v01 Направляющая привода: "
                 "%.1f кг"), result);
    return result;
}

Mass BarScreen::CalcMass_Rke00Ad09()
{
    Mass result = 0.01;
    ADD_STEP(wxT("Масса детали РКЭ-00.00.00.09.v01 Втулка сбрасывателя: %.2f кг"),
             result);
    return result;
}

Mass BarScreen::CalcMass_Rke00Ad13()
{
    Mass result = 0.15;
    ADD_STEP(wxT("Масса детали РКЭ-00.00.00.13.v01 Гайка Тр20х4: %.1f кг"),
             result);
    return result;
}

Mass BarScreen::CalcChainMass_Ms56r100()
{
    Mass result = 4.18 * m_chainLength.value();
    ADD_STEP(wxT("Масса цепи МС56-Р-100: %.1f кг"), result);
    return result;
}

Mass BarScreen::CalcFastenersMass_Rke00Ad()
{
    Mass result = 1.24;
    ADD_STEP(wxT("Масса крепежа узла РКЭ (...)-00.00.00.00 СБ Решетка: "
                 "%.1f кг"), result);
    return result;
}
