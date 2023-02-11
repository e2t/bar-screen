from tkinter import font
from typing import ValuesView


def text_width(text: str, pad: int = 0) -> int:
    line = text + '0' * pad
    return font.nametofont('TkDefaultFont').measure(line)


def max_column_width(headings: ValuesView[str], pad: int = 0) -> int:
    return max(text_width(i, pad) for i in headings)
