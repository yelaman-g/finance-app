class PollOption {
  const PollOption({
    required this.id,
    required this.text,
    required this.votes,
  });

  factory PollOption.fromJson(Map<String, dynamic> j) => PollOption(
        id: j['id'] as String? ?? '',
        text: j['text'] as String? ?? '',
        votes: j['votes'] as int? ?? 0,
      );

  final String id;
  final String text;
  final int votes;
}

class Poll {
  const Poll({
    required this.id,
    required this.question,
    required this.closed,
    required this.createdBy,
    required this.options,
    this.myVoteOptionId,
  });

  factory Poll.fromJson(Map<String, dynamic> j) => Poll(
        id: j['id'] as String? ?? '',
        question: j['question'] as String? ?? '',
        closed: j['closed'] as bool? ?? false,
        createdBy: j['createdBy'] as String? ?? '',
        options: (j['options'] as List<dynamic>? ?? <dynamic>[])
            .map((e) => PollOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        myVoteOptionId: j['myVoteOptionId'] as String?,
      );

  final String id;
  final String question;
  final bool closed;
  final String createdBy;
  final List<PollOption> options;
  final String? myVoteOptionId;
}
