import sys
from timeit import default_timer as timer
from datetime import timedelta
from barscreen import (
    InputData, SCREEN_WIDTH_SERIES, SCREEN_HEIGHT_SERIES, GRATE_HEIGHT_SERIES, FILTER_PROFILES,
    DEFAULT_DISCHARGE_HEIGHT, STD_GAPS, MAX_DIFF_SCREEN_AND_GRATE_HS, BarScreen)
from Dry.allcalc import WidthSerie, HeightSerie
from Dry.allgui import to_mm


ARRAY_NAME = 'gWeights'
KEY_NAME = 'Key'


def function_name3(ws: WidthSerie) -> str:
    return f'Init_{ws:02d}'


def function_name2(ws: WidthSerie, hs: HeightSerie) -> str:
    return f'Init_{ws:02d}{hs:02d}'


def function_name(ws: WidthSerie, hs: HeightSerie, gs: HeightSerie) -> str:
    return f'Init_{ws:02d}{hs:02d}_{gs:02d}'


def main() -> None:
    print(f'Dim {ARRAY_NAME} As Dictionary\n')

    print('Public Sub Init()')
    print(f'    Set {ARRAY_NAME} = New Dictionary\n')
    for ws in SCREEN_WIDTH_SERIES:
        print(f'    {function_name3(ws)}')
    print('End Sub\n')

    for ws in SCREEN_WIDTH_SERIES:
        print(f'Private Sub {function_name3(ws)}()')
        for hs in SCREEN_HEIGHT_SERIES:
            print(f'    {function_name2(ws, hs)}')
        print('End Sub\n')

    for ws in SCREEN_WIDTH_SERIES:
        for hs in SCREEN_HEIGHT_SERIES:
            print(f'Private Sub {function_name2(ws, hs)}()')
            for gs in GRATE_HEIGHT_SERIES:
                if gs - hs > MAX_DIFF_SCREEN_AND_GRATE_HS:
                    break
                print(f'    {function_name(ws, hs, gs)}')
            print('End Sub\n')

    print(f'Public Function {KEY_NAME}(ws As String, hs As String, gs As String, fp As String, '
          'gap As String) As String')
    print(f'    {KEY_NAME} = ws + "@" + hs + "@" + gs + "@" + fp + "@" + gap')
    print('End Sub\n')

    for ws in SCREEN_WIDTH_SERIES:
        for hs in SCREEN_HEIGHT_SERIES:
            for gs in GRATE_HEIGHT_SERIES:
                if gs - hs > MAX_DIFF_SCREEN_AND_GRATE_HS:
                    break
                print(f'Private Sub {function_name(ws, hs, gs)}()')
                for fp in FILTER_PROFILES:
                    for gap in STD_GAPS:
                        bs = BarScreen(InputData(
                            screen_ws=ws, screen_hs=hs, grate_hs=gs, fp=fp, gap=gap,
                            min_discharge_height=DEFAULT_DISCHARGE_HEIGHT,
                            channel_width=(ws + 1) / 10,
                            channel_height=hs / 10 - 0.3))
                        print(f'    {ARRAY_NAME}.Add {KEY_NAME}("{ws:02d}", "{hs:02d}", '
                              f'"{gs:02d}", "{fp.name}", "{round(to_mm(gap))}"), '
                              f'"{round(bs.mass)}"')
                print('End Sub\n')
            # return


if __name__ == '__main__':
    start = timer()
    main()
    end = timer()
    print(timedelta(seconds=end-start), file=sys.stderr)
