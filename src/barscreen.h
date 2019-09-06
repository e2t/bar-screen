#ifndef SCREEN_H
#define SCREEN_H

#include <optional>

typedef int WidthStdSize;   // Типоразмер по ширине.
typedef int HeightStdSize;  // Типоразмер по высоте.

typedef double Mass;      // Масса, кг.
typedef double Distance;  // Расстояние, м.

enum FilterProfile { fp3999, fp6x30, fp777 };

class BarScreen
{
public:
    struct InputData
    {
        WidthStdSize screenWss;   // Типоразмер решетки по ширине.
        HeightStdSize screenHss;  // Типоразмер решетки по высоте.
        HeightStdSize grateHss;   // Типоразмер полотна по высоте.
        Distance channelWidth;    // Ширина канала, м.
        Distance channelHeight;   // Глубина канала, м.
        FilterProfile fp;         // Тип фильтровального профиля.
        Distance gap;             // Прозор полотна, м.
    };
    BarScreen(const InputData& inputData, wxString& error,
              wxArrayString& order);
    wxString GetDesignation();
    Mass GetMass();
    wxString GetError();
    bool IsStandardSize();
private:
    static const WidthStdSize maxScreenWss = 24;
    static const HeightStdSize maxScreenHss = 30;

    wxString& m_error;
    wxArrayString& m_order;
    InputData m_inputData;

    const bool m_isHeavyVersion = false;
    std::optional<WidthStdSize> m_channelWss;
    std::optional<HeightStdSize> m_standHss;
    std::optional<Distance> m_screenPivotHeight;
    std::optional<int> m_profilesCount;
    std::optional<WidthStdSize> m_wssDiff;
    std::optional<HeightStdSize> m_backwallHss;
    std::optional<HeightStdSize> m_coverHss;
    std::optional<Distance> m_standHeight;  // Высота подставки от поверхности канала до оси.
    std::optional<Distance> m_fpWidth;
    std::optional<Distance> m_innerScreenWidth;
    std::optional<wxString> m_designation;
    std::optional<Mass> m_mass;
    std::optional<bool> m_isStandardSize;
    std::optional<int> m_rakesCount;
    std::optional<int> m_coversCount;
    std::optional<Distance> m_chainLength;

    std::optional<Mass> m_mass_Rke010101Ad;
    std::optional<Mass> m_mass_Rke010111Ad;
    std::optional<Mass> m_mass_Rke010102Ad;
    std::optional<Mass> m_mass_Rke010103Ad;
    std::optional<Mass> m_mass_Rke010104Ad;
    std::optional<Mass> m_mass_Rke010105Ad;
    std::optional<Mass> m_mass_Rke010107Ad;
    std::optional<Mass> m_mass_Rke010108Ad;
    std::optional<Mass> m_mass_Rke010109Ad;
    std::optional<Mass> m_mass_Rke0101Ad02;
    std::optional<Mass> m_fastenersMass_Rke0101Ad;
    std::optional<Mass> m_mass_Rke0101Ad;
    std::optional<Mass> m_mass_Rke0102Ad;
    std::optional<Mass> m_mass_Rke010301Ad;
    std::optional<Mass> m_mass_Rke0103Ad01;
    std::optional<Mass> m_mass_Rke0103Ad02;
    std::optional<Mass> m_mass_Rke0103Ad;
    std::optional<Mass> m_mass_Rke0104Ad;
    std::optional<Mass> m_mass_Rke01Ad01;
    std::optional<Mass> m_fastenersMass_Rke01Ad;
    std::optional<Mass> m_mass_Rke01Ad;
    std::optional<Mass> m_mass_Rke02Ad;
    std::optional<Mass> m_mass_Rke03Ad;
    std::optional<Mass> m_mass_Rke04Ad;
    std::optional<Mass> m_mass_Rke05Ad;
    std::optional<Mass> m_mass_Rke06Ad;
    std::optional<Mass> m_mass_Rke07Ad;
    std::optional<Mass> m_mass_Rke08Ad;
    std::optional<Mass> m_mass_Rke09Ad;
    std::optional<Mass> m_mass_Rke10Ad;
    std::optional<Mass> m_mass_Rke11Ad;
    std::optional<Mass> m_mass_Rke12Ad;
    std::optional<Mass> m_mass_Rke13Ad;
    std::optional<Mass> m_mass_Rke18Ad;
    std::optional<Mass> m_mass_Rke19Ad;
    std::optional<Mass> m_mass_Rke00Ad05;
    std::optional<Mass> m_mass_Rke00Ad09;
    std::optional<Mass> m_mass_Rke00Ad13;
    std::optional<Mass> m_chainMass_Ms56r100;
    std::optional<Mass> m_fastenersMass_Rke00Ad;

    void ThrowInputDataError(const wxString& errorMessage);

    WidthStdSize CalcWssDiff();
    Distance CalcStandHeight();
    bool CheckStandardSize();
    Mass CalcMass_Rke00Ad();
    wxString CreateDesignation();
    WidthStdSize CalcChannelWss();
    HeightStdSize CalcBackwallHss();
    Mass CalcMass_Rke0102Ad();
    Mass CalcMass_Rke010301Ad();
    Distance CalcInnerScreenWidth();
    Distance CalcFilterProfileWidth();
    int CalcProfilesCount();
    Mass CalcMass_Rke0103Ad01();
    Mass CalcMass_Rke0103Ad02();
    Mass CalcMass_Rke0103Ad();
    Mass CalcMass_Rke0104Ad();
    Mass CalcMass_Rke01Ad01();
    Mass CalcFastenersMass_Rke01Ad();
    Mass CalcMass_Rke010101Ad();
    Mass CalcMass_Rke010111Ad();
    Mass CalcMass_Rke010102Ad();
    Mass CalcMass_Rke010103Ad();
    Mass CalcMass_Rke010104Ad();
    Mass CalcMass_Rke010105Ad();
    Mass CalcMass_Rke010107Ad();
    Mass CalcMass_Rke010108Ad();
    Mass CalcMass_Rke010109Ad();
    Mass CalcMass_Rke0101Ad02();
    Mass CalcFastenersMass_Rke0101Ad();
    Mass CalcMass_Rke0101Ad();
    Mass CalcMass_Rke01Ad();
    Mass CalcMass_Rke02Ad();
    Mass CalcMass_Rke03Ad();
    Mass CalcMass_Rke04Ad();
    Distance CalcChainLength();
    int CalcRakesCount();
    Mass CalcMass_Rke05Ad();
    Mass CalcMass_Rke06Ad();
    Mass CalcMass_Rke07Ad();
    Distance CalcScreenPivotHeight();
    HeightStdSize CalcStandHss();
    Mass CalcMass_Rke08Ad();
    Mass CalcMass_Rke09Ad();
    int CalcCoversCount();
    HeightStdSize CalcCoverHss();
    Mass CalcMass_Rke10Ad();
    Mass CalcMass_Rke11Ad();
    Mass CalcMass_Rke12Ad();
    Mass CalcMass_Rke13Ad();
    Mass CalcMass_Rke18Ad();
    Mass CalcMass_Rke19Ad();
    Mass CalcMass_Rke00Ad05();
    Mass CalcMass_Rke00Ad09();
    Mass CalcMass_Rke00Ad13();
    Mass CalcChainMass_Ms56r100();
    Mass CalcFastenersMass_Rke00Ad();
};

#endif
