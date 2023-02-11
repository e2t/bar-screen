from typing import Callable

from mypy_extensions import VarArg

ENG = 'eng'
UKR = 'ukr'
RUS = 'rus'
LIT = 'lit'

MsgFormat = dict[str, str] | str
AddMsgL10n = Callable[[MsgFormat, VarArg()], None]
