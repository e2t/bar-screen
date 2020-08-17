"""Библиотека стандартных графических решений."""
import locale
from typing import Union, Optional, Tuple, Sequence
from tkinter import Text, NORMAL, END, DISABLED, Event
from tkinter.ttk import Widget, Frame, LabelFrame, Entry, Treeview
from tkinter.scrolledtext import ScrolledText
from abc import abstractmethod
from math import radians
from functools import partial
from dry.allcalc import Distance, VolumeFlowRate, Angle, Power


def convert_str_to_positive_float(text: str) -> float:
    """Преобразование строки в вещественное число больше нуля."""
    value = locale.atof(text)
    if value <= 0:
        raise ValueError
    return value


def fstr(value: Union[int, float], pattern: str = '%g') -> str:
    """Форматирует число в региональном формате."""
    return locale.format_string(pattern, value, True)


def print_in_disabled_text(memo: Union[Text, ScrolledText], text: str) -> None:
    """Заменить текст в отключенном виджете типа Text."""
    memo.config(state=NORMAL)
    memo.delete(1.0, END)
    memo.insert(END, text)
    memo.config(state=DISABLED)


def format_params(lines: Sequence[Tuple[str, str]]) -> str:
    """Форматирует (выравнивает) список параметров и их значения."""
    longest_param = max([i[0] for i in lines], key=len)
    indent = len(longest_param)
    return '\n'.join(['%-*s  %s' % (indent, i[0], i[1]) for i in lines])


def handle_ctrl_shortcut(event: Event) -> None:
    shift = (event.state & 0x1) != 0
    ctrl = (event.state & 0x4) != 0
    alt = (event.state & 0x20000) != 0

    if not (shift or alt) and ctrl:
        if event.keycode == 86 and event.keysym.lower() != 'v':
            event.widget.event_generate('<<Paste>>')
        elif event.keycode == 67 and event.keysym.lower() != 'c':
            event.widget.event_generate('<<Copy>>')
        elif event.keycode == 88 and event.keysym.lower() != 'x':
            event.widget.event_generate('<<Cut>>')
        elif event.keycode == 65 and event.keysym.lower() != 'a':
            event.widget.event_generate('<<SelectAll>>')
        elif event.keycode == 90 and event.keysym.lower() != 'z':
            event.widget.event_generate('<<Undo>>')
        elif event.keycode == 89 and event.keysym.lower() != 'y':
            event.widget.event_generate('<<Redo>>')


class MyFrame(Frame):
    """Форма с зазором между виджетами."""

    # Добавление зазора между виджетами.
    # Вызывать после создания всех виджетов на форме.
    def _add_pad_to_all_widgets(self) -> None:
        self.grid(padx=7, pady=7)
        for i in self.winfo_children():
            self._add_pad_to_child_widgets(i)

    # Добавление зазора между дочерними виджетами фреймов, сами фреймы пропускаются.
    def _add_pad_to_child_widgets(self, widget: Widget) -> None:
        if isinstance(widget, (Frame, LabelFrame)):
            for i in widget.winfo_children():
                self._add_pad_to_child_widgets(i)
        else:
            widget.grid(padx=3, pady=3)

    # Передать фокус в первое текстовое поле.
    # Вызывать после создания всех виджетов на форме.
    def _focus_first_entry(self, widget: Widget) -> bool:
        if isinstance(widget, Entry):
            widget.focus_set()
            return True
        if isinstance(widget, (Frame, LabelFrame)):
            for i in widget.winfo_children():
                if self._focus_first_entry(i):
                    return True
        return False

    @abstractmethod
    def _print_error(self, text: str) -> None:
        """Вывести сообщение об ошибке."""

    def _print_error_and_select(self, entry: Entry) -> None:
        self._print_error('Неправильное значение.')
        entry.focus_set()
        entry.select_range(0, 'end')

    def _get_positive_float_from_entry(self, entry: Entry) -> float:
        try:
            value = convert_str_to_positive_float(entry.get())
        except ValueError:
            self._print_error_and_select(entry)
            raise
        return value

    def _get_opt_positive_float_from_entry(
            self, entry: Entry) -> Optional[float]:
        text = entry.get()
        if not text:
            return None
        try:
            value = convert_str_to_positive_float(text)
        except ValueError:
            self._print_error_and_select(entry)
            raise
        return value

    def _get_mm_from_entry(self, entry: Entry) -> Distance:
        value = self._get_positive_float_from_entry(entry)
        return Distance(value / 1e3)  # мм -> м

    def _get_opt_mm_from_entry(self, entry: Entry) -> Optional[Distance]:
        value = self._get_opt_positive_float_from_entry(entry)
        if value is not None:
            return Distance(value / 1e3)  # мм -> м
        return None

    def _get_opt_l_s_from_entry(
            self, entry: Entry) -> Optional[VolumeFlowRate]:
        value = self._get_opt_positive_float_from_entry(entry)
        if value is not None:
            return VolumeFlowRate(value / 1e3)  # л/с -> м3/с
        return None

    def _get_opt_deg_from_entry(self, entry: Entry) -> Optional[Angle]:
        value = self._get_opt_positive_float_from_entry(entry)
        if value is not None:
            return Angle(radians(value))  # градусы -> радианы
        return None


class SortableTreeview(Treeview):
    def heading(self, column, sort_as=None, **kwargs):
        if sort_as and not hasattr(kwargs, 'command'):
            func = getattr(self, f"_sort_as_{sort_as}", None)
            if func:
                kwargs['command'] = partial(func, column, False)
        return super().heading(column, **kwargs)

    def _sort(self, column, reverse, data_type, callback):
        l = [(self.set(k, column), k) for k in self.get_children('')]
        l.sort(key=lambda t: data_type(t[0]), reverse=reverse)
        for index, (_, k) in enumerate(l):
            self.move(k, '', index)
        self.heading(column, command=partial(callback, column, not reverse))

    def _sort_as_num(self, column, reverse):
        self._sort(column, reverse, locale.atof, self._sort_as_num)

    def _sort_as_str(self, column, reverse):
        self._sort(column, reverse, str, self._sort_as_str)


def to_mm(meters: Distance) -> Distance:
    """Преобразование метров в миллиметры."""
    return Distance(meters * 1e3)


def from_mm(mms: Distance) -> Distance:
    """Преобразование миллиметров в метры."""
    return Distance(mms / 1e3)


def to_kw(watt: Power) -> Power:
    """Преобразование ватт в киловатты."""
    return Power(watt / 1e3)
