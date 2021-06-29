"""Расчет параметров грабельной решетки больших типоразмеров."""
from typing import NamedTuple, Optional, Callable, Dict, Tuple
from math import ceil, radians, sin
from abc import abstractmethod, ABC
from Dry.allcalc import (
    WidthSerie, HeightSerie, Mass, Distance, Power, VolumeFlowRate, Angle,
    Velocity, Area, GRAV_ACC, InputDataError, Torque)


SCREEN_WIDTH_SERIES = range(5, 31)
SCREEN_HEIGHT_SERIES = range(3, 145, 3)
GRATE_HEIGHT_SERIES = range(6, 61, 3)

DEFAULT_DISCHARGE_HEIGHT = Distance(0.89)

MAX_DIFF_SCREEN_AND_GRATE_HS = 9

DEFAULT_TILT_ANGLE = 80

STD_GAPS = (Distance(0.005), Distance(0.006), Distance(0.008), Distance(0.010), Distance(0.012),
            Distance(0.015), Distance(0.016), Distance(0.020), Distance(0.025), Distance(0.030),
            Distance(0.040), Distance(0.050), Distance(0.060), Distance(0.070), Distance(0.080),
            Distance(0.090), Distance(0.100))


class FilterProfile(NamedTuple):
    """Профиль фильтровального полотна."""

    name: str            # Название профиля.
    width: Distance      # Ширина профиля, м.
    is_removable: bool   # True - вставное полотно, False - сварное полотно.
    shape_factor: float  # Коэффициент формы.
    # Вычиление массы исходя из типоразмера полотна.
    calc_mass: Callable[[HeightSerie], Mass]


FILTER_PROFILES = (
    FilterProfile('3999', Distance(0.0095), False, 1.5,
                  lambda grate_hs: Mass(0.1167 * grate_hs - 0.13)),
    FilterProfile('341', Distance(0.0055), False, 0.95,
                  lambda grate_hs: Mass(0.0939 * grate_hs - 0.1067)),
    FilterProfile('777', Distance(0.0078), False, 0.95,
                  lambda grate_hs: Mass(0.1887 * grate_hs - 0.194)),
    FilterProfile('1492', Distance(0.008), True, 0.95,
                  lambda grate_hs: Mass(0.2481 * grate_hs - 0.4829)),
    FilterProfile('6x30', Distance(0.006), False, 2.42,
                  lambda grate_hs: Mass(0.144 * grate_hs - 0.158)),
    FilterProfile('6x60', Distance(0.006), True, 2.42,
                  lambda grate_hs: Mass(0.2881 * grate_hs - 0.5529)))


class DriveUnit(NamedTuple):
    """Основные характеристики привода."""

    name: str
    mass: Mass
    power: Power
    output_torque: Torque


DRIVE_UNITS_SMALL = (
    DriveUnit('SK 12080AZBHVL-71LP/4 TF', mass=Mass(38), power=Power(370),
              output_torque=Torque(680)),
)


DRIVE_UNITS_BIG = (
    DriveUnit('SK 32100AZBHVL-80LP/4 TF', mass=Mass(67), power=Power(750),
              output_torque=Torque(1663)),
    DriveUnit('SK 43125AZBHVL-90SP/4 TF', mass=Mass(129), power=Power(1100),
              output_torque=Torque(3052)),
)


class InputData(NamedTuple):
    """Структура входных данных для расчета решетки."""

    screen_ws: Optional[WidthSerie]     # Типоразмер решетки по ширине.
    screen_hs: Optional[HeightSerie]    # Типоразмер решетки по высоте.
    grate_hs: Optional[HeightSerie]     # Типоразмер полотна по высоте.
    channel_width: Distance             # Ширина канала, м.
    channel_height: Distance            # Глубина канала, м.
    min_discharge_height: Distance      # Минимальная высота сброса, м.
    fp: FilterProfile                   # Тип фильтровального профиля.
    gap: Distance                       # Прозор полотна, м.
    tilt_angle: Angle                   # Угол наклона, радианы.
    # Гидравлические параметры:
    water_flow: Optional[VolumeFlowRate] = None  # Расход воды, м3/с.
    final_level: Optional[Distance] = None       # Уровень после решетки, м.


class Hydraulic(NamedTuple):
    """Расчетные гидравлические параметры, зависящие от загрязнения полотна."""

    velocity_in_gap: Optional[Velocity]
    relative_flow_area: float
    blinding_factor: float
    level_diff: Optional[Distance]
    start_level: Optional[Distance]
    upstream_flow_velocity: Optional[Velocity]


