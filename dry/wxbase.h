#ifndef WXBASE_H
#define WXBASE_H

#pragma GCC system_header

#include <wx/wxprec.h>
#ifndef WX_PRECOMP
    #include <wx/wx.h>
#endif

#include <wx/cmdline.h>
#include <wx/filename.h>

#ifdef _WIN32
    #include <windows.h>
#endif

class BaseAppConsole : public wxAppConsole
{
protected:
    bool OnInit()
    {
        SetCLocale();
        return wxAppConsole::OnInit();
    }

    void OnInitCmdLine(wxCmdLineParser& parser)
    {
#ifdef _WIN32
        wchar_t **argw = CommandLineToArgvW(GetCommandLineW(), &argc);
        parser.SetCmdLine(argc, argw);
#endif
        wxAppConsole::OnInitCmdLine(parser);
    }
};

#endif
