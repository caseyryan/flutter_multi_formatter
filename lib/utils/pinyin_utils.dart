import 'dart:collection';
import 'dart:convert';

import 'package:collection/collection.dart';

import 'hanzi_utils.dart';

class SyllableData {
  String value;
  int tone;
  bool isValid;
  int start;
  int end;
  SyllableData({
    required this.value,
    required this.tone,
    required this.isValid,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toMap() {
    return {
      'value': value,
      'tone': tone,
      'isValid': isValid,
    };
  }

  @override
  String toString() {
    return jsonEncode(toMap());
  }
}

class PinyinUtils {
  static const String UNICODE_SQUARE = '⬜';

  static final RegExp _unstarredTextRegexp = RegExp(r'[^*]+');
  static final RegExp _punctuationRegex = RegExp(r"['!?.\[\],，。？！；：（ ）【 】［］]");
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
    "lue",
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
    "pi",
    "mi",
    "ce",
    "te",
    "na",
    "ai",
    "fa",
    "ba",
    "ou",
    "e",
    "o",
    "a",
    "r",
  ];

  /// Converts unicode sequences to chinese characters
  static String encodeUnicodeToChinese(String unicodeString) {
    unicodeString = unicodeString.replaceAll(r'\\u', r'\u');
    var presplit = unicodeString.split(r'\u')..removeAt(0);
    final result = String.fromCharCodes(
      presplit.map<int>((hex) => int.parse(hex, radix: 16)),
    );
    return result;
  }

  static String clearPunctuation(String value) {
    return value.replaceAll(_punctuationRegex, '');
  }

  /// Pass a tone or untoned pinyin and get a list
  /// of toned vowels that can be in this pinyin
  static List<String> promptTonesForPinyin(String pinyin) {
    final chars = HashSet<String>.from(
      PinyinUtils.simplifyPinyin(pinyin).split(''),
    ).toList();
    final temp = <String>[];
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (_mappedVowels.containsKey(char)) {
        temp.addAll(_mappedVowels[char]!);
      }
    }

    return temp;
  }

  final _toneRegexp = RegExp(r'[āáǎàēéěèōóǒòīíǐìūúǔùǖǘǚǜü]+');

  bool containsTone(String text) {
    return _toneRegexp.hasMatch(text);
  }

