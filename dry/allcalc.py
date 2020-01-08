"""Общие классы и функции для инженерных расчетов."""
from typing import NewType


WidthSerie = NewType('WidthSerie', int)            # Типоразмер по ширине.
HeightSerie = NewType('HeightSerie', int)          # Типоразмер по высоте.
Mass = NewType('Mass', float)                      # Масса, кг.
Distance = NewType('Distance', float)              # Расстояние, м.
Power = NewType('Power', float)                    # Мощность, Вт.
VolumeFlowRate = NewType('VolumeFlowRate', float)  # Объемный расход, м3/с.
Angle = NewType('Angle', float)                    # Угол, радианы.
Velocity = NewType('Velocity', float)              # Векторная скорость, м/с.
Area = NewType('Area', float)                      # Площадь, м2.
Acceleration = NewType('Acceleration', float)      # Ускорение, м/с2.

GRAV_ACC = Acceleration(9.80665)


class InputDataError(Exception):
    """Класс исключений, связанный с неправильными входными данными."""
