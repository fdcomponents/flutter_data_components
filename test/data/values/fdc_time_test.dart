import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FdcTime stores SQL Server time(7) compatible ticks', () {
    final value = FdcTime(
      hour: 12,
      minute: 34,
      second: 56,
      millisecond: 789,
      microsecond: 123,
      tick100ns: 4,
    );

    expect(value.hour, 12);
    expect(value.minute, 34);
    expect(value.second, 56);
    expect(value.millisecond, 789);
    expect(value.microsecond, 123);
    expect(value.tick100ns, 4);
    expect(value.toSqlString(), '12:34:56.7891234');
    expect(value.toSqlString(scale: 3), '12:34:56.789');
  });

  test('FdcTime parses SQL Server time literals', () {
    expect(FdcTime.parse('00:00'), FdcTime(hour: 0));
    expect(
      FdcTime.parse('23:59:59.9999999').ticksSinceMidnight,
      FdcTime.ticksPerDay - 1,
    );
    expect(
      FdcTime.parse('08:15:30.12'),
      FdcTime(hour: 8, minute: 15, second: 30, millisecond: 120),
    );
  });

  test('FdcTime rejects values outside SQL Server time range', () {
    expect(() => FdcTime.parse('24:00:00'), throwsRangeError);
    expect(() => FdcTime.parse('10:60:00'), throwsRangeError);
    expect(() => FdcTime.parse('10:00:60'), throwsRangeError);
    expect(() => FdcTime.parse('10:00:00.12345678'), throwsFormatException);
  });
}
