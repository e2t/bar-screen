from tkinter import Widget, Toplevel, Label, Event, LEFT, SOLID
from typing import Optional


class Tooltip():
    def __init__(self, widget: Widget, text: str) -> None:
        self.widget = widget
        self.text = text
        widget.bind('<Enter>', self.showtip)
        widget.bind('<Leave>', self.hidetip)
        self.tipwindow: Optional[Toplevel] = None

    def showtip(self, _: Event) -> None:
        """Display text in tooltip window."""
        # x, y, cx, cy = self.widget.bbox("insert")
        x = self.widget.winfo_rootx() + 20
        y = self.widget.winfo_rooty() + self.widget.winfo_height() + 1
        self.tipwindow = Toplevel(self.widget)
        self.tipwindow.wm_overrideredirect(True)
        self.tipwindow.wm_geometry('+%d+%d' % (x, y))
        label = Label(self.tipwindow, text=self.text, justify=LEFT,
                      background='#ffffe0', relief=SOLID, borderwidth=1)
        label.pack(ipadx=1)

    def hidetip(self, _: Event) -> None:
        if self.tipwindow:
            self.tipwindow.destroy()
