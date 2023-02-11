import os
from configparser import ConfigParser
from tkinter import END, Event, Misc, Tk
from tkinter.scrolledtext import ScrolledText
from tkinter.ttk import Button, Combobox, Frame
from typing import Any, Callable

from appdirs import user_config_dir

from dry.basegui import PAD
from dry.l10n import ENG, LIT, RUS, UKR, MsgFormat

LANG_CAPTIONS = {
    ENG: 'English',
    UKR: 'Українська',
    RUS: 'Русский',
    LIT: 'Lietuvių'
}
RUN_CAPTIONS = {
    ENG: 'Run',
    UKR: 'Рахувати',
    RUS: 'Расчет',
    LIT: 'Skaičiuoti'
}
GUI_SECTION = 'Interface'
OPT_UILANG = 'uilang'
OPT_OUTLANG = 'outlang'

Langs = tuple[str, ...]


class MsgQueue:
    def __init__(self) -> None:
        self.queue: list[str | Callable[[str], str]] = []
        self.msg: dict[str, list[str]] = {}

    def __bool__(self) -> bool:
        return bool(self.queue)

    def __getitem__(self, lang: str) -> list[str]:
        if lang not in self.msg:
            self.msg[lang] = []
            for i in self.queue:
                if callable(i):
                    self.msg[lang].append(i(lang))
                else:
                    self.msg[lang].append(i)
        return self.msg[lang]

    def append(self, s: MsgFormat, *args: object) -> None:
        def localize(lang: str) -> str:  # crutch for mypy
            assert isinstance(s, dict)
            return s[lang].format(*args)

        if isinstance(s, dict):
            self.queue.append(localize)
        else:
            self.queue.append(s.format(*args))

    def clear(self) -> None:
        self.queue.clear()
        self.msg.clear()


class CalcApp():
    def __init__(self, root: Tk, appname: str, appvendor: str, appversion: str,
                 uilangs: Langs, outlangs: Langs, title: MsgFormat) -> None:
        self.root = root
        self.title = title
        self.appname = appname
        self.appversion = appversion

        self.errors = MsgQueue()
        self.results = MsgQueue()
        self.inpdata: dict[str, Any] = {}

        cfgdir = user_config_dir(appname, appvendor, roaming=True)
        if not os.path.exists(cfgdir):
            os.makedirs(cfgdir)
        self.cfgfile = os.path.join(cfgdir, 'settings.ini')
        self.cfg = ConfigParser()
        self.cfg.read(self.cfgfile)
        if not self.cfg.has_section(GUI_SECTION):
            self.cfg.add_section(GUI_SECTION)

        self.uilang = self.getcfg_lang(OPT_UILANG, uilangs)
        self.outlang = self.getcfg_lang(OPT_OUTLANG, outlangs)
        self.uichoices = {LANG_CAPTIONS[i]: i for i in uilangs}
        self.outchoices = {LANG_CAPTIONS[i]: i for i in outlangs}

        mainframe = Frame(root)
        mainframe.grid(sticky='WENS', padx=PAD, pady=PAD)
        self.widgetframe = Frame(mainframe)
        self.widgetframe.grid(row=0, column=0, sticky='WN')
        self.outputframe = Frame(mainframe)
        self.outputframe.grid(row=0, column=1, columnspan=2, sticky='WENS')
        self.memo = ScrolledText(self.outputframe, state='disabled',
                                 font='TkDefaultFont')
        self.memo.grid(row=0, column=0, sticky='WENS', padx=PAD, pady=PAD)
        bottom_row = 10
        self.uilangbox = Combobox(mainframe, state='readonly',
                                  values=tuple(self.uichoices))
        self.uilangbox.set(LANG_CAPTIONS[self.uilang])
        self.uilangbox.grid(row=bottom_row, column=0, sticky='W',
                            padx=PAD, pady=PAD)
        self.outlangbox = Combobox(mainframe, state='readonly',
                                   values=tuple(self.outchoices))
        self.outlangbox.set(LANG_CAPTIONS[self.outlang])
        self.outlangbox.grid(row=bottom_row, column=1, sticky='W',
                             padx=PAD, pady=PAD)
        self.runbutton = Button(mainframe, command=self.on_run)
        self.runbutton.grid(row=bottom_row, column=2, sticky='E',
                            padx=PAD, pady=PAD)
        root.grid_rowconfigure(0, weight=1)
        root.grid_columnconfigure(0, weight=1)
        mainframe.grid_rowconfigure(0, weight=1)
        mainframe.grid_columnconfigure(1, weight=1)
        self.outputframe.grid_rowconfigure(0, weight=1)
        self.outputframe.grid_columnconfigure(0, weight=1)

        root.protocol('WM_DELETE_WINDOW', self.on_close)
        root.bind('<Return>', self.event_run)
        self.uilangbox.bind('<<ComboboxSelected>>', self.event_uilang)
        self.outlangbox.bind('<<ComboboxSelected>>', self.event_outlang)

    def getcfg_lang(self, option: str, langs: Langs) -> str:
        lang = self.cfg.get(GUI_SECTION, option, fallback=langs[0])
        return lang if lang in langs else langs[0]

    def init(self) -> None:
        self.translate_ui()
        self.translate_out()

    def translate_ui(self) -> None:
        self.uilang = self.uichoices[self.uilangbox.get()]
        self.cfg.set(GUI_SECTION, OPT_UILANG, self.uilang)
        if isinstance(self.title, dict):
            title = self.title[self.uilang]
        else:
            title = self.title
        self.root.title(f'{title} — {self.appname} {self.appversion}')
        self.runbutton['text'] = RUN_CAPTIONS[self.uilang]
        if self.errors:
            self.print_errors()

    def translate_out(self) -> None:
        self.outlang = self.outchoices[self.outlangbox.get()]
        self.cfg.set(GUI_SECTION, OPT_OUTLANG, self.outlang)
        if not self.errors:
            self.print_result()

    def event_uilang(self, _event: 'Event[Combobox]') -> None:
        self.translate_ui()

    def event_outlang(self, _event: 'Event[Combobox]') -> None:
        self.translate_out()

    def event_run(self, _event: 'Event[Misc]') -> None:
        self.on_run()

    def on_close(self) -> None:
        with open(self.cfgfile, 'w', encoding='utf-8') as file:
            self.cfg.write(file)
        self.root.destroy()

    def get_inputdata(self) -> None:
        pass

    def runcalc(self) -> None:
        pass

    def print_to_memo(self, text: str) -> None:
        self.memo.configure(state='normal')
        self.memo.delete(1.0, END)
        self.memo.insert(END, text)
        self.memo.configure(state='disabled')

    def print_errors(self) -> None:
        self.print_to_memo('\n'.join(self.errors[self.uilang]))

    def print_result(self) -> None:
        self.print_to_memo('\n'.join(self.results[self.outlang]))

    def on_run(self) -> None:
        self.errors.clear()
        self.results.clear()
        self.inpdata.clear()

        self.get_inputdata()
        if self.errors:
            self.print_errors()
            return

        self.runcalc()
        if self.errors:
            self.print_errors()
        else:
            self.print_result()

    def adderror(self, s: MsgFormat, *args: object) -> None:
        self.errors.append(s, *args)

    def addline(self, s: MsgFormat, *args: object) -> None:
        self.results.append(s, *args)
