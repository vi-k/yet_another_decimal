> **Состояние на 2026-08-25:** сделано и смержено.
> **Что это:** отчёт о починке секции `exclude` в `analysis_options.yaml`.
> **Связанные записи:** `2026-08-25[1]-ai-onboarding-report.md`.

# Секция `exclude` в `analysis_options.yaml` не работала

## Дефект

`dart analyze` выдавал два одинаковых замечания:

```
warning - analysis_options.yaml:6:5 - Invalid format for the 'exclude' section. - invalid_section_format
warning - example/analysis_options.yaml:6:5 - Invalid format for the 'exclude' section. - invalid_section_format
```

Секция была записана картой:

```yaml
  exclude:
    'web/**': true
    'build/**': true
```

Анализатор ждёт здесь список глобов, а не карту. Разобрать такую секцию он не
может и **игнорирует её целиком** — то есть исключения не действовали вообще.

Заметных последствий не было только потому, что ни одного из перечисленных
путей (`web/`, `build/`, `assets/`, `lib/generated_plugin_registrant.dart`,
`.test_coverage.dart`) в проекте не существует. Дефект был тихим и ждал
первого же появления сгенерированного или собранного каталога.

## Правка

Карта заменена на список, состав путей и комментарии сохранены:

```yaml
  exclude:
    # Web
    - 'web/**'
    # Build
    - 'build/**'
    - 'lib/generated_plugin_registrant.dart'
    - '.test_coverage.dart'
    # Assets
    - 'assets/**'
```

Оба файла — корневой и `example/analysis_options.yaml` — побайтово одинаковы,
правка применена к обоим одинаково.

Пути не чистились, хотя все они относятся к Flutter-проектам, а этот пакет —
чистый Dart. Файл явно используется владельцем как переносимый шаблон: в нём
включены и другие Flutter-правила (`no_logic_in_create_state`,
`use_build_context_synchronously`, `sized_box_for_whitespace`). Выкидывать из
шаблона его смысл — не задача этой правки.

## Проверка

`dart analyze` — оба предупреждения ушли, осталось одно замечание, к
`analysis_options.yaml` отношения не имеющее (`use_named_constants` в
`example/lib/src/utils/output.dart:3:25`). `dart test` — 60 тестов проходят,
`dart format` — чисто.
