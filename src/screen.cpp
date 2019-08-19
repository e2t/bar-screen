#include <cmath>
#include <algorithm>
#include "wx.h"
#include "screen.h"

// Обозначение решетки.
wxString CreateDesignation(WidthStdSize screenWss, HeightStdSize screenHss,
                            WidthStdSize channelWss, HeightStdSize grateHss,
                            FilterProfile fp, Distance gap)
{
    wxString dsg = wxT("РКЭ ");
    dsg << wxString::Format(wxT("%02i"), screenWss)
        << wxString::Format(wxT("%02i"), screenHss);
    if ( channelWss != screenWss or grateHss != screenHss )
    {
        dsg << wxT("(");
        if ( channelWss == screenWss )
        {
            dsg << wxT("00");
        }
        else
        {
            dsg << wxString::Format(wxT("%02i"), channelWss);
        }
        if ( grateHss == screenHss )
        {
            dsg << wxT("00");
        }
        else
        {
            dsg << wxString::Format(wxT("%02i"), grateHss);
        }
        dsg << wxT(")");
    }
    dsg << wxT(".");
    switch ( fp )
    {
        case fp3999: dsg << wxT("3999"); break;
        case fp6x30: dsg << wxT("6x30"); break;
        case fp777:  dsg << wxT("777");  break;
    }
    dsg << wxT(".") << gap * 1000;
    return dsg;
}

// Типоразмер канала по ширине.
WidthStdSize CalcChannelWss(Distance channelWidth)
{
    return round((channelWidth - 0.1) / 0.1);
}

// Типоразмер стола (задней стенки).
HeightStdSize CalcBackwallHss(HeightStdSize screenHss, HeightStdSize grateHss)
{
    return screenHss - grateHss;
}

// Масса узла РКЭ-01.02.00.00.v01 СБ Лоток.
Mass CalcMass_Rke0102Ad(WidthStdSize screenWss)
{
    return 1.5024 * screenWss - 0.1065;
}

// Масса узла РКЭ-01.03.01.00-хххх.хх.v01 СБ Балка вставного полотна.
// Прозор и тип полотна игнорируются.
Mass CalcMass_Rke010301Ad(WidthStdSize screenWss)
{
    return 0.6919 * screenWss - 0.7431;
}

// Просвет решетки в месте установки полотна.
Distance CalcInnerScreenWidth(WidthStdSize screenWss)
{
    return 0.1 * screenWss - 0.132;
}

// Ширина фильтровального профиля.
Distance CalcFilterProfileWidth(FilterProfile fp)
{
    switch ( fp )
    {
        case fp6x30: return 0.006;
        case fp777: return 0.0078;
        case fp3999: return 0.0095;
    }
    wxFAIL_MSG("Unreachable");
    return -1;
}

// Количество фильтровальных профилей.
int CalcProfilesCount(WidthStdSize screenWss, FilterProfile fp, Distance gap)
{
    Distance fpWidth = CalcFilterProfileWidth(fp);
    Distance innerScreenWidth = CalcInnerScreenWidth(screenWss);
    return ceil((innerScreenWidth - gap) / (fpWidth + gap));
}

// Масса детали РКЭ-01.03.00.01-хххх.v01(профиль).
Mass CalcMass_Rke0103Ad01(HeightStdSize grateHss, FilterProfile fp)
{
    switch ( fp )
    {
        case fp6x30: return 0.144 * grateHss - 0.158;
        case fp777: return 0.1887 * grateHss - 0.194;
        case fp3999: return 0.1167 * grateHss - 0.13;
    }
    wxFAIL_MSG("Unreachable");
    return -1;
}

// Масса детали РКЭ-01.03.00.02.v01 Винт установочный.
Mass CalcMass_Rke0103Ad02()
{
    return 0.16;
}

// Масса узла РКЭ-01.03.00.00-0700.6х30.10.v01 СБ Полотно вставное.
Mass CalcMass_Rke0103Ad(WidthStdSize screenWss, HeightStdSize grateHss,
                        FilterProfile fp, int profilesCount)
{
    return CalcMass_Rke010301Ad(screenWss) * 2
         + CalcMass_Rke0103Ad01(grateHss, fp) * profilesCount
         + CalcMass_Rke0103Ad02() * 4;
}

