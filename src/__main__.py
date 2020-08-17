"""Запуск программы."""
import locale
from tkinter import Tk
from gui import MainForm
locale.setlocale(locale.LC_NUMERIC, '')


ROOT = Tk()
_ = MainForm(ROOT)
ROOT.resizable(False, False)
ROOT.mainloop()
