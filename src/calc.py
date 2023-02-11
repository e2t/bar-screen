from dataclasses import dataclass
from math import ceil, floor, sin
from typing import Callable
from abc import ABC, abstractmethod

from dry.basecalc import BaseCalc, CalcError
from dry.comparablefloat import ComparableFloat as Cf
from dry.l10n import AddMsgL10n
from dry.mathutils import GRAV_ACC, mround
from dry.measurements import (degree, kg, kw, meter, mm, nm, rpm, to_degree,
                              to_mm, to_kw, to_rpm)

from captions import ErrorMsg, Output


@dataclass(frozen=True)
class Drive:
    designation: str
    weight: float
    power: float
    torque: float
    speed: float


@dataclass(frozen=True)
class Spring:
    designation: str
    r: float


@dataclass(frozen=True)
class Filter:
    name: str
    width: float
    is_removable: bool
    shape_factor: float
    calc_mass: Callable[[int], float]


@dataclass(frozen=True)
class InputData:
    width: float
    depth: float
    mindrop: float
    gap: float
    ws: int | None
    hs: int | None
    gs: int | None
    fp: Filter
    flow: float | None
    level: float | None
    angle: float


# Расчетные гидравлические параметры, зависящие от загрязнения полотна.
@dataclass(slots=True)
class Hydraulic:
    relative_flow_area: float = float(0)
    blinding_factor: float = float(0)
    velocity_in_gap: float | None = None
    level_diff: float | None = None
    start_level: float | None = None
    upstream_flow_velocity: float | None = None


WSDATA = range(5, 31)
HSDATA = range(3, 172, 3)
GSDATA = range(6, 61, 3)
NOMINAL_GAPS = (mm(5), mm(6), mm(8), mm(10), mm(12), mm(15), mm(16), mm(20),
                mm(25), mm(30), mm(40), mm(50), mm(60), mm(70), mm(80), mm(90),
                mm(100))
DEFAULT_DISCHARGE_HEIGHT = mm(890)

DEFAULT_TILT_ANGLE = degree(80)
ANGLE_DIFF = degree(5)
MIN_TITLE_ANGLE = DEFAULT_TILT_ANGLE - ANGLE_DIFF
MAX_TITLE_ANGLE = DEFAULT_TILT_ANGLE + ANGLE_DIFF

FILTERS = (
    Filter(name='3999', width=mm(9.5), is_removable=False, shape_factor=1.5,
           calc_mass=lambda gs: 0.1167 * gs - 0.13),
    Filter(name='341', width=mm(5.5), is_removable=False, shape_factor=0.95,
           calc_mass=lambda gs: 0.0939 * gs - 0.1067),
    Filter(name='777', width=mm(7.8), is_removable=False, shape_factor=0.95,
           calc_mass=lambda gs: 0.1887 * gs - 0.194),
    Filter(name='1492', width=mm(8), is_removable=True, shape_factor=0.95,
           calc_mass=lambda gs: 0.2481 * gs - 0.4829),
    Filter(name='6x30', width=mm(6), is_removable=False, shape_factor=2.42,
           calc_mass=lambda gs: 0.144 * gs - 0.158),
    Filter(name='6x60', width=mm(6), is_removable=True, shape_factor=2.42,
           calc_mass=lambda gs: 0.2881 * gs - 0.5529),
)
DRIVE_UNITS_SMALL = {
    Drive(designation='SK 12080 AZBHVL-63LP/4',
          weight=kg(35),
          power=kw(0.18),
          torque=nm(244),
          speed=rpm(4.8)): Spring(designation='1L38151 IMPEX-READY s.c.',
                                  r=16.3e3),
}
DRIVE_UNITS_BIG = {
    Drive(designation='SK 32100 AZBHVL-71LP/4',
          weight=kg(64),
          power=kw(0.37),
          torque=nm(826),
          speed=rpm(2.2)): Spring(designation='1S51151 IMPEX-READY s.c.',
                                  r=60e3),
    Drive(designation='SK 32100 AZBHVL-80LP/4',
          weight=kg(67),
          power=kw(0.75),
          torque=nm(1663),
          speed=rpm(2.2)): Spring(designation='3S51126 IMPEX-READY s.c.',
                                  r=154e3),
    Drive(designation='SK 43125 AZBHVL-90SP/4',
          weight=kg(129),
          power=kw(1.1),
          torque=nm(3052),
          speed=rpm(2.4)): Spring(designation='4S63151 IMPEX-READY s.c.',
                                  r=396e3),
    Drive(designation='SK 9053.1 AZBH-90SP/4',
          weight=kg(214),
          power=kw(1.1),
          torque=nm(4265),
          speed=rpm(2.5)): Spring(designation='4S63151 IMPEX-READY s.c.',
                                  r=801e3)
}

