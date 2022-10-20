/// The logic of this class is almost a direct Dart port of this JS
/// repo https://github.com/Connum/npm-pinyin-separate
/// with some minor changes and improvements
class PinyinUtils {
  static final RegExp _punctuationRegex = RegExp(r"['!?.\[\],，。？！；：（ ）【 】［］]");
  static const vowels = 'aāáǎăàeēéěĕèiīíǐĭìoōóǒŏòuūúǔŭùüǖǘǚǚü̆ǜvv̄v́v̆v̌v̀';
  static const tones =
      'ā|á|ǎ|ă|à|ē|é|ě|ĕ|è|ī|í|ǐ|ĭ|ì|ō|ó|ǒ|ŏ|ò|ū|ú|ǔ|ŭ|ù|ǖ|ǘ|ǚ|ǚ|ü̆|ǜ|v̄|v́|v̆|v̌|v̀';
  static const initials = 'b|p|m|f|d|t|n|l|g|k|h|j|q|x|zh|ch|sh|r|z|c|s';
  static final List<RegExp> _regExps = [
    RegExp('\'', caseSensitive: false),
    RegExp('($tones)($tones)', caseSensitive: false),
    // RegExp('([$vowels])([^${vowels}nr])', caseSensitive: false),
    /// Not sure about this line. If use the upper (commented one) it will not split
    /// syllable "ne" in phrases like wo hen hau ni ne
    RegExp('([$vowels])(([^${vowels}nr])|(ne))', caseSensitive: false),
    RegExp('(\\w)([csz]h)', caseSensitive: false),
    RegExp('([\${vowels}]{2}(ng? )?)([^\\snr])', caseSensitive: false),
    RegExp('([\${vowels}]{2})(n[\${vowels}])', caseSensitive: false),
    RegExp('(n)([^${vowels}vg])', caseSensitive: false),
    RegExp('((ch|sh|(y|b|p|m|f|d|t|n|l|j|q|x)i)(a|ā|á|ǎ|ă|à)) (o)',
        caseSensitive: false),
    RegExp(
      '(w|gu|ku|hu|zhu|chu|shu)(a|ā|á|ǎ|ă|à) (i)',
      caseSensitive: false,
    ),
    RegExp(
      '((a|ā|á|ǎ|ă|à)o)($initials)',
      caseSensitive: false,
    ),
    RegExp(
      '((o|ō|ó|ǒ|ŏ|ò)u)($initials)',
      caseSensitive: false,
    ),
    RegExp(
      '(y(u|ū|ú|ǔ|ŭ|ù|ü|ǖ|ǘ|ǚ|ǚ|ü̆|ǜ|v|v̄|v́|v̆|v̌|v̀))(n)(u|ū|ú|ǔ|ŭ|ù|ü|ǖ|ǘ|ǚ|ǚ|ü̆|ǜ|v|v̄|v́|v̆|v̌|v̀)',
      caseSensitive: false,
    ),
    RegExp(
      '([${vowels}v])([^$vowels\\w\\s])([${vowels}v])',
      caseSensitive: false,
    ),
    RegExp(
      '([${vowels}v])(n)(g)([${vowels}v])',
      caseSensitive: false,
    ),
    RegExp(
      '([gr])([^$vowels])',
      caseSensitive: false,
    ),
    RegExp(
      '([^eēéěĕè\\w\\s])(r)',
      caseSensitive: false,
    ),
    RegExp(
      '([^\\w\\s])([eēéěĕè]r)',
      caseSensitive: false,
    ),
    RegExp(
      '\\s{2,}/',
      caseSensitive: false,
    ),
  ];

  static String clearPunctuation(String value) {
    return value.replaceAll(_punctuationRegex, '');
  }

  static final RegExp _aRegex = RegExp(r'[āáǎăà]+');
  static final RegExp _eRegex = RegExp(r'[ēéěĕè]+');
  static final RegExp _iRegex = RegExp(r'[īíǐĭì]+');
  static final RegExp _oRegex = RegExp(r'[ōóǒŏò]+');
  static final RegExp _uRegex = RegExp(r'[ūúǔŭùüǖǘǚǚü̆ǜ]+');
  static final RegExp _vRegex = RegExp(r'[v̄v́v̆v̌v̀]+');

  /// converts all spcial symbols in pinyin to it's
  /// normal latin analog like ě -> e or ǔ -> u
  static String simplifyPinyin(String pinyin) {
    return pinyin
        .replaceAll(_aRegex, 'a')
        .replaceAll(_eRegex, 'e')
        .replaceAll(_iRegex, 'i')
        .replaceAll(_oRegex, 'o')
        .replaceAll(_uRegex, 'u')
        .replaceAll(_vRegex, 'v');
  }

  static String splitToSyllablesBySeparator(
    String value, [
    String separator = " ",
  ]) {
    final result = splitToSyllables(value)
        .join(" ")
        .replaceAll(RegExp(r"[']+"), " ")
        .replaceAll(RegExp(r"\s+"), separator);
    return result;
  }

  /// [value] a string to split into pinyin syllables
  /// [removePunctuation] whether to remove punctuation marks
  /// like commas, periods, colons etc. or not
  static List<String> splitToSyllables(
    String value, {
    bool removePunctuation = true,
  }) {
    if (value.isEmpty) {
      return [];
    }
    if (removePunctuation) {
      value = clearPunctuation(value);
    }
    final pinyin = value
        .replaceAll(_regExps[0], ' ')
        .replaceAllMapped(_regExps[1], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[2], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[3], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[4], (m) => '${m[1]} ${m[3]}')
        .replaceAllMapped(_regExps[5], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[6], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[7], (m) => '${m[1]}${m[5]}')
        .replaceAllMapped(_regExps[8], (m) => '${m[1]}${m[2]}${m[3]}')
        .replaceAllMapped(_regExps[9], (m) => '${m[1]} ${m[3]}')
        .replaceAllMapped(_regExps[10], (m) => '${m[1]} ${m[3]}')
        .replaceAllMapped(_regExps[11], (m) => '${m[1]} ${m[3]}${m[4]}')
        .replaceAllMapped(_regExps[12], (m) => '${m[1]} ${m[2]}${m[3]}')
        .replaceAllMapped(_regExps[13], (m) => '${m[1]}${m[2]} ${m[3]}${m[4]}')
        .replaceAllMapped(_regExps[14], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[15], (m) => '${m[1]} ${m[2]}')
        .replaceAllMapped(_regExps[16], (m) => '${m[1]} ${m[2]}')
        .replaceAll(_regExps[17], ' ');
    return pinyin.split(' ');
  }
}
