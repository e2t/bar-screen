from dry.l10n import ENG, LIT, RUS, UKR

from constants import Col, Col2


class UiText:
    AUTO = {
        ENG: 'Auto',
        UKR: 'Авто',
        RUS: 'Авто',
        LIT: 'Auto'
    }

    WS = {
        ENG: 'Width (series):',
        UKR: 'Ширина (серія):',
        RUS: 'Ширина (серия):',
        LIT: 'Plotis (serija):'
    }

    HS = {
        ENG: 'Height (series):',
        UKR: 'Висота (серія):',
        RUS: 'Высота (серия):',
        LIT: 'Aukštis (serija):'
    }

    GS = {
        ENG: 'Mesh (series):',
        UKR: 'Полотно (серія):',
        RUS: 'Полотно (серия):',
        LIT: 'Grotelės (serija):'
    }

    WID = {
        ENG: 'Channel width (mm):',
        UKR: 'Ширина каналу (мм):',
        RUS: 'Ширина канала (мм):',
        LIT: 'Kanalo plotis (mm):'
    }

    DEP = {
        ENG: 'Channel depth (mm):',
        UKR: 'Глибина каналу (мм):',
        RUS: 'Глубина канала (мм):',
        LIT: 'Kanalo gylis (mm):'
    }

    DROP = {
        ENG: 'Min. drop height (mm):',
        UKR: 'Мін. висота скидання (мм):',
        RUS: 'Мин. высота сброса (мм):',
        LIT: 'Min. kritimo aukštis (mm):'
    }

    GAP = {
        ENG: 'Nominal gap (mm):',
        UKR: 'Номінальний прозор (мм):',
        RUS: 'Номинальный прозор (мм):',
        LIT: 'Nominalus protarpis (mm):'
    }

    TITLE = {
        ENG: 'RKE calculation',
        UKR: 'Розрахунок РКЕ',
        RUS: 'Расчет РКЭ',
        LIT: 'RKE skaičiavimas'
    }

    COL = {
        Col.NAME: {
            ENG: 'Profile',
            UKR: 'Профіль',
            RUS: 'Профиль',
            LIT: 'Profilis'
        },
        Col.MOUNT: {
            ENG: 'Mounting',
            UKR: 'Кріплення',
            RUS: 'Крепление',
            LIT: 'Taisymas'
        },
        Col.FACTOR: {
            ENG: 'Factor',
            UKR: 'Коефіцієнт',
            RUS: 'Коэффициент',
            LIT: 'Veiksnys'
        }
    }

    FPWELD = {
        ENG: 'welded',
        UKR: 'зварний',
        RUS: 'сварной',
        LIT: 'suvirintas'
    }

    FPREMOV = {
        ENG: 'removable',
        UKR: 'знімний',
        RUS: 'съемный',
        LIT: 'nuimamas'
    }

    HYDR = {
        ENG: 'Hydraulics (optional):',
        UKR: "Гідравліка (необов'язково):",
        RUS: 'Гидравлика (необязательно):',
        LIT: 'Hidraulika (pasirinktinai):'
    }

    FLOW = {
        ENG: 'Water flow rate (l/s):',
        UKR: 'Витрата води (л/с):',
        RUS: 'Расход воды (л/с):',
        LIT: 'Vandens srautas (l/s):'
    }

    LEVEL = {
        ENG: 'Level behind screen (mm):',
        UKR: 'Рівень за решіткою (мм):',
        RUS: 'Уровень за решеткой (мм):',
        LIT: 'Lygis už ekrano (mm):'
    }

    ANGLE = {
        ENG: 'Tilt angle (°):',
        UKR: 'Кут нахилу (°):',
        RUS: 'Угол наклона (°):',
        LIT: 'Pakreipimo kampas (°):'
    }

    COL2 = {
        Col2.POLL: {
            ENG: 'Pollution',
            UKR: 'Забруднення',
            RUS: 'Загрязнение',
            LIT: 'Tarša'
        },
        Col2.GAPSPEED: {
            ENG: 'Speed in the gaps',
            UKR: 'Швидкість у прозорах',
            RUS: 'Скорость в прозорах',
            LIT: 'Greitis tarpuose'
        },
        Col2.AREA: {
            ENG: 'Flowing area',
            UKR: 'Віднос. площа потоку',
            RUS: 'Относ. площадь потока',
            LIT: 'Srauto plotas'
        },
        Col2.BFACTOR: {
            ENG: 'Blinding factor',
            UKR: 'Blinding factor',
            RUS: 'Blinding factor',
            LIT: 'Blinding factor'
        },
        Col2.DIFF: {
            ENG: 'Level difference',
            UKR: 'Різниця рівнів',
            RUS: 'Разность уровней',
            LIT: 'Lygių skirtumas'
        },
        Col2.FRONT: {
            ENG: 'Front level',
            UKR: 'Рівень до решітки',
            RUS: 'Уровень до решетки',
            LIT: 'Priekinis lygis'
        },
        Col2.CHNSPEED: {
            ENG: 'Channel speed',
            UKR: 'Швидкість у каналі',
            RUS: 'Скорость в канале',
            LIT: 'Kanalo greitis'
        }
    }


