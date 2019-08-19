#include <iostream>
#include "wx.h"
#include "screen.h"

class MyApp : public wxApp
{
public:
    virtual bool OnInit();
};

class MyFrame : public wxFrame
{
public:
    MyFrame();
    static void StaticMembersInit();
private:
    static WidthStdSize *ms_screenWssArray;
    static wxArrayString ms_screenWssChoices;
    static HeightStdSize *ms_screenHssArray;
    static wxArrayString ms_screenHssChoices;
    static HeightStdSize *ms_grateHssArray;
    static wxArrayString ms_grateHssChoices;
    static FilterProfile *ms_fpArray;
    static wxArrayString ms_fpChoices;

    wxChoice *m_screenWssCh;
    wxChoice *m_screenHssCh;
    wxChoice *m_grateHssCh;
    wxTextCtrl *m_channelWidthTc;
    wxTextCtrl *m_channelHeightTc;
    wxChoice *m_fpCh;
    wxTextCtrl *m_gapTc;
    wxTextCtrl *m_rkeMassTc;

    void OnRunButtonClick(wxCommandEvent& event);
    void OnPressKey(wxKeyEvent& event);

    bool GetMmFromTc(Distance& value, wxTextCtrl *tc);
    void Run();
};

enum
{
    ID_SCREEN_WSS_CH = 1,
    ID_SCREEN_HSS_CH,
    ID_GRATE_HSS_CH,
    ID_CHANNEL_WIDTH_TC,
    ID_CHANNEL_HEIGHT_TC,
    ID_FP_CH,
    ID_GAP_TC,
    ID_RKE_MASS_TC,
    ID_RUN_BT
};

wxIMPLEMENT_APP(MyApp);

bool MyApp::OnInit()
{
    MyFrame::StaticMembersInit();
    MyFrame *frame = new MyFrame();
    frame->Show(true);
    return true;
}

WidthStdSize *MyFrame::ms_screenWssArray;
wxArrayString MyFrame::ms_screenWssChoices;
HeightStdSize *MyFrame::ms_screenHssArray;
wxArrayString MyFrame::ms_screenHssChoices;
HeightStdSize *MyFrame::ms_grateHssArray;
wxArrayString MyFrame::ms_grateHssChoices;
FilterProfile *MyFrame::ms_fpArray;
wxArrayString MyFrame::ms_fpChoices;

void MyFrame::StaticMembersInit()
{
    // Типоразмеры решетки по ширине.
    const WidthStdSize minScreenWss = 5;
    const WidthStdSize maxScreenWss = 24;
    const int screenWssCount = maxScreenWss - minScreenWss + 1;
    ms_screenWssArray = new WidthStdSize[screenWssCount];
    for ( int i = 0; i < screenWssCount; i++ )
    {
        ms_screenWssArray[i] = minScreenWss + i;
        wxString choice;
        choice.Printf(wxT("%02d"), ms_screenWssArray[i]);
        ms_screenWssChoices.Add(choice);
    }

    // Типоразмеры решетки по высоте.
    const HeightStdSize minBigScreenHss = 12;
    const HeightStdSize maxBigScreenHss = 30;
    const int screenHssCount = (maxBigScreenHss - minBigScreenHss) / 3 + 1;
    ms_screenHssArray = new HeightStdSize[screenHssCount];
    // TODO: Малые типоразмеры еще не добавлены: 06, 07, 09.
    for ( int i = 0; i < screenHssCount; i++ )
    {
        ms_screenHssArray[i] = minBigScreenHss + i * 3;
        wxString choice;
        choice.Printf(wxT("%02d"), ms_screenHssArray[i]);
        ms_screenHssChoices.Add(choice);
    }

    // Типоразмеры полотна по высоте.
    const WidthStdSize minGrateHss = 6;
    const WidthStdSize maxGrateHss = 30;
    const int grateHssCount = (maxGrateHss - minGrateHss) / 3 + 1;
    ms_grateHssArray = new HeightStdSize[grateHssCount];
    for ( int i = 0; i < grateHssCount; i++ )
    {
        ms_grateHssArray[i] = minGrateHss + i * 3;
        wxString choice;
        choice.Printf(wxT("%02d"), ms_grateHssArray[i]);
        ms_grateHssChoices.Add(choice);
    }

    // Виды фильтровального профиля.
    // ВНИМАНИЕ: Эти же записи используются в выводе обозначения.
    ms_fpArray = new FilterProfile[3];

    ms_fpArray[0] = fp3999;
    ms_fpChoices.Add(wxT("3999"));

    ms_fpArray[1] = fp6x30;
    ms_fpChoices.Add(wxT("6x30"));

    ms_fpArray[2] = fp777;
    ms_fpChoices.Add(wxT("777"));
}

