from locale import atof
from tkinter import END, Tk
from tkinter.ttk import Combobox, Entry, Label, Treeview

from dry.basegui import PAD
from dry.calcapp import CalcApp, MsgQueue
from dry.l10n import ENG, LIT, RUS, UKR
from dry.measurements import degree, liter_per_sec, mm, to_degree, to_mm
from dry.tkutils import max_column_width

from calc import (DEFAULT_DISCHARGE_HEIGHT, DEFAULT_TILT_ANGLE, FILTERS,
                  GSDATA, HSDATA, NOMINAL_GAPS, POLLUTIONS, WSDATA, InputData,
                  run_calc)
from captions import ErrorMsg, UiText
from constants import Col, Col2

WSCHOICES = {f'{i:02d}': i for i in WSDATA}
HSCHOICES = {f'{i:02d}': i for i in HSDATA}
GSCHOICES = {f'{i:02d}': i for i in GSDATA}
GAPCHOICES = {f'{to_mm(i):n}': i for i in NOMINAL_GAPS}


class App(CalcApp):
    def __init__(self, root: Tk) -> None:
        super().__init__(root,
                         appname='BarScreen',
                         appvendor='Esmil',
                         appversion='2023.1',
                         uilangs=(ENG, UKR, LIT),
                         outlangs=(ENG, UKR, RUS),
                         title=UiText.TITLE)
        entrywid = 15

        self.widlabel = Label(self.widgetframe)
        self.widlabel.grid(row=0, column=0, padx=PAD, pady=PAD, sticky='W')
        self.widbox = Entry(self.widgetframe, width=entrywid)
        self.widbox.grid(row=0, column=1, padx=PAD, pady=PAD, sticky='E')
        self.widbox.focus()

        self.deplabel = Label(self.widgetframe)
        self.deplabel.grid(row=1, column=0, padx=PAD, pady=PAD, sticky='W')
        self.depbox = Entry(self.widgetframe, width=1)
        self.depbox.grid(row=1, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.droplabel = Label(self.widgetframe)
        self.droplabel.grid(row=2, column=0, padx=PAD, pady=PAD, sticky='W')
        self.dropbox = Entry(self.widgetframe, width=1)
        self.dropbox.insert(0, f'{to_mm(DEFAULT_DISCHARGE_HEIGHT):n}')
        self.dropbox.grid(row=2, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.gaplabel = Label(self.widgetframe)
        self.gaplabel.grid(row=3, column=0, padx=PAD, pady=PAD, sticky='W')
        self.gapbox = Combobox(self.widgetframe, state='readonly',
                               values=tuple(GAPCHOICES), width=1)
        self.gapbox.current(0)
        self.gapbox.grid(row=3, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.wslabel = Label(self.widgetframe)
        self.wslabel.grid(row=4, column=0, padx=PAD, pady=PAD, sticky='W')
        self.wsbox = Combobox(self.widgetframe, state='readonly', width=1)
        self.wsbox.grid(row=4, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.hslabel = Label(self.widgetframe)
        self.hslabel.grid(row=5, column=0, padx=PAD, pady=PAD, sticky='W')
        self.hsbox = Combobox(self.widgetframe, state='readonly', width=1)
        self.hsbox.grid(row=5, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.gslabel = Label(self.widgetframe)
        self.gslabel.grid(row=6, column=0, padx=PAD, pady=PAD, sticky='W')
        self.gsbox = Combobox(self.widgetframe, state='readonly', width=1)
        self.gsbox.grid(row=6, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.table = Treeview(self.widgetframe,
                              show='headings',
                              selectmode='browse',
                              height=len(FILTERS),
                              columns=tuple(Col))
        for i in Col:
            width = max_column_width(UiText.COL[i].values(), 2)
            self.table.column(i, width=width)
        self.table.column(Col.FACTOR, anchor='e')
        self.table.grid(row=7, column=0, columnspan=2,
                        padx=PAD, pady=PAD, sticky='WE')
        self.tablerows = {}
        for _i, value in enumerate(FILTERS):
            item = self.table.insert('', END)
            self.tablerows[item] = value
        self.table.selection_set(next(iter(self.tablerows)))

        self.hydrlabel = Label(self.widgetframe)
        self.hydrlabel.grid(row=8, column=0, columnspan=2, padx=PAD, pady=PAD)

        self.flowlabel = Label(self.widgetframe)
        self.flowlabel.grid(row=9, column=0, padx=PAD, pady=PAD, sticky='W')
        self.flowbox = Entry(self.widgetframe, width=1)
        self.flowbox.grid(row=9, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.levellabel = Label(self.widgetframe)
        self.levellabel.grid(row=10, column=0, padx=PAD, pady=PAD, sticky='W')
        self.levelbox = Entry(self.widgetframe, width=1)
        self.levelbox.grid(row=10, column=1, padx=PAD, pady=PAD, sticky='WE')

        self.anglelabel = Label(self.widgetframe)
        self.anglelabel.grid(row=11, column=0, padx=PAD, pady=PAD, sticky='W')
        self.anglebox = Entry(self.widgetframe, width=1)
        self.anglebox.grid(row=11, column=1, padx=PAD, pady=PAD, sticky='WE')
        self.anglebox.insert(0, f'{to_degree(DEFAULT_TILT_ANGLE):n}')

        self.table2 = Treeview(self.outputframe,
                               show='headings',
                               selectmode='browse',
                               height=len(POLLUTIONS),
                               columns=tuple(Col2))
        for j in Col2:
            width = max_column_width(UiText.COL2[j].values(), 2)
            self.table2.column(j, width=width, anchor='e')
        self.table2.grid(row=1, column=0, columnspan=2,
                         padx=PAD, pady=PAD, sticky='WE')
        self.hydraulic = {}
        for _ in POLLUTIONS:
            item = self.table2.insert('', END)
            self.hydraulic[item] = MsgQueue()

        self.wschoices: dict[str, int | None]
        self.hschoices: dict[str, int | None]
        self.gschoices: dict[str, int | None]

    def translate_ui(self) -> None:
        super().translate_ui()

        self.wschoices = {UiText.AUTO[self.uilang]: None}
        self.wschoices.update(WSCHOICES)
        self.wsbox.config(values=tuple(self.wschoices))
        ws = self.wsbox.current()
        self.wsbox.current(ws if ws >= 0 else 0)

        self.hschoices = {UiText.AUTO[self.uilang]: None}
        self.hschoices.update(HSCHOICES)
        self.hsbox.config(values=tuple(self.hschoices))
        hs = self.hsbox.current()
        self.hsbox.current(hs if hs >= 0 else 0)

        self.gschoices = {UiText.AUTO[self.uilang]: None}
        self.gschoices.update(GSCHOICES)
        self.gsbox.config(values=tuple(self.gschoices))
        gs = self.gsbox.current()
        self.gsbox.current(gs if gs >= 0 else 0)

        self.wslabel['text'] = UiText.WS[self.uilang]
        self.hslabel['text'] = UiText.HS[self.uilang]
        self.gslabel['text'] = UiText.GS[self.uilang]
        self.gaplabel['text'] = UiText.GAP[self.uilang]
        self.widlabel['text'] = UiText.WID[self.uilang]
        self.deplabel['text'] = UiText.DEP[self.uilang]
        self.droplabel['text'] = UiText.DROP[self.uilang]
        for col, text in UiText.COL.items():
            self.table.heading(col, text=text[self.uilang])
        for row, value in self.tablerows.items():
            mount = UiText.FPREMOV if value.is_removable else UiText.FPWELD
            self.table.item(row,
                            values=[
                                f'{value.name}',
                                mount[self.uilang],
                                f'{value.shape_factor:n}'
                            ])
        self.hydrlabel['text'] = UiText.HYDR[self.uilang]
        self.flowlabel['text'] = UiText.FLOW[self.uilang]
        self.levellabel['text'] = UiText.LEVEL[self.uilang]
        self.anglelabel['text'] = UiText.ANGLE[self.uilang]

    def translate_out(self) -> None:
        super().translate_out()

        for col2, text in UiText.COL2.items():
            self.table2.heading(col2, text=text[self.outlang])

    def print_result(self) -> None:
        super().print_result()

        for key, value in self.hydraulic.items():
            self.table2.item(key, values=value[self.outlang])

    def get_inputdata(self) -> None:
        widtext = self.widbox.get()
        try:
            self.inpdata['width'] = mm(atof(widtext))
        except ValueError:
            self.adderror(ErrorMsg.WIDTH)

        deptext = self.depbox.get()
        try:
            self.inpdata['depth'] = mm(atof(deptext))
        except ValueError:
            self.adderror(ErrorMsg.DEPTH)

        droptext = self.dropbox.get()
        try:
            self.inpdata['mindrop'] = mm(atof(droptext))
        except ValueError:
            self.adderror(ErrorMsg.DROP)

        gapchoice = self.gapbox.get()
        self.inpdata['gap'] = GAPCHOICES[gapchoice]

        wschoise = self.wsbox.get()
        self.inpdata['ws'] = self.wschoices[wschoise]

        hschoise = self.hsbox.get()
        self.inpdata['hs'] = self.hschoices[hschoise]

        gschoise = self.gsbox.get()
        self.inpdata['gs'] = self.gschoices[gschoise]

        self.inpdata['fp'] = self.tablerows[self.table.selection()[0]]

        flowtext = self.flowbox.get()
        if flowtext:
            try:
                self.inpdata['flow'] = liter_per_sec(atof(flowtext))
            except ValueError:
                self.adderror(ErrorMsg.FLOW)
        else:
            self.inpdata['flow'] = None

        leveltext = self.levelbox.get()
        if leveltext:
            try:
                self.inpdata['level'] = mm(atof(leveltext))
            except ValueError:
                self.adderror(ErrorMsg.LEVEL)
        else:
            self.inpdata['level'] = None

        angletext = self.anglebox.get()
        try:
            self.inpdata['angle'] = degree(atof(angletext))
        except ValueError:
            self.adderror(ErrorMsg.ANGLE)

    def runcalc(self) -> None:
        for i in self.hydraulic.values():
            i.clear()
        run_calc(InputData(**self.inpdata), self.adderror, self.addline,
                 [i.append for i in self.hydraulic.values()])
