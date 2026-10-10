enum QuestionType {
  singleChoice('SINGLE_CHOICE'),
  multipleSelect('MULTIPLE_SELECT'),
  binaryChoice('BINARY_CHOICE'),
  shortText('SHORT_TEXT'),
  matching('MATCHING'),
  ordering('ORDERING'),
  imageChoice('IMAGE_CHOICE'),
  audioChoice('AUDIO_CHOICE'),
  longText('LONG_TEXT'),
  codeInput('CODE_INPUT'),
  imageHotspot('IMAGE_HOTSPOT'),
  voiceResponse('VOICE_RESPONSE'),
  timelineBuilder('TIMELINE_BUILDER'),
  evidenceBoard('EVIDENCE_BOARD');

  const QuestionType(this.payload);

  final String payload;
}

enum TextInputMode { text, numeric, decimal, fraction, code }

enum MultipleSelectScoring { allCorrect, partialCredit, penaltyForWrong }

enum EvaluationStatus {
  checking,
  aiAvailable,
  mentorReviewNeeded,
  validated,
}

class TemplateQuestion {
  const TemplateQuestion({
    required this.id,
    required this.questionType,
    required this.prompt,
    this.instruction,
    this.options = const [],
    this.media,
    this.responseConfig,
    this.scoringConfig,
    this.matchingPairs = const [],
    this.orderingItems = const [],
    this.hotspotAreas = const [],
    this.timelineItems = const [],
    this.evidenceItems = const [],
    this.codeConfig,
    this.savedAnswer,
  });

  final String id;
  final QuestionType questionType;
  final String prompt;
  final String? instruction;
  final List<TemplateOption> options;
  final TemplateMedia? media;
  final ResponseConfig? responseConfig;
  final MultipleSelectScoring? scoringConfig;
  final List<MatchingPair> matchingPairs;
  final List<OrderingItem> orderingItems;
  final List<HotspotArea> hotspotAreas;
  final List<TimelineItem> timelineItems;
  final List<EvidenceItem> evidenceItems;
  final CodeConfig? codeConfig;
  final Map<String, dynamic>? savedAnswer;
}

class TemplateOption {
  const TemplateOption({
    required this.id,
    required this.label,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String label;
  final String? imageUrl;
  final String? description;
}

class TemplateMedia {
  const TemplateMedia({
    required this.type,
    required this.url,
    this.durationSeconds,
    this.maxReplay,
    this.transcriptAvailable = false,
    this.transcript,
  });

  final String type;
  final String url;
  final int? durationSeconds;
  final int? maxReplay;
  final bool transcriptAvailable;
  final String? transcript;
}

class ResponseConfig {
  const ResponseConfig({
    this.inputMode = TextInputMode.text,
    this.maxLength = 200,
    this.caseSensitive = false,
    this.allowEmpty = false,
    this.allowUnit = false,
  });

  final TextInputMode inputMode;
  final int maxLength;
  final bool caseSensitive;
  final bool allowEmpty;
  final bool allowUnit;
}

class MatchingPair {
  const MatchingPair({
    required this.leftId,
    required this.leftLabel,
    required this.rightId,
    required this.rightLabel,
  });

  final String leftId;
  final String leftLabel;
  final String rightId;
  final String rightLabel;
}

class OrderingItem {
  const OrderingItem({required this.id, required this.label});

  final String id;
  final String label;
}

class HotspotArea {
  const HotspotArea({
    required this.id,
    required this.label,
    required this.x,
    required this.y,
    this.radius = 0.08,
  });

  final String id;
  final String label;
  final double x;
  final double y;
  final double radius;
}

class TimelineItem {
  const TimelineItem({
    required this.id,
    required this.label,
    this.timeLabel,
    this.description,
  });

  final String id;
  final String label;
  final String? timeLabel;
  final String? description;
}

class EvidenceItem {
  const EvidenceItem({
    required this.id,
    required this.label,
    this.description,
    this.category,
  });

  final String id;
  final String label;
  final String? description;
  final String? category;
}

class CodeConfig {
  const CodeConfig({
    required this.language,
    this.initialCode = '',
    this.readOnlyPrefix,
    this.expectedOutput,
    this.backendExecutionEnabled = false,
  });

  final String language;
  final String initialCode;
  final String? readOnlyPrefix;
  final String? expectedOutput;
  final bool backendExecutionEnabled;
}
