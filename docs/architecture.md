# Архитектура

Устройство пакета `yet_another_decimal` и решения, которые за ним стоят.
Здесь только то, что меняется редко. Текущее состояние работ — в
`docs/handoff.md`.

## Задача пакета

Десятичные числа с фиксированной точкой без потери точности. Ключевое отличие
от соседей по pub.dev (`fixed`, `decimal_type`, `big_decimal`): деление нигде
не проходит через `double`, поэтому результат не портится на больших числах.
Подробное сравнение с обоснованием — в `README.md`.

## Два типа вместо одного

Пакет даёт два независимых типа с почти одинаковым API:

| | `Decimal` | `ShortDecimal` |
|:--|:--|:--|
| Хранилище | `BigInt` | `int` |
| Границы | нет | int64 (в JS — int53) |
| Переполнение | невозможно | **не контролируется**, тихо ломает результат |
| Нормализация | ленивая, с кешем | немедленная, в конструкторе |
| `@immutable` | нет (кеш `_packed`) | да, есть `const`-значения |
| Скорость | ниже | выше |

Это не наследники и не реализации общего интерфейса — два параллельных
семейства классов. Дублирование кода здесь сознательное: общий интерфейс
заставил бы `ShortDecimal` платить за полиморфизм, а он существует именно ради
скорости.

Соответствие семейств:

| `Decimal` | `ShortDecimal` |
|:--|:--|
| `Decimal` | `ShortDecimal` |
| `Fraction` | `ShortFraction` |
| `Division` | `ShortDivision` |
| `DecimalDivideException` | `ShortDecimalDivideException` |

API двух семейств совпадает не полностью. Осознанные расхождения:

| | `Decimal` | `ShortDecimal` |
|:--|:--|:--|
| Конструктор | `shiftRight` | `shiftRight` **и** `shiftLeft` |
| Из целого | `Decimal(int)`, `Decimal.fromBigInt(BigInt)` | `ShortDecimal(int)` |
| В целое | `toBigInt()` | `toInt()` |
| Расширения | `int.toDecimal()`, `BigInt.toDecimal()` | `int.toShortDecimal()` |
| `optimize()` | есть | не нужен — упаковка немедленная |

`shiftLeft` у `ShortDecimal` — не украшение: отрицательный `scale` для него
рабочий режим, и задавать его явно приходится чаще.

Расхождения, которые расхождениями быть не должны, перечислены в
`docs/handoff.md`.

## Представление числа

Число хранится парой полей:

```
значение = base × 10^(−scale)
```

- `base` — значащая часть (`BigInt` или `int`);
- `scale` — положение десятичной точки.

`scale` может быть **отрицательным** — это значит, что у числа есть хвостовые
нули, которые не хранятся: `(base: 9223372036854775807, scale: −23)` — это
число из 42 цифр, укладывающееся в int64. Для `ShortDecimal` это не
оптимизация, а способ существования: считать такое число можно только в том же
масштабе, иначе `base` вылетит за границы `int`.

Оба поля помечены `@visibleForTesting` — это внутреннее представление, а не
часть публичного API. Для отладки есть `debugToString()`.

## Файлы

```
lib/yet_another_decimal.dart          экспорт двух подсистем и больше ничего
lib/src/helpers.dart                  внутренние расширения (fastGcd, splitByIndex)
lib/src/decimal/
    decimal.dart                      Decimal, DecimalDivideException
    fraction.dart                     part: Fraction
    division.dart                     part: Division
lib/src/short_decimal/
    short_decimal.dart                ShortDecimal, ShortDecimalDivideException
    short_fraction.dart               part: ShortFraction
    short_division.dart               part: ShortDivision
```

`Fraction`/`Division` — `part of 'decimal.dart'`, а не отдельные библиотеки:
им нужен доступ к приватным `Decimal._asIs`, `Decimal._align`,
`Decimal._bigInt10`. То же у короткого семейства.

## Ключевые механизмы

### Выравнивание — `_align`

```dart
(BigInt, BigInt, int) _align(Decimal other)
```

Приводит два числа к общему `scale`, домножая меньшее на степень десяти, и
возвращает `(a, b, scale)`. На нём построено всё, где два числа надо сравнить
поразрядно: `+`, `-`, `%`, `~/`, `remainder`, `<`, `<=`, `>`, `>=`,
`compareTo`, `==`, `divideToFraction`, `Division`.

Из этого следует главный инвариант равенства: **числа сравниваются по
значению, а не по представлению**. `(base: 60, scale: 1) == (base: 6, scale: 0)`.

### Нормализация — «упаковка»

Упаковка — снятие хвостовых нулей у `base` с уменьшением `scale`:
`(600, 2) → (6, 0)`.

- **`ShortDecimal`** упаковывает **сразу**, в фабрике `_pack`, после каждой
  операции. Иначе `int` переполняется абсурдно быстро: восемнадцати умножений
  `1.0 * 1.0` хватает, чтобы выйти за int64, хотя значение всё это время равно
  единице.
- **`Decimal`** упаковывает **лениво** и кеширует результат в изменяемом поле
  `_packed`. `BigInt` не переполняется, поэтому платить за нормализацию после
  каждой операции незачем. Упакованная форма нужна только там, где она
  действительно требуется: `hashCode`, `fractionDigits`, `isInteger`,
  `toString`. Публичный `optimize()` позволяет заплатить эту цену заранее —
  например, перед многократным выводом одного и того же числа.