class BarScreen:
    """Грабельная решетка больших типоразмеров."""

    MAX_BIG_SCREEN_WS = WidthSerie(24)
    MAX_BIG_SCREEN_HS = HeightSerie(30)

    @property
    def designation(self) -> str:
        """Обозначение решетки."""
        return self._designation

    @property
    def min_torque(self) -> Torque:
        """Минимальный крутящий момент."""
        return self._min_torque

    @property
    def is_standard_serie(self) -> bool:
        """Принадлежит ли решетка к стандартному типоряду."""
        return self._is_standard_serie

    @property
    def drive(self) -> Optional[DriveUnit]:
        """Привод (для стандартных типоразмеров)."""
        return self._drive

    @property
    def inner_screen_width(self) -> Distance:
        """Ширина просвета решетки."""
        return self._inner_screen_width

    @property
    def inner_screen_height(self) -> Distance:
        """Высота просвета решетки."""
        return self._inner_screen_height

    @property
    def discharge_width(self) -> Distance:
        """Ширина сброса."""
        return self._discharge_width

    @property
    def discharge_height(self) -> Distance:
        """Высота сброса над каналом."""
        return self._discharge_height

    @property
    def discharge_full_height(self) -> Distance:
        """Высота сброса от дна канала."""
        return self._discharge_full_height

    @property
    def hydraulic(self) -> Dict[float, Hydraulic]:
        """Расчетные гидравлические параметры, зависящие от загрязнения."""
        return self._hydraulic

    @property
    def rakes_count(self) -> int:
        """Количество граблин."""
        return self._rakes_count

    @property
    def fp_length(self) -> Distance:
        """Длина профиля."""
        return self._fp_length

    @property
    def chain_length(self) -> Distance:
        """Длина цепи (шаг 100 мм)."""
        return self._chain_length

    @property
    def screen_length(self) -> Distance:
        """Длина решетки (боковины)."""
        return self._screen_length

    @property
    def profiles_count(self) -> int:
        """Количество профилей."""
        return self._profiles_count

    @property
    def is_small(self) -> bool:
        """Решетка малая или нет."""
        return self._is_small

    def __init__(self, input_data: InputData):
        """Конструктор и одновременно расчет решетки."""
        self._input_data = input_data
        self._screen_ws: WidthSerie = self._input_data.screen_ws or self._calc_screen_ws()
        self._screen_hs: HeightSerie = self._input_data.screen_hs or self._calc_screen_hs()
        self._is_small: bool = self._calc_is_small()

        self._discharge_full_height = self._calc_discharge_full_height(self._screen_hs)
        self._discharge_height = self._calc_discharge_height()
        if self._discharge_height < self._input_data.min_discharge_height:
            raise InputDataError('Высота сброса меньше указанной минимальной высоты.')

        self._inner_screen_width = self._calc_inner_screen_width()
        # Гидравлический расчет:
        self._b = self._calc_b_hydraulic()
        self._c = self._calc_c_hydraulic()
        self._efficiency = self._calc_efficiency()
        self._hydraulic = self._calc_hydraulic()

        self._grate_hs: HeightSerie = self._input_data.grate_hs or self._calc_grate_hs()

        # TODO: Усиленный привод - сделать расчет от высоты решетки.
        self._is_heavy_version = True

        if (self._screen_hs - self._grate_hs) < -MAX_DIFF_SCREEN_AND_GRATE_HS:
            raise InputDataError('Полотно больше решетки более чем на {:d} типоразмеров.'.format(
                MAX_DIFF_SCREEN_AND_GRATE_HS))
        self._channel_ws = self._calc_channel_ws()
        if (self._channel_ws - self._screen_ws) < 0:
            raise InputDataError('Слишком узкий канал.')
        if (self._channel_ws - self._screen_ws) > 2:
            raise InputDataError('Слишком широкий канал.')
        self._screen_pivot_height = self._calc_screen_pivot_height()
        self._stand_height = self._calc_stand_height()
        self._stand_hs = self._calc_stand_hs()

        self._profiles_count = self._calc_profiles_count()
        if self._profiles_count < 2:
            raise InputDataError('Слишком большой прозор.')

        self._inner_screen_height = self._calc_inner_screen_height(self._grate_hs)

        if self._input_data.final_level is not None:
            if self._input_data.final_level >= self._input_data.channel_height:
                raise InputDataError('Уровень воды выше канала.')
            if self._input_data.final_level >= self._inner_screen_height:
                raise InputDataError('Уровень воды выше полотна.')

        if not radians(45) <= self._input_data.tilt_angle <= radians(90):
            raise InputDataError(f'Недопустимый угол. Стандартный: {DEFAULT_TILT_ANGLE}+-5.')

        self._chain_length = self._calc_chain_length()
        self._rakes_count = self._calc_rakes_count()
        self._designation = self._create_designation()
        self._is_standard_serie = self._check_standard_serie()
        self._min_torque = self._calc_min_torque()
        self._drive = self._calc_drive()
        self._screen_length = self._calc_screen_length()  # после длины цепи
        self._fp_length = self._calc_fp_length()
        self._discharge_width = self._calc_discharge_width()
        self._ws_diff = self._calc_ws_diff()
        self._backwall_hs = self._calc_backwall_hs()
        self._cover_hs = self._calc_cover_hs()
        self._covers_count = self._calc_covers_count()

    # Решетка малая или большая?
    def _calc_is_small(self) -> bool:
        return (self._screen_ws <= WidthSerie(7) and self._screen_hs <= HeightSerie(15)) or \
             (self._screen_ws <= WidthSerie(9) and self._screen_hs <= HeightSerie(12))

    # На 100 мм меньше, затем в меньшую сторону.
    def _calc_screen_ws(self) -> WidthSerie:
        return WidthSerie(int(round(self._input_data.channel_width - 0.1, 3) * 10))

    # TODO: Высота решетки - сделать подбор неограниченным.
    def _calc_screen_hs(self) -> HeightSerie:
        min_full_discharge_height = self._input_data.channel_height \
            + self._input_data.min_discharge_height
        for i in SCREEN_HEIGHT_SERIES:
            if self._calc_discharge_full_height(HeightSerie(i)) >= min_full_discharge_height:
                return HeightSerie(i)
        raise InputDataError('Не удается подобрать высоту решетки из стандартного ряда.')

    def _calc_grate_hs(self) -> HeightSerie:

        def calc_by(some_level: Optional[Distance]) -> Tuple[Distance, bool]:
            if (some_level is not None) and (some_level < self._input_data.channel_height):
                return some_level, False
            return self._input_data.channel_height, True

        start_levels = [i.start_level for i in self._hydraulic.values()
                        if i.start_level is not None]
        if start_levels:
            min_grate_height, can_be_equal = calc_by(max(start_levels))
        elif self._input_data.final_level is not None:
            min_grate_height, can_be_equal = calc_by(
                self._input_data.final_level)
        else:
            min_grate_height, can_be_equal = calc_by(None)
        for i in GRATE_HEIGHT_SERIES:
            grate_height = self._calc_inner_screen_height(HeightSerie(i))
            if grate_height > min_grate_height or (
                    can_be_equal and grate_height == min_grate_height):
                return HeightSerie(i)
        raise InputDataError('Не удается подобрать высоту полотна из стандартного ряда.')

    def _calc_screen_length(self) -> Distance:
        if self._is_small:
            return Distance(self._chain_length / 2 + 0.38)
        return Distance((100 * self._screen_hs + 1765) / 1e3)

    def _calc_fp_length(self) -> Distance:
        if self._input_data.fp.is_removable:
            return Distance((100 * self._grate_hs - 175) / 1e3)
        return Distance((100 * self._grate_hs - 106) / 1e3)

    def _calc_discharge_height(self) -> Distance:
        return Distance(self._discharge_full_height - self._input_data.channel_height)

    @staticmethod
    def _calc_discharge_full_height(screen_hs: HeightSerie) -> Distance:
        # Типоразмер расчитывается по конструкции больших решеток.
        # Малые решетки подгоняются под типоразмер.
        step_chain = 100  # Шаг цепи больших решеток.
        step_h = sin(radians(DEFAULT_TILT_ANGLE)) * step_chain
        return Distance(round((step_h * screen_hs + 961.09) / 1e3, 3))

    def _calc_b_hydraulic(self) -> Optional[Distance]:
        if self._input_data.final_level is not None:
            return Distance(2 * self._input_data.final_level)
        return None

    def _calc_c_hydraulic(self) -> Optional[Area]:
        if self._input_data.final_level is not None:
            return Area(self._input_data.final_level**2)
        return None

    def _calc_hydraulic(self) -> Dict[float, Hydraulic]:
        result: Dict[float, Hydraulic] = {}
        for i in (0.1, 0.2, 0.3, 0.4):  # При разном уровне загрязнения.
            relative_flow_area = self._calc_relative_flow_area(i)
            blinding_factor = self._calc_blinding_factor(relative_flow_area)
            d = self._calc_d_hydraulic(i, blinding_factor)
            level_diff = self._calc_level_diff(d)
            start_level = self._calc_start_level(level_diff)
            upstream_flow_velocity = self._calc_upstream_flow_velocity(start_level)
            velocity_in_gap = self._calc_velocity_in_gap(start_level, i)

            result[i] = Hydraulic(
                relative_flow_area=relative_flow_area,
                blinding_factor=blinding_factor,
                level_diff=level_diff,
                start_level=start_level,
                upstream_flow_velocity=upstream_flow_velocity,
                velocity_in_gap=velocity_in_gap)
        return result

    def _calc_velocity_in_gap(self, start_level: Optional[Distance],
                              blinding: float) -> Optional[Velocity]:
        if self._input_data.water_flow is not None and start_level is not None:
            return Velocity(self._input_data.water_flow / (self._inner_screen_width * start_level
                                                           * self._efficiency * (1 - blinding)))
        return None

    def _calc_upstream_flow_velocity(self, start_level: Optional[Distance]) -> Optional[Velocity]:
        if self._input_data.water_flow is not None and start_level is not None:
            return Velocity(self._input_data.water_flow
                            / (self._input_data.channel_width * start_level))
        return None

    def _calc_start_level(self, level_diff: Optional[Distance]) -> Optional[Distance]:
        if self._input_data.final_level is not None and level_diff is not None:
            return Distance(self._input_data.final_level + level_diff)
        return None

    def _calc_level_diff(self, d: Optional[float]) -> Optional[Distance]:
        if d is not None and self._b is not None and self._c is not None:
            a1 = (27 * d**2 + 18 * self._b * self._c * d + 4 * self._c**3
                  - 4 * self._b**3 * d - self._b**2 * self._c**2)
            a2 = (27 * d + 9 * self._b * self._c - 2 * self._b**3 + 5.19615 * a1**0.5)
            b1 = (2187 * self._c - 729 * self._b**2)
            c1 = (27 * d**2 + 18 * self._b * self._c * d + 4 * self._c**3
                  - 4 * self._b**3 * d - self._b**2 * self._c**2)
            c2 = (27 * d + 9 * self._b * self._c - 2 * self._b**3 + 5.19615 * c1**0.5)
            return Distance(0.264567 * a2**(1 / 3) - 0.000576096 * b1 / c2**(1 / 3)
                            - 0.333333 * self._b)
        return None

    def _calc_relative_flow_area(self, blinding: float) -> float:
        return self._input_data.gap / (self._input_data.gap + self._input_data.fp.width) \
            - blinding * self._input_data.gap / \
            (self._input_data.fp.width + self._input_data.gap)

    # В расчете не были указаны единицы измерения (будто это коэффициент),
    # но по всему видно, что это должна быть длина.
    def _calc_blinding_factor(self, relative_flow_area: float) -> float:
        return self._input_data.gap - relative_flow_area \
            * (self._input_data.gap + self._input_data.fp.width)

    # Неизвестны единицы измерения и вообще суть параметра.
    def _calc_d_hydraulic(self, blinding: float, blinding_factor: float) -> Optional[float]:
        if self._input_data.water_flow is not None:
            return ((((self._input_data.water_flow / self._inner_screen_width
                       / (self._efficiency * (1 - blinding)))**2)
                     / (2 * GRAV_ACC)) * sin(self._input_data.tilt_angle)
                    * self._input_data.fp.shape_factor
                    * (((self._input_data.fp.width + blinding_factor)
                        / (self._input_data.gap - blinding_factor))**(4 / 3)))
        return None

    # Эффективная поверхность решетки.
    def _calc_efficiency(self) -> float:
        return self._input_data.gap / (self._input_data.gap + self._input_data.fp.width)

    # Ширина сброса. Подходит для больших и малых решеток.
    def _calc_discharge_width(self) -> Distance:
        return Distance((100 * self._screen_ws - 129) / 1e3)

    # Высота просвета решетки.
    # ВНИМАНИЕ: Не учитывается высота лотка.
    @staticmethod
    def _calc_inner_screen_height(grate_hs: HeightSerie) -> Distance:
        return Distance(round((98.481 * grate_hs - 173.215) / 1e3, 3))

    # Подбор мощности привода.
    def _calc_drive(self) -> Optional[DriveUnit]:
        drives: Tuple[DriveUnit, ...]
        if self._is_small:
            drives = DRIVE_UNITS_SMALL
        else:
            drives = DRIVE_UNITS_BIG
        for i in drives:
            if self._min_torque <= i.output_torque:
                return i
        return None

    # Расчет крутящего момента привода.
    def _calc_min_torque(self) -> Torque:
        specific_garbage_load = 90  # кг/м граблины
        rack_len = self._inner_screen_width  # условно
        loaded_rack_count = ceil(self._rakes_count / 2)

        load = Mass(specific_garbage_load * rack_len * loaded_rack_count)
        if self._is_small:
            # 126 мм - диаметр дел. окружности звездочки РКЭм
            lever_arm = Distance(0.063)
        else:
            # 261,31 мм - диаметр дел. окружности звездочки РКЭ
            lever_arm = Distance(0.131)
        return Torque(load * GRAV_ACC * lever_arm)

    # Проверка, входит ли решетка в стандартный типоряд.
    def _check_standard_serie(self) -> bool:
        return (self._screen_ws <= self.MAX_BIG_SCREEN_WS) and \
            (self._screen_hs <= self.MAX_BIG_SCREEN_HS)

    # Обозначение решетки.
    def _create_designation(self) -> str:
        if self._is_small:
            abbr = 'РКЭм'
        else:
            abbr = 'РКЭ'
        dsg = [f'{abbr} {self._screen_ws:02d}{self._screen_hs:02d}']
        if (self._channel_ws != self._screen_ws) or (self._grate_hs != self._screen_hs):
            dsg.append('(')
            if self._channel_ws == self._screen_ws:
                dsg.append('00')
            else:
                dsg.append(f'{self._channel_ws:02d}')
            if self._grate_hs == self._screen_hs:
                dsg.append('00')
            else:
                dsg.append(f'{self._grate_hs:02d}')
            dsg.append(')')
        dsg.append(
            f'.{self._input_data.fp.name}.{self._input_data.gap * 1000:g}')
        return ''.join(dsg)

    def _calc_inner_screen_width(self) -> Distance:
        if self._is_small:
            return Distance(0.1 * self._screen_ws - 0.128)
        return Distance(0.1 * self._screen_ws - 0.132)

    # Примерное (теоретическое) количество, конструктор может менять шаг.
    def _calc_profiles_count(self) -> int:
        return ceil((self._inner_screen_width - self._input_data.gap)
                    / (self._input_data.fp.width + self._input_data.gap))

    def _calc_chain_length(self) -> Distance:
        small_chain_lengths = {3: Distance(3.528),
                               6: Distance(4.032),
                               9: Distance(4.662),
                               12: Distance(5.292),
                               15: Distance(5.922)}
        if self._is_small:
            return small_chain_lengths[self._screen_hs]
        return Distance(0.2 * self._screen_hs + 3.2)

    def _calc_rakes_count(self) -> int:
        return round(self._chain_length / 0.825)

    def _calc_channel_ws(self) -> WidthSerie:
        return WidthSerie(round((self._input_data.channel_width - 0.1) / 0.1))

    def _calc_screen_pivot_height(self) -> Distance:
        return Distance(0.0985 * self._screen_hs + 1.0299)

    def _calc_stand_height(self) -> Distance:
        return Distance(self._screen_pivot_height - self._input_data.channel_height)

    # Типоразмер подставки на пол.
    def _calc_stand_hs(self) -> HeightSerie:
        if 0.4535 <= self._stand_height < 0.6035:
            return HeightSerie(6)
        elif 0.6035 <= self._stand_height < 0.8535:
            return HeightSerie(7)
        elif self._stand_height >= 0.8535:
            return HeightSerie(round((self._stand_height - 1.0035) / 0.3) * 3 + 10)
        raise InputDataError('Слишком маленькая опора.')

    def _calc_backwall_hs(self) -> HeightSerie:
        return HeightSerie(self._screen_hs - self._grate_hs + 10)

    def _calc_ws_diff(self) -> WidthSerie:
        return WidthSerie(self._channel_ws - self._screen_ws)

    def _calc_covers_count(self) -> int:
        if self._screen_ws <= 10:
            return 2
        return 4

    def _calc_cover_hs(self) -> HeightSerie:
        return min(self._backwall_hs, self._stand_hs)


