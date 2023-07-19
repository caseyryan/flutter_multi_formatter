/// My implementation of th Luhn algorithm 
/// https://en.wikipedia.org/wiki/Luhn_algorithm
bool checkNumberByLuhn({
  required String number,
}) {
  final luhn = _LuhnAlgo(
    number: number,
  );
  return luhn.isValid;
}

final _digits = RegExp(r'\d+');

class _LuhnAlgo {
  _LuhnAlgo({
    required this.number,
  }) {
    if (number.isNotEmpty) {
      final digitList = _digits
          .allMatches(number)
          .map(
            (e) => number.substring(e.start, e.end),
          )
          .join('')
          .split('')
          .map((e) => int.parse(e))
          .toList();
      for (var i = 0; i < digitList.length; i++) {
        if (i % 2 != 0) {
          _resultingNumbers.add(
            _OddNumberWrapper(digitList[i]).result,
          );
        } else {
          _resultingNumbers.add(digitList[i]);
        }
      }
      _finalResult = _resultingNumbers.fold(
        0,
        (prev, cur) => prev + cur,
      );
    }
  }

  String number;
  List<int> _resultingNumbers = [];
  int _finalResult = -1;

  bool get isValid {
    if (_resultingNumbers.isEmpty) {
      return false;
    }
    return _finalResult % 10 == 0;
  }
}

class _OddNumberWrapper {
  int number;
  _OddNumberWrapper(this.number) {
    number = number * 2;
    if (number > 10) {
      number = number.toString().split('').map((e) => int.parse(e)).fold(
            0,
            (previousValue, element) => element + previousValue,
          );
    }
  }

  int get result {
    return number;
  }
}
