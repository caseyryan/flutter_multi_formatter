import 'dart:convert';

class SyllableData {
  String value;
  int tone;
  bool isValidSyllable;
  SyllableData({
    required this.value,
    required this.tone,
    required this.isValidSyllable,
  });

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'tone': tone,
      'isValidSyllable': isValidSyllable,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}

class PinyinUtils {
  static final RegExp _punctuationRegex = RegExp(r"['!?.\[\],，。？！；：（ ）【 】［］]");
  static final _notAsteristRegex = RegExp(r'[^*]');
  static const _allSyllables = [
    "zhuang",
    "shuang",
    "chuang",
    "jiong",
    "xiang",
    "kuang",
    "shang",
    "chuai",
    "zhuan",
    "chong",
    "guang",
    "shuan",
    "chang",
    "jiang",
    "zheng",
    "shuai",
    "qiong",
    "huang",
    "zhuai",
    "liang",
    "zhong",
    "xiong",
    "sheng",
    "cheng",
    "chuan",
    "zhang",
    "qiang",
    "niang",
    "cang",
    "ping",
    "kuan",
    "chai",
    "chou",
    "rong",
    "heng",
    "lang",
    "xing",
    "qian",
    "miao",
    "zhui",
    "dong",
    "mang",
    "cong",
    "tuan",
    "juan",
    "shai",
    "shen",
    "shun",
    "tang",
    "ceng",
    "deng",
    "shei",
    "lian",
    "xiao",
    "seng",
    "zhan",
    "tian",
    "geng",
    "ting",
    "pang",
    "shui",
    "ming",
    "zhen",
    "ruan",
    "dang",
    "kuai",
    "huai",
    "suan",
    "tiao",
    "gang",
    "guai",
    "piao",
    "biao",
    "hong",
    "liao",
    "guan",
    "bing",
    "ying",
    "ding",
    "shan",
    "shou",
    "cuan",
    "gong",
    "kong",
    "duan",
    "shao",
    "neng",
    "pian",
    "ning",
    "chua",
    "wang",
    "tong",
    "long",
    "chuo",
    "qing",
    "jing",
    "huan",
    "keng",
    "song",
    "nang",
    "yong",
    "zhou",
    "chao",
    "zhei",
    "hang",
    "zhun",
    "chun",
    "zhao",
    "zong",
    "diao",
    "xuan",
    "zhua",
    "zuan",
    "shua",
    "mian",
    "sang",
    "jiao",
    "peng",
    "luan",
    "feng",
    "fang",
    "niao",
    "nuan",
    "zhuo",
    "meng",
    "yang",
    "leng",
    "nong",
    "chan",
    "zhai",
    "ling",
    "chui",
    "zeng",
    "xian",
    "dian",
    "shuo",
    "chen",
    "bian",
    "kang",
    "weng",
    "quan",
    "teng",
    "zang",
    "rang",
    "nian",
    "beng",
    "yuan",
    "jian",
    "reng",
    "qiao",
    "bang",
    "xia",
    "zuo",
    "gei",
    "duo",
    "bai",
    "lei",
    "ran",
    "cen",
    "zan",
    "sui",
    "nen",
    "zai",
    "bei",
    "yao",
    "jiu",
    "hui",
    "guo",
    "chi",
    "yun",
    "wai",
    "den",
    "mao",
    "hou",
    "she",
    "gui",
    "tui",
    "diu",
    "dan",
    "wei",
    "hao",
    "tai",
    "gan",
    "lve",
    "zha",
    "huo",
    "luo",
    "kuo",
    "sou",
    "jia",
    "bie",
    "qin",
    "niu",
    "lie",
    "mai",
    "hun",
    "kei",
    "tun",
    "gai",
    "que",
    "chu",
    "dai",
    "ruo",
    "fen",
    "xun",
    "nai",
    "ang",
    "sao",
    "miu",
    "kua",
    "hen",
    "xie",
    "mou",
    "you",
    "kai",
    "nie",
    "suo",
    "fei",
    "gua",
    "nou",
    "san",
    "pou",
    "zao",
    "lun",
    "cuo",
    "gou",
    "tao",
    "gen",
    "zhe",
    "yue",
    "zei",
    "tie",
    "dui",
    "dun",
    "kui",
    "jin",
    "bin",
    "qie",
    "shi",
    "cei",
    "nao",
    "tou",
    "xin",
    "pen",
    "zhu",
    "lao",
    "fou",
    "can",
    "man",
    "tan",
    "fan",
    "zui",
    "pie",
    "zen",
    "dei",
    "sun",
    "nin",
    "zun",
    "ben",
    "yan",
    "cao",
    "lia",
    "wan",
    "rao",
    "rui",
    "jie",
    "ken",
    "hei",
    "lou",
    "pao",
    "men",
    "pei",
    "hai",
    "kan",
    "xiu",
    "nan",
    "yin",
    "kao",
    "mei",
    "kou",
    "gao",
    "tuo",
    "qun",
    "ren",
    "cui",
    "bao",
    "cai",
    "nei",
    "zhi",
    "pin",
    "cun",
    "hng",
    "lan",
    "rua",
    "cou",
    "sha",
    "qia",
    "lai",
    "jun",
    "sei",
    "rou",
    "gun",
    "shu",
    "kun",
    "dao",
    "run",
    "nuo",
    "che",
    "ban",
    "min",
    "liu",
    "jue",
    "xue",
    "lin",
    "zou",
    "hua",
    "cha",
    "mie",
    "sai",
    "han",
    "dou",
    "pai",
    "qiu",
    "wen",
    "die",
    "pan",
    "sen",
    "nve",
    "ha",
    "nu",
    "xi",
    "le",
    "lu",
    "pu",
    "ke",
    "zu",
    "en",
    "xu",
    "gu",
    "du",
    "ji",
    "wu",
    "pa",
    "li",
    "ei",
    "lv",
    "se",
    "hu",
    "yi",
    "ze",
    "ka",
    "ti",
    "ri",
    "bu",
    "bo",
    "ye",
    "hm",
    "zi",
    "er",
    "su",
    "an",
    "wa",
    "mu",
    "yu",
    "po",
    "cu",
    "di",
    "ku",
    "ru",
    "ga",
    "da",
    "ne",
    "tu",
    "ya",
    "qi",
    "ng",
    "la",
    "qu",
    "ao",
    "ni",
    "mo",
    "ta",
    "ci",
    "ju",
    "ge",
    "fo",
    "he",
    "de",
    "sa",
    "fu",
    "ca",
    "nv",
    "bi",
    "wo",
    "re",
    "me",
    "si",
    "ma",
    "mi",
    "ce",
    "te",
    "na",
    "ai",
    "pi",
    "za",
    "fa",
    "ou",
    "ba",
    "e",
    "m",
    "o",
    "n",
    "a",
    "r",
  ];

