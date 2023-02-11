from math import degrees, radians


# From input to SI


def mm(value: float) -> float:
    return value / 1000


def gram(value: float) -> float:
    return value / 1000


def meter(value: float) -> float:
    return value


def kw(value: float) -> float:
    return value * 1000


def nm(value: float) -> float:
    return value


def rpm(value: float) -> float:
    return value / 60


def kg(value: float) -> float:
    return value


def degree(value: float) -> float:
    return radians(value)


def radian(value: float) -> float:
    return value


def liter_per_sec(value: float) -> float:
    return value / 1000


def mpa(value: float) -> float:
    return value * 1_000_000


# Convert to printable


def to_mm(m: float) -> float:
    return m * 1000


def to_gram(kilogram: float) -> float:
    return kilogram * 1000


def to_kw(watt: float) -> float:
    return watt / 1000


def to_rpm(rps: float) -> float:
    return rps * 60


def to_degree(rad: float) -> float:
    return degrees(rad)


def to_mpa(pas: float) -> float:
    return pas / 1_000_000
