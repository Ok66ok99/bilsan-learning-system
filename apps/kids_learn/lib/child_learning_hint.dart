import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Fixed-topic educational hint only. No child name, chat or free-form prompt.
class ChildLearningHint {
  static const supportedTopics = {'letters', 'numbers', 'colors'};

  static Future<String> getHint({
    required String familyId,
    required String topic,
  }) async {
    if (!supportedTopics.contains(topic)) {
      throw ArgumentError.value(topic, 'topic', 'Unsupported learning topic');
    }
    if (FirebaseAuth.instance.currentUser == null) {
      throw StateError('Sign in before requesting a learning hint');
    }
    final result = await FirebaseFunctions.instanceFor(region: 'us-central1')
        .httpsCallable('childLearningHint')
        .call({'familyId': familyId, 'topic': topic});
    final hint = (result.data as Map)['hint'];
    if (hint is! String || hint.trim().isEmpty) {
      throw StateError('No learning hint returned');
    }
    return hint.trim();
  }
}