// Масса узла РКЭ-01.04.00.00-хх.v01 СБ Стол.
Mass CalcMass_Rke0104Ad(WidthStdSize screenWss, HeightStdSize backwallHss)
{
    return 0.218 * backwallHss * screenWss
         + 0.2955 * backwallHss + 3.0592 * screenWss - 11.4608;
}

// Масса детали РКЭ-01.00.00.01.v01 Лыжа.
Mass CalcMass_Rke01Ad01()
{
    return 0.62;
}

// Масса крепежа узла РКЭ хххх.хххх.хх-01.00.00.00 СБ Корпус.
Mass CalcFastenersMass_Rke01Ad()
{
    return 1.07;
}

// Масса узла хххх.хххх.хх-01.01.01.00 СБ Боковина.
Mass CalcMass_Rke010101Ad(HeightStdSize screenHss)
{
    return 2.7233 * screenHss + 46.32;
}

// Масса узла хххх.хххх.хх-01.01.11.00 СБ Боковина.
Mass CalcMass_Rke010111Ad(HeightStdSize screenHss)
{
    return 2.7467 * screenHss + 46.03;
}

// Масса узла РКЭ-01.01.02.00.v01 СБ Балка.
Mass CalcMass_Rke010102Ad(WidthStdSize screenWss)
{
    return 0.5963 * screenWss - 0.3838;
}

// Масса узла РКЭ-01.01.03.00.v01 СБ Балка оси вращения.
Mass CalcMass_Rke010103Ad(WidthStdSize screenWss)
{
    return 0.5881 * screenWss + 0.4531;
}

// Масса узла РКЭ-01.01.04.00.v01 СБ Балка верхняя.
Mass CalcMass_Rke010104Ad(WidthStdSize screenWss)
{
    return 0.8544 * screenWss - 0.1806;
}

// Масса узла РКЭ-01.01.05.00.v01 СБ Балка средняя.
Mass CalcMass_Rke010105Ad(WidthStdSize screenWss)
{
    return 0.6313 * screenWss + 0.1013;
}

// Масса узла РКЭ-01.01.07.00.v02 СБ Шарнир.
Mass CalcMass_Rke010107Ad(WidthStdSize wssDiff)
{
    return 0.605 * wssDiff + 3.36;
}

// Масса узла РКЭ-01.01.08.00.v01 СБ Балка распорная.
Mass CalcMass_Rke010108Ad(WidthStdSize screenWss)
{
    return 0.445 * screenWss - 0.245;
}

// Масса узла РКЭ-01.01.09.00.v01 СБ Балка под 4 облицовки.
Mass CalcMass_Rke010109Ad(WidthStdSize screenWss)
{
    if ( screenWss <= 10 )
    {
        return 0.136 * screenWss + 0.13;
    }
    return 0.1358 * screenWss + 0.2758;
}

// Масса детали РКЭ-01.01.00.02.v01 Серьга разрезная.
Mass CalcMass_Rke0101Ad02()
{
    return 0.42;
}

// Масса крепежа узла РКЭ xxxx.xxxx.xx-01.01.00.00 СБ Рама.
Mass CalcFastenersMass_Rke0101Ad()
{
    return 2.22;
}

// Масса узла РКЭ xxxx.xxxx.xx-01.01.00.00 СБ Рама
Mass CalcMass_Rke0101Ad(WidthStdSize screenWss, HeightStdSize screenHss,
                        WidthStdSize wssDiff)
{
    return CalcMass_Rke010101Ad(screenHss) * 1
         + CalcMass_Rke010111Ad(screenHss) * 1
         + CalcMass_Rke010102Ad(screenWss) * 2
         + CalcMass_Rke010103Ad(screenWss) * 1
         + CalcMass_Rke010104Ad(screenWss) * 1
         + CalcMass_Rke010105Ad(screenWss) * 1
         + CalcMass_Rke010107Ad(wssDiff) * 2
         + CalcMass_Rke010108Ad(screenWss) * 1
         + CalcMass_Rke010109Ad(screenWss) * 1
         + CalcMass_Rke0101Ad02() * 2
         + CalcFastenersMass_Rke0101Ad();
}