  /// Returns a list of tones for the whole sentence
  static List<int> getPinyinTones(String sentence) {
    return splitToSyllables<SyllableData>(sentence)
        .where((e) => e.isValid)
        .map(
          (e) => e.value,
        )
        .map(getPinyinTone)
        .toList();
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
  static const _uDottedS = '(?:ü|ǖ|ǘ|ǚ|ǚ|ü̆|ǜ)';

  static const Map<String, List<String>> _mappedVowels = {
    'a': ['ā', 'á', 'ǎ', 'à'],
    'e': ['ē', 'é', 'ě', 'è'],
    'i': ['ī', 'í', 'ǐ', 'ì'],
    'o': ['ō', 'ó', 'ǒ', 'ò'],
    'u': ['ū', 'ú', 'ǔ', 'ù', 'ü', 'ǖ', 'ǘ', 'ǚ', 'ǜ'],
  };

  static Map<String, List<String>> get mappedVowels {
    return _mappedVowels;
  }

  static final RegExp _aRegex = RegExp('[$_aS]');
  static final RegExp _eRegex = RegExp('[$_eS]');
  static final RegExp _iRegex = RegExp('[$_iS]');
  static final RegExp _oRegex = RegExp('[$_oS]');
  static final RegExp _uRegex = RegExp('[$_uS]');

  /// https://stackoverflow.com/questions/74223173/simple-regexp-matches-what-it-shouldnt/74223270#74223270
  static final RegExp _uDottedRegex = RegExp(_uDottedS, unicode: true);
  static final RegExp _vRegex = RegExp('[$_vS]');
  static final RegExp _spaceRegex = RegExp(r'\s+');

  /// createds a generic regular expression that allows
  /// you to search a pinyin regardless of its tone
  /// e.g. in a database request
  static RegExp? createRegexpForPinyinSearch(String syllable) {
    if (syllable.isEmpty) return null;
    syllable = simplifyPinyin(syllable);
    final allVowelsMatch = RegExp('[aouei]+').firstMatch(syllable);
    if (allVowelsMatch != null) {
      final vowels = syllable.substring(
        allVowelsMatch.start,
        allVowelsMatch.end,
      );
      final presplit = vowels.split('');

      String preffix = '^';
      final buffer = StringBuffer('');
      if (allVowelsMatch.start > 0) {
        preffix += syllable.substring(
          0,
          allVowelsMatch.start,
        );
      }
      for (var v in presplit) {
        if (v == 'u') {
          buffer.write('[(?:u|ū|ú|ǔ|ŭ|ù|ü|ǖ|ǘ|ǚ|ǚ|ü̆|ǜ)]');
        } else if (v == 'a') {
          buffer.write('[aāáǎăà]');
        } else if (v == 'o') {
          buffer.write('[oōóǒŏò]');
        } else if (v == 'e') {
          buffer.write('[eēéěĕè]');
        } else if (v == 'i') {
          buffer.write('[iīíǐĭì]');
        }
      }
      if (allVowelsMatch.end < syllable.length) {
        buffer.write(syllable.substring(allVowelsMatch.end));
      }
      buffer.write(r'$');
      final result = '$preffix${buffer.toString()}';
      return RegExp(result);
    }
    return RegExp(syllable);
  }

  /// converts all spcial symbols in pinyin to it's
  /// normal latin analog like ě -> e or ǔ -> u
  static String simplifyPinyin(String pinyin) {
    int i = pinyin.length;
    while (pinyin.contains(_aRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_aRegex, 'a');
      if (i <= 0) break;
    }
    i = pinyin.length;
    while (pinyin.contains(_eRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_eRegex, 'e');
      if (i <= 0) break;
    }
    i = pinyin.length;
    while (pinyin.contains(_iRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_iRegex, 'i');
      if (i <= 0) break;
    }
    i = pinyin.length;
    while (pinyin.contains(_oRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_oRegex, 'o');
      if (i <= 0) break;
    }
    i = pinyin.length;
    while (pinyin.contains(_uRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_uRegex, 'u');
      if (i <= 0) break;
    }

    /// i is just a safeguard from an endless loop
    i = pinyin.length;
    while (pinyin.contains(_uDottedRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_uDottedRegex, 'u');
      if (i <= 0) break;
    }
    i = pinyin.length;
    while (pinyin.contains(_vRegex)) {
      i--;
      pinyin = pinyin.replaceFirst(_vRegex, 'v');
      if (i <= 0) break;
    }
    return pinyin;
  }

  /// some sillables might be mistakingly separated in a wrong way
  /// this map contains exceptions. That must replace original text
  /// so it would split more precisely
  static const Map<String, String> _splittableExceptions = {
    'nine': 'ni ne',
    'jini': 'ji ni',
  };

  static String splitToSyllablesBySeparator(
    String value, [
    String separator = "'",
  ]) {
    final spaceRegexp = RegExp(r"\s+");
    final apostropheRegexp = RegExp("[$separator]+");
    const empty = '';
    value = value
        .replaceAll(
          apostropheRegexp,
          empty,
        )
        .replaceAll(spaceRegexp, empty);
    return splitToSyllables<String>(value).join(separator);
  }

  static List<T> splitToSyllables<T>(
    String value, {
    bool removePunctuation = true,
  }) {
    assert(
      T == String || T == SyllableData,
      'T can only be a String or a SyllableData',
    );
    value = value.replaceAll('\'', '');
    var simplified = simplifyPinyin(value);

    /// тут надо вставить предопределенные пробелы, чтобы
    /// избежать случаев, когда, анприметр nine делится не как
    /// ni ne, а как nin e
    for (var kv in _splittableExceptions.entries) {
      if (simplified.contains(kv.key)) {
        int indexOfSpace = kv.value.indexOf(' ');
        int indexOfFoundValue = simplified.indexOf(kv.key);
        final presplit = value.split('');
        presplit.insert(indexOfFoundValue + indexOfSpace, ' ');
        value = presplit.join();
        return splitToSyllables(value);
      }
    }

    if (value.contains(_spaceRegex)) {
      final list = value.split(_spaceRegex);
      final res = <T>[];
      for (var subsentence in list) {
        final results = splitToSyllables<T>(subsentence);
        res.addAll(results);
      }
      return res;
    }
    List<_Sentence> allPossibleSentences = [];
    _findSentenceWithBiggerScore(
      value,
      allPossibleSentences: allPossibleSentences,
    );
    // print(allPossibleSentences);
    if (allPossibleSentences.isNotEmpty) {
      _Sentence? sentence;
      // print(allPossibleSentences);
      if (allPossibleSentences.length > 1) {
        for (var s in allPossibleSentences) {
          s.toCorrectSequence(true);
        }
        allPossibleSentences.sort(
          (a, b) => a.totalUseRank.compareTo(b.totalUseRank),
        );
      }
      sentence = allPossibleSentences.first;
      final correctSequence = sentence.toCorrectSequence();
      if (T == String) {
        return correctSequence.map((e) => e.value).toList() as List<T>;
      }
      return correctSequence as List<T>;
    }

    return [];
  }

  /// counts the number of syllables in a text line
  static int countNumSyllables(String value) {
    return RegExp('[aouei]{1,2}').allMatches(value).length;
  }

  /// суть в том, чтобы для каждого максимально длинного слона найти
  /// из списка его под слоги и сгруппировать с ним а потом, при каждом ошибочном
  /// использовании слога, увеличивать итератор и брать для подстановки следующий
  /// из списка
  //   {
  //   "syllables": [],
  //   "iterator": 0,
  // }

  static List<_Subsyllable> _splitToSubsyllables(
    List<String> syllables,
  ) {
    var result = <_Subsyllable>[];
    syllables.sort(((a, b) => b.length.compareTo(a.length)));

    for (int i = 0; i < syllables.length; i++) {
      var syl = syllables[i];
      result.add(_Subsyllable()..syllables.add(syl));
      for (var j = i + 1; j < syllables.length; j++) {
        var subSyl = syllables[j];
        if (syl.contains(subSyl)) {
          result.last.syllables.add(subSyl);
        }
      }
    }
    return result;
  }

  /// this method tries to find the maximum number of possible
  /// syllables in a line of text. It might happen that it finds
  /// more than one sentence with the same summary length of all
  /// syllables. To avoid this it will take every syllable,
  /// calculate a power of its length, and then sum up all powers
  /// This allows it to sort the sentences with longer syllables
  /// before the others. So in 99% of cases the first sentence in
  /// an array will be the most fitting one
  static void _findSentenceWithBiggerScore(
    String value, {
    List<String>? allPossibleSyllables,
    int? numSyllables,
    String? simplified,
    List<_Subsyllable>? subsyllables,
    List<_Sentence>? allPossibleSentences,
    bool removePunctuation = true,
  }) {
    if (removePunctuation) {
      value = clearPunctuation(value);
    }
    simplified ??= simplifyPinyin(value);
    numSyllables ??= countNumSyllables(simplified);
    if (allPossibleSyllables == null) {
      allPossibleSyllables = [];
      for (var syl in _allSyllables) {
        final regExp = RegExp(syl);
        final numOccurences = regExp.allMatches(simplified).length;
        for (var i = 0; i < numOccurences; i++) {
          allPossibleSyllables.add(syl);
        }
      }
    }
    subsyllables ??= _splitToSubsyllables(allPossibleSyllables);
    if (subsyllables.length == 1) {
      allPossibleSentences ??= [];
      allPossibleSentences.add(
        _Sentence(
          simplified: simplified,
          initialValue: value,
        )..possibleSyllables.add(
            subsyllables.first.currentSyllable,
          ),
      );
    } else if (_hasIncomplete(subsyllables) ||
        (allPossibleSentences?.isEmpty == true && subsyllables.isNotEmpty)) {
      allPossibleSentences ??= [];
      String tempValue = simplified;
      _Sentence sentence = _Sentence(
        simplified: simplified,
        initialValue: value,
      );
      allPossibleSentences.add(sentence);
      for (var subsyl in subsyllables) {
        final curSyl = subsyl.currentSyllable;
        if (tempValue.contains(curSyl)) {
          sentence.possibleSyllables.add(curSyl);
          tempValue = tempValue.replaceFirst(curSyl, '');
        }
      }

      /// нужно обязательно переключить на следующий подслог
      /// чтобы избежать бесконечной рекурсии
      subsyllables.firstWhereOrNull((s) => s.isIncomplete)?.next();

      /// надо вызывать рекурентно до тех пор, пока не закончатся все варианты
      _findSentenceWithBiggerScore(
        value,
        allPossibleSyllables: allPossibleSyllables,
        numSyllables: numSyllables,
        simplified: simplified,
        subsyllables: subsyllables,
        allPossibleSentences: allPossibleSentences,
        removePunctuation: removePunctuation,
      );
    } else {
      final maxScoredSentences =
          _getSentencesWithMaxScore(allPossibleSentences!);
      allPossibleSentences.clear();
      allPossibleSentences.addAll(maxScoredSentences);
    }
  }

  static List<_Sentence> _getSentencesWithMaxScore(List<_Sentence> value) {
    final temp = <_Sentence>[];
    value = HashSet<_Sentence>.from(value).toList();

    /// тут уже все возможные варианты отсортированные по скору
    /// скор расчитывается как отношение общей длины всех найденных слогов
    /// к длине исходной фразы. Чем больше скор, тем больше совпадений в предложении
    value.sort((a, b) => b.score.compareTo(a.score));
    final maxScore = value.firstOrNull?.score ?? 0;
    for (var s in value) {
      if (s.score < maxScore) {
        break;
      }
      temp.add(s);
    }
    return temp;
  }

  static bool _hasIncomplete(List<_Subsyllable> subsyllables) {
    return subsyllables.any((e) => e.isIncomplete);
  }
}

/// при проверке совпадений в слове берется первый из таких объектов
/// у которого isComplete == false, и дальше в слово начинают подставляться
/// все последующие слоги. После первой неудачной попытки у слога вызвается next()
/// чтобы повысить итератор, и снова происходит та же процедура.
/// Как только подслог становится isComplete == true, переключаемся на слудующий
/// слог и там та же процедура
class _Subsyllable {
  int _iterator = 0;
  List<String> syllables = [];

