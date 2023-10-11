extension IntExtension on int {
  int subtractClamping(
    int subtract, {
    int minValue = 0,
    int maxValue = 999999999,
  }) {
    return (this - subtract).clamp(
      minValue,
      maxValue,
    );
  }
}
