from locale import LC_ALL, setlocale
from tkinter import Tk

from app import App

setlocale(LC_ALL, '')
root = Tk()
app = App(root)
app.init()
root.mainloop()
