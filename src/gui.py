"""Графическая оболочка программы."""
import sys
from tkinter import (Tk, W, E, N, S, NORMAL, DISABLED, END, Event, HORIZONTAL,
                     DoubleVar)
from tkinter.ttk import (Frame, Label, Entry, Button, Combobox, Treeview,
                         Separator)
from tkinter.scrolledtext import ScrolledText
from typing import Optional, List, Dict
from barscreen import (
    FILTER_PROFILES, InputData, BarScreen, SCREEN_WIDTH_SERIES,
    SCREEN_HEIGHT_SERIES, GRATE_HEIGHT_SERIES)
sys.path.append(f'{sys.path[0]}/..')
from dry.allgui import MyFrame
from dry.allcalc import InputDataError, WidthSerie, HeightSerie
from dry.tooltip import Tooltip


CMB_AUTO = 'Авто'


class MainForm(MyFrame):
    """Главная форма."""

    SCREEN_WIDTH_CHOICES: Dict[str, Optional[WidthSerie]] = {
        CMB_AUTO: None,
        **{f'{i:02d}': WidthSerie(i) for i in SCREEN_WIDTH_SERIES}}
    SCREEN_HEIGHT_CHOICES: Dict[str, Optional[HeightSerie]] = {
        CMB_AUTO: None,
        **{f'{i:02d}': HeightSerie(i) for i in SCREEN_HEIGHT_SERIES}}
    GRATE_HEIGHT_CHOICES: Dict[str, Optional[HeightSerie]] = {
        CMB_AUTO: None,
        **{f'{i:02d}': HeightSerie(i) for i in GRATE_HEIGHT_SERIES}}

    def __init__(self, root: Tk) -> None:
        """Конструктор формы."""
        root.title('Расчет грабельной решетки (v1.2.0)')
        super().__init__(root)

        CMB_W = 5

        subframe = Frame(self)
        subframe.grid(row=0, column=0, sticky=W)

        row = 0
        Label(subframe, text='Ширина канала:').grid(row=row, column=0,
                                                    sticky=W)
        self._ent_channel_w = Entry(subframe, width=1)
        self._ent_channel_w.grid(row=row, column=1, sticky=W + E)
        Label(subframe, text='мм').grid(row=row, column=2, sticky=W)

        row += 1
        Label(subframe, text='Глубина канала:').grid(row=row, column=0,
                                                     sticky=W)
        self._ent_channel_h = Entry(subframe, width=1)
        self._ent_channel_h.grid(row=row, column=1, sticky=W + E)
        Label(subframe, text='мм').grid(row=row, column=2, sticky=W)

        row += 1
        Label(subframe, text='Мин. высота сброса:').grid(row=row, column=0,
                                                         sticky=W)
        self._ent_min_discharge_h = Entry(subframe, width=1)
        self._ent_min_discharge_h.grid(row=row, column=1, sticky=W + E)
        self._ent_min_discharge_h.insert(END, 890)
        Tooltip(self._ent_min_discharge_h,
                'Минимальная высота сброса над каналом.')
        Label(subframe, text='мм').grid(row=row, column=2, sticky=W)

        row += 1
        Label(subframe, text='Прозор:').grid(row=row, column=0, sticky=W)
        self._ent_gap = Entry(subframe, width=1)
        self._ent_gap.grid(row=row, column=1, sticky=W + E)
        Label(subframe, text='мм').grid(row=row, column=2, sticky=W)

        row += 1
        Label(subframe, text='Профиль:').grid(row=row, column=0, sticky=W)
        self._cmb_fp = Combobox(subframe, state='readonly', width=CMB_W,
                                values=[i.name for i in FILTER_PROFILES])
        self._cmb_fp.grid(row=row, column=1, sticky=W)
        self._cmb_fp.bind("<<ComboboxSelected>>", self._change_fp_factor)
        self._cmb_fp.current(0)
        self._ent_fp_factor_var = DoubleVar()
        self._ent_fp_factor = Entry(subframe, width=4, state='disable',
                                    textvariable=self._ent_fp_factor_var)
        self._ent_fp_factor.grid(row=row, column=2, sticky=W + E)
        Tooltip(self._ent_fp_factor, 'Коэффициент формы профиля.')
        self._change_fp_factor(None)

        row += 1
        Separator(subframe, orient=HORIZONTAL).grid(row=row, column=0,
                                                    columnspan=3, sticky=W + E)

        row += 1
        Label(subframe, text='Расход воды:').grid(row=row, column=0, sticky=W)
        self._ent_water_flow = Entry(subframe, width=1)
        self._ent_water_flow.grid(row=row, column=1, sticky=W + E)
        Label(subframe, text='л/с').grid(row=row, column=2, sticky=W)

        row += 1
        Label(subframe, text='Уровень за решеткой:').grid(row=row, column=0,
                                                          sticky=W)
        self._ent_final_level = Entry(subframe, width=1)
        self._ent_final_level.grid(row=row, column=1, sticky=W + E)
        Label(subframe, text='мм').grid(row=row, column=2, sticky=W)

        row += 1
        Label(subframe, text='Угол:').grid(row=row, column=0, sticky=W)
        self._ent_tilt_angle = Entry(subframe, width=1)
        self._ent_tilt_angle.grid(row=row, column=1, sticky=W + E)
        self._ent_tilt_angle.insert(END, 80)
        Tooltip(self._ent_tilt_angle,
                'Угол используется только для гидравлического расчета.\n'
                'Масса решетки рассчитывается для угла 80 градусов.')
        Label(subframe, text='град.').grid(row=row, column=2, sticky=W)

        row += 1
        Separator(subframe, orient=HORIZONTAL).grid(row=row, column=0,
                                                    columnspan=3, sticky=W + E)

        row += 1
        Label(subframe, text='Ширина решетки:').grid(row=row, column=0,
                                                     sticky=W)
        self._cmb_screen_ws = Combobox(subframe, state='readonly', width=CMB_W,
                                       values=list(self.SCREEN_WIDTH_CHOICES))
        self._cmb_screen_ws.grid(row=row, column=1)
        self._cmb_screen_ws.current(0)

        row += 1
        Label(subframe, text='Высота решетки:').grid(row=row, column=0,
                                                     sticky=W)
        self._cmb_screen_hs = Combobox(subframe, state='readonly', width=CMB_W,
                                       values=list(self.SCREEN_HEIGHT_CHOICES))
        self._cmb_screen_hs.grid(row=row, column=1)
        self._cmb_screen_hs.current(0)

        row += 1
        Label(subframe, text='Полотно:').grid(row=row, column=0, sticky=W)
        self._cmb_grate_hs = Combobox(subframe, state='readonly', width=CMB_W,
                                      values=list(self.GRATE_HEIGHT_CHOICES))
        self._cmb_grate_hs.grid(row=row, column=1)
        self._cmb_grate_hs.current(0)

        self._memo = ScrolledText(self, state=DISABLED, height=1)
        self._memo.grid(row=0, column=1, sticky=W + E + N + S)

        # TODO: Привязать к уровню загрязнений (4).
        self._table = Treeview(self, columns=[''] * 6, height=4)
        self._table.heading('#0', text='Загрязнение')
        self._table.column('#0', width=100)
        self._table.heading('#1', text='Скорость в прозорах')
        self._table.column('#1', width=150)
        self._table.heading('#2', text='Относ. площадь потока')
        self._table.column('#2', width=150)
        self._table.heading('#3', text='Blinding factor')
        self._table.column('#3', width=100)
        self._table.heading('#4', text='Разность уровней')
        self._table.column('#4', width=150)
        self._table.heading('#5', text='Уровень до решетки')
        self._table.column('#5', width=150)
        self._table.heading('#6', text='Скорость в канале')
        self._table.column('#6', width=150)
        self._table.grid(row=1, columnspan=2, sticky=W + E)

        Button(self, text='Расчет', command=self._run).grid(row=2, column=1,
                                                            sticky=E)
        self.bind_all('<Return>', self._on_press_enter)

        self._add_pad_to_all_widgets(self)
        self._focus_first_entry(self)

    def _change_fp_factor(self, _) -> None:
        value = FILTER_PROFILES[self._cmb_fp.current()].shape_factor
        self._ent_fp_factor_var.set(value)

    def _output(self, text: str) -> None:
        self._memo.config(state=NORMAL)
        self._memo.delete(1.0, END)
        self._memo.insert(END, text)
        self._memo.config(state=DISABLED)

    def _print_error(self, text: str) -> None:
        self._output(text)

    def _run(self) -> None:
        self._table.delete(*self._table.get_children())

        screen_ws = self.SCREEN_WIDTH_CHOICES[self._cmb_screen_ws.get()]
        screen_hs = self.SCREEN_HEIGHT_CHOICES[self._cmb_screen_hs.get()]
        fp = FILTER_PROFILES[self._cmb_fp.current()]
        grate_hs = self.GRATE_HEIGHT_CHOICES[self._cmb_grate_hs.get()]
        try:
            channel_width = self._get_mm_from_entry(self._ent_channel_w)
            channel_height = self._get_mm_from_entry(self._ent_channel_h)
            min_discharge_height = self._get_mm_from_entry(
                self._ent_min_discharge_h)
            gap = self._get_mm_from_entry(self._ent_gap)
            water_flow = self._get_opt_l_s_from_entry(self._ent_water_flow)
            final_level = self._get_opt_mm_from_entry(self._ent_final_level)
            tilt_angle = self._get_opt_deg_from_entry(self._ent_tilt_angle)
        except ValueError:
            return

        input_data = InputData(screen_ws=screen_ws, screen_hs=screen_hs,
                               grate_hs=grate_hs, channel_width=channel_width,
                               channel_height=channel_height, fp=fp, gap=gap,
                               water_flow=water_flow, final_level=final_level,
                               tilt_angle=tilt_angle,
                               min_discharge_height=min_discharge_height)
        order: List[str] = []
        try:
            bs = BarScreen(input_data, order)
        except InputDataError as excp:
            self._output(str(excp))
            return

        output = bs.designation

        lines = []
        lines.append(('Масса', '{:.0f} кг{}'.format(
            bs.mass, ' (примерно)' if not bs.is_standard_serie else '')))
        lines.append(('Привод', f'{bs.drive_power / 1e3} кВт' if bs.drive_power
                      else 'нестандартный'))
        lines.append(('Просвет', f'{bs.inner_screen_width * 1e3:.0f} x '
                                 f'{bs.inner_screen_height * 1e3:.0f} мм'))
        lines.append(('Длина решетки', f'{bs.screen_length * 1e3:.0f} мм'))
        lines.append(('Длина цепи', f'{bs.chain_length * 1e3:.0f} мм'))
        lines.append(('Длина профиля', f'{bs.fp_length * 1e3:.0f} мм'))
        lines.append(('Количество профилей', f'{bs.profiles_count} ± 1 шт.'))
        lines.append(('Количество граблин', f'{bs.rakes_count} шт.'))
        lines.append(('Ширина сброса', f'{bs.discharge_width * 1e3:.0f} мм'))
        lines.append(('Высота сброса',
                      f'{bs.discharge_height * 1e3:.0f} мм (над каналом), '
                      f'{bs.discharge_full_height * 1e3:.0f} мм (от дна)'))

        longest_param = max([i[0] for i in lines], key=len)
        indent = len(longest_param)
        output += '\n' + '\n'.join(
            ['%-*s  %s' % (indent, i[0], i[1]) for i in lines])

        output += f'\n{"Вставное" if fp.is_removable else "Сварное"} полотно'
        for blinding, hydr in bs.hydraulic.items():
            self._table.insert(
                '', 'end', None, text=f'{blinding * 100:g}%', values=(
                    f'{hydr.velocity_in_gap:.2f} м/с'
                    if hydr.velocity_in_gap is not None else '',
                    f'{hydr.relative_flow_area:.2f}'
                    if hydr.relative_flow_area is not None else '',
                    f'{hydr.blinding_factor * 1e3:.1f}'
                    if hydr.blinding_factor is not None else '',
                    f'{hydr.level_diff * 1e3:.0f} мм'
                    if hydr.level_diff is not None else '',
                    f'{hydr.start_level * 1e3:.0f} мм'
                    if hydr.start_level is not None else '',
                    f'{hydr.upstream_flow_velocity:.2f} м/с'
                    if hydr.upstream_flow_velocity is not None else ''))
            if hydr.start_level is not None:
                overflow_channel = hydr.start_level > channel_height
                # Округлить до миллиметров.
                diff = round(hydr.start_level - bs.inner_screen_height, 3)
                overflow_grate = diff >= 0
                if overflow_channel or overflow_grate:
                    output += f'\n{blinding * 100:g}% - '
                    warnings = []
                    if overflow_channel:
                        warnings.append('переполнение канала')
                    if overflow_grate:
                        warnings.append('уровень выше полотна '
                                        f'({diff * 1e3:.0f} мм)')
                    output += ', '.join(warnings)
        output += '\n\nПОРЯДОК ВЫЧИЛЕНИЯ МАССЫ\n'
        output += '\n'.join([f'{i + 1}) {value}'
                             for i, value in enumerate(order)])
        self._output(output)

    def _on_press_enter(self, _: Event) -> None:
        self._run()