Кеш `_packed` — причина, по которой `Decimal` не `@immutable` и почему в нём
стоят `// ignore: avoid_equals_and_hash_code_on_mutable_classes`. Наблюдаемое
значение при этом неизменно: `base` и `scale` — `final`.

`hashCode` считается по упакованной форме именно затем, чтобы согласоваться с
`==`, который сравнивает по значению.

### Деление — только точное

`operator /` возвращает результат, **только если он представим** конечной
десятичной дробью. Алгоритм:

1. сократить делимое и делитель на НОД;
2. вытащить из делителя множители 5 и 2, компенсируя каждый увеличением
   `scale` (домножение `base` на 2 и на 5 соответственно);
3. если делитель после этого не стал единицей — результат непредставим,
   бросается `DecimalDivideException`.

Исключение — не тупик, а способ вернуть управление вызывающему. Оно несёт в
себе всё, что можно сделать дальше:

```dart
try {
  final r = a / b;
} on DecimalDivideException catch (e) {
  e.fraction;               // Fraction — точная дробь
  e.quotientWithRemainder;  // Division — частное и остаток
  e.round(2);               // Decimal — округлить до 2 знаков
  e.floor(2); e.ceil(2); e.truncate(2);
}
```

Те же результаты доступны и без исключения: `divideToFraction`,
`divideWithRemainder`, `divideToDouble`.

Поэтому `DecimalDivideException` — `Exception`, а не `Error`: это штатная
развилка, а не ошибка программиста.

### `Fraction` — точная дробь

Рациональное число: `numerator` / `denominator`, всегда сокращённое,
знаменатель всегда положителен (знак живёт в числителе). Арифметика `+ - * /`,
округления `floor`/`round`/`ceil`/`truncate` до заданного числа знаков —
именно они превращают непредставимое деление в `Decimal`. `Fraction`
`@immutable`, в отличие от `Decimal`.

### `Division` — частное с остатком

`quotient` (целое) и `remainder` (`Decimal`). Инвариант, проверяемый в тестах:

```
quotient * divisor + remainder == dividend
```

### `fastGcd`

Свой цикл Евклида в `lib/src/helpers.dart` вместо `BigInt.gcd` — штатный
медленный, см. [dart-lang/sdk#46180](https://github.com/dart-lang/sdk/issues/46180).
Используется в `operator /` и при сокращении `Fraction`.

## Границы `ShortDecimal`

Переполнение **не проверяется намеренно**. Проверка на каждой операции
кратно замедлила бы сложение, ради скорости которого этот тип и существует:

```dart
ShortDecimal(9223372036854775807) + ShortDecimal.one; // -9223372036854775808
```

В границы int64 должна укладываться значащая часть — `base` без хвостовых
нулей. Само число может быть сколь угодно длинным, пока с ним работают в его
собственном масштабе. Развёрнутое объяснение с примерами — в `README.md`,
раздел «`ShortDecimal` limitations».

`_pow10` в `ShortDecimal` реализован как `math.pow(10, exponent) as int` — это
тоже работает только внутри int64.

## Исключения

| Исключение | Когда |
|:--|:--|
| `DecimalDivideException`, `ShortDecimalDivideException` | результат деления непредставим |
| `FormatException` | `parse` не разобрал строку (`tryParse` вернёт `null`) |
| `UnsupportedError` | деление на ноль в `Fraction`/`Division` |
| `ArgumentError` | отрицательные `fractionDigits`/`exponent`, `lowerLimit > upperLimit` в `clamp` |
| `UnimplementedError` | `toStringAsExponential`, `toStringAsPrecision` — не написаны |

Тексты всех сообщений — по-английски.

## Тесты

Один файл `test/yet_another_decimal_test.dart` (~4300 строк). Сверху — набор
хелперов (`expectDecimal`, `expectShortDecimal`, `expectFraction`,
`expectDivision`, `expectDivide`, `expectDouble` и их короткие двойники),
которые проверяют не только `toString()`, но и внутреннее представление —
`base`, `scale`, `fractionDigits`. Дальше — группы по типам: `Decimal`,
`Fraction`, `Division`, `ShortDecimal`, `ShortFraction`, `ShortDivision`.

`expectDouble` умеет проверять и «сломанный» случай (`isValid: false`) — так
в тестах зафиксировано, где `double` действительно теряет точность, а
`Decimal` нет.

## `example/`

Отдельный пакет (`publish_to: none`) — стенд для сравнения скорости с
`decimal`, `fixed`, `decimal_type`, `big_decimal`, `big_double`. Не примеры
использования в обычном смысле, а бенчмарки, цифры из которых попадают в
таблицы `README.md`.

```
example/bin/benchmark.dart    точка входа, разбор тегов пакетов и тестов
example/bin/format.dart       вспомогательная утилита
example/lib/src/packages.dart перечень сравниваемых пакетов
example/lib/src/tests.dart    перечень бенчмарков и их данные
example/lib/src/operations.dart операции (add, multiply, divide, view)
example/lib/src/run.dart      прогон и печать сводной таблицы
example/lib/src/tests/*.dart  по файлу-адаптеру на каждый сравниваемый пакет
```

Аргументы фильтруют прогон по имени или тегу, префикс `-` исключает:
`dart bin/benchmark.dart divide -fixed`.
