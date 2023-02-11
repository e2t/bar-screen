import math
from typing import SupportsFloat


class ComparableFloat(float):
    precision = 1e-6

    def __eq__(self, x: object) -> bool:
        if not isinstance(x, SupportsFloat):
            return NotImplemented
        return math.isclose(self, x, abs_tol=self.precision)

    def __ne__(self, x: object) -> bool:
        if not isinstance(x, SupportsFloat):
            return NotImplemented
        return not math.isclose(self, x, abs_tol=self.precision)

    def __lt__(self, x: object) -> bool:
        if not isinstance(x, SupportsFloat):
            return NotImplemented
        return (not math.isclose(self, x, abs_tol=self.precision)) \
            and super().__lt__(x.__float__())

    def __gt__(self, x: object) -> bool:
        if not isinstance(x, SupportsFloat):
            return NotImplemented
        return (not math.isclose(self, x, abs_tol=self.precision)) \
            and super().__gt__(x.__float__())

    def __le__(self, x: object) -> bool:
        if not isinstance(x, SupportsFloat):
            return NotImplemented
        return super().__le__(x.__float__()) or \
            math.isclose(self, x, abs_tol=self.precision)

    def __ge__(self, x: object) -> bool:
        if not isinstance(x, SupportsFloat):
            return NotImplemented
        return super().__ge__(x.__float__()) or \
            math.isclose(self, x, abs_tol=self.precision)
