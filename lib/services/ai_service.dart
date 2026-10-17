import '../models/plan.dart';

/// Phase 5 placeholder. The real implementation will call a secure backend
/// (never a provider directly from the app, and never with an API key in the
/// app) using ONLY the structured, approved plan, then validate the response
/// against a schema and fall back to [OfflineExplanationService] on any failure.
class PlanExplanation {
  const PlanExplanation({required this.summary, this.fromAi = false});
  final String summary;
  final bool fromAi;
}

abstract class ExplanationService {
  Future<PlanExplanation> explain(RecommendationPlan plan);
}

/// Deterministic explanation built from reviewed content; used when AI is
/// unavailable. Not yet wired into the UI (the results screen shows each
/// exercise's own `purpose` text directly).
class OfflineExplanationService implements ExplanationService {
  const OfflineExplanationService();

  @override
  Future<PlanExplanation> explain(RecommendationPlan plan) async {
    if (!plan.hasPlan) {
      return const PlanExplanation(
        summary: 'Please follow the guidance shown on screen.',
      );
    }
    return PlanExplanation(
      summary: 'These are general, gentle ideas for your '
          '${plan.regionLabel?.toLowerCase() ?? 'selected area'}. They are '
          'not a diagnosis or treatment. Stop if anything gets worse.',
    );
  }
}
