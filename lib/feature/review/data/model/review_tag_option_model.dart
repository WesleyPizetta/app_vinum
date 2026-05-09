import '../../domain/entity/review_tag.dart';

class ReviewTagOptionModel {
  final String code;
  final String label;

  const ReviewTagOptionModel({
    required this.code,
    required this.label,
  });

  factory ReviewTagOptionModel.fromJson(Map<String, dynamic> json) {
    return ReviewTagOptionModel(
      code: json['code'] as String,
      label: json['label'] as String,
    );
  }

  ReviewTagOption? toEntity() {
    final tag = ReviewTag.fromCode(code);
    if (tag == null) {
      return null;
    }
    return ReviewTagOption(tag: tag, label: label);
  }
}