  static String clearPunctuation(String value) {
    return value.replaceAll(_punctuationRegex, '');
  }

  final _toneRegexp = RegExp(r'[āáǎàēéěèōóǒòīíǐìūúǔùǖǘǚǜü]+');

  bool containsTone(String text) {
    return _toneRegexp.hasMatch(text);
  }

  /// Returns a list of tones for the whole sentence
  static List<int> getPinyinTones(String sentence) {
    return splitToSyllables<String>(sentence).map(getPinyinTone).toList();
  }

  /// Detects a tone of a single syllable where 5 means neutral tone
  /// it works for one syllable only. If you need to detect
  /// tones of a sentence, use getPinyinTones() instead
  static int getPinyinTone(String syllable) {
    final tones = [
      ['ā', 'ē', 'ō', 'ī', 'ū', 'ǖ'],
      ['á', 'é', 'ó', 'í', 'ú', 'ǘ'],
      ['ǎ', 'ě', 'ǒ', 'ǐ', 'ǔ', 'ǚ'],
      ['à', 'è', 'ò', 'ì', 'ù', 'ǜ'],
    ];
    for (int i = 0; i < tones.length; i++) {
      final list = tones[i];
      if (list.any((s) => syllable.contains(s))) {
        return i + 1;
      }
    }
    return 5;
  }

  static const _aS = 'āáǎăà';
  static const _eS = 'ēéěĕè';
  static const _iS = 'īíǐĭì';
  static const _oS = 'ōóǒŏò';
  static const _uS = 'ūúǔŭù';
  static const _vS = 'v̄v́v̆v̌v̀';

  static final RegExp _aRegex = RegExp('[$_aS]');
  static final RegExp _eRegex = RegExp('[$_eS]');
  static final RegExp _iRegex = RegExp('[$_iS]');
  static final RegExp _oRegex = RegExp('[$_oS]');
  static final RegExp _uRegex = RegExp('[$_uS]');

  /// https://stackoverflow.com/questions/74223173/simple-regexp-matches-what-it-shouldnt/74223270#74223270
  static final RegExp _uDottedRegex = RegExp('(?:ü|ǖ|ǘ|ǚ|ǚ|ü̆|ǜ)', unicode: true);
  static final RegExp _vRegex = RegExp('[$_vS]');

  /// converts all spcial symbols in pinyin to it's
  /// normal latin analog like ě -> e or ǔ -> u
  static String simplifyPinyin(String pinyin) {
    while (pinyin.contains(_aRegex)) {
      pinyin = pinyin.replaceFirst(_aRegex, 'a');
    }
    while (pinyin.contains(_eRegex)) {
      pinyin = pinyin.replaceFirst(_eRegex, 'e');
    }
    while (pinyin.contains(_iRegex)) {
      pinyin = pinyin.replaceFirst(_iRegex, 'i');
    }
    while (pinyin.contains(_oRegex)) {
      pinyin = pinyin.replaceFirst(_oRegex, 'o');
    }
    while (pinyin.contains(_uRegex)) {
      pinyin = pinyin.replaceFirst(_uRegex, 'u');
    }

    /// i is just a safeguard from an endless loop
    int i = pinyin.length;
    while (pinyin.contains(_uDottedRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_uDottedRegex, 'u');
      if (i <= 0) break;
    }
    while (pinyin.contains(_vRegex)) {
      pinyin = pinyin.replaceFirst(_vRegex, 'v');
    }
    return pinyin;
  }

