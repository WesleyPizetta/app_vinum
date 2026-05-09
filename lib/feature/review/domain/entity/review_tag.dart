enum ReviewTag {
  amadeirado('AMADEIRADO'),
  suave('SUAVE'),
  encorpado('ENCORPADO'),
  frutado('FRUTADO'),
  seco('SECO'),
  citrico('CITRICO');

  final String code;
  const ReviewTag(this.code);

  static ReviewTag? fromCode(String code) {
    final normalized = code.trim().toUpperCase();
    for (final value in ReviewTag.values) {
      if (value.code == normalized) {
        return value;
      }
    }
    return null;
  }
}

class ReviewTagOption {
  final ReviewTag tag;
  final String label;

  const ReviewTagOption({
    required this.tag,
    required this.label,
  });
}
