"""Графическая оболочка программы."""
import locale
from tkinter import (Tk, W, E, N, S, NORMAL, DISABLED, END, Event, HORIZONTAL, NO, YES)
from tkinter.ttk import (Frame, Label, Entry, Button, Combobox, Treeview, Separator, Style)
from tkinter.scrolledtext import ScrolledText
from typing import Optional, Dict
from barscreen import (
    FILTER_PROFILES, InputData, BarScreen, SCREEN_WIDTH_SERIES, SCREEN_HEIGHT_SERIES,
    GRATE_HEIGHT_SERIES)
from dry.allgui import MyFrame, handle_ctrl_shortcut, fstr, SortableTreeview
from dry.allcalc import InputDataError, WidthSerie, HeightSerie
from dry.tooltip import Tooltip
locale.setlocale(locale.LC_NUMERIC, '')


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
    FILTER_PROFILE_CHOICES = ['{0:>4} {1} K={2}'.format(
        i.name,
        'съемный' if i.is_removable else 'сварной',
        fstr(i.shape_factor)) for i in FILTER_PROFILES]

    def __init__(self, root: Tk) -> None:
        """Конструктор формы."""
        root.title('Расчет грабельной решетки (v1.2.2)')
        super().__init__(root)

        self.dpi = root.winfo_fpixels('1i')

        def fdpi(pixels: int) -> int:
            return int(pixels * self.dpi / 96)

        s = Style()
        s.configure('DPI.Treeview', rowheight=fdpi(20))

        cmb_w = 5

        left_frame = Frame(self)
        left_frame.grid(row=0, column=0)

        row = 0
        Label(left_frame, text='Ширина канала (мм):').grid(row=row, column=0, sticky=W)
        self._ent_channel_w = Entry(left_frame, width=1)
        self._ent_channel_w.grid(row=row, column=1, sticky=W + E)

        row += 1
        Label(left_frame, text='Глубина канала (мм):').grid(row=row, column=0, sticky=W)
        self._ent_channel_h = Entry(left_frame, width=1)
        self._ent_channel_h.grid(row=row, column=1, sticky=W + E)

        row += 1
        Label(left_frame, text='Мин. высота сброса (мм):').grid(row=row, column=0, sticky=W)
        self._ent_min_discharge_h = Entry(left_frame, width=1)
        self._ent_min_discharge_h.grid(row=row, column=1, sticky=W + E)
        self._ent_min_discharge_h.insert(END, 890)
        Tooltip(self._ent_min_discharge_h, 'Минимальная высота сброса над каналом.')

        row += 1
        Label(left_frame, text='Прозор (мм):').grid(row=row, column=0, sticky=W)
        self._ent_gap = Entry(left_frame, width=1)
        self._ent_gap.grid(row=row, column=1, sticky=W + E)

        row += 1
        Separator(left_frame, orient=HORIZONTAL).grid(row=row, column=0, columnspan=2,
                                                      sticky=W + E)

        row += 1
        Label(left_frame, text='Расход воды (л/с):').grid(row=row, column=0, sticky=W)
        self._ent_water_flow = Entry(left_frame, width=1)
        self._ent_water_flow.grid(row=row, column=1, sticky=W + E)

        row += 1
        Label(left_frame, text='Уровень за решеткой (мм):').grid(row=row, column=0, sticky=W)
        self._ent_final_level = Entry(left_frame, width=1)
        self._ent_final_level.grid(row=row, column=1, sticky=W + E)

        row += 1
        Label(left_frame, text='Угол (градусы):').grid(row=row, column=0, sticky=W)
        self._ent_tilt_angle = Entry(left_frame, width=1)
        self._ent_tilt_angle.grid(row=row, column=1, sticky=W + E)
        self._ent_tilt_angle.insert(END, 80)
        Tooltip(self._ent_tilt_angle,
                'Угол используется только для гидравлического расчета.\n'
                'Масса решетки рассчитывается для угла 80 градусов.')

        row += 1
        Separator(left_frame, orient=HORIZONTAL).grid(row=row, column=0, columnspan=2,
                                                      sticky=W + E)

        row += 1
        Label(left_frame, text='Типоразмер по ширине:').grid(row=row, column=0, sticky=W)
        self._cmb_screen_ws = Combobox(left_frame, state='readonly', width=cmb_w,
                                       values=list(self.SCREEN_WIDTH_CHOICES))
        self._cmb_screen_ws.grid(row=row, column=1)
        self._cmb_screen_ws.current(0)

        row += 1
        Label(left_frame, text='Типоразмер по высоте:').grid(row=row, column=0, sticky=W)
        self._cmb_screen_hs = Combobox(left_frame, state='readonly', width=cmb_w,
                                       values=list(self.SCREEN_HEIGHT_CHOICES))
        self._cmb_screen_hs.grid(row=row, column=1)
        self._cmb_screen_hs.current(0)

        row += 1
        Label(left_frame, text='Типоразмер полотна:').grid(row=row, column=0, sticky=W)
        self._cmb_grate_hs = Combobox(left_frame, state='readonly', width=cmb_w,
                                      values=list(self.GRATE_HEIGHT_CHOICES))
        self._cmb_grate_hs.grid(row=row, column=1)
        self._cmb_grate_hs.current(0)

        row += 1
        self._fp_table = SortableTreeview(
            left_frame, columns=[''] * 3, show='headings', height=len(self.FILTER_PROFILE_CHOICES),
            style='DPI.Treeview')
        self._fp_table.heading('#1', text='Профиль', sort_as='str')
        self._fp_table.column('#1', width=fdpi(70), stretch=NO)
        self._fp_table.heading('#2', text='Крепление', sort_as='str')
        self._fp_table.column('#2', width=fdpi(85), stretch=NO)
        self._fp_table.heading('#3', text='Коэф.', sort_as='num')
        self._fp_table.column('#3', anchor=E, width=-1, stretch=YES)
        self._fp_table.grid(row=row, columnspan=2, sticky=W + E)

        for index, i in enumerate(FILTER_PROFILES):
            self._fp_table.insert('', 'end', iid=index, values=(
                i.name,
                'съемный' if i.is_removable else 'сварной',
                fstr(i.shape_factor)))
        self._fp_table.selection_set([0])

        right_frame = Frame(self)
        right_frame.grid(row=0, column=1, sticky=N + S)
        right_frame.grid_rowconfigure(0, weight=1)

        self._memo = ScrolledText(right_frame, state=DISABLED, height=1)
        self._memo.grid(row=0, column=0, sticky=W + E + N + S)

        # TODO: Привязать к уровню загрязнений (4).
        self._hydr_table = Treeview(right_frame, columns=[''] * 7, height=4, show='headings',
                                    style='DPI.Treeview')
        self._hydr_table.heading('#1', text='Загрязнение')
        self._hydr_table.column('#1', anchor=E, width=fdpi(95))
        self._hydr_table.heading('#2', text='Скорость в прозорах')
        self._hydr_table.column('#2', anchor=E, width=fdpi(140))
        self._hydr_table.heading('#3', text='Относ. площадь потока')
        self._hydr_table.column('#3', anchor=E, width=fdpi(145))
        self._hydr_table.heading('#4', text='Blinding factor')
        self._hydr_table.column('#4', anchor=E, width=fdpi(95))
        self._hydr_table.heading('#5', text='Разность уровней')
        self._hydr_table.column('#5', anchor=E, width=fdpi(125))
        self._hydr_table.heading('#6', text='Уровень до решетки')
        self._hydr_table.column('#6', anchor=E, width=fdpi(135))
        self._hydr_table.heading('#7', text='Скорость в канале')
        self._hydr_table.column('#7', anchor=E, width=fdpi(125))
        self._hydr_table.grid(row=1, column=0, sticky=W + E + S)

        btn_frame = Frame(self)
        btn_frame.grid(row=2, column=1, sticky=E)

        Button(btn_frame, text='Рассчитать', command=self._run).grid(row=0, column=1)
        self.bind_all('<Return>', self._on_press_enter)

        self._add_pad_to_all_widgets()
        self._focus_first_entry(self)
        root.bind_all('<Key>', handle_ctrl_shortcut, '+')

    def _output(self, text: str) -> None:
        self._memo.config(state=NORMAL)
        self._memo.delete(1.0, END)
        self._memo.insert(END, text)
        self._memo.config(state=DISABLED)

    def _print_error(self, text: str) -> None:
        self._output(text)

    def _run(self) -> None:
        self._hydr_table.delete(*self._hydr_table.get_children())

        screen_ws = self.SCREEN_WIDTH_CHOICES[self._cmb_screen_ws.get()]
        screen_hs = self.SCREEN_HEIGHT_CHOICES[self._cmb_screen_hs.get()]
        fp = FILTER_PROFILES[int(self._fp_table.selection()[0])]
        grate_hs = self.GRATE_HEIGHT_CHOICES[self._cmb_grate_hs.get()]
        try:
            channel_width = self._get_mm_from_entry(self._ent_channel_w)
            channel_height = self._get_mm_from_entry(self._ent_channel_h)
            min_discharge_height = self._get_mm_from_entry(self._ent_min_discharge_h)
            gap = self._get_mm_from_entry(self._ent_gap)
            water_flow = self._get_opt_l_s_from_entry(self._ent_water_flow)
            final_level = self._get_opt_mm_from_entry(self._ent_final_level)
            tilt_angle = self._get_opt_deg_from_entry(self._ent_tilt_angle)
        except ValueError:
            return

        input_data = InputData(
            screen_ws=screen_ws, screen_hs=screen_hs, grate_hs=grate_hs,
            channel_width=channel_width, channel_height=channel_height, fp=fp, gap=gap,
            water_flow=water_flow, final_level=final_level, tilt_angle=tilt_angle,
            min_discharge_height=min_discharge_height)
        try:
            bs = BarScreen(input_data)
        except InputDataError as excp:
            self._output(str(excp))
            return

        output = [
            bs.designation,
            'Масса {} кг{}'.format(
                fstr(bs.mass, '%.0f'), ' (примерно)' if not bs.is_standard_serie else ''),
            'Привод {} кВт'.format(
                fstr(bs.drive_power / 1e3) if bs.drive_power else 'нестандартный'),
            '',
            'Ширина просвета {} мм'.format(fstr(bs.inner_screen_width * 1e3, '%.0f')),
            'Высота просвета (от дна) {} мм'.format(fstr(bs.inner_screen_height * 1e3, '%.0f')),
            'Длина решетки {} мм'.format(fstr(bs.screen_length * 1e3, '%.0f')),
            'Длина цепи {} мм'.format(fstr(bs.chain_length * 1e3, '%.0f')),
            'Длина профиля {} мм'.format(fstr(bs.fp_length * 1e3, '%.0f')),
            'Количество профилей {} ± 1 шт.'.format(fstr(bs.profiles_count)),
            'Количество граблин {} шт.'.format(fstr(bs.rakes_count)),
            'Ширина сброса {} мм'.format(fstr(bs.discharge_width * 1e3, '%.0f')),
            'Высота сброса (над каналом) {} мм'.format(fstr(bs.discharge_height * 1e3, '%.0f')),
            'Высота сброса (до дна) {} мм'.format(fstr(bs.discharge_full_height * 1e3, '%.0f'))]

        for blinding, hydr in bs.hydraulic.items():
            self._hydr_table.insert('', 'end', None, values=(
                '{}%'.format(fstr(blinding * 100)),
                '{} м/с'.format(fstr(hydr.velocity_in_gap, '%.2f'))
                if hydr.velocity_in_gap is not None else '',
                '{}'.format(fstr(hydr.relative_flow_area, '%.2f'))
                if hydr.relative_flow_area is not None else '',
                '{}'.format(fstr(hydr.blinding_factor * 1e3, '%.1f'))
                if hydr.blinding_factor is not None else '',
                '{} мм'.format(fstr(hydr.level_diff * 1e3, '%.0f'))
                if hydr.level_diff is not None else '',
                '{} мм'.format(fstr(hydr.start_level * 1e3, '%.0f'))
                if hydr.start_level is not None else '',
                '{} м/с'.format(fstr(hydr.upstream_flow_velocity, '%.2f'))
                if hydr.upstream_flow_velocity is not None else ''))
            if hydr.start_level is not None:
                overflow_channel = hydr.start_level > channel_height
                # Округлить до миллиметров.
                diff = round(hydr.start_level - bs.inner_screen_height, 3)
                overflow_grate = diff >= 0
                if overflow_channel or overflow_grate:
                    output += '\n{}% - '.format(fstr(blinding * 100))
                    warnings = []
                    if overflow_channel:
                        warnings.append('переполнение канала')
                    if overflow_grate:
                        warnings.append('уровень выше полотна ({} мм)'.format(
                            fstr(diff * 1e3, '%.0f')))
                    output.append(', '.join(warnings))
        self._output('\n'.join(output))

    def _on_press_enter(self, _: Event) -> None:
        self._run()