class ErrorMsg:
    WIDTH = {
        ENG: 'Wrong channel width!',
        UKR: 'Неправильна ширина каналу!',
        RUS: 'Неправильная ширина канала!',
        LIT: 'Neteisingas kanalo plotis!'
    }

    DEPTH = {
        ENG: 'Wrong channel depth!',
        UKR: 'Неправильна глибина каналу!',
        RUS: 'Неправильная глубина канала!',
        LIT: 'Neteisingas kanalo gylis!'
    }

    DROP = {
        ENG: 'Wrong drop height!',
        UKR: 'Неправильна висота скидання!',
        RUS: 'Неправильная высота сброса!',
        LIT: 'Neteisingas kritimo aukštis!'
    }

    FLOW = {
        ENG: 'Wrong water flow!',
        UKR: 'Неправильна витрата води!',
        RUS: 'Неправильный расход воды!',
        LIT: 'Neteisingas vandens suvartojimas!'
    }

    LEVEL = {
        ENG: 'Wrong level after the screen!',
        UKR: 'Неправильний рівень за решіткою!',
        RUS: 'Неправильный уровень за решеткой!',
        LIT: 'Neteisingas lygis po ekranu!'
    }

    ANGLE = {
        ENG: 'Wrong angle!',
        UKR: 'Неправильний кут нахилу!',
        RUS: 'Неправильный угол наклона!',
        LIT: 'Neteisingas pasvirimo kampas!'
    }

    TOOHIGH_HS = {
        ENG: 'The screen is too high.',
        UKR: 'Занадто висока решітка.',
        RUS: 'Слишком высокая решетка.',
        LIT: 'Ekranas yra per aukštai.'
    }

    MINDROP = {
        ENG: 'Discharge height is less than the specified minimum height.',
        UKR: 'Висота скидання менша за вказану мінімальну висоту.',
        RUS: 'Высота сброса меньше указанной минимальной высоты.',
        LIT: 'Išleidimo aukštis yra mažesnis už nurodytą minimalų aukštį.'
    }

    TOOHIGH_GS = {
        ENG: 'The grate is too high.',
        UKR: 'Занадто високе полотно.',
        RUS: 'Слишком высокое полотно.',
        LIT: 'Tinklelis yra per aukštas.'
    }

    DIFF_HS_GS = {
        ENG: 'The height difference between the grate and the screen '
             'is too big.',
        UKR: 'Занадто велика різниця висоти полотна і решітки.',
        RUS: 'Слишком большая разница высоты полотна и решетки.',
        LIT: 'Aukščio skirtumas tarp grotelių ir ekrano yra per didelis.'
    }

    TOONARROW = {
        ENG: 'The channel is too narrow.',
        UKR: 'Занадто вузький канал.',
        RUS: 'Слишком узкий канал.',
        LIT: 'Kanalas yra per siauras.'
    }

    TOOWIDE = {
        ENG: 'The channel is too wide.',
        UKR: 'Занадто широкий канал.',
        RUS: 'Слишком широкий канал.',
        LIT: 'Kanalas yra per platus.'
    }

    TOOSMALL = {
        ENG: 'Too little support.',
        UKR: 'Занадто маленька опора.',
        RUS: 'Слишком маленькая опора.',
        LIT: 'Parama yra per maža.'
    }

    TOOBIGGAP = {
        ENG: 'The gap is too big.',
        UKR: 'Занадто великий прозор.',
        RUS: 'Слишком большой прозор.',
        LIT: 'Atotrūkis yra per didelis.'
    }

    FINAL_ABOVE_CHN = {
        ENG: 'The water level is above the channel.',
        UKR: 'Рівень води вище за канал.',
        RUS: 'Уровень воды выше канала.',
        LIT: 'Vandens lygis yra aukščiau kanalo.'
    }

    FINAL_ABOVE_GS = {
        ENG: 'The water level is above the grid.',
        UKR: 'Рівень води вище полотна.',
        RUS: 'Уровень воды выше полотна.',
        LIT: 'Vandens lygis yra virš grotelių.'
    }

    ANGLE_DIAPASON = {
        ENG: 'The angle {:n}+/-{:n}° is allowed.',
        UKR: 'Допускається кут {:n}+/-{:n}°.',
        RUS: 'Допускается угол {:n}+/-{:n}°',
        LIT: 'Leidžiamas kampas {:n}+/-{:n}°'
    }


def heading(text: str) -> str:
    indent = '======'
    return f'{indent} {text} {indent}'