SMALL_CHAINS = {
    3: meter(3.528),
    6: meter(4.032),
    9: meter(4.662),
    12: meter(5.292),
    15: meter(5.922),
}

#  Шаг цепи больших решеток.
STEP_CHAIN = mm(100)
STEP_CHAIN_Y = sin(DEFAULT_TILT_ANGLE) * STEP_CHAIN

POLLUTIONS = (0.1, 0.2, 0.3, 0.4)
MAX_DIFF_SCREEN_AND_GRATE_HS = 9


# Типоразмер расчитывается по конструкции больших решеток.
# Малые решетки подгоняются под типоразмер.
def calc_full_drop(hs: int) -> float:
    return round(STEP_CHAIN_Y * hs + 0.96109, 3)


FULL_DROP_HEIGHTS = {i: calc_full_drop(i) for i in HSDATA}


class BarScreen(BaseCalc):
    def __init__(self, inpdata: InputData, adderror: AddMsgL10n) -> None:
        super().__init__(adderror)

        if Cf(inpdata.width) <= Cf(0):
            self.raise_error(ErrorMsg.WIDTH)
        if Cf(inpdata.depth) <= Cf(0):
            self.raise_error(ErrorMsg.DEPTH)
        if Cf(inpdata.mindrop) <= Cf(0):
            self.raise_error(ErrorMsg.DROP)
        if inpdata.flow:
            if Cf(inpdata.flow) <= Cf(0):
                self.raise_error(ErrorMsg.FLOW)
        if inpdata.level:
            if Cf(inpdata.level) <= Cf(0):
                self.raise_error(ErrorMsg.LEVEL)
        if not Cf(MIN_TITLE_ANGLE) <= Cf(inpdata.angle) <= Cf(MAX_TITLE_ANGLE):
            self.raise_error(ErrorMsg.ANGLE_DIAPASON,
                             to_degree(DEFAULT_TILT_ANGLE),
                             to_degree(ANGLE_DIFF))
        self.depth = inpdata.depth
        self.mindrop = inpdata.mindrop
        self.fp = inpdata.fp
        self.nominap_gap = inpdata.gap
        self.water_flow = inpdata.flow
        self.final_level = inpdata.level
        self.angle = inpdata.angle
        self.channel_width = inpdata.width

        self.ws = inpdata.ws or floor((inpdata.width - mm(100)) * 10)
        if self.ws < WSDATA[0]:
            self.ws = WSDATA[0]

        self.hs = inpdata.hs or self.calc_optimal_hs()
        self.issmall = (self.ws <= 7 and self.hs <= 15) or \
                       (self.ws <= 9 and self.hs <= 12)
        self.full_drop = FULL_DROP_HEIGHTS[self.hs]
        self.drop = self.full_drop - self.depth
        if inpdata.hs and Cf(self.drop) < Cf(self.mindrop):
            self.raise_error(ErrorMsg.MINDROP)
        self.inner_width = 0.1 * self.ws - (0.128 if self.issmall else 0.132)
        self.fpcount = self.calc_fpcount()
        self.step = (self.inner_width + self.fp.width) / self.fpcount
        self.gap = self.step - self.fp.width

        # Гидравлический расчет:
        if self.final_level:
            self.b = 2 * self.final_level
            self.c = float(self.final_level**2)
        self.efficiency = self.gap / (self.gap + self.fp.width)
        self.hydraulics = {}
        for i in POLLUTIONS:
            self.hydraulics[i] = self.calc_hydraulic(i)

        self.gs = inpdata.gs or self.calc_optimal_gs()
        if self.hs - self.gs < -MAX_DIFF_SCREEN_AND_GRATE_HS:
            self.raise_error(ErrorMsg.DIFF_HS_GS)

        self.channel_ws = round((self.channel_width - 0.1) / 0.1)
        if self.channel_ws - self.ws < 0:
            self.raise_error(ErrorMsg.TOONARROW)
        if self.channel_ws - self.ws > 2:
            self.raise_error(ErrorMsg.TOOWIDE)

        self.is_heavy = self.hs >= 21
        self.pivot_height = 0.0985 * self.hs + 1.0299
        self.stand_height = self.pivot_height - self.depth
        self.stand_hs = self.calc_stand_hs()

        self.fpcount = ceil((self.inner_width - self.gap)
                            / (self.fp.width + self.gap))
        if self.fpcount < 2:
            self.raise_error(ErrorMsg.TOOBIGGAP)

        self.inner_height = self.calc_inner_screen_height(self.gs)
        if self.final_level:
            if Cf(self.final_level) >= Cf(self.depth):
                self.raise_error(ErrorMsg.FINAL_ABOVE_CHN)
            if Cf(self.final_level) >= Cf(self.inner_height):
                self.raise_error(ErrorMsg.FINAL_ABOVE_GS)

        if self.issmall:
            self.chain_length = SMALL_CHAINS[self.hs]
            self.length = self.chain_length / 2 + 0.38
        else:
            self.chain_length = 0.2 * self.hs + 3.2
            self.length = 0.1 * self.hs + 1.765

        self.rake_count = round(self.chain_length / 0.825)
        self.is_standard_serie = self.ws <= 24 and self.hs <= 30
        self.mintorque = self.calc_min_torque()
        self.drive, self.spring, self.is_drive_passed = self.calc_drive()
        if self.spring:
            self.spring_preload = self.calc_spring_load()

        if inpdata.fp.is_removable:
            self.fplength = 0.1 * self.gs - 0.175
        else:
            self.fplength = 0.1 * self.gs - 0.106

        self.drop_width = 0.1 * self.ws - 0.129
        self.wsdiff = self.channel_ws - self.ws
        self.backwall_hs = self.hs - self.gs + 10
        self.coverhs = min(self.backwall_hs, self.stand_hs)
        self.covercount = 2 if self.ws <= 10 else 4

        if self.issmall:
            self.weight = MassSmall(self).mass
        else:
            self.weight = MassLarge(self).mass

    def calc_optimal_hs(self) -> int:
        min_full_drop = self.depth + self.mindrop
        for hs, full_drop in FULL_DROP_HEIGHTS.items():
            if Cf(full_drop) >= Cf(min_full_drop):
                return hs
        self.adderror(ErrorMsg.TOOHIGH_HS)
        raise CalcError()

    def calc_fpcount(self) -> int:
        nominap_step = self.nominap_gap + self.fp.width
        return floor((self.inner_width + self.fp.width) / nominap_step)

    def calc_hydraulic(self, pollution: float) -> Hydraulic:
        res = Hydraulic()
        res.relative_flow_area = self.gap \
            / (self.gap + self.fp.width) - pollution * self.gap \
            / (self.fp.width + self.gap)
        res.blinding_factor = self.gap - res.relative_flow_area \
            * (self.gap + self.fp.width)
        if self.water_flow:
            d = float(
                ((self.water_flow / self.inner_width
                 / (self.efficiency * (1 - pollution)))**2
                 / (2 * GRAV_ACC)) * sin(self.angle) * self.fp.shape_factor
                * ((self.fp.width + res.blinding_factor)
                   / (self.gap - res.blinding_factor))**(4 / 3))
            if self.final_level:
                res.level_diff = self.calc_level_diff(self.b, self.c, d)
                res.start_level = self.final_level + res.level_diff
                res.upstream_flow_velocity = self.water_flow \
                    / (self.channel_width * res.start_level)
                res.velocity_in_gap = self.water_flow \
                    / (self.inner_width * res.start_level * self.efficiency
                       * (1 - pollution))
        return res

    @staticmethod
    def calc_level_diff(b: float, c: float, d: float) -> float:
        a1 = float(27 * d**2 + 18 * b * c * d + 4 * c**3 - 4 * b**3 * d
                   - b**2 * c**2)
        a2 = float(27 * d + 9 * b * c - 2 * b**3 + 5.19615 * a1**0.5)
        b1 = float(2187 * c - 729 * b**2)
        c1 = float(27 * d**2 + 18 * b * c * d + 4 * c**3 - 4 * b**3 * d
                   - b**2 * c**2)
        c2 = float(27 * d + 9 * b * c - 2 * b**3 + 5.19615 * c1**0.5)
        return float(0.264567 * a2**(1 / 3) - 0.000576096 * b1 / c2**(1 / 3)
                     - 0.333333 * b)

    def calc_optimal_gs(self) -> int:
        start_levels = tuple(i.start_level for i in self.hydraulics.values()
                             if i.start_level)
        some_level = max(start_levels) if start_levels else self.final_level
        if some_level and Cf(some_level) < Cf(self.depth):
            min_grate_height = some_level
            can_be_equal = False
        else:
            min_grate_height = self.depth
            can_be_equal = True
        for i in GSDATA:
            grate_height = self.calc_inner_screen_height(i)
            if Cf(grate_height) > Cf(min_grate_height) or (
                    can_be_equal and Cf(grate_height) == Cf(min_grate_height)):
                return i
        self.adderror(ErrorMsg.TOOHIGH_GS)
        raise CalcError()

    # ВНИМАНИЕ: Не учитывается высота лотка.
    def calc_inner_screen_height(self, gs: int) -> float:
        return round((98.481 * gs - 173.215) / 1000, 3)

    def calc_stand_hs(self) -> int:
        if Cf(0.4535) <= Cf(self.stand_height) < Cf(0.6035):
            return 6
        if Cf(0.6035) <= Cf(self.stand_height) < Cf(0.8535):
            return 7
        if Cf(self.stand_height) >= Cf(0.8535):
            return round((self.stand_height - 1.0035) / 0.3) * 3 + 10
        self.adderror(ErrorMsg.TOOSMALL)
        raise CalcError()

    def calc_min_torque(self) -> float:
        # радиус дел. окружности звездочки
        lever_arm = mm(63) if self.issmall else mm(130.655)

        # From Luk'yanenko
        specific_garbage_load = 90  # kg/m
        power_margin = 1.2
        rake_pitch = 0.8
        return specific_garbage_load * GRAV_ACC * power_margin * lever_arm \
            * ceil(self.chain_length / rake_pitch / 2) * (self.ws / 10 - 0.126)

    def calc_drive(self) -> tuple[Drive | None, Spring | None, bool]:
        drives = DRIVE_UNITS_SMALL if self.issmall else DRIVE_UNITS_BIG
        for drive, spring in drives.items():
            if Cf(self.mintorque) <= Cf(drive.torque):
                return drive, spring, True

        # From Luk'yanenko
        # before it was: return None
        return *next(reversed(drives.items())), False

    def calc_spring_load(self) -> float:
        assert self.spring
        # From Luk'yanenko
        max_delta_sensor = mm(9.5)
        sensor_delta = mm(15.5)
        axes_distance = 0.2 if self.issmall else 0.195
        max_spring_load = self.mintorque / axes_distance * 0.9
        spring_preload = mround(
            max_spring_load / self.spring.r - sensor_delta, mm(0.5))
        if not self.is_drive_passed \
                and Cf(spring_preload) > Cf(max_delta_sensor):
            return max_delta_sensor
        return spring_preload


