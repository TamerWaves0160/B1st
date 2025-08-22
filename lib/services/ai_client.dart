// lib/services/ai_client.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:behaviorfirst/models/fba_bip_draft.dart';

/// Thin wrapper around Firebase Callable Functions used by BehaviorFirst.
/// Keeps region/name in one place so UI code stays simple.
class AiClient {
  AiClient._();
  static final AiClient instance = AiClient._();

  static const String _region = 'us-central1';
  static const String _fnGenerateFbaBipDraft = 'generateFbaBipDraft';

  FirebaseFunctions get _fx => FirebaseFunctions.instanceFor(region: _region);

  /// Returns a normalized `Map<String, dynamic>`.
  Future<Map<String, dynamic>> generateFbaBipDraft({Map<String, dynamic>? payload}) async {
    final HttpsCallable callable = _fx.httpsCallable(_fnGenerateFbaBipDraft);
    final HttpsCallableResult result = await callable(payload ?? const {});
    final data = result.data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    debugPrint('[AiClient] Unexpected return type: ${data.runtimeType}');
    return {'raw': data, '_warning': 'Function returned a non-Map payload.'};
  }

  /// Typed convenience: parses the callable result into `DraftResponse`.
  Future<DraftResponse> generateFbaBipDraftTyped({Map<String, dynamic>? payload}) async {
    final map = await generateFbaBipDraft(payload: payload);
    return DraftResponse.fromMap(map);
  }
}
