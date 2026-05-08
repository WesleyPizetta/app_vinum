import 'package:essentials/essentials.dart';

import '../repository/review_repository.dart';

class DeleteReviewParams {
  final String id;
  final String token;

  const DeleteReviewParams({required this.id, required this.token});
}

class DeleteReview implements UseCase<void, DeleteReviewParams> {
  final ReviewRepository _repository;

  DeleteReview(this._repository);

  @override
  Future<Try<void>> call(DeleteReviewParams params) =>
      _repository.deleteReview(id: params.id, token: params.token);
}
