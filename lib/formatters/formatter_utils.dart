  final RegExp _digitRegex = RegExp(r'\d+');

String toNumericString(String inputString) {
  if (inputString == null) return '';
  var regExp = RegExp(r'\d+');
  return inputString.splitMapJoin(regExp,
      onMatch: (m) => m.group(0),
      onNonMatch: (nm) => ''
  );
}
bool isDigit(String character) {
    return _digitRegex.stringMatch(character) != null;
  }