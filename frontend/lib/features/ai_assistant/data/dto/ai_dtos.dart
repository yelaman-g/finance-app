class DigestEvent {
  const DigestEvent({required this.title, required this.date});
  final String title;
  final DateTime date;
  factory DigestEvent.fromJson(Map<String, dynamic> j) => DigestEvent(
        title: j['title'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
      );
}

class AiDigest {
  const AiDigest({
    required this.tipOfDay,
    required this.narrative,
    required this.highlights,
    required this.upcomingEvents,
  });
  final String tipOfDay;
  final String narrative;
  final List<String> highlights;
  final List<DigestEvent> upcomingEvents;
  factory AiDigest.fromJson(Map<String, dynamic> j) => AiDigest(
        tipOfDay: j['tipOfDay'] as String? ?? '',
        narrative: j['narrative'] as String? ?? '',
        highlights:
            (j['highlights'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList(),
        upcomingEvents: (j['upcomingEvents'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => DigestEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class BudgetAnalysis {
  const BudgetAnalysis({required this.analysis, required this.tips});
  final String analysis;
  final List<String> tips;
  factory BudgetAnalysis.fromJson(Map<String, dynamic> j) => BudgetAnalysis(
        analysis: j['analysis'] as String? ?? '',
        tips: (j['tips'] as List<dynamic>? ?? <dynamic>[]).map((e) => e.toString()).toList(),
      );
}

class SavingsPlan {
  const SavingsPlan({
    required this.monthlyAmount,
    required this.monthsRemaining,
    required this.feasible,
    required this.advice,
  });
  final double monthlyAmount;
  final int monthsRemaining;
  final bool feasible;
  final String advice;
  factory SavingsPlan.fromJson(Map<String, dynamic> j) => SavingsPlan(
        monthlyAmount: (j['monthlyAmount'] as num?)?.toDouble() ?? 0,
        monthsRemaining: (j['monthsRemaining'] as num?)?.toInt() ?? 0,
        feasible: j['feasible'] as bool? ?? false,
        advice: j['advice'] as String? ?? '',
      );
}

class Reminder {
  const Reminder({
    required this.id,
    required this.eventName,
    required this.eventDate,
    this.targetAmount,
    required this.savedAmount,
    required this.daysUntil,
    required this.monthsRemaining,
    required this.monthlyNeeded,
    required this.progressPercent,
  });
  final String id;
  final String eventName;
  final DateTime eventDate;
  final double? targetAmount;
  final double savedAmount;
  final int daysUntil;
  final int monthsRemaining;
  final double monthlyNeeded;
  final double progressPercent;
  factory Reminder.fromJson(Map<String, dynamic> j) => Reminder(
        id: j['id'] as String,
        eventName: j['eventName'] as String,
        eventDate: DateTime.parse(j['eventDate'] as String),
        targetAmount: (j['targetAmount'] as num?)?.toDouble(),
        savedAmount: (j['savedAmount'] as num?)?.toDouble() ?? 0,
        daysUntil: (j['daysUntil'] as num?)?.toInt() ?? 0,
        monthsRemaining: (j['monthsRemaining'] as num?)?.toInt() ?? 1,
        monthlyNeeded: (j['monthlyNeeded'] as num?)?.toDouble() ?? 0,
        progressPercent: (j['progressPercent'] as num?)?.toDouble() ?? 0,
      );
}