class Output:
    BIGDSG = {
        ENG: 'RKE {:02d}{:02d}{}-{}-{:n}',
        UKR: 'РКЕ {:02d}{:02d}{}-{}-{:n}',
        RUS: 'РКЭ {:02d}{:02d}{}-{}-{:n}',
    }

    SMALLDSG = {
        ENG: 'RKEm {:02d}{:02d}{}-{}-{:n}',
        UKR: 'РКЕм {:02d}{:02d}{}-{}-{:n}',
        RUS: 'РКЭм {:02d}{:02d}{}-{}-{:n}',
    }

    WEIGHT = {
        ENG: 'Weight {:n} kg',
        UKR: 'Маса {:n} кг',
        RUS: 'Масса {:n} кг',
    }

    WEIGHT_APPROX = {
        ENG: 'Weight {:n} kg (approx.)',
        UKR: 'Вага {:n} кг (приблизно)',
        RUS: 'Вес {:n} кг (примерно)',
    }

    DRIVE = {
        ENG: 'Gearmotor «{}»; {:n} kW; {:n} Nm; {:n} rpm',
        UKR: 'Мотор-редуктор «{}»; {:n} кВт; {:n} Нм; {:n} об/хв',
        RUS: 'Мотор-редуктор «{}»; {:n} кВт; {:n} Нм; {:n} об/мин',
    }

    INNER_WIDTH = {
        ENG: 'Section width {:n} mm',
        UKR: 'Ширина просвіту {:n} мм',
        RUS: 'Ширина просвета {:n} мм',
    }

    INNER_HEIGHT = {
        ENG: 'Section height (above the channel bottom) {:n} mm',
        UKR: 'Висота просвіту (над дном каналу) {:n} мм',
        RUS: 'Высота просвета (над дном канала) {:n} мм',
    }

    SCR_LENGTH = {
        ENG: 'Screen length {:n} mm',
        UKR: 'Довжина решітки {:n} мм',
        RUS: 'Длина решетки {:n} мм',
    }

    CHAIN_LENGTH = {
        ENG: 'Chain length {:n} mm',
        UKR: 'Довжина ланцюга {:n} мм',
        RUS: 'Длина цепи {:n} мм',
    }

    FP_LENGTH = {
        ENG: 'Profile length {:n} mm',
        UKR: 'Довжина профілю {:n} мм',
        RUS: 'Длина профиля {:n} мм',
    }

    FP_COUNT = {
        ENG: 'Number of profiles {:n} ± 1 pc.',
        UKR: 'Кількість профілів {:n} ± 1 шт.',
        RUS: 'Количество профилей {:n} ± 1 шт.',
    }

    RAKE_COUNT = {
        ENG: 'Number of rakes {:n} pcs.',
        UKR: 'Кількість граблин {:n} шт.',
        RUS: 'Количество граблин {:n} шт.',
    }

    DROP_WIDTH = {
        ENG: 'Discharge width {:n} mm',
        UKR: 'Ширина скидання {:n} мм',
        RUS: 'Ширина сброса {:n} мм',
    }

    DROP_ABOVE_TOP = {
        ENG: 'Discharge height (above the channel surface) {}{:n} mm',
        UKR: 'Висота скидання (над поверхнею каналом) {}{:n} мм',
        RUS: 'Высота сброса (над поверхностью каналом) {}{:n} мм',
    }

    DROP_ABOVE_BOTTOM = {
        ENG: 'Discharge height (above the channel bottom) {}{:n} mm',
        UKR: 'Висота скидання (над дном каналу) {}{:n} мм',
        RUS: 'Высота сброса (над дном канала) {}{:n} мм',
    }

    HYDR_MM = {
        ENG: '{:n} mm',
        UKR: '{:n} мм',
        RUS: '{:n} мм',
    }

    HYDR_MS = {
        ENG: '{:n} m/s',
        UKR: '{:n} м/с',
        RUS: '{:n} м/с',
    }

    WARNING_OVERFLOW = {
        ENG: '{}% - channel overflow',
        UKR: '{}% - переповнення каналу',
        RUS: '{}% - переполнение канала',
    }

    WARNING_DIFF = {
        ENG: '{}% - level above the grid (by {:n} mm)',
        UKR: '{}% - рівень вище полотна (на {:n} мм)',
        RUS: '{}% - уровень выше полотна (на {:n} мм)',
    }

    MINTORQUE = {
        ENG: 'Minimum torque {:n} Nm',
        UKR: 'Мінімальний обертаючий момент {:n} Нм',
        RUS: 'Минимальный крутящий момент {:n} Нм',
    }

    GAP = {
        ENG: 'Actual gap {:n} mm',
        UKR: 'Фактичний прозор {:n} мм',
        RUS: 'Фактический прозор {:n} мм',
    }

    SPRING = {
        ENG: 'Spring «{}»; pre-compression {:n} mm',
        UKR: 'Пружина «{}»; попередній стиск {:n} мм',
        RUS: 'Пружина «{}»; предварительное сжатие {:n} мм',
    }

    # _ = {
    #     ENG: '',
    #     UKR: '',
    #     RUS: '',
    # }
