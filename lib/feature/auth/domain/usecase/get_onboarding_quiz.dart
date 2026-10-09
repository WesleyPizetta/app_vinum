import 'package:essentials/essentials.dart';

import '../entity/onboarding_question.dart';
import '../repository/auth_repository.dart';

class GetOnboardingQuiz implements UseCase<List<OnboardingQuestion>, void> {
  final AuthRepository _repository;

  GetOnboardingQuiz(this._repository);

  @override
  Future<Try<List<OnboardingQuestion>>> call(void params) =>
      _repository.getOnboardingQuiz();
}