def run_calc(inpdata: InputData, adderror: AddMsgL10n, addline: AddMsgL10n,
             addcolumn: list[AddMsgL10n]) -> None:
    try:
        scr = BarScreen(inpdata, adderror)
    except CalcError:
        return
    create_result(scr, addline, addcolumn)


def create_result(scr: BarScreen, addline: AddMsgL10n,
                  addcolumn: list[AddMsgL10n]) -> None:
    if scr.channel_ws != scr.ws or scr.gs != scr.hs:
        add1 = f'{scr.channel_ws:02d}' if scr.channel_ws != scr.ws else '00'
        add2 = f'{scr.gs:02d}' if scr.gs != scr.hs else '00'
        add_dsg = f'({add1}{add2})'
    else:
        add_dsg = ''
    addline(Output.SMALLDSG if scr.issmall else Output.BIGDSG,
            scr.ws, scr.hs, add_dsg, scr.fp.name, to_mm(scr.nominap_gap))
    addline(Output.WEIGHT if scr.is_standard_serie else Output.WEIGHT_APPROX,
            round(scr.weight))
    if scr.drive:
        addline(Output.DRIVE, scr.drive.designation, to_kw(scr.drive.power),
                scr.drive.torque, to_rpm(scr.drive.speed))
    addline('')
    prefix = '≈' if scr.issmall else ''
    addline(Output.INNER_WIDTH, round(to_mm(scr.inner_width)))
    addline(Output.INNER_HEIGHT, round(to_mm(scr.inner_height)))
    addline(Output.SCR_LENGTH, round(to_mm(scr.length)))
    addline(Output.CHAIN_LENGTH, round(to_mm(scr.chain_length)))
    addline(Output.FP_LENGTH, round(to_mm(scr.fplength)))
    addline(Output.FP_COUNT, scr.fpcount)
    addline(Output.RAKE_COUNT, scr.rake_count)
    addline(Output.DROP_WIDTH, round(to_mm(scr.drop_width)))
    addline(Output.DROP_ABOVE_TOP, prefix, round(to_mm(scr.drop)))
    addline(Output.DROP_ABOVE_BOTTOM, prefix, round(to_mm(scr.full_drop)))
    addline('')
    addline(Output.MINTORQUE, round(scr.mintorque))
    addline(Output.GAP, round(to_mm(scr.gap), 2))
    if scr.spring:
        addline(Output.SPRING, scr.spring.designation,
                to_mm(scr.spring_preload))
    addline('')

    for index, i in enumerate(POLLUTIONS):
        addcol = addcolumn[index]
        poll = round(i * 100)

        # POLL
        addcol(f'{poll:n}%')

        # GAPSPEED
        x = scr.hydraulics[i].velocity_in_gap
        if x:
            addcol(Output.HYDR_MS, round(x, 2))
        else:
            addcol('')

        # AREA
        addcol(f'{round(scr.hydraulics[i].relative_flow_area, 2):n}')

        # BFACTOR
        addcol(f'{round(scr.hydraulics[i].blinding_factor * 1000, 1):n}')

        # DIFF
        x = scr.hydraulics[i].level_diff
        if x:
            addcol(Output.HYDR_MM, round(to_mm(x)))
        else:
            addcol('')

        # FRONT
        x = scr.hydraulics[i].start_level
        if x:
            addcol(Output.HYDR_MM, round(to_mm(x)))
            if Cf(x) > Cf(scr.depth):
                addline(Output.WARNING_OVERFLOW, poll)
            diff = round(x - scr.inner_height, 3)
            if Cf(diff) >= Cf(0):
                addline(Output.WARNING_DIFF, poll, round(to_mm(diff)))
        else:
            addcol('')

        # CHNSPEED
        x = scr.hydraulics[i].upstream_flow_velocity
        if x:
            addcol(Output.HYDR_MS, round(x, 2))
        else:
            addcol('')


