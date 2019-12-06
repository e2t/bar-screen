"""Запуск программы."""
from tkinter import Tk
from gui import MainForm


ROOT = Tk()
_ = MainForm(ROOT)
ROOT.resizable(False, False)
ROOT.mainloop()
