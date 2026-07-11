import 'package:flutter_data_components/fdc.dart';
import 'package:flutter_data_components/src/common/codecs/fdc_value_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FdcValueCodec<Object?> integerCodec({bool negative = true}) {
    return FdcValueCodecResolver.resolve<Object?>(
      FdcValueCodecConfig(
        kind: FdcValueCodecKind.integer,
        sourceName: 'quantity',
        label: 'Quantity',
        negative: negative,
        formatSettings: const FdcFormatSettings(),
      ),
    );
  }

  test(
    'integer codec accepts integer text without storage-specific range checks',
    () {
      final result = integerCodec().parseForCommit(
        '11111111111111111111111111',
      );

      expect(result.errorText, isNull);
      expect(result.value.toString(), '11111111111111111111111111');
    },
  );
}
