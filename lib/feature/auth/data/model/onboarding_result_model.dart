import '../../domain/entity/onboarding_result.dart';
import '../../../../core/utils/json_utils.dart';

class OnboardingResultModel {
  final double acidityScore;
  final double bodyScore;
  final String? preferredType;

  const OnboardingResultModel({
    required this.acidityScore,
    required this.bodyScore,
    this.preferredType,
  });

  /// Tolerante: o que importa no envio é o status 200; campos ausentes viram
  /// valores padrão para não transformar um envio bem-sucedido em erro.
  factory OnboardingResultModel.fromJson(dynamic body) {
    final map = JsonUtils.asMap(body) ?? const <String, dynamic>{};
    return OnboardingResultModel(
      acidityScore: JsonUtils.readDouble(map['acidity_score']) ?? 0,
      bodyScore: JsonUtils.readDouble(map['body_score']) ?? 0,
      preferredType: JsonUtils.readString(map['preferred_type']),
    );
  }

  OnboardingResult toEntity() => OnboardingResult(
        acidityScore: acidityScore,
        bodyScore: bodyScore,
        preferredType: preferredType,
      );
}
