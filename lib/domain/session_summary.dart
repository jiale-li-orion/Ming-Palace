/// Summary of a completed or aborted test session.
///
/// Matches the schema defined in Project.md §8.1.
class SessionSummary {

  const SessionSummary({
    required this.sessionId,
    required this.startedAt,
    this.endedAt,
    required this.completed,
    required this.route,
    required this.durationSeconds,
    this.questionChoice,
    required this.helpCount,
    required this.interrupted,
    this.survey,
  });
  final String sessionId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final bool completed;
  final String route;
  final int durationSeconds;
  final String? questionChoice;
  final int helpCount;
  final bool interrupted;
  final SurveyAnswers? survey;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'startedAt': startedAt.toIso8601String(),
        if (endedAt != null) 'endedAt': endedAt!.toIso8601String(),
        'completed': completed,
        'route': route,
        'durationSeconds': durationSeconds,
        if (questionChoice != null) 'questionChoice': questionChoice,
        'helpCount': helpCount,
        'interrupted': interrupted,
        if (survey != null) 'survey': survey!.toJson(),
      };
}

/// User's survey responses (Project.md §9).
class SurveyAnswers {

  const SurveyAnswers({
    required this.experienceDescription,
    required this.mostEngagingMoment,
    required this.confusingMoment,
    required this.wantsLongerExperience,
    required this.wantsNextTest,
  });
  final String experienceDescription;
  final String mostEngagingMoment;
  final String confusingMoment;
  final bool wantsLongerExperience;
  final bool wantsNextTest;

  Map<String, dynamic> toJson() => {
        'experienceDescription': experienceDescription,
        'mostEngagingMoment': mostEngagingMoment,
        'confusingMoment': confusingMoment,
        'wantsLongerExperience': wantsLongerExperience,
        'wantsNextTest': wantsNextTest,
      };
}