MyFrame::MyFrame()
    : wxFrame(NULL, wxID_ANY, wxT("Расчет грабельной решетки (v0.1.0)"),
              wxDefaultPosition, wxDefaultSize,
              wxDEFAULT_FRAME_STYLE & ~(wxRESIZE_BORDER | wxMAXIMIZE_BOX))
{
    wxPanel *panel = new wxPanel(this);

    m_screenWssCh = new wxChoice(panel, ID_SCREEN_WSS_CH);
    m_screenWssCh->Append(ms_screenWssChoices);
    m_screenWssCh->SetSelection(0);

    m_screenHssCh = new wxChoice(panel, ID_SCREEN_HSS_CH);
    m_screenHssCh->Append(ms_screenHssChoices);
    m_screenHssCh->SetSelection(0);

    m_grateHssCh = new wxChoice(panel, ID_GRATE_HSS_CH);
    m_grateHssCh->Append(ms_grateHssChoices);
    m_grateHssCh->SetSelection(0);

    m_channelWidthTc = new wxTextCtrl(
        panel, ID_CHANNEL_WIDTH_TC, wxEmptyString, wxDefaultPosition,
        wxMinWidth, 0, wxTextValidator(wxFILTER_NUMERIC));

    m_channelHeightTc = new wxTextCtrl(
        panel, ID_CHANNEL_HEIGHT_TC, wxEmptyString, wxDefaultPosition,
        wxMinWidth, 0, wxTextValidator(wxFILTER_NUMERIC));

    m_fpCh = new wxChoice(panel, ID_FP_CH);
    m_fpCh->Append(ms_fpChoices);
    m_fpCh->SetSelection(0);

    m_gapTc = new wxTextCtrl(panel, ID_GAP_TC, wxEmptyString, wxDefaultPosition,
                             wxMinWidth, 0, wxTextValidator(wxFILTER_NUMERIC));

    m_rkeMassTc = new wxTextCtrl(panel, ID_RKE_MASS_TC, wxEmptyString,
                                 wxDefaultPosition, wxMinWidth, wxTE_READONLY);

    wxButton *runBt = new wxButton(panel, ID_RUN_BT, wxT("Расчет"));

    const int border = 5;
    wxBoxSizer *topBs = new wxBoxSizer(wxHORIZONTAL);
    wxGridBagSizer *bs = new wxGridBagSizer(border, border);

    topBs->Add(bs, 0, wxALL, border);

    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Решетка:")),
            wxGBPosition(0, 0), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_screenWssCh, wxGBPosition(0, 1));
    bs->Add(m_screenHssCh, wxGBPosition(0, 2));
    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Ширина канала, мм:")),
            wxGBPosition(1, 0), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_channelWidthTc, wxGBPosition(1, 1), wxGBSpan(1, 2), wxEXPAND);
    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Высота канала, мм:")),
            wxGBPosition(2, 0), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_channelHeightTc, wxGBPosition(2, 1), wxGBSpan(1, 2), wxEXPAND);
    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Масса решетки, кг:")),
            wxGBPosition(4, 0), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_rkeMassTc, wxGBPosition(4, 1), wxGBSpan(1, 2), wxEXPAND);

    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Полотно:")),
            wxGBPosition(0, 3), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_grateHssCh, wxGBPosition(0, 4), wxDefaultSpan, wxEXPAND);
    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Профиль:")),
            wxGBPosition(1, 3), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_fpCh, wxGBPosition(1, 4), wxDefaultSpan, wxEXPAND);
    bs->Add(new wxStaticText(panel, wxID_ANY, wxT("Прозор, мм:")),
            wxGBPosition(2, 3), wxDefaultSpan, wxALIGN_CENTER_VERTICAL);
    bs->Add(m_gapTc, wxGBPosition(2, 4), wxDefaultSpan, wxEXPAND);
    bs->Add(runBt, wxGBPosition(4, 4), wxDefaultSpan, wxALIGN_RIGHT);

    CreateStatusBar();

    panel->SetSizerAndFit(topBs);
    Fit();

    Bind(wxEVT_BUTTON, &MyFrame::OnRunButtonClick, this, ID_RUN_BT);
    Bind(wxEVT_CHAR_HOOK, &MyFrame::OnPressKey, this);
}

