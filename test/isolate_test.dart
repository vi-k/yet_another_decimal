/// Разделение экземпляров между изолятами.
///
/// На `ShortDecimal` стоит `@pragma('vm:deeply-immutable')`. Компилятор
/// проверяет только то, что класс аннотации соответствует: поля `final` и не
/// `late`. Что обещанное этим свойство есть на деле — что VM отдаёт другому
/// изоляту тот же экземпляр, а не копию, — не проверяет никто, и проверяется
/// это здесь.
///
/// Признак прямой: отправленный через порт объект возвращается `identical`
/// самому себе. `Decimal` так не умеет и не будет: поле типа `BigInt` эта
/// аннотация отвергает. Обычный класс из двух полей `int` — тоже, и он здесь
/// затем, чтобы показать, что дело именно в аннотации, а не в простоте полей.
@TestOn('vm')
library;

import 'dart:isolate';

import 'package:denary/denary.dart';
import 'package:test/test.dart';

/// Класс, повторяющий поля `ShortDecimal`, но без аннотации.
final class _Plain {
  _Plain(this.base, this.scale);

  final int base;
  final int scale;
}

/// Возвращает отправителю всё, что получил, кроме самого порта.
void _echo(List<Object> message) {
  (message[0] as SendPort).send(message.sublist(1));
}

/// Печатает полученное значение у себя и отдаёт строку.
///
/// Разделённый экземпляр — тот же объект, что и в отправившем изоляте. Здесь
/// проверяется, что пользоваться им можно наравне со своим.
void _print(List<Object> message) {
  final port = message[0] as SendPort;
  final value = message[1] as ShortDecimal;
  port.send(value.toString());
}

/// Прогоняет значения через изолят и возвращает то, что пришло обратно.
Future<List<Object?>> _roundTrip(List<Object> values) async {
  final port = ReceivePort();
  await Isolate.spawn(_echo, <Object>[port.sendPort, ...values]);
  final back = await port.first as List<Object?>;
  port.close();

  return back;
}

void main() {
  group('vm:deeply-immutable', () {
    test('ShortDecimal переживает изолят тем же объектом', () async {
      // Значение строится в рантайме: канонизацию констант исключаем.
      final sent = ShortDecimal(1999, shiftRight: 2);
      final back = await _roundTrip([sent]);

      expect(identical(back.single, sent), isTrue);
      expect(back.single, sent);
    });

    test('Decimal возвращается копией', () async {
      final sent = Decimal(1999, shiftRight: 2);
      final back = await _roundTrip([sent]);

      expect(identical(back.single, sent), isFalse);
      expect(back.single, sent);
    });

    test('такой же класс без аннотации возвращается копией', () async {
      final sent = _Plain(1999, 2);
      final back = await _roundTrip([sent]);

      expect(identical(back.single, sent), isFalse);
    });

    test('разделённое значение печатается в чужом изоляте', () async {
      final sent = ShortDecimal(1999, shiftRight: 2);
      final port = ReceivePort();
      await Isolate.spawn(_print, <Object>[port.sendPort, sent]);
      final printed = await port.first;
      port.close();

      expect(printed, '19.99');
    });

    test('константы семейства разделяются наравне с остальными', () async {
      final back = await _roundTrip([ShortDecimal.ten, ShortDecimal.zero]);

      expect(identical(back[0], ShortDecimal.ten), isTrue);
      expect(identical(back[1], ShortDecimal.zero), isTrue);
    });
  });
}
