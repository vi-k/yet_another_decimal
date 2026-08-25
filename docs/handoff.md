# Текущее состояние

> Обновлено: 2026-08-25

Здесь только то, что происходит с проектом сейчас. Истории коммитов, разбора
законченных эпизодов и пожеланий владельца тут быть не должно — см. `git log`,
`docs/records/` и `docs/backlog.md`.

## Чем занимаемся

Ничего в работе. Сделаны: первичная настройка проекта под работу с
ИИ-агентами (`AGENTS.md`, `CLAUDE.md`, `docs/`) и починка секции `exclude` в
обоих `analysis_options.yaml`. Отчёты —
`docs/records/2026-08-25[1]-ai-onboarding-report.md` и
`docs/records/2026-08-25[2]-analysis-options-report.md`.

Следующий шаг определяет владелец. В `docs/backlog.md` шесть его записей,
самая крупная — dartdoc для публичного API.

## Состояние ветки

`main`, рабочее дерево чистое. Опубликованная версия — 1.1.2, тег `v1.1.2`.

## Здоровье кодовой базы

Проверено 2026-08-25 на Dart 3.13.0:

| Проверка | Результат |
|:--|:--|
| `dart test` | 60 тестов, все проходят |
| `dart format --output=none --set-exit-if-changed .` | чисто, 25 файлов |
| `dart analyze` | 1 замечание, ниже |

`example/lib/src/utils/output.dart:3:25` — `use_named_constants`, предложено
взять `Color256.gray12` вместо конструктора. Единственное замечание на весь
проект, в `lib/` чисто.

## Известные пробелы

- `Decimal.toStringAsExponential` и `Decimal.toStringAsPrecision` объявлены и
  бросают `UnimplementedError`. У `ShortDecimal` их нет вовсе — то есть
  асимметрия здесь двойная: метод не написан в одном семействе и отсутствует
  в другом.
- `ShortDecimalDivideException.toString()` печатает только дробь: строка с
  `quotientWithRemainder` закомментирована, в `DecimalDivideException`
  печатаются обе. Причина в коде не объяснена.
- Публичный API `ShortDecimal` почти без dartdoc, у `Decimal` покрыт заметно
  лучше. Пакет опубликован — это видно на pub.dev.
- `example/README.md` — заглушка от шаблона `dart create`.