bool MyFrame::GetMmFromTc(Distance& value, wxTextCtrl *tc)
{
    bool result = tc->GetLineText(0).ToDouble(&value);
    if ( result and value > 0 )
    {
        value /= 1000.0;  // мм -> м
    }
    else
    {
        SetStatusText(wxT("Неправильное значение."));
        tc->SetFocus();
        tc->SelectAll();
    }
    return result;
}

void MyFrame::OnRunButtonClick(wxCommandEvent&)
{
    Run();
}

void MyFrame::OnPressKey(wxKeyEvent& event)
{
    switch ( event.GetKeyCode() )
    {
        case WXK_RETURN:
        case WXK_NUMPAD_ENTER:
            Run();
    }
    event.Skip();
}

void MyFrame::Run()
{
    SetStatusText(wxT(""));
    m_rkeMassTc->Clear();

    WidthStdSize screenWss = ms_screenWssArray[m_screenWssCh->GetSelection()];
    HeightStdSize screenHss = ms_screenHssArray[m_screenHssCh->GetSelection()];
    HeightStdSize grateHss = ms_grateHssArray[m_grateHssCh->GetSelection()];
    FilterProfile fp = ms_fpArray[m_fpCh->GetSelection()];

    Distance channelWidth;
    if ( !GetMmFromTc(channelWidth, m_channelWidthTc) ) return;
    WidthStdSize channelWss = CalcChannelWss(channelWidth);
    if ( channelWss - screenWss < 0 )
    {
        SetStatusText(wxT("Слишком узкий канал."));
        return;
    }
    if ( channelWss - screenWss > 2 )
    {
        SetStatusText(wxT("Слишком широкий канал."));
        return;
    }

    Distance channelHeight;
    if ( !GetMmFromTc(channelHeight, m_channelHeightTc) ) return;
    HeightStdSize standHss = CalcStandHss(screenHss, channelHeight);
    if ( standHss < 7 )
    {
        SetStatusText(wxT("Слишком глубокий канал."));
        return;
    }

    Distance gap;
    if ( !GetMmFromTc(gap, m_gapTc) ) return;
    int profilesCount = CalcProfilesCount(screenWss, fp, gap);
    if ( profilesCount < 2 )
    {
        SetStatusText(wxT("Слишком большой прозор."));
        return;
    }

    Mass mass = CalcMass_Rke00Ad(screenWss, screenHss, grateHss, channelWss,
                                 standHss, fp, profilesCount);
    *m_rkeMassTc << mass;

    wxString dsg = CreateDesignation(screenWss, screenHss, channelWss, grateHss,
                                     fp, gap);
    SetStatusText(dsg);
}
