import 'package:essentials/essentials.dart';

import '../entity/review_tag.dart';
import '../repository/review_repository.dart';

class GetReviewTags implements UseCase<List<ReviewTagOption>, void> {
  final ReviewRepository _repository;

  GetReviewTags(this._repository);

  @override
  Future<Try<List<ReviewTagOption>>> call(void params) => _repository.getTags();
}
