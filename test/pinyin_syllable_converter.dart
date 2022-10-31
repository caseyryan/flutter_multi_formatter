import 'package:flutter_multi_formatter/utils/pinyin_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Tests pinyin format', () {
    var result = PinyinUtils.splitToSyllables<SyllableData>(
      'wǒhěngāoxìngrènshinǐ',
    );
    final numValid = result.where((e) => e.isValid).length;
    expect(
      numValid,
      7,
      reason: 'Expcted number of valid syllables is 7',
    );
  });
}
