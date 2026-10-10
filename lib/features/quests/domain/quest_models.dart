import '../../test_templates/domain/test_template_models.dart';

/// Ringkasan Quest hari ini - dipetakan dari respons
/// `GET /student/quests/today` (field `quest` + `assignmentId` + `attempt`).
class QuestSummary {
  const QuestSummary({
    required this.assignmentId,
    required this.attemptId,
    required this.title,
    required this.story,
    required this.objective,
    required this.studentInstruction,
    required this.estimatedMinutes,
    required this.rewardXp,
    required this.hints,
    required this.chapterTitle,
    required this.questions,
    this.attemptStatus,
    this.missionType,
    this.expiresAt,
  });

  factory QuestSummary.fromJson(Map<String, dynamic> json) {
    final quest = json['quest'] as Map<String, dynamic>;
    final attempt = json['attempt'] as Map<String, dynamic>?;
    final chapter = quest['chapter'] as Map<String, dynamic>?;
    final questions = (json['questions'] as List)
        .cast<Map<String, dynamic>>()
        .map(questionFromBackendJson)
        .toList();

    return QuestSummary(
      assignmentId: json['assignmentId'] as String,
      attemptId: attempt?['id'] as String?,
      title: quest['title'] as String? ?? 'Quest',
      story: quest['story'] as String? ?? '',
      objective: quest['objective'] as String? ?? '',
      studentInstruction: quest['studentInstruction'] as String? ?? '',
      estimatedMinutes: quest['estimatedMinutes'] as int? ?? 10,
      rewardXp: quest['rewardXp'] as int? ?? 0,
      hints: (quest['hints'] as List?)?.cast<String>() ?? const [],
      chapterTitle: chapter?['title'] as String?,
      questions: questions,
      attemptStatus: attempt?['status'] as String?,
      missionType: quest['missionType'] as String?,
      expiresAt: DateTime.tryParse(attempt?['expiresAt'] as String? ?? ''),
    );
  }

  final String assignmentId;
  final String? attemptId;
  final String title;
  final String story;
  final String objective;
  final String studentInstruction;
  final int estimatedMinutes;
  final int rewardXp;
  final List<String> hints;
  final String? chapterTitle;
  final List<TemplateQuestion> questions;
  final String? attemptStatus;
  final String? missionType;
  final DateTime? expiresAt;
  bool get isTimedExam =>
      missionType == 'TOPIK_MOCK_PBT' || missionType == 'TOPIK_MOCK_IBT';
}

/// Semua misi hari ini untuk satu dunia (sequence 1..N) - dipetakan dari
/// `GET /student/quests/today-all`. Dipakai untuk progress "misi 2/3 selesai"
/// dan tombol "Misi Lagi" kalau [canRequestNext] true.
class QuestDailyProgress {
  const QuestDailyProgress({
    required this.dailyQuestCount,
    required this.assignments,
    required this.canRequestNext,
  });

  factory QuestDailyProgress.fromJson(Map<String, dynamic> json) {
    return QuestDailyProgress(
      dailyQuestCount: json['dailyQuestCount'] as int,
      assignments: (json['assignments'] as List)
          .cast<Map<String, dynamic>>()
          .map(QuestSummary.fromJson)
          .toList(),
      canRequestNext: json['canRequestNext'] as bool? ?? false,
    );
  }

  final int dailyQuestCount;
  final List<QuestSummary> assignments;
  final bool canRequestNext;

  int get completedCount =>
      assignments.where((a) => a.attemptStatus == 'SUBMITTED').length;
}

class QuestHistorySummary {
  const QuestHistorySummary({
    required this.totalAttempts,
    required this.completedAttempts,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.reviewQuestions,
    required this.accuracy,
    required this.averageScore,
  });