  static String splitToSyllablesBySeparator(
    String value, [
    String separator = "'",
  ]) {
    final spaceRegexp = RegExp(r"\s+");
    final apostropheRegexp = RegExp("[$separator]+");
    const empty = '';
    value = value.replaceAll(apostropheRegexp, empty).replaceAll(spaceRegexp, empty);
    return splitToSyllables<String>(value).join(separator);
  }

  static List<T> splitToSyllables<T>(
    String value, {
    bool removePunctuation = true,
  }) {
    var reversedValues = _innerSplitToSyllablesReversed(
      value,
      removePunctuation: false,
      firstRun: true,
      accumulatedValues: {},
    );
    return _postProcessSyllables<T>(
      reversedValues,
      value,
    );
  }

  static List<T> _postProcessSyllables<T>(
    Map<int, Map<String, dynamic>> reversed,
    String initialValue,
  ) {
    assert(
      T == String || T == SyllableData,
      'T can only be a String or SyllableData',
    );
    final list = <T>[];
    var s = StringBuffer();
    for (var kv in reversed.entries.toList().reversed) {
      final end = initialValue.length - kv.key;
      final isValid = kv.value['isValid'];
      final value = _reverseString(kv.value['value']);
      final start = initialValue.length - (value.length + kv.key);
      final sub = initialValue.substring(start, end);
      if (isValid) {
        if (s.isNotEmpty) {
          /// записывает невалидные значения
          if (T == SyllableData) {
            list.add(
              SyllableData(
                value: s.toString(),
                tone: -1,
                isValidSyllable: false,
              ) as T,
            );
          }
          if (T == String) {
            list.add(s.toString() as T);
          }
        }

        if (T == SyllableData) {
          list.add(
            SyllableData(
              value: sub,
              tone: getPinyinTone(sub),
              isValidSyllable: true,
            ) as T,
          );
        } else if (T == String) {
          list.add(sub as T);
        }
        s = StringBuffer();
      } else {
        s.write(sub);
      }
    }
    if (s.isNotEmpty) {
      if (T == SyllableData) {
        list.add(
          SyllableData(
            value: s.toString(),
            tone: -1,
            isValidSyllable: false,
          ) as T,
        );
      } else {
        list.add(s.toString() as T);
      }
    }
    return list;
  }

  /// [value] a string to split into pinyin syllables
  /// [removePunctuation] whether to remove punctuation marks
  /// like commas, periods, colons etc. or not
  /// [initialValue] is required to save original request
  /// and map the syllables to it
  static Map<int, Map<String, dynamic>> _innerSplitToSyllablesReversed(
    String value, {
    bool removePunctuation = true,
    bool firstRun = true,
    required Map<int, Map<String, dynamic>> accumulatedValues,
  }) {
    if (value.isEmpty) {
      return {};
    }
    if (removePunctuation) {
      value = clearPunctuation(value);
    }
    var tempValue = firstRun ? _reverseString(simplifyPinyin(value)) : value;
    var reversedSyllables = _allSyllables.reversed.map(_reverseString).toList();

    /// the number of iterations here doesn't matter
    /// it must be as big as possible. Anyway the loop breaks
    /// when all possible syllables are checked
    for (var i = 0; i < 10000000; i++) {
      final start = tempValue.indexOf(_notAsteristRegex);
      String foundCandidate = '';
      for (var syl in reversedSyllables) {
        if (tempValue.indexOf(syl) == start && start > -1) {
          foundCandidate = syl;
        }
      }

      if (foundCandidate.isEmpty) {
        /// if no candidate was found at the beginning,
        /// we need to repeate the search by with a shortened string
        if (start + 1 < tempValue.length) {
          final accValue = tempValue.substring(start, start + 1);
          accumulatedValues[start] = {
            'value': accValue,
            'isValid': false,
          };
          return _innerSplitToSyllablesReversed(
            tempValue.replaceRange(start, start + 1, '*'),
            firstRun: false,
            removePunctuation: false,
            accumulatedValues: accumulatedValues,
          );
        } else {
          /// nothing found at all
          final unfoundValue = tempValue.replaceAll('*', '');
          accumulatedValues[start] = {
            'value': unfoundValue,
            'isValid': false,
          };
          break;
        }
      }
      if (foundCandidate.isNotEmpty) {
        final end = start + foundCandidate.length;
        final accValue = tempValue.substring(start, end);
        accumulatedValues[start] = {
          'value': accValue,
          'isValid': true,
        };
        tempValue = tempValue.replaceRange(
          start,
          end,
          _getFiller(foundCandidate),
        );
        if (end >= tempValue.length) {
          break;
        }
      }
    }
    return accumulatedValues;
  }

  static String _reverseString(String value) {
    StringBuffer s = StringBuffer();
    for (var i = value.length - 1; i >= 0; i--) {
      s.write(value[i]);
    }
    return s.toString();
  }

  static String _getFiller(String syllable) {
    StringBuffer s = StringBuffer();
    for (var i = 0; i < syllable.length; i++) {
      s.write('*');
    }
    return s.toString();
  }
}