  /// нужно, чтобы переключиться на проверку следующего слога из списка
  bool get isComplete {
    return _iterator >= syllables.length - 1;
  }

  bool get isIncomplete {
    return !isComplete;
  }

  void next() {
    _iterator++;
    if (_iterator >= syllables.length) {
      _iterator = syllables.length - 1;
    }
  }

  String get currentSyllable {
    return syllables[_iterator];
  }
}

class _Sentence {
  final String initialValue;
  final String simplified;

  List<String> possibleSyllables = [];
  _Sentence({
    required this.initialValue,
    required this.simplified,
  });

  @override
  bool operator ==(covariant _Sentence other) {
    return other.toString() == toString();
  }

  @override
  int get hashCode {
    return toString().hashCode;
  }

  int get totalSyllablesLength {
    int l = 0;
    for (var syl in possibleSyllables) {
      l += syl.length;
    }
    return l;
  }

  double get score {
    return totalSyllablesLength / initialValue.length;
  }

  /// бывает так, что в список попадают предложения с
  /// одинаковым весом, но в одном больше длинных слогов, а в
  /// другом больше коротких. Предпочтение надо отдавать тем предложениям
  /// в которых наибольшее количество длинных слогов
  /// для этого суммируются не длины каждого слога, а их степени
  // int get syllablesWeight {
  //   int power = 0;
  //   for (var syl in possibleSyllables) {
  //     // power += pow(syl.length, 2).toInt();
  //   }
  //   return power;
  // }