  factory QuestHistorySummary.fromJson(Map<String, dynamic> json) {
    return QuestHistorySummary(
      totalAttempts: json['totalAttempts'] as int? ?? 0,
      completedAttempts: json['completedAttempts'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      reviewQuestions: json['reviewQuestions'] as int? ?? 0,
      accuracy: json['accuracy'] as int? ?? 0,
      averageScore: json['averageScore'] as int? ?? 0,
    );
  }

  final int totalAttempts;
  final int completedAttempts;
  final int totalQuestions;
  final int correctAnswers;
  final int reviewQuestions;
  final int accuracy;
  final int averageScore;
}

class QuestWeakSpot {
  const QuestWeakSpot({
    required this.label,
    required this.detail,
    required this.count,
  });

  factory QuestWeakSpot.fromJson(Map<String, dynamic> json) {
    return QuestWeakSpot(
      label: json['label'] as String? ?? 'Latihan',
      detail: json['detail'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  final String label;
  final String detail;
  final int count;
}

class QuestHistoryAttempt {
  const QuestHistoryAttempt({
    required this.id,
    required this.title,
    required this.worldKey,
    required this.worldName,
    required this.submittedAt,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.reviewQuestions,
  });

  factory QuestHistoryAttempt.fromJson(Map<String, dynamic> json) {
    return QuestHistoryAttempt(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Latihan',
      worldKey: json['worldKey'] as String? ?? '',
      worldName: json['worldName'] as String? ?? 'Dunia',
      submittedAt: DateTime.tryParse(json['submittedAt'] as String? ?? ''),
      score: json['score'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      reviewQuestions: json['reviewQuestions'] as int? ?? 0,
    );
  }

  final String id;
  final String title;
  final String worldKey;
  final String worldName;
  final DateTime? submittedAt;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int reviewQuestions;
}

class QuestHistory {
  const QuestHistory({
    required this.summary,
    required this.weakSpots,
    required this.recentAttempts,
  });

  factory QuestHistory.fromJson(Map<String, dynamic> json) {
    return QuestHistory(
      summary: QuestHistorySummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      weakSpots: (json['weakSpots'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(QuestWeakSpot.fromJson)
          .toList(),
      recentAttempts: (json['recentAttempts'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(QuestHistoryAttempt.fromJson)
          .toList(),
    );
  }

  final QuestHistorySummary summary;
  final List<QuestWeakSpot> weakSpots;
  final List<QuestHistoryAttempt> recentAttempts;
}

/// Hasil satu soal setelah submit (kunci jawaban sudah boleh terlihat).
class QuestQuestionResult {
  const QuestQuestionResult({
    required this.questionId,
    required this.score,
    required this.isCorrect,
    required this.evaluationStatus,
    this.feedback,
  });

  factory QuestQuestionResult.fromJson(Map<String, dynamic> json) {
    return QuestQuestionResult(
      questionId: json['id'] as String,
      score: (json['score'] as num?)?.toDouble(),
      isCorrect: json['isCorrect'] as bool?,
      evaluationStatus:
          json['evaluationStatus'] as String? ?? 'MENTOR_REVIEW_NEEDED',
      feedback: json['feedback'] as String?,
    );
  }

  final String questionId;
  final double? score;
  final bool? isCorrect;
  final String evaluationStatus;
  final String? feedback;

  bool get isPendingReview => evaluationStatus == 'MENTOR_REVIEW_NEEDED';
}

/// Ringkasan hasil submit keseluruhan quest.
class QuestSubmitResult {
  const QuestSubmitResult({
    required this.attemptId,
    required this.overallScore,
    required this.xpGained,
    required this.accountLevel,
    required this.accountLeveledUp,
    required this.worldLevel,
    required this.worldLeveledUp,
    required this.questions,
    this.exam,
  });

  factory QuestSubmitResult.fromJson(Map<String, dynamic> json) {
    final gameProfile =
        json['gameProfile'] as Map<String, dynamic>? ?? const {};
    return QuestSubmitResult(
      attemptId: json['attemptId'] as String,
      overallScore: (json['overallScore'] as num?)?.toDouble() ?? 0,
      xpGained: json['xpGained'] as int? ?? 0,
      accountLevel: gameProfile['accountLevel'] as int?,
      accountLeveledUp: gameProfile['accountLeveledUp'] as bool? ?? false,
      worldLevel: gameProfile['worldLevel'] as int?,
      worldLeveledUp: gameProfile['worldLeveledUp'] as bool? ?? false,
      questions: (json['questions'] as List)
          .cast<Map<String, dynamic>>()
          .map(QuestQuestionResult.fromJson)
          .toList(),
      exam: json['exam'] as Map<String, dynamic>?,
    );
  }

  final String attemptId;
  final double overallScore;
  final int xpGained;
  final int? accountLevel;
  final bool accountLeveledUp;
  final int? worldLevel;
  final bool worldLeveledUp;
  final List<QuestQuestionResult> questions;
  final Map<String, dynamic>? exam;

  int get autoScoredCount =>
      questions.where((question) => !question.isPendingReview).length;

  int get correctAutoScoredCount =>
      questions.where((question) => question.isCorrect == true).length;

  int get pendingReviewCount =>
      questions.where((question) => question.isPendingReview).length;

  String get recommendation {
    if (pendingReviewCount > 0) {
      return 'Ada jawaban yang menunggu review mentor. Sambil menunggu, ulangi materi dan cek alasan jawabanmu.';
    }
    if (exam != null) {
      final sections = (exam!['sections'] as List).cast<Map<String, dynamic>>();
      final sorted = [...sections]..sort((a, b) =>
          (a['score'] as num? ?? 0).compareTo(b['score'] as num? ?? 0));
      return 'Bagian terendah pada latihan ini: ${sorted.first['section']}. Tinjau alasan jawaban, kerjakan ulang tugas yang terlewat, dan gunakan feedback writing untuk latihan berikutnya.';
    }
    if (overallScore >= 80) {
      return 'Pemahamanmu kuat. Lanjutkan ke quest berikutnya atau coba world lain.';
    }
    if (overallScore >= 60) {
      return 'Dasarnya sudah terbentuk. Baca ulang checklist materi lalu ulangi bagian yang masih ragu.';
    }
    return 'Mulai dari materi inti lagi, kerjakan contoh cara berpikir, lalu coba quest ulang.';
  }
}

/// Konversi bentuk JSON per-soal dari backend `student-quests` ke
/// [TemplateQuestion] supaya 14 widget yang sudah ada di
/// `test_templates/presentation/templates` bisa dipakai apa adanya tanpa
/// perlu ditulis ulang.
TemplateQuestion questionFromBackendJson(Map<String, dynamic> json) {
  final type = QuestionType.values.firstWhere(
    (t) => t.payload == json['questionType'],
    orElse: () => QuestionType.shortText,
  );

  final mediaList =
      (json['media'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final media = mediaList.isEmpty
      ? null
      : TemplateMedia(
          type: mediaList.first['mediaType'] as String? ?? 'audio',
          url: mediaList.first['url'] as String? ?? '',
          durationSeconds: mediaList.first['durationSeconds'] as int?,
          maxReplay: mediaList.first['maxReplay'] as int?,
          transcriptAvailable:
              mediaList.first['transcriptAvailable'] as bool? ?? false,
          transcript: mediaList.first['transcript'] as String?,
        );

  final options = (json['options'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((o) => TemplateOption(
                id: _jsonText(o, ['id', 'optionId', 'key'], fallback: ''),
                label: _jsonText(o, ['label', 'text', 'title', 'name']),
                imageUrl: o['imageUrl'] as String?,
                description: o['description'] as String?,
              ))
          .toList() ??
      const [];

  final left =
      (json['matchingLeftOptions'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  final right =
      (json['matchingRightOptions'] as List?)?.cast<Map<String, dynamic>>() ??
          const [];
  final pairCount = left.length < right.length ? left.length : right.length;
  final matchingPairs = List.generate(
    pairCount,
    (i) => MatchingPair(
      leftId: _jsonText(left[i], ['id', 'leftId'], fallback: '$i'),
      leftLabel: _jsonText(left[i], ['label', 'leftLabel', 'text', 'title']),
      rightId: _jsonText(right[i], ['id', 'rightId'], fallback: '$i'),
      rightLabel: _jsonText(right[i], ['label', 'rightLabel', 'text', 'title']),
    ),
  );

  final items =
      (json['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
  final orderingItems = type == QuestionType.ordering
      ? items.map(_orderingItemFromJson).toList()
      : const <OrderingItem>[];
  final timelineItems = type == QuestionType.timelineBuilder
      ? items
          .map((i) => TimelineItem(
                id: _jsonText(i, ['id', 'itemId'], fallback: ''),
                label: _jsonText(
                    i, ['label', 'text', 'title', 'name', 'description']),
                timeLabel: i['timeLabel'] as String?,
                description: i['description'] as String?,
              ))
          .toList()
      : const <TimelineItem>[];

  final hotspotAreas = (json['hotspotAreas'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((h) => HotspotArea(
                id: _jsonText(h, ['id', 'hotspotId'], fallback: ''),
                label: _jsonText(h, ['label', 'text', 'title', 'name']),
                x: (h['x'] as num?)?.toDouble() ?? 0,
                y: (h['y'] as num?)?.toDouble() ?? 0,
                radius: (h['radius'] as num?)?.toDouble() ?? 0.08,
              ))
          .toList() ??
      const [];

  final evidenceItems = (json['evidenceItems'] as List?)
          ?.cast<Map<String, dynamic>>()
          .map((e) => EvidenceItem(
                id: _jsonText(e, ['id', 'evidenceId'], fallback: ''),
                label: _jsonText(e, ['label', 'text', 'title', 'name']),
                description: e['description'] as String?,
                category: e['category'] as String?,
              ))
          .toList() ??
      const [];

  final codeConfigJson = json['codeConfig'] as Map<String, dynamic>?;
  final codeConfig = codeConfigJson == null
      ? null
      : CodeConfig(
          language: codeConfigJson['language'] as String? ?? 'text',
          initialCode: codeConfigJson['initialCode'] as String? ?? '',
          readOnlyPrefix: codeConfigJson['readOnlyPrefix'] as String?,
        );

  final inputMode = switch (json['inputMode']) {
    'numeric' => TextInputMode.numeric,
    'decimal' => TextInputMode.decimal,
    'fraction' => TextInputMode.fraction,
    'code' => TextInputMode.code,
    _ => TextInputMode.text,
  };

  return TemplateQuestion(
    id: json['id'] as String,
    questionType: type,
    prompt: json['questionText'] as String? ?? '',
    instruction: json['instruction'] as String?,
    options: options,
    media: media,
    responseConfig: ResponseConfig(
      inputMode: inputMode,
      maxLength: json['maxLength'] as int? ?? 200,
    ),
    matchingPairs: matchingPairs,
    orderingItems: orderingItems,
    hotspotAreas: hotspotAreas,
    timelineItems: timelineItems,
    evidenceItems: evidenceItems,
    codeConfig: codeConfig,
    savedAnswer: json['savedAnswer'] as Map<String, dynamic>?,
  );
}

OrderingItem _orderingItemFromJson(Map<String, dynamic> json) {
  final id = _jsonText(json, ['id', 'itemId'], fallback: '');
  final label = _jsonText(
    json,
    ['label', 'text', 'title', 'name', 'description'],
    fallback: id,
  );
  return OrderingItem(id: id, label: label);
}

String _jsonText(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) return value.trim();
    if (value is num || value is bool) return value.toString();
  }
  return fallback;
}
