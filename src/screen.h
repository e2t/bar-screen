#ifndef SCREEN_H
#define SCREEN_H

typedef int WidthStdSize;   // Типоразмер по ширине.
typedef int HeightStdSize;  // Типоразмер по высоте.

typedef double Mass;      // Масса, кг.
typedef double Distance;  // Расстояние, м.

enum FilterProfile { fp3999, fp6x30, fp777 };

// Обозначение решетки.
wxString CreateDesignation(WidthStdSize screenWss, HeightStdSize screenHss,
                           WidthStdSize channelWss, HeightStdSize grateHss,
                           FilterProfile fp, Distance gap);

// Типоразмер канала по ширине.
WidthStdSize CalcChannelWss(Distance channelWidth);

// Типоразмер высоты подставки на поверхность канала.
HeightStdSize CalcStandHss(HeightStdSize screenHss, Distance channelHeight);

// Количество фильтровальных профилей.
int CalcProfilesCount(WidthStdSize screenWss, FilterProfile fp, Distance gap);

// Масса решетки.
Mass CalcMass_Rke00Ad(WidthStdSize screenWss, HeightStdSize screenHss,
                      HeightStdSize grateHss, WidthStdSize channelWss,
                      HeightStdSize standHss, FilterProfile fp,
                      int profilesCount);

#endif