class MassCalculator(ABC):
    def __init__(self, scr: BarScreen) -> None:
        self.scr = scr
        self.mass_grid = self.calc_mass_grid()
        self.mass: float = 0

    def calc_mass_grid(self) -> float:
        mass_grid_balk = self.calc_mass_grid_balk()
        mass_fp = self.scr.fp.calc_mass(self.scr.gs)
        mass_grid_screw = self.calc_mass_grid_screw()
        return mass_grid_balk * 2 + mass_fp * self.scr.fpcount \
            + mass_grid_screw * 4

    @abstractmethod
    def calc_mass_grid_balk(self) -> float:
        pass

    @abstractmethod
    def calc_mass_grid_screw(self) -> float:
        pass


class MassLarge(MassCalculator):
    def __init__(self, scr: BarScreen) -> None:
        super().__init__(scr)

        fasteners = 1.24
        mass_rke07ad = 1.08
        mass_rke11ad = 0.42
        mass_rke12ad = 0.16
        mass_rke18ad = 1.13
        mass_rke00ad05 = 0.87
        mass_rke00ad09 = 0.01
        mass_rke00ad13 = 0.15

        self.mass = self.calc_mass_rke01ad() \
            + self.calc_mass_rke02ad() \
            + self.calc_mass_rke03ad() * 2 \
            + self.calc_mass_rke04ad() * self.scr.rake_count \
            + self.calc_mass_rke05ad() \
            + self.calc_mass_rke06ad() \
            + mass_rke07ad \
            + self.calc_mass_rke08ad() * 2 \
            + self.calc_mass_rke09ad() \
            + self.calc_mass_rke10ad() * self.scr.covercount \
            + mass_rke11ad * 2 \
            + mass_rke12ad * 2 \
            + self.calc_mass_rke13ad() \
            + mass_rke18ad * 2 \
            + self.calc_mass_rke19ad() \
            + mass_rke00ad05 * 4 \
            + mass_rke00ad09 * 2 \
            + mass_rke00ad13 * 2 \
            + self.calc_chain_mass_ms56r100() * 2 \
            + fasteners

    def calc_mass_rke0102ad(self) -> float:
        return 1.5024 * self.scr.ws - 0.1065

    def calc_mass_rke0104ad(self) -> float:
        return 0.2886 * self.scr.backwall_hs * self.scr.ws \
            - 0.2754 * self.scr.backwall_hs + 2.2173 * self.scr.ws - 2.6036

    def calc_mass_rke010101ad(self) -> float:
        return 2.7233 * self.scr.hs + 46.32

    def calc_mass_rke010111ad(self) -> float:
        return 2.7467 * self.scr.hs + 46.03

    def calc_mass_rke010102ad(self) -> float:
        return 0.5963 * self.scr.ws - 0.3838

    def calc_mass_rke010103ad(self) -> float:
        return 0.5881 * self.scr.ws + 0.4531

    def calc_mass_rke010104ad(self) -> float:
        return 0.8544 * self.scr.ws - 0.1806

    def calc_mass_rke010105ad(self) -> float:
        return 0.6313 * self.scr.ws + 0.1013

    def calc_mass_rke010107ad(self) -> float:
        return 0.605 * self.scr.wsdiff + 3.36

    def calc_mass_rke010108ad(self) -> float:
        return 0.445 * self.scr.ws - 0.245

    def calc_mass_rke010109ad(self) -> float:
        if self.scr.ws <= 10:
            return 0.136 * self.scr.ws + 0.13
        return 0.1358 * self.scr.ws + 0.2758

    def calc_mass_rke0101ad(self) -> float:
        fasteners = 2.22
        mass_rke0101ad02 = 0.42

        return self.calc_mass_rke010101ad() \
            + self.calc_mass_rke010111ad() \
            + self.calc_mass_rke010102ad() * 2 \
            + self.calc_mass_rke010103ad() \
            + self.calc_mass_rke010104ad() \
            + self.calc_mass_rke010105ad() \
            + self.calc_mass_rke010107ad() * 2 \
            + self.calc_mass_rke010108ad() \
            + self.calc_mass_rke010109ad() \
            + mass_rke0101ad02 * 2 \
            + fasteners

    def calc_mass_rke01ad(self) -> float:
        fasteners = 1.07
        mass_rke01ad01 = 0.62

        return self.calc_mass_rke0101ad() \
            + self.calc_mass_rke0102ad() \
            + self.mass_grid \
            + self.calc_mass_rke0104ad() \
            + mass_rke01ad01 * 2 \
            + fasteners

    def calc_mass_rke02ad(self) -> float:
        return 1.85 * self.scr.ws + 97.28 + (2.29 if self.scr.is_heavy else 0)

    def calc_mass_rke03ad(self) -> float:
        return 0.12 * self.scr.wsdiff * self.scr.gs + 2.12 * self.scr.wsdiff \
            + 0.4967 * self.scr.gs - 1.32

    # Тип полотна и прозор игнорируются.
    def calc_mass_rke04ad(self) -> float:
        return 0.5524 * self.scr.ws + 0.2035

    def calc_mass_rke05ad(self) -> float:
        return 0.8547 * self.scr.ws + 1.4571

    def calc_mass_rke06ad(self) -> float:
        return 0.5218 * self.scr.ws + 0.6576

    # Масса подставки на пол.
    def calc_mass_rke08ad(self) -> float:
        assert self.scr.stand_hs >= 6
        if self.scr.stand_hs == 6:
            return 17.81
        if self.scr.stand_hs == 7:
            return 21.47
        return 1.8267 * self.scr.stand_hs + 8.0633

    def calc_mass_rke09ad(self) -> float:
        return 1.7871 * self.scr.ws - 0.4094

    def calc_mass_rke10ad(self) -> float:
        if self.scr.ws <= 10:
            return 0.06 * self.scr.coverhs * self.scr.ws \
                - 0.055 * self.scr.coverhs + 0.3167 * self.scr.ws + 0.3933
        return 0.03 * self.scr.coverhs * self.scr.ws \
            - 0.0183 * self.scr.coverhs + 0.1582 * self.scr.ws + 0.6052

    # TODO: Возможно рамку нужно делать по высоте канала, а не полотна.
    def calc_mass_rke13ad(self) -> float:
        return 0.1811 * self.scr.gs + 0.49 * self.scr.ws + 0.7867

    def calc_mass_rke19ad(self) -> float:
        return 0.0161 * self.scr.gs + 0.2067

    def calc_chain_mass_ms56r100(self) -> float:
        return 4.18 * self.scr.chain_length

    def calc_mass_grid_balk(self) -> float:
        return 0.6919 * self.scr.ws - 0.7431

    def calc_mass_grid_screw(self) -> float:
        return 0.16


