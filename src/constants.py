from enum import StrEnum, auto, unique


@unique
class Col(StrEnum):
    NAME = auto()
    MOUNT = auto()
    FACTOR = auto()


@unique
class Col2(StrEnum):
    POLL = auto()
    GAPSPEED = auto()
    AREA = auto()
    BFACTOR = auto()
    DIFF = auto()
    FRONT = auto()
    CHNSPEED = auto()