  /// заполняется только если найдено более одного варианта предложений
  int _totalUseRank = 0;
  int get totalUseRank => _totalUseRank;

  List<SyllableData>? _correctSequence;

  List<SyllableData> toCorrectSequence([
    bool rankByUse = false,
  ]) {
    if (_correctSequence != null) {
      return _correctSequence!;
    }
    _correctSequence = <SyllableData>[];
    var temp = simplified;
    possibleSyllables.sort((a, b) => b.length.compareTo(a.length));
    for (var syl in possibleSyllables) {
      int start = temp.indexOf(syl);
      int end = start + syl.length;
      if (start < 0) {
        continue;
      }
      final filler = _getFiller(syl);
      temp = temp.replaceFirst(syl, filler);
      final realSyllable = initialValue.substring(
        start,
        end,
      );

      /// valid syllable addition
      _correctSequence!.add(
        SyllableData(
          value: realSyllable,
          tone: PinyinUtils.getPinyinTone(realSyllable),
          isValid: true,
          start: start,
          end: end,
        ),
      );
    }
    final unstarred = PinyinUtils._unstarredTextRegexp;

    /// заменяет оставшиеся символы, которые не совпали с валидными слогами
    final matches = unstarred.allMatches(temp);
    for (var m in matches) {
      final text = temp.substring(m.start, m.end);
      _correctSequence!.add(
        SyllableData(
          value: text,
          tone: -1,
          isValid: false,
          start: m.start,
          end: m.end,
        ),
      );
    }

    const invalidTone = -1;
    _correctSequence!.sort((a, b) => a.start.compareTo(b.start));
    final wrongSyllables = <SyllableData>[];

    /// here we also need to find all the parts that were
    /// not parts of valid syllables but are parts of innitial
    /// input
    for (int i = 0; i < _correctSequence!.length; i++) {
      final curSyllable = _correctSequence![i];
      final isFirst = i == 0;
      final isLast = i == _correctSequence!.length - 1;
      if (isFirst) {
        if (curSyllable.start != 0) {
          wrongSyllables.add(
            SyllableData(
              value: initialValue.substring(
                0,
                curSyllable.start,
              ),
              tone: invalidTone,
              isValid: false,
              start: 0,
              end: curSyllable.start,
            ),
          );
        }
      }
      if (isLast) {
        if (curSyllable.end != initialValue.length) {
          wrongSyllables.add(
            SyllableData(
              value: initialValue.substring(
                curSyllable.end,
              ),
              tone: invalidTone,
              isValid: false,
              start: curSyllable.end,
              end: initialValue.length,
            ),
          );
        }
      }
      if (!isFirst && !isLast) {
        final previous = _correctSequence![i - 1];
        if (previous.end != curSyllable.start) {
          final wrongSyllable = initialValue.substring(
            previous.end,
            curSyllable.start,
          );

          wrongSyllables.add(
            SyllableData(
              value: wrongSyllable,
              tone: invalidTone,
              isValid: false,
              start: previous.end,
              end: curSyllable.start,
            ),
          );
        }
      }
    }
    if (rankByUse) {
      for (var r in _correctSequence!) {
        List<HanziRankInfo> rankInfo =
            HanziUtils.findHanziRankByPinyin(r.value);
        int rank = rankInfo.firstOrNull?.fequencyRank ?? 10000;
        _totalUseRank += rank;
      }
    }

    _correctSequence!.addAll(wrongSyllables);
    _correctSequence!.sort((a, b) => a.start.compareTo(b.start));
    return _correctSequence!;
  }

  static String _getFiller(String syllable) {
    StringBuffer s = StringBuffer();
    for (var i = 0; i < syllable.length; i++) {
      s.write('*');
    }
    return s.toString();
  }

  @override
  String toString() {
    possibleSyllables.sort();
    return possibleSyllables.join(' ');
  }
}
