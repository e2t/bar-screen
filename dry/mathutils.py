GRAV_ACC = 9.80665  # Metre/sec2
STEEL_ELAST = 2.0e11  # Pa


def mround(value: float, base: float) -> float:
    return round(value / base) * base
