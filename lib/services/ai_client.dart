// lib/services/ai_client.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Typed models
import 'package:behaviorfirst/models/fba_bip_draft.dart'; // DraftResponse

class AiClient {
  AiClient._();
  static final AiClient instance = AiClient._();

  // Functions in us-central1 per your setup
  final FirebaseFunctions _fx = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );

  // ---------- Helpers ----------
  Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }
    return {'value': data};
  }

  // ---------- FBA/BIP generation ----------
  /// Raw call; returns the exact map the function returned (with {meta, draft}).
  Future<Map<String, dynamic>> generateFbaBipDraftRaw({
    required Map<String, dynamic> payload,
  }) async {
    final callable = _fx.httpsCallable('generateFbaBipDraft');
    final res = await callable(payload);
    final map = _asMap(res.data);
    // Optional debug breadcrumbs
    try {
      final draft = _asMap(map['draft']);
      final m2 = _asMap(draft['meta']);
      debugPrint(
        '[AI] generateFbaBipDraftRaw engine=${m2['engine']} callId=${_asMap(_asMap(payload)['_meta'])['callId']}',
      );
    } catch (_) {}
    return map;
  }

  /// Typed call; parses into DraftResponse so you can access resp.draft.* safely.
  Future<DraftResponse> generateFbaBipDraftTyped({
    required Map<String, dynamic> payload,
  }) async {
    final raw = await generateFbaBipDraftRaw(payload: payload);
    // DraftResponse expects the top-level { meta, draft } shape.
    final resp = DraftResponse.fromJson(raw.cast<String, dynamic>());
    debugPrint('[AI] generateFbaBipDraftTyped => ${resp.draft.meta.engine}');
    return resp;
  }

  // ---------- Intervention recommender ----------
  // REMOVED: Old recommendInterventions function
  // Now using RAG system via getIntervention in renni_reports_tab.dart
}
