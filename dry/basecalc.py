from typing import NoReturn

from dry.l10n import AddMsgL10n, MsgFormat


class CalcError(Exception):
    pass


class BaseCalc:
    def __init__(self, adderror: AddMsgL10n):
        self.adderror = adderror

    def raise_error(self, msg: MsgFormat, *args: object) -> NoReturn:
        self.adderror(msg, *args)
        raise CalcError()