// Масса узла хххх.хххх.хх-01.00.00.00 СБ Корпус.
Mass CalcMass_Rke01Ad(WidthStdSize screenWss, HeightStdSize screenHss,
                      WidthStdSize wssDiff, HeightStdSize grateHss,
                      HeightStdSize backwallHss, FilterProfile fp,
                      int profilesCount)
{
    return CalcMass_Rke0101Ad(screenWss, screenHss, wssDiff) * 1
         + CalcMass_Rke0102Ad(screenWss) * 1
         + CalcMass_Rke0103Ad(screenWss, grateHss, fp, profilesCount) * 1
         + CalcMass_Rke0104Ad(screenWss, backwallHss) * 1
         + CalcMass_Rke01Ad01() * 2
         + CalcFastenersMass_Rke01Ad();
}

// Масса узла РКЭ-02.00.00.00.v01 СБ Привод.
Mass CalcMass_Rke02Ad(WidthStdSize screenWss, bool isHeavyVersion = false)
{
    return 1.85 * screenWss + 97.28 + (isHeavyVersion ? 2.29 : 0);
}

// Масса узла РКЭ-03.00.00.00.v02 СБ Экран.
Mass CalcMass_Rke03Ad(WidthStdSize wssDiff, HeightStdSize grateHss)
{
    return 0.12 * wssDiff * grateHss
         + 2.12 * wssDiff + 0.4967 * grateHss - 1.32;
}

// Масса узла РКЭ-04.00.00.00-xxxx.xx.v01 СБ Граблина.
// Тип полотна и прозор игнорируются.
Mass CalcMass_Rke04Ad(WidthStdSize screenWss)
{
    return 0.5524 * screenWss + 0.2035;
}

// Длина цепи.
Distance CalcChainLength(HeightStdSize screenHss)
{
    switch ( screenHss )
    {
        case 6: return 3.528;
        case 7: return 4.158;
        case 9: return 4.662;
    }
    return 0.2 * screenHss + 3.2;
}

// Количество граблин.
int CalcRakesCount(HeightStdSize screenHss)
{
    return round(CalcChainLength(screenHss) / 0.825);
}

// Масса узла РКЭ-05.00.00.00.v01 СБ Сбрасыватель.
Mass CalcMass_Rke05Ad(WidthStdSize screenWss)
{
    return 0.8547 * screenWss + 1.4571;
}

// Масса узла РКЭ-06.00.00.00.v01 СБ Крышка.
Mass CalcMass_Rke06Ad(WidthStdSize screenWss)
{
    return 0.5218 * screenWss + 0.6576;
}

// Масса узла РКЭ-07.00.00.00.v01 СБ Ключ торцевой.
Mass CalcMass_Rke07Ad()
{
    return 1.08;
}

// Высота от дна канала до оси поворота решетки.
Distance CalcScreenPivotHeight(HeightStdSize screenHss)
{
    return 98.48 * screenHss + 1029.88;
}

// Типоразмер высоты подставки на поверхность канала.
HeightStdSize CalcStandHss(HeightStdSize screenHss, Distance channelHeight)
{
    // Высота подставки от поверхности канала до оси.
    Distance standHeight = CalcScreenPivotHeight(screenHss) - channelHeight;
    return round((standHeight - 1003.5) / 300.0) * 3 + 10;
}

// Масса узла РКЭ-08.00.00.00.v01 СБ Подставка на пол.
Mass CalcMass_Rke08Ad(HeightStdSize standHss)
{
    return 1.8267 * standHss + 8.0633;
}

// Масса узла РКЭ-09.00.00.00.v01 СБ Склиз+кожух выброса.
Mass CalcMass_Rke09Ad(WidthStdSize screenWss)
{
    return 1.7871 * screenWss - 0.4094;
}

// Количество(передних крышек) облицовки.
int CalcCoversCount(WidthStdSize screenWss)
{
    return (screenWss <= 10) ? 2 : 4;
}

// Типоразмер высоты облицовки(передней крышки).
HeightStdSize CalcCoverHss(HeightStdSize backwallHss, HeightStdSize standHss)
{
    return std::min(backwallHss, standHss);
}