class MassSmall(MassCalculator):
    def __init__(self, scr: BarScreen) -> None:
        super().__init__(scr)

        other = 3.57
        self.mass = self.calc_mass_body() \
            + self.calc_mass_cover() \
            + self.calc_chain_with_rakes_mass() \
            + self.calc_mass_discharge() \
            + self.calc_mass_top_cover() \
            + self.calc_mass_drive_asm() \
            + self.calc_mass_ejector() \
            + self.calc_mass_frame_loop() \
            + self.calc_mass_support() * 2 \
            + self.calc_mass_side_screen() * 2 \
            + other

    # Рама
    def calc_mass_frame(self) -> float:
        return 1.95 * self.scr.ws + 3.18 * self.scr.hs + 50.02

    # Стол
    def calc_mass_backwall(self) -> float:
        return 0.2358 * self.scr.ws * self.scr.backwall_hs \
            + 1.3529 * self.scr.ws - 0.0383 * self.scr.backwall_hs - 0.8492

    # Лоток
    def calc_mass_tray(self) -> float:
        return 0.7575 * self.scr.ws - 0.225

    # Облицовка
    def calc_mass_cover(self) -> float:
        return 0.1175 * self.scr.ws * self.scr.coverhs + 0.8413 * self.scr.ws \
            - 0.085 * self.scr.coverhs + 0.0125

    # Масса цепи (1 шт.)
    def calc_chain_mass_ms28r63(self) -> float:
        return 4.5455 * self.scr.chain_length

    # Граблина
    def calc_mass_rake(self) -> float:
        return 0.47 * self.scr.ws - 0.06

    # Цепь в сборе
    def calc_chain_with_rakes_mass(self) -> float:
        fasteners = 0.12
        return self.calc_chain_mass_ms28r63() * 2 \
            + self.calc_mass_rake() * self.scr.rake_count + fasteners

    # Кожух сброса
    def calc_mass_discharge(self) -> float:
        return 1.3 * self.scr.ws + 0.75

    # Верхняя крышка (на петлях)
    def calc_mass_top_cover(self) -> float:
        return 0.2775 * self.scr.ws + 0.655

    # Узел привода (в сборе с валом, подшипниками и т.д.)
    def calc_mass_drive_asm(self) -> float:
        return 1.2725 * self.scr.ws + 15.865

    # Сбрасыватель
    def calc_mass_ejector(self) -> float:
        return 0.475 * self.scr.ws + 0.47

    # Рамка из прутка
    def calc_mass_frame_loop(self) -> float:
        return 0.34 * self.scr.ws + 0.2883 * self.scr.gs - 1.195

    # Опора решетки (на канал)
    def calc_mass_support(self) -> float:
        return 1.07 * self.scr.stand_hs + 11.91

    # Защитный экран
    def calc_mass_side_screen(self) -> float:
        return 0.1503 * self.scr.wsdiff * self.scr.gs \
            + 0.7608 * self.scr.wsdiff + 0.4967 * self.scr.gs - 2.81

    # Корпус
    def calc_mass_body(self) -> float:
        fasteners = 1.02
        # Лыжа
        mass_ski = 0.45
        # Серьга разрезная
        mass_lug = 0.42

        return self.calc_mass_frame() \
            + self.calc_mass_backwall() \
            + self.calc_mass_tray() \
            + mass_ski * 2 \
            + mass_lug * 2 \
            + self.mass_grid \
            + fasteners

    def calc_mass_grid_balk(self) -> float:
        return 0.3825 * self.scr.ws - 0.565

    def calc_mass_grid_screw(self) -> float:
        return 0.08
