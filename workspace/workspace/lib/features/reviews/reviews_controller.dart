import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/firebase_service.dart';
import 'review_model.dart';

final reviewsProvider = StreamProvider.family<List<ReviewModel>, String>((ref, productId) {
  return FirebaseService.instance.ref('reviews/$productId').onValue.map((event) {
    final val = event.snapshot.value;
    if (val is! Map) return <ReviewModel>[];
    return val.entries
        .map((e) => ReviewModel.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });
});

class ReviewsController {
  Future<void> submit({
    required String productId,
    required String userName,
    required int rating,
    required String comment,
  }) async {
    final uid = FirebaseService.instance.auth.currentUser?.uid;
    if (uid == null) throw Exception('Login required');
    final review = ReviewModel(
      userId: uid,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await FirebaseService.instance.ref('reviews/$productId/$uid').set(review.toMap());

    final snap = await FirebaseService.instance.ref('reviews/$productId').get();
    if (snap.value is Map) {
      final all = snap.value as Map;
      var total = 0;
      var count = 0;
      for (final v in all.values) {
        if (v is Map) {
          total += (v['rating'] as num?)?.toInt() ?? 0;
          count++;
        }
      }
      if (count > 0) {
        await FirebaseService.instance.ref('products/$productId').update({
          'avgRating': double.parse((total / count).toStringAsFixed(1)),
          'reviewCount': count,
        });
      }
    }
  }
}