// Масса узла РКЭ-10.00.00.00-10.v01 СБ Облицовка.
Mass CalcMass_Rke10Ad(HeightStdSize coverHss, WidthStdSize screenWss)
{
    if ( screenWss <= 10 )
    {
        return 0.06 * coverHss * screenWss
             - 0.055 * coverHss + 0.3167 * screenWss + 0.3933;
    }
    return 0.03 * coverHss * screenWss
         - 0.0183 * coverHss + 0.1582 * screenWss + 0.6052;
}

// Масса узла РКЭ-11.00.00.00.v01 СБ Крышка боковая.
Mass CalcMass_Rke11Ad()
{
    return 0.42;
}

// Масса узла РКЭ-12.00.00.00.v01 СБ Упор сбрасывателя.
Mass CalcMass_Rke12Ad()
{
    return 0.16;
}

// Масса узла РКЭ-13.00.00.00-хххх.v01 СБ Рамка с прутка.
// TODO: Возможно рамку нужно делать по высоте канала, а не полотна.
Mass CalcMass_Rke13Ad(WidthStdSize screenWss, HeightStdSize grateHss)
{
    return 0.1811 * grateHss + 0.49 * screenWss + 0.7867;
}

// Масса узла РКЭ-18.00.00.00.v01 СБ Ползун.
Mass CalcMass_Rke18Ad()
{
    return 1.13;
}

// Масса узла РКЭ-19.00.00.00.v01 СБ Датчик штыревой.
Mass CalcMass_Rke19Ad(HeightStdSize grateHss)
{
    return 0.0161 * grateHss + 0.2067;
}

// Масса детали РКЭ-00.00.00.05.v01 Направляющая привода.
Mass CalcMass_Rke00Ad05()
{
    return 0.87;
}

// Масса детали РКЭ-00.00.00.09.v01 Втулка сбрасывателя.
Mass CalcMass_Rke00Ad09()
{
    return 0.01;
}

// Масса детали РКЭ-00.00.00.13.v01 Гайка Тр20х4.
Mass CalcMass_Rke00Ad13()
{
    return 0.15;
}

// Масса цепи МС56-Р-100.
Mass CalcChainMass_Ms56r100(HeightStdSize screenHss)
{
    return 4.18 * CalcChainLength(screenHss);
}

// Масса крепежа узла РКЭ хххх.хххх.хх-00.00.00.00 СБ Решетка.
Mass CalcFastenersMass_Rke00Ad()
{
    return 1.24;
}

// Масса решетки.
Mass CalcMass_Rke00Ad(WidthStdSize screenWss, HeightStdSize screenHss,
                      HeightStdSize grateHss, WidthStdSize channelWss,
                      HeightStdSize standHss, FilterProfile fp,
                      int profilesCount)
{
    WidthStdSize wssDiff = channelWss - screenWss;
    HeightStdSize backwallHss = CalcBackwallHss(screenHss, grateHss);
    HeightStdSize coverHss = CalcCoverHss(backwallHss, standHss);

    return CalcMass_Rke01Ad(screenWss, screenHss, wssDiff, grateHss,
                            backwallHss, fp, profilesCount) * 1
         + CalcMass_Rke02Ad(screenWss) * 1
         + CalcMass_Rke03Ad(wssDiff, grateHss) * 2
         + CalcMass_Rke04Ad(screenWss) * CalcRakesCount(screenHss)
         + CalcMass_Rke05Ad(screenWss) * 1
         + CalcMass_Rke06Ad(screenWss) * 1
         + CalcMass_Rke07Ad() * 1
         + CalcMass_Rke08Ad(standHss) * 2
         + CalcMass_Rke09Ad(screenWss) * 1
         + CalcMass_Rke10Ad(coverHss, screenWss) * CalcCoversCount(screenWss)
         + CalcMass_Rke11Ad() * 2
         + CalcMass_Rke12Ad() * 2
         + CalcMass_Rke13Ad(screenWss, grateHss) * 1
         + CalcMass_Rke18Ad() * 2
         + CalcMass_Rke19Ad(grateHss) * 1
         + CalcMass_Rke00Ad05() * 4
         + CalcMass_Rke00Ad09() * 2
         + CalcMass_Rke00Ad13() * 2
         + CalcChainMass_Ms56r100(screenHss) * 2
         + CalcFastenersMass_Rke00Ad();
}
