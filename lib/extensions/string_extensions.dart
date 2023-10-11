extension StringExtension on String {
  String removeCharAt(int charIndex) {
    final charList = split('').toList();
    charList.removeAt(charIndex);
    return charList.join('');
  }
}
