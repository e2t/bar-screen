"""Расчет параметров грабельной решетки больших типоразмеров."""
from typing import NamedTuple, Optional, Callable, Dict, Tuple
from math import ceil, radians, sin
from dry.allcalc import (
    WidthSerie, HeightSerie, Mass, Distance, Power, VolumeFlowRate, Angle,
    Velocity, Area, GRAV_ACC, InputDataError)


SCREEN_WIDTH_SERIES = range(5, 31)
SCREEN_HEIGHT_SERIES = range(12, 200, 3)
GRATE_HEIGHT_SERIES = range(6, 61, 3)


class FilterProfile(NamedTuple):
    """Профиль фильтровального полотна."""

    name: str            # Название профиля.
    width: Distance      # Ширина профиля, м.
    is_removable: bool   # True - вставное полотно, False - сварное полотно.
    shape_factor: float  # Коэффициент формы.
    calc_mass: Callable[[HeightSerie], Mass]  # Вычиление массы исходя из типоразмера полотна.


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
    # Гидравлические параметры:
    water_flow: Optional[VolumeFlowRate] = None  # Расход воды, м3/с.
    final_level: Optional[Distance] = None       # Уровень после решетки, м.
    tilt_angle: Optional[Angle] = None           # Угол наклона, радианы.


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

    MAX_SMALL_SCREEN_WS = WidthSerie(10)
    MAX_SMALL_SCREEN_HS = HeightSerie(9)
    MAX_BIG_SCREEN_WS = WidthSerie(24)
    MAX_BIG_SCREEN_HS = HeightSerie(30)

    @property
    def designation(self) -> str:
        """Обозначение решетки."""
        return self._designation

    @property
    def mass(self) -> Mass:
        """Масса решетки."""
        return self._mass

    @property
    def is_standard_serie(self) -> bool:
        """Принадлежит ли решетка к стандартному типоряду."""
        return self._is_standard_serie

    @property
    def drive_power(self) -> Optional[Power]:
        """Мощность привода (для стандартных типоразмеров)."""
        return self._drive_power

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

    def __init__(self, input_data: InputData):
        """Конструктор и одновременно расчет решетки."""
        self._input_data = input_data
        self._screen_ws: WidthSerie = self._input_data.screen_ws or self._calc_screen_ws()
        self._screen_hs: HeightSerie = self._input_data.screen_hs or self._calc_screen_hs()

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

        max_diff_screen_and_grate_hs = 9
        if (self._screen_hs - self._grate_hs) < -max_diff_screen_and_grate_hs:
            raise InputDataError('Полотно больше решетки более чем на {:d} типоразмеров.'.format(
                max_diff_screen_and_grate_hs))
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

        if self._input_data.tilt_angle is not None:
            if not radians(45) <= self._input_data.tilt_angle <= radians(90):
                raise InputDataError('Недопустимый угол. Стандартный: 80+-5.')

        self._ws_diff = self._calc_ws_diff()
        self._backwall_hs = self._calc_backwall_hs()
        self._cover_hs = self._calc_cover_hs()
        self._chain_length = self._calc_chain_length()
        self._rakes_count = self._calc_rakes_count()
        self._covers_count = self._calc_covers_count()
        self._mass_rke010101ad = self._calc_mass_rke010101ad()
        self._mass_rke010111ad = self._calc_mass_rke010111ad()
        self._mass_rke010102ad = self._calc_mass_rke010102ad()
        self._mass_rke010103ad = self._calc_mass_rke010103ad()
        self._mass_rke010104ad = self._calc_mass_rke010104ad()
        self._mass_rke010105ad = self._calc_mass_rke010105ad()
        self._mass_rke010107ad = self._calc_mass_rke010107ad()
        self._mass_rke010108ad = self._calc_mass_rke010108ad()
        self._mass_rke010109ad = self._calc_mass_rke010109ad()
        self._mass_rke0101ad02 = self._calc_mass_rke0101ad02()
        self._fasteners_mass_rke0101ad = self._calc_fasteners_mass_rke0101ad()
        self._mass_rke0101ad = self._calc_mass_rke0101ad()
        self._mass_rke0102ad = self._calc_mass_rke0102ad()
        self._mass_rke010301ad = self._calc_mass_rke010301ad()
        self._mass_rke0103ad01 = self._calc_mass_rke0103ad01()
        self._mass_rke0103ad02 = self._calc_mass_rke0103ad02()
        self._mass_rke0103ad = self._calc_mass_rke0103ad()
        self._mass_rke0104ad = self._calc_mass_rke0104ad()
        self._mass_rke01ad01 = self._calc_mass_rke01ad01()
        self._fasteners_mass_rke01ad = self._calc_fasteners_mass_rke01ad()
        self._mass_rke01ad = self._calc_mass_rke01ad()
        self._mass_rke02ad = self._calc_mass_rke02ad()
        self._mass_rke03ad = self._calc_mass_rke03ad()
        self._mass_rke04ad = self._calc_mass_rke04ad()
        self._mass_rke05ad = self._calc_mass_rke05ad()
        self._mass_rke06ad = self._calc_mass_rke06ad()
        self._mass_rke07ad = self._calc_mass_rke07ad()
        self._mass_rke08ad = self._calc_mass_rke08ad()
        self._mass_rke09ad = self._calc_mass_rke09ad()
        self._mass_rke10ad = self._calc_mass_rke10ad()
        self._mass_rke11ad = self._calc_mass_rke11ad()
        self._mass_rke12ad = self._calc_mass_rke12ad()
        self._mass_rke13ad = self._calc_mass_rke13ad()
        self._mass_rke18ad = self._calc_mass_rke18ad()
        self._mass_rke19ad = self._calc_mass_rke19ad()
        self._mass_rke00ad05 = self._calc_mass_rke00ad05()
        self._mass_rke00ad09 = self._calc_mass_rke00ad09()
        self._mass_rke00ad13 = self._calc_mass_rke00ad13()
        self._chain_mass_ms56r100 = self._calc_chain_mass_ms56r100()
        self._fasteners_mass_rke00ad = self._calc_fasteners_mass_rke00ad()
        self._mass = self._calc_mass_rke00ad()
        self._designation = self._create_designation()
        self._is_standard_serie = self._check_standard_serie()
        self._drive_power = self._calc_drive_power()

        self._screen_length = self._calc_screen_length()
        self._fp_length = self._calc_fp_length()
        self._discharge_width = self._calc_discharge_width()

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
            min_grate_height, can_be_equal = calc_by(self._input_data.final_level)
        else:
            min_grate_height, can_be_equal = calc_by(None)
        for i in GRATE_HEIGHT_SERIES:
            grate_height = self._calc_inner_screen_height(HeightSerie(i))
            if grate_height > min_grate_height or (
                    can_be_equal and grate_height == min_grate_height):
                return HeightSerie(i)
        raise InputDataError('Не удается подобрать высоту полотна из стандартного ряда.')

    def _calc_screen_length(self) -> Distance:
        return Distance((100 * self._screen_hs + 1765) / 1e3)

    def _calc_fp_length(self) -> Distance:
        if self._input_data.fp.is_removable:
            return Distance((100 * self._grate_hs - 175) / 1e3)
        return Distance((100 * self._grate_hs - 106) / 1e3)

    def _calc_discharge_height(self) -> Distance:
        return Distance(self._discharge_full_height - self._input_data.channel_height)

    @staticmethod
    def _calc_discharge_full_height(screen_hs: HeightSerie) -> Distance:
        return Distance(round((98.4667 * screen_hs + 961.4) / 1e3, 3))

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
            return Distance(0.264567 * a2**(1 / 3)
                            - 0.000576096 * b1 / c2**(1 / 3)
                            - 0.333333 * self._b)
        return None

    def _calc_relative_flow_area(self, blinding: float) -> float:
        return self._input_data.gap / (self._input_data.gap + self._input_data.fp.width) \
            - blinding * self._input_data.gap / (self._input_data.fp.width + self._input_data.gap)

    # В расчете не были указаны единицы измерения (будто это коэффициент),
    # но по всему видно, что это должна быть длина.
    def _calc_blinding_factor(self, relative_flow_area: float) -> float:
        return self._input_data.gap - relative_flow_area \
            * (self._input_data.gap + self._input_data.fp.width)

    # Неизвестны единицы измерения и вообще суть параметра.
    def _calc_d_hydraulic(self, blinding: float, blinding_factor: float) -> Optional[float]:
        if self._input_data.water_flow is not None and self._input_data.tilt_angle is not None:
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

    # Ширина сброса.
    def _calc_discharge_width(self) -> Distance:
        return Distance((100 * self._screen_ws - 129) / 1e3)

    # Высота просвета решетки.
    # ВНИМАНИЕ: Не учитывается высота лотка.
    @staticmethod
    def _calc_inner_screen_height(grate_hs: HeightSerie) -> Distance:
        return Distance(round((98.481 * grate_hs - 173.215) / 1e3, 3))

    # Подбор мощности привода.
    def _calc_drive_power(self) -> Optional[Power]:
        if self._screen_ws <= self.MAX_SMALL_SCREEN_WS and \
                self._screen_hs <= self.MAX_SMALL_SCREEN_HS:
            return Power(370)
        if self._screen_ws <= self.MAX_BIG_SCREEN_WS:
            if self._screen_hs <= self.MAX_BIG_SCREEN_HS:
                return Power(750)
            if int(self._screen_ws) + int(self._screen_hs) < 54:
                return Power(1100)
        return None

    # Проверка, входит ли решетка в стандартный типоряд.
    def _check_standard_serie(self) -> bool:
        return (self._screen_ws <= self.MAX_BIG_SCREEN_WS) and \
            (self._screen_hs <= self.MAX_BIG_SCREEN_HS)

    # Обозначение решетки.
    def _create_designation(self) -> str:
        dsg = [f'РКЭ {self._screen_ws:02d}{self._screen_hs:02d}']
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
        dsg.append(f'.{self._input_data.fp.name}.{self._input_data.gap * 1000:g}')
        return ''.join(dsg)

    def _calc_ws_diff(self) -> WidthSerie:
        return WidthSerie(self._channel_ws - self._screen_ws)

    def _calc_stand_height(self) -> Distance:
        return Distance(self._screen_pivot_height - self._input_data.channel_height)

    def _calc_mass_rke00ad(self) -> Mass:
        return Mass(self._mass_rke01ad * 1
                    + self._mass_rke02ad * 1
                    + self._mass_rke03ad * 2
                    + self._mass_rke04ad * self._rakes_count
                    + self._mass_rke05ad * 1
                    + self._mass_rke06ad * 1
                    + self._mass_rke07ad * 1
                    + self._mass_rke08ad * 2
                    + self._mass_rke09ad * 1
                    + self._mass_rke10ad * self._covers_count
                    + self._mass_rke11ad * 2
                    + self._mass_rke12ad * 2
                    + self._mass_rke13ad * 1
                    + self._mass_rke18ad * 2
                    + self._mass_rke19ad * 1
                    + self._mass_rke00ad05 * 4
                    + self._mass_rke00ad09 * 2
                    + self._mass_rke00ad13 * 2
                    + self._chain_mass_ms56r100 * 2
                    + self._fasteners_mass_rke00ad)

    def _calc_channel_ws(self) -> WidthSerie:
        return WidthSerie(round((self._input_data.channel_width - 0.1) / 0.1))

    def _calc_backwall_hs(self) -> HeightSerie:
        return HeightSerie(self._screen_hs - self._grate_hs + 10)

    def _calc_mass_rke0102ad(self) -> Mass:
        return Mass(1.5024 * self._screen_ws - 0.1065)

    def _calc_mass_rke010301ad(self) -> Mass:
        return Mass(0.6919 * self._screen_ws - 0.7431)

    def _calc_inner_screen_width(self) -> Distance:
        return Distance(0.1 * self._screen_ws - 0.132)

    # Примерное (теоретическое) количество, конструктор может менять шаг.
    def _calc_profiles_count(self) -> int:
        return ceil((self._inner_screen_width - self._input_data.gap)
                    / (self._input_data.fp.width + self._input_data.gap))

    def _calc_mass_rke0103ad01(self) -> Mass:
        return self._input_data.fp.calc_mass(self._grate_hs)

    def _calc_mass_rke0103ad02(self) -> Mass:
        return Mass(0.16)

    def _calc_mass_rke0103ad(self) -> Mass:
        return Mass(self._mass_rke010301ad * 2
                    + self._mass_rke0103ad01 * self._profiles_count
                    + self._mass_rke0103ad02 * 4)

    def _calc_mass_rke0104ad(self) -> Mass:
        return Mass(0.2886 * self._backwall_hs * self._screen_ws
                    - 0.2754 * self._backwall_hs
                    + 2.2173 * self._screen_ws - 2.6036)

    def _calc_mass_rke01ad01(self) -> Mass:
        return Mass(0.62)

    def _calc_fasteners_mass_rke01ad(self) -> Mass:
        return Mass(1.07)

    def _calc_mass_rke010101ad(self) -> Mass:
        return Mass(2.7233 * self._screen_hs + 46.32)

    def _calc_mass_rke010111ad(self) -> Mass:
        return Mass(2.7467 * self._screen_hs + 46.03)

    def _calc_mass_rke010102ad(self) -> Mass:
        return Mass(0.5963 * self._screen_ws - 0.3838)

    def _calc_mass_rke010103ad(self) -> Mass:
        return Mass(0.5881 * self._screen_ws + 0.4531)

    def _calc_mass_rke010104ad(self) -> Mass:
        return Mass(0.8544 * self._screen_ws - 0.1806)

    def _calc_mass_rke010105ad(self) -> Mass:
        return Mass(0.6313 * self._screen_ws + 0.1013)

    def _calc_mass_rke010107ad(self) -> Mass:
        return Mass(0.605 * self._ws_diff + 3.36)

    def _calc_mass_rke010108ad(self) -> Mass:
        return Mass(0.445 * self._screen_ws - 0.245)

    def _calc_mass_rke010109ad(self) -> Mass:
        if self._screen_ws <= 10:
            return Mass(0.136 * self._screen_ws + 0.13)
        return Mass(0.1358 * self._screen_ws + 0.2758)

    def _calc_mass_rke0101ad02(self) -> Mass:
        return Mass(0.42)

    def _calc_fasteners_mass_rke0101ad(self) -> Mass:
        return Mass(2.22)

    def _calc_mass_rke0101ad(self) -> Mass:
        return Mass(self._mass_rke010101ad * 1
                    + self._mass_rke010111ad * 1
                    + self._mass_rke010102ad * 2
                    + self._mass_rke010103ad * 1
                    + self._mass_rke010104ad * 1
                    + self._mass_rke010105ad * 1
                    + self._mass_rke010107ad * 2
                    + self._mass_rke010108ad * 1
                    + self._mass_rke010109ad * 1
                    + self._mass_rke0101ad02 * 2
                    + self._fasteners_mass_rke0101ad)

    def _calc_mass_rke01ad(self) -> Mass:
        return Mass(self._mass_rke0101ad * 1
                    + self._mass_rke0102ad * 1
                    + self._mass_rke0103ad * 1
                    + self._mass_rke0104ad * 1
                    + self._mass_rke01ad01 * 2
                    + self._fasteners_mass_rke01ad)

    def _calc_mass_rke02ad(self) -> Mass:
        result = Mass(1.85 * self._screen_ws + 97.28)
        if self._is_heavy_version:
            result = Mass(result + 2.29)
        return result

    def _calc_mass_rke03ad(self) -> Mass:
        return Mass(0.12 * self._ws_diff * self._grate_hs
                    + 2.12 * self._ws_diff + 0.4967 * self._grate_hs
                    - 1.32)

    # Тип полотна и прозор игнорируются.
    def _calc_mass_rke04ad(self) -> Mass:
        return Mass(0.5524 * self._screen_ws + 0.2035)

    def _calc_chain_length(self) -> Distance:
        small_chain_lengths = {6: Distance(3.528),
                               7: Distance(4.158),
                               9: Distance(4.662)}
        if self._screen_hs < 12:
            return small_chain_lengths[self._screen_hs]
        return Distance(0.2 * self._screen_hs + 3.2)

    def _calc_rakes_count(self) -> int:
        return round(self._chain_length / 0.825)

    def _calc_mass_rke05ad(self) -> Mass:
        return Mass(0.8547 * self._screen_ws + 1.4571)

    def _calc_mass_rke06ad(self) -> Mass:
        return Mass(0.5218 * self._screen_ws + 0.6576)

    def _calc_mass_rke07ad(self) -> Mass:
        return Mass(1.08)

    def _calc_screen_pivot_height(self) -> Distance:
        return Distance(0.0985 * self._screen_hs + 1.0299)

    # Типоразмер подставки на пол.
    def _calc_stand_hs(self) -> HeightSerie:
        if 0.4535 <= self._stand_height < 0.6035:
            return HeightSerie(6)
        elif 0.6035 <= self._stand_height < 0.8535:
            return HeightSerie(7)
        elif self._stand_height >= 0.8535:
            return HeightSerie(round((self._stand_height - 1.0035) / 0.3) * 3 + 10)
        raise InputDataError('Слишком маленькая опора.')

    # Масса подставки на пол.
    def _calc_mass_rke08ad(self) -> Mass:
        if self._stand_hs == 6:
            return Mass(17.81)
        elif self._stand_hs == 7:
            return Mass(21.47)
        elif self._stand_hs > 7:
            return Mass(1.8267 * self._stand_hs + 8.0633)
        raise InputDataError('Невозможно посчитать массу опоры.')

    def _calc_mass_rke09ad(self) -> Mass:
        return Mass(1.7871 * self._screen_ws - 0.4094)

    def _calc_covers_count(self) -> int:
        if self._screen_ws <= 10:
            return 2
        return 4

    def _calc_cover_hs(self) -> HeightSerie:
        return min(self._backwall_hs, self._stand_hs)

    def _calc_mass_rke10ad(self) -> Mass:
        if self._screen_ws <= 10:
            return Mass(0.06 * self._cover_hs * self._screen_ws
                        - 0.055 * self._cover_hs
                        + 0.3167 * self._screen_ws + 0.3933)
        return Mass(0.03 * self._cover_hs * self._screen_ws
                    - 0.0183 * self._cover_hs
                    + 0.1582 * self._screen_ws + 0.6052)

    def _calc_mass_rke11ad(self) -> Mass:
        return Mass(0.42)

    def _calc_mass_rke12ad(self) -> Mass:
        return Mass(0.16)

    # TODO: Возможно рамку нужно делать по высоте канала, а не полотна.
    def _calc_mass_rke13ad(self) -> Mass:
        return Mass(0.1811 * self._grate_hs + 0.49 * self._screen_ws + 0.7867)

    def _calc_mass_rke18ad(self) -> Mass:
        return Mass(1.13)

    def _calc_mass_rke19ad(self) -> Mass:
        return Mass(0.0161 * self._grate_hs + 0.2067)

    def _calc_mass_rke00ad05(self) -> Mass:
        return Mass(0.87)

    def _calc_mass_rke00ad09(self) -> Mass:
        return Mass(0.01)

    def _calc_mass_rke00ad13(self) -> Mass:
        return Mass(0.15)

    def _calc_chain_mass_ms56r100(self) -> Mass:
        return Mass(4.18 * self._chain_length)

    def _calc_fasteners_mass_rke00ad(self) -> Mass:
        return Mass(1.24)