class MassCalculator(ABC):
    @property
    def mass(self) -> Mass:
        """Расчетная масса решетки."""
        return self._mass

    def __init__(self) -> None:
        self._mass: Mass

    def _calc_mass_grid(self, bs: BarScreen) -> Mass:
        mass_grid_balk = self._calc_mass_grid_balk(bs)
        mass_fp = self._calc_mass_fp(bs)
        mass_grid_screw = self._calc_mass_grid_screw()

        return Mass(mass_grid_balk * 2 +
                    mass_fp * bs._profiles_count +
                    mass_grid_screw * 4)

    def _calc_mass_fp(self, bs: BarScreen) -> Mass:
        return bs._input_data.fp.calc_mass(bs._grate_hs)

    @abstractmethod
    def _calc_mass_grid_balk(self, bs: BarScreen) -> Mass:
        pass

    @abstractmethod
    def _calc_mass_grid_screw(self) -> Mass:
        pass


class MassLarge(MassCalculator):
    def __init__(self, bs: BarScreen) -> None:
        mass_rke01ad = self._calc_mass_rke01ad(bs)
        mass_rke02ad = self._calc_mass_rke02ad(bs)
        mass_rke03ad = self._calc_mass_rke03ad(bs)
        mass_rke04ad = self._calc_mass_rke04ad(bs)
        mass_rke05ad = self._calc_mass_rke05ad(bs)
        mass_rke06ad = self._calc_mass_rke06ad(bs)
        mass_rke07ad = self._calc_mass_rke07ad()
        mass_rke08ad = self._calc_mass_rke08ad(bs)
        mass_rke09ad = self._calc_mass_rke09ad(bs)
        mass_rke10ad = self._calc_mass_rke10ad(bs)
        mass_rke11ad = self._calc_mass_rke11ad()
        mass_rke12ad = self._calc_mass_rke12ad()
        mass_rke13ad = self._calc_mass_rke13ad(bs)
        mass_rke18ad = self._calc_mass_rke18ad()
        mass_rke19ad = self._calc_mass_rke19ad(bs)
        mass_rke00ad05 = self._calc_mass_rke00ad05()
        mass_rke00ad09 = self._calc_mass_rke00ad09()
        mass_rke00ad13 = self._calc_mass_rke00ad13()
        mass_chain_ms56r100 = self._calc_chain_mass_ms56r100(bs)

        fasteners = Mass(1.24)
        self._mass = Mass(mass_rke01ad
                          + mass_rke02ad
                          + mass_rke03ad * 2
                          + mass_rke04ad * bs._rakes_count
                          + mass_rke05ad
                          + mass_rke06ad
                          + mass_rke07ad
                          + mass_rke08ad * 2
                          + mass_rke09ad
                          + mass_rke10ad * bs._covers_count
                          + mass_rke11ad * 2
                          + mass_rke12ad * 2
                          + mass_rke13ad
                          + mass_rke18ad * 2
                          + mass_rke19ad
                          + mass_rke00ad05 * 4
                          + mass_rke00ad09 * 2
                          + mass_rke00ad13 * 2
                          + mass_chain_ms56r100 * 2
                          + fasteners)

    def _calc_mass_rke0102ad(self, bs: BarScreen) -> Mass:
        return Mass(1.5024 * bs._screen_ws - 0.1065)

    def _calc_mass_grid_balk(self, bs: BarScreen) -> Mass:
        return Mass(0.6919 * bs._screen_ws - 0.7431)

    def _calc_mass_grid_screw(self) -> Mass:
        return Mass(0.16)

    def _calc_mass_rke0104ad(self, bs: BarScreen) -> Mass:
        return Mass(0.2886 * bs._backwall_hs * bs._screen_ws
                    - 0.2754 * bs._backwall_hs
                    + 2.2173 * bs._screen_ws - 2.6036)

    def _calc_mass_rke01ad01(self) -> Mass:
        return Mass(0.62)

    def _calc_mass_rke010101ad(self, bs: BarScreen) -> Mass:
        return Mass(2.7233 * bs._screen_hs + 46.32)

    def _calc_mass_rke010111ad(self, bs: BarScreen) -> Mass:
        return Mass(2.7467 * bs._screen_hs + 46.03)

    def _calc_mass_rke010102ad(self, bs: BarScreen) -> Mass:
        return Mass(0.5963 * bs._screen_ws - 0.3838)

    def _calc_mass_rke010103ad(self, bs: BarScreen) -> Mass:
        return Mass(0.5881 * bs._screen_ws + 0.4531)

    def _calc_mass_rke010104ad(self, bs: BarScreen) -> Mass:
        return Mass(0.8544 * bs._screen_ws - 0.1806)

    def _calc_mass_rke010105ad(self, bs: BarScreen) -> Mass:
        return Mass(0.6313 * bs._screen_ws + 0.1013)

    def _calc_mass_rke010107ad(self, bs: BarScreen) -> Mass:
        return Mass(0.605 * bs._ws_diff + 3.36)

    def _calc_mass_rke010108ad(self, bs: BarScreen) -> Mass:
        return Mass(0.445 * bs._screen_ws - 0.245)

    def _calc_mass_rke010109ad(self, bs: BarScreen) -> Mass:
        if bs._screen_ws <= 10:
            return Mass(0.136 * bs._screen_ws + 0.13)
        return Mass(0.1358 * bs._screen_ws + 0.2758)

    def _calc_mass_rke0101ad02(self) -> Mass:
        return Mass(0.42)

    def _calc_mass_rke0101ad(self, bs: BarScreen) -> Mass:
        mass_rke010101ad = self._calc_mass_rke010101ad(bs)
        mass_rke010111ad = self._calc_mass_rke010111ad(bs)
        mass_rke010102ad = self._calc_mass_rke010102ad(bs)
        mass_rke010103ad = self._calc_mass_rke010103ad(bs)
        mass_rke010104ad = self._calc_mass_rke010104ad(bs)
        mass_rke010105ad = self._calc_mass_rke010105ad(bs)
        mass_rke010107ad = self._calc_mass_rke010107ad(bs)
        mass_rke010108ad = self._calc_mass_rke010108ad(bs)
        mass_rke010109ad = self._calc_mass_rke010109ad(bs)
        mass_rke0101ad02 = self._calc_mass_rke0101ad02()

        fasteners = Mass(2.22)
        return Mass(mass_rke010101ad
                    + mass_rke010111ad
                    + mass_rke010102ad * 2
                    + mass_rke010103ad
                    + mass_rke010104ad
                    + mass_rke010105ad
                    + mass_rke010107ad * 2
                    + mass_rke010108ad
                    + mass_rke010109ad
                    + mass_rke0101ad02 * 2
                    + fasteners)

    def _calc_mass_rke01ad(self, bs: BarScreen) -> Mass:
        mass_rke0101ad = self._calc_mass_rke0101ad(bs)
        mass_rke0102ad = self._calc_mass_rke0102ad(bs)
        mass_grid = self._calc_mass_grid(bs)
        mass_rke0104ad = self._calc_mass_rke0104ad(bs)
        mass_rke01ad01 = self._calc_mass_rke01ad01()

        fasteners = Mass(1.07)
        return Mass(mass_rke0101ad
                    + mass_rke0102ad
                    + mass_grid
                    + mass_rke0104ad
                    + mass_rke01ad01 * 2
                    + fasteners)

    def _calc_mass_rke02ad(self, bs: BarScreen) -> Mass:
        result = Mass(1.85 * bs._screen_ws + 97.28)
        if bs._is_heavy_version:
            result = Mass(result + 2.29)
        return result

    def _calc_mass_rke03ad(self, bs: BarScreen) -> Mass:
        return Mass(0.12 * bs._ws_diff * bs._grate_hs
                    + 2.12 * bs._ws_diff + 0.4967 * bs._grate_hs
                    - 1.32)

    # Тип полотна и прозор игнорируются.
    def _calc_mass_rke04ad(self, bs: BarScreen) -> Mass:
        return Mass(0.5524 * bs._screen_ws + 0.2035)

    def _calc_mass_rke05ad(self, bs: BarScreen) -> Mass:
        return Mass(0.8547 * bs._screen_ws + 1.4571)

    def _calc_mass_rke06ad(self, bs: BarScreen) -> Mass:
        return Mass(0.5218 * bs._screen_ws + 0.6576)

    def _calc_mass_rke07ad(self) -> Mass:
        return Mass(1.08)

    # Масса подставки на пол.
    def _calc_mass_rke08ad(self, bs: BarScreen) -> Mass:
        if bs._stand_hs == 6:
            return Mass(17.81)
        elif bs._stand_hs == 7:
            return Mass(21.47)
        elif bs._stand_hs > 7:
            return Mass(1.8267 * bs._stand_hs + 8.0633)
        raise InputDataError('Невозможно посчитать массу опоры.')

    def _calc_mass_rke09ad(self, bs: BarScreen) -> Mass:
        return Mass(1.7871 * bs._screen_ws - 0.4094)

    def _calc_mass_rke10ad(self, bs: BarScreen) -> Mass:
        if bs._screen_ws <= 10:
            return Mass(0.06 * bs._cover_hs * bs._screen_ws
                        - 0.055 * bs._cover_hs
                        + 0.3167 * bs._screen_ws + 0.3933)
        return Mass(0.03 * bs._cover_hs * bs._screen_ws
                    - 0.0183 * bs._cover_hs
                    + 0.1582 * bs._screen_ws + 0.6052)

    def _calc_mass_rke11ad(self) -> Mass:
        return Mass(0.42)

    def _calc_mass_rke12ad(self) -> Mass:
        return Mass(0.16)

    # TODO: Возможно рамку нужно делать по высоте канала, а не полотна.
    def _calc_mass_rke13ad(self, bs: BarScreen) -> Mass:
        return Mass(0.1811 * bs._grate_hs + 0.49 * bs._screen_ws + 0.7867)

    def _calc_mass_rke18ad(self) -> Mass:
        return Mass(1.13)

    def _calc_mass_rke19ad(self, bs: BarScreen) -> Mass:
        return Mass(0.0161 * bs._grate_hs + 0.2067)

    def _calc_mass_rke00ad05(self) -> Mass:
        return Mass(0.87)

    def _calc_mass_rke00ad09(self) -> Mass:
        return Mass(0.01)

    def _calc_mass_rke00ad13(self) -> Mass:
        return Mass(0.15)

    def _calc_chain_mass_ms56r100(self, bs: BarScreen) -> Mass:
        return Mass(4.18 * bs._chain_length)


