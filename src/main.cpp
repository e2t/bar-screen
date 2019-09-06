#include "../dry/wxgui.h"
#include "barscreen.h"

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
    static WidthStdSize  *ms_screenWssArray;
    static wxArrayString  ms_screenWssChoices;
    static HeightStdSize *ms_screenHssArray;
    static wxArrayString  ms_screenHssChoices;
    static HeightStdSize *ms_grateHssArray;
    static wxArrayString  ms_grateHssChoices;
    static FilterProfile *ms_fpArray;
    static wxArrayString  ms_fpChoices;

    wxChoice   *m_screenWssCh;
    wxChoice   *m_screenHssCh;
    wxChoice   *m_grateHssCh;
    wxTextCtrl *m_channelWidthTc;
    wxTextCtrl *m_channelHeightTc;
    wxChoice   *m_fpCh;
    wxTextCtrl *m_gapTc;
    wxTextCtrl *m_rkeMassTc;

    void OnRunButtonClick(wxCommandEvent& event);
    void OnPressKey(wxKeyEvent& event);

    bool GetMmFromTc(Distance& value, wxTextCtrl *tc);
    void Run();
    void Print(const wxString& output);
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

WidthStdSize  *MyFrame::ms_screenWssArray;
wxArrayString  MyFrame::ms_screenWssChoices;
HeightStdSize *MyFrame::ms_screenHssArray;
wxArrayString  MyFrame::ms_screenHssChoices;
HeightStdSize *MyFrame::ms_grateHssArray;
wxArrayString  MyFrame::ms_grateHssChoices;
FilterProfile *MyFrame::ms_fpArray;
wxArrayString  MyFrame::ms_fpChoices;

void MyFrame::StaticMembersInit()
{
    // Типоразмеры решетки по ширине.
    const WidthStdSize minScreenWss = 5;
    const WidthStdSize maxScreenWss = 30;
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
    const HeightStdSize maxBigScreenHss = 144;
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
    ms_fpArray = new FilterProfile[3];

    ms_fpArray[0] = fp3999;
    ms_fpChoices.Add(wxT("3999"));

    ms_fpArray[1] = fp6x30;
    ms_fpChoices.Add(wxT("6x30"));

    ms_fpArray[2] = fp777;
    ms_fpChoices.Add(wxT("777"));
}

MyFrame::MyFrame()
    : wxFrame(NULL, wxID_ANY, wxT("Расчет грабельной решетки (v0.2.0)"),
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

    m_channelWidthTc = new wxTextCtrl(
        panel, ID_CHANNEL_WIDTH_TC, wxEmptyString, wxDefaultPosition,
        wxMinWidth, 0, wxTextValidator(wxFILTER_NUMERIC));

    m_channelHeightTc = new wxTextCtrl(
        panel, ID_CHANNEL_HEIGHT_TC, wxEmptyString, wxDefaultPosition,
        wxMinWidth, 0, wxTextValidator(wxFILTER_NUMERIC));

    m_grateHssCh = new wxChoice(panel, ID_GRATE_HSS_CH);
    m_grateHssCh->Append(ms_grateHssChoices);
    m_grateHssCh->SetSelection(0);

    m_fpCh = new wxChoice(panel, ID_FP_CH);
    m_fpCh->Append(ms_fpChoices);
    m_fpCh->SetSelection(0);

    m_gapTc = new wxTextCtrl(panel, ID_GAP_TC, wxEmptyString, wxDefaultPosition,
                             wxMinWidth, 0, wxTextValidator(wxFILTER_NUMERIC));

    m_rkeMassTc = new wxTextCtrl(panel, ID_RKE_MASS_TC, wxEmptyString,
                                 wxDefaultPosition,
                                 ConvertDialogToPixels(wxSize(-1, 100)),
                                 wxTE_READONLY|wxTE_MULTILINE);

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
    bs->Add(m_rkeMassTc, wxGBPosition(3, 0), wxGBSpan(1, 5), wxEXPAND);

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

    panel->SetSizerAndFit(topBs);
    Fit();

    Bind(wxEVT_BUTTON, &MyFrame::OnRunButtonClick, this, ID_RUN_BT);
    Bind(wxEVT_CHAR_HOOK, &MyFrame::OnPressKey, this);
}

void MyFrame::Print(const wxString& output)
{
    m_rkeMassTc->Clear();
    *m_rkeMassTc << output;
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
        Print(wxT("Неправильное значение."));
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
    BarScreen::InputData inputData;

    inputData.screenWss = ms_screenWssArray[m_screenWssCh->GetSelection()];
    inputData.screenHss = ms_screenHssArray[m_screenHssCh->GetSelection()];
    inputData.fp = ms_fpArray[m_fpCh->GetSelection()];
    inputData.grateHss = ms_grateHssArray[m_grateHssCh->GetSelection()];

    if ( !GetMmFromTc(inputData.channelWidth, m_channelWidthTc) )
    {
        return;
    }
    if ( !GetMmFromTc(inputData.channelHeight, m_channelHeightTc) )
    {
        return;
    }
    if ( !GetMmFromTc(inputData.gap, m_gapTc) )
    {
        return;
    }
    wxString error;
    wxArrayString order;
    try
    {
        BarScreen bs(inputData, error, order);
        wxString output;
        output.Printf(wxT("%s\nМасса - %.0f кг"), bs.GetDesignation(),
                      bs.GetMass());
        if ( !bs.IsStandardSize() )
        {
            output << wxT(" (примерно)");
        }
        output << wxT("\n\nПОРЯДОК ВЫЧИЛЕНИЙ");
        for ( size_t i = 0; i < order.size(); i++ )
        {
            output << wxT("\n") << (i + 1) << wxT(") ") << order[i];
        }
#ifdef __WINDOWS__
        long pos = ::SendMessage(m_rkeMassTc->GetHandle(),
                                 EM_GETFIRSTVISIBLELINE, 0, 0);
        Print(output);
        int newpos = ::SendMessage(m_rkeMassTc->GetHandle(),
                                   EM_GETFIRSTVISIBLELINE, 0, 0);
        ::SendMessage(m_rkeMassTc->GetHandle(), EM_LINESCROLL, 0, pos - newpos);
#else
        Print(output);
        m_rkeMassTc->ShowPosition(0);
#endif
    }
    catch (const std::invalid_argument& e)
    {
        Print(error);
    }
    catch (const std::bad_optional_access& e)
    {
        Print(wxT("Логическая ошибка в программе."));
    }
}
