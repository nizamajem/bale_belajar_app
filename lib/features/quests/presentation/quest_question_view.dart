import 'package:flutter/material.dart';

import '../../test_templates/domain/test_template_models.dart';
import '../../test_templates/presentation/templates/test_templates.dart';
import 'korean_activity_view.dart';

/// Dispatcher berbasis `question.questionType` (bukan berdasarkan posisi
/// index seperti bug yang ditemukan di `_PlacementTestFlow` pada
/// `simple_auth_screen.dart`) - memilih salah satu dari 14 widget yang
/// sudah ada di `test_templates/presentation/templates` tanpa menulis
/// ulang UI-nya sama sekali.
///
/// `onAnswered` dipanggil sekali dengan payload yang bentuknya sudah
/// disesuaikan dengan yang diharapkan `quest-evaluation.util.ts` di
/// backend (selectedOptionId/selectedOptionIds/text/matches/order/dst).
class QuestQuestionView extends StatelessWidget {
  const QuestQuestionView({
    required this.question,
    required this.currentQuestion,
    required this.totalQuestions,
    required this.onAnswered,
    this.worldKey,
    this.onDraft,
    this.savedAnswer,
    super.key,
  });

  final TemplateQuestion question;
  final int currentQuestion;
  final int totalQuestions;
  final ValueChanged<Map<String, dynamic>> onAnswered;
  final String? worldKey;
  final ValueChanged<Map<String, dynamic>>? onDraft;
  final Map<String, dynamic>? savedAnswer;

  @override
  Widget build(BuildContext context) {
    if ((question.questionType == QuestionType.audioChoice &&
            question.media?.url == 'tts:ko-KR') ||
        (question.questionType == QuestionType.longText &&
            (worldKey?.startsWith('korean-') ?? false)) ||
        (question.questionType == QuestionType.singleChoice &&
            (worldKey?.startsWith('korean-topik-') ?? false))) {
      return KoreanActivityView(
          key: ValueKey(question.id),
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onDraft: onDraft,
          savedAnswer: savedAnswer,
          onAnswered: onAnswered);
    }
    switch (question.questionType) {
      case QuestionType.singleChoice:
        return SingleChoiceTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'selectedOptionId': value}),
        );
      case QuestionType.imageChoice:
        return ImageChoiceTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'selectedOptionId': value}),
        );
      case QuestionType.audioChoice:
        return AudioChoiceTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          // Pemutaran audio sungguhan belum diimplementasikan di iterasi
          // ini (butuh integrasi audio player terpisah) - tombol play/pause
          // sengaja no-op, penilaian tetap berjalan dari pilihan jawaban.
          onPlay: () {},
          onPause: () {},
          onCheckAnswer: (value) => onAnswered({'selectedOptionId': value}),
        );
      case QuestionType.binaryChoice:
        return BinaryChoiceTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) {
            if (value == null || question.options.length < 2) return;
            final selectedOptionId =
                value ? question.options[0].id : question.options[1].id;
            onAnswered({'selectedOptionId': selectedOptionId});
          },
        );
      case QuestionType.multipleSelect:
        return MultipleSelectTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) =>
              onAnswered({'selectedOptionIds': value.toList()}),
        );
      case QuestionType.shortText:
        return ShortTextTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'text': value}),
        );
      case QuestionType.longText:
        return LongTextTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onSubmitAnswer: (value) => onAnswered({'text': value.join('\n\n')}),
        );
      case QuestionType.matching:
        return MatchingTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'matches': value}),
        );
      case QuestionType.ordering:
        return OrderingTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'order': value}),
        );
      case QuestionType.timelineBuilder:
        return TimelineBuilderTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'order': value}),
        );
      case QuestionType.imageHotspot:
        return ImageHotspotTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'selectedHotspotId': value}),
        );
      case QuestionType.evidenceBoard:
        return EvidenceBoardTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) =>
              onAnswered({'selectedEvidenceIds': value.toList()}),
        );
      case QuestionType.voiceResponse:
        return VoiceResponseTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          // Rekam audio sungguhan (+ speech-to-text) belum diimplementasikan
          // di iterasi ini - lihat catatan scope di plan implementasi.
          // Soal tetap tampil dan jawaban teks tetap tersimpan, tapi selalu
          // berstatus menunggu review mentor (tidak pernah auto-scored).
          onStartRecording: () {},
          onStopRecording: () {},
          onSubmitAnswer: (value) => onAnswered({'text': value}),
        );
      case QuestionType.codeInput:
        return CodeInputTemplate(
          question: question,
          currentQuestion: currentQuestion,
          totalQuestions: totalQuestions,
          onCheckAnswer: (value) => onAnswered({'code': value ?? ''}),
        );
    }
  }
}