class MassSmall(MassCalculator):
    def __init__(self, bs: BarScreen) -> None:
        mass_body = self._calc_mass_body(bs)
        mass_cover = self._calc_mass_cover(bs)
        mass_chain_with_rakes = self._calc_mass_chain_with_rakes(bs)
        mass_discharge = self._calc_mass_discharge(bs)
        mass_top_cover = self._calc_mass_top_cover(bs)
        mass_drive_asm = self._calc_mass_drive_asm(bs)
        mass_ejector = self._calc_mass_ejector(bs)
        mass_frame_loop = self._calc_mass_frame_loop(bs)
        mass_support = self._calc_mass_support(bs)
        mass_side_screen = self._calc_mass_side_screen(bs)

        other = 3.57
        self._mass = Mass(mass_body
                          + mass_cover
                          + mass_chain_with_rakes
                          + mass_discharge
                          + mass_top_cover
                          + mass_drive_asm
                          + mass_ejector
                          + mass_frame_loop
                          + mass_support * 2
                          + mass_side_screen * 2
                          + other)

    # Корпус
    def _calc_mass_body(self, bs: BarScreen) -> Mass:
        mass_frame = self._calc_mass_frame(bs)
        mass_backwall = self._calc_mass_backwall(bs)
        mass_tray = self._calc_mass_tray(bs)
        mass_ski = self._calc_mass_ski()
        mass_lug = self._calc_mass_lug()
        mass_grid = self._calc_mass_grid(bs)

        fasteners = 1.02
        return Mass(mass_frame
                    + mass_backwall
                    + mass_tray
                    + mass_ski * 2
                    + mass_lug * 2
                    + mass_grid
                    + fasteners)

    # Рама
    def _calc_mass_frame(self, bs: BarScreen) -> Mass:
        return Mass(1.95 * bs._screen_ws + 3.18 * bs._screen_hs + 50.02)

    # Стол
    def _calc_mass_backwall(self, bs: BarScreen) -> Mass:
        return Mass(0.2358 * bs._screen_ws * bs._backwall_hs + 1.3529 * bs._screen_ws
                    - 0.0383 * bs._backwall_hs - 0.8492)

    # Лоток
    def _calc_mass_tray(self, bs: BarScreen) -> Mass:
        return Mass(0.7575 * bs._screen_ws - 0.225)

    # Лыжа
    def _calc_mass_ski(self) -> Mass:
        return Mass(0.45)

    # Серьга разрезная
    def _calc_mass_lug(self) -> Mass:
        return Mass(0.42)

    def _calc_mass_grid_balk(self, bs: BarScreen) -> Mass:
        return Mass(0.3825 * bs._screen_ws - 0.565)

    def _calc_mass_grid_screw(self) -> Mass:
        return Mass(0.08)

    # Облицовка
    def _calc_mass_cover(self, bs: BarScreen) -> Mass:
        return Mass(0.1175 * bs._screen_ws * bs._cover_hs + 0.8413 * bs._screen_ws
                    - 0.085 * bs._cover_hs + 0.0125)

    # Масса цепи (1 шт.)
    def _calc_mass_chain_ms28r63(self, bs: BarScreen) -> Mass:
        return Mass(4.5455 * bs._chain_length)

    # Граблина
    def _calc_mass_rake(self, bs: BarScreen) -> Mass:
        return Mass(0.47 * bs._screen_ws - 0.06)

    # Цепь в сборе
    def _calc_mass_chain_with_rakes(self, bs: BarScreen) -> Mass:
        mass_chain = self._calc_mass_chain_ms28r63(bs)
        mass_rake = self._calc_mass_rake(bs)

        fasteners = 0.12
        return Mass(mass_chain * 2
                    + mass_rake * bs._rakes_count
                    + fasteners)

    # Кожух сброса.
    def _calc_mass_discharge(self, bs: BarScreen) -> Mass:
        return Mass(1.3 * bs._screen_ws + 0.75)

    # Верхняя крышка (на петлях)
    def _calc_mass_top_cover(self, bs: BarScreen) -> Mass:
        return Mass(0.2775 * bs._screen_ws + 0.655)

    # Узел привода (в сборе с валом, подшипниками и т.д.)
    def _calc_mass_drive_asm(self, bs: BarScreen) -> Mass:
        return Mass(1.2725 * bs._screen_ws + 15.865)

    # Сбрасыватель
    def _calc_mass_ejector(self, bs: BarScreen) -> Mass:
        return Mass(0.475 * bs._screen_ws + 0.47)

    # Рамка из прутка
    def _calc_mass_frame_loop(self, bs: BarScreen) -> Mass:
        return Mass(0.34 * bs._screen_ws + 0.2883 * bs._grate_hs - 1.195)

    # Опора решетки (на канал)
    def _calc_mass_support(self, bs: BarScreen) -> Mass:
        return Mass(1.07 * bs._stand_hs + 11.91)

    # Защитный экран
    def _calc_mass_side_screen(self, bs: BarScreen) -> Mass:
        return Mass(0.1503 * bs._ws_diff * bs._grate_hs + 0.7608 * bs._ws_diff
                    + 0.4967 * bs._grate_hs - 2.81)
