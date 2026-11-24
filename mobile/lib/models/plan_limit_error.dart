import 'dart:convert';

class PlanLimitError {
  final String code;
  final String feature;
  final String currentPlan;
  final String recommendedPlan;
  final String message;
  final int? limit;
  final int? current;

  const PlanLimitError({
    required this.code,
    required this.feature,
    required this.currentPlan,
    required this.recommendedPlan,
    required this.message,
    this.limit,
    this.current,
  });

  bool get isQuotaExceeded => code == 'PLAN_QUOTA_EXCEEDED';

  static PlanLimitError? tryParse(int statusCode, String body) {
    if (statusCode != 403 || body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) return null;
      final detail = decoded['detail'];
      if (detail is! Map) return null;
      final map = Map<String, dynamic>.from(detail);
      final code = map['error']?.toString() ?? '';
      if (code != 'PLAN_FEATURE_LOCKED' && code != 'PLAN_QUOTA_EXCEEDED') {
        return null;
      }
      return PlanLimitError(
        code: code,
        feature: map['feature']?.toString() ?? '',
        currentPlan: map['current_plan']?.toString() ?? '',
        recommendedPlan: map['recommended_plan']?.toString() ?? 'pro',
        message: map['message']?.toString() ??
            'Cette fonctionnalité nécessite un forfait supérieur.',
        limit: (map['limit'] as num?)?.toInt(),
        current: (map['current'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }
}
