> **Состояние на 2026-08-25:** выполнен целиком, отчёт — в
> `2026-08-25[7]-wave-0-tests-report.md`.
> **Что это:** план доделки волны 0 — три оставшихся пункта по существующему
> `test/yet_another_decimal_test.dart`: снятие сверки представления, разбор
> табличных циклов, разбиение файла.
> **Связанные записи:** `2026-08-25[5]-package-rework-plan.md` (волны целиком),
> `2026-08-25[3]-package-review.md` (находки про тесты),
> `2026-08-25[7]-wave-0-tests-report.md` (отчёт).

# Доделка волны 0

Владелец ответил на открытый вопрос: доделываем волну 0, к волне 1 переходим
после неё.

Правок в `lib/` в этом заходе нет ни одной — как и во всей волне 0.

## Что осталось

Пункты 6, 7 и 8 из `2026-08-25[5]-package-rework-plan.md`. Ниже — как именно.

## Пункт 6. Снять сверку представления с арифметики

Сейчас `base` и `scale` сверяются 245 раз. Распределение по группам (замер
`awk` по файлу):

| Группа | `base:` |
|:--|--:|
| `Decimal.parse` | 66 |
| `ShortDecimal.parse` | 52 |
| `ShortDecimal.multiply` | 40 |
| `ShortDecimal.add` | 17 |
| `Decimal.multiply`, `Decimal.divide`, `ShortDecimal.divide` | по 14 |
| `Decimal.add` | 10 |
| `Decimal.toStringAsFixed` | 4 |
| `abs` (оба семейства) | по 3 |
| `pow` (оба семейства) | по 2 |
| `toString` (оба), `ShortDecimal.toInt` | по 1 |

**Снимаем** в `add`, `multiply`, `divide`, `abs`, `pow`, `toInt` — 120 мест.
Там форма хранения результата — артефакт алгоритма, и быстрый путь деления из
волны 3 законно даст другую форму при том же значении.

**Оставляем** в `parse`, `toString`, `toStringAsFixed` — 125 мест. Там форма
хранения и есть предмет проверки: `parse` обязан не нормализовать вход,
`toString` обязан снимать нули, не трогая представление. Четыре места в
`toStringAsFixed` — это сверка результата `fromBigInt`, то же самое, что
`parse`.

Сами параметры `base`/`scale` у хелперов остаются: они нужны оставшимся 125
местам.

Заодно заводим отсутствующий тест на `Decimal.optimize()` — единственный метод,
у которого предмет проверки целиком в представлении (ленивая нормализация), и
у которого сейчас нет ни одного теста.

`fractionDigits` не трогаем нигде: это публичное свойство значения, а не форма
его хранения.

## Пункт 7. Разложить табличные циклы

Циклы `for (final p in [...]) { expect...(p.$1, p.$2); }` внутри одного `test`
скрывают все случаи после упавшего и не говорят, какой упал. Разворачиваем
цикл **наружу** `test`, чтобы каждый случай стал отдельным тестом с внятным
именем:

```dart
group('clamp', () {
  for (final p in [...]) {
    test('${p.$1} в [${p.$2}, ${p.$3}] даёт ${p.$4}', () {
      expectDecimal(p.$1.clamp(p.$2, p.$3), p.$4);
    });
  }
});
```

Затрагивает `parse` (оба семейства), `clamp`, `isInteger`, `toString`.

Циклы, которые не табличные, а нагрузочные (`for (var i = 0; i < 60; i++)` в
`hashCode`, накопление суммы сорока слагаемых), остаются циклами: там случаи не
независимы, и разбирать их не на что.

## Пункт 8. Разбить файл

`test/yet_another_decimal_test.dart` (4336 строк) уходит целиком. Хелперы —
в `test/support/expect.dart`, тесты — по семействам и темам:

```
test/support/expect.dart          хелперы expectDecimal и прочие
test/decimal/parse_test.dart      Decimal.parse, fromBigInt, конструкторы
test/decimal/arithmetic_test.dart add, multiply, abs, pow
test/decimal/divide_test.dart     divide, DecimalDivideException
test/decimal/compare_test.dart    hashCode, ==, compareTo, операторы, clamp
test/decimal/convert_test.dart    toBigInt, toDouble, isInteger
test/decimal/format_test.dart     toString, toStringAsFixed, optimize
test/decimal/fraction_test.dart   Fraction
test/decimal/division_test.dart   Division
test/short_decimal/…              то же самое для второго семейства
```

У `ShortDecimal` заводятся отсутствующие группы `compare` и `toStringAsFixed` —
зеркала тех, что есть у `Decimal`. Их отсутствие и есть причина 30 %
непокрытого кода.

Имена тестов при переносе не меняются: иначе в диффе не отличить перенос от
правки.

## Готово, когда

- `dart test` зелёный, число `skip` не изменилось (41, все с номером дефекта);
- в `add`, `multiply`, `divide`, `abs`, `pow`, `toInt` не осталось ни одного
  `base:`/`scale:`;
- у `ShortDecimal` есть группы `compare` и `toStringAsFixed`;
- `dart analyze` без новых замечаний, `dart format` чисто;
- `docs/conventions.md` описывает новую раскладку тестов, а не старый
  единый файл.
