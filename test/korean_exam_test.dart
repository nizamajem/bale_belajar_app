import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bale_belajar_app/features/quests/application/quest_attempt_controller.dart';
import 'package:bale_belajar_app/features/quests/data/quest_repository.dart';
import 'package:bale_belajar_app/features/quests/domain/quest_models.dart';
import 'package:bale_belajar_app/features/quests/presentation/korean_activity_view.dart';
import 'package:bale_belajar_app/features/test_templates/domain/test_template_models.dart';

class _ExamRepository extends QuestRepository {
  _ExamRepository(this.summary);
  final QuestSummary summary;
  final saved = <Map<String, dynamic>>[];
  int submitted = 0;
  @override
  Future<QuestSummary> getTodayQuest(String worldKey,
          {String? competencyId}) async =>
      summary;
  @override
  Future<void> saveAnswer(
      {required String attemptId,
      required String questionId,
      required Map<String, dynamic> payload}) async {
    saved.add({'questionId': questionId, 'payload': payload});
  }

  @override
  Future<QuestSubmitResult> submitAttempt(String attemptId) async {
    submitted++;
    return QuestSubmitResult(
        attemptId: attemptId,
        overallScore: 0,
        xpGained: 0,
        accountLevel: 1,
        accountLeveledUp: false,
        worldLevel: 1,
        worldLeveledUp: false,
        questions: const []);
  }
}

QuestSummary _summary(DateTime deadline) => QuestSummary(
      assignmentId: 'assignment',
      attemptId: 'attempt',
      title: 'PBT',
      story: '',
      objective: '',
      studentInstruction: '',
      estimatedMinutes: 180,
      rewardXp: 120,
      hints: const [],
      chapterTitle: 'PBT',
      attemptStatus: 'IN_PROGRESS',
      missionType: 'TOPIK_MOCK_PBT',
      expiresAt: deadline,
      questions: const [
        TemplateQuestion(
            id: 'writing',
            questionType: QuestionType.longText,
            prompt: '에세이',
            savedAnswer: {'text': '저장된 글'}),
        TemplateQuestion(
            id: 'reading',
            questionType: QuestionType.singleChoice,
            prompt: '읽기'),
      ],
    );

void main() {
  testWidgets(
      'restores saved drafts and keeps the original server deadline on resume',
      (tester) async {
    final deadline = DateTime.now().add(const Duration(minutes: 170));
    final repository = _ExamRepository(_summary(deadline));
    final controller = QuestAttemptController(
        worldKey: 'korean-topik-pbt', repository: repository);

    await controller.load();
    expect(controller.expiresAt, deadline);
    expect(controller.answers['writing']?['text'], '저장된 글');
    expect(controller.remainingSeconds, lessThanOrEqualTo(170 * 60));
    controller.dispose();
  });

  testWidgets(
      'an expired resumed exam submits once instead of restarting its timer',
      (tester) async {
    final repository = _ExamRepository(
        _summary(DateTime.now().subtract(const Duration(seconds: 2))));
    final controller = QuestAttemptController(
        worldKey: 'korean-topik-pbt', repository: repository);

    await controller.load();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(repository.submitted, 1);
    expect(controller.status, QuestLoadStatus.submitted);
    await tester.pump(const Duration(seconds: 2));
    expect(repository.submitted, 1);
    controller.dispose();
  });

  testWidgets('autosaves a writing draft before changing exam questions',
      (tester) async {
    final repository =
        _ExamRepository(_summary(DateTime.now().add(const Duration(hours: 3))));
    final controller = QuestAttemptController(
        worldKey: 'korean-topik-pbt', repository: repository);

    await controller.load();
    controller.saveCurrentDraft({'text': '새로운 답안'});
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();
    expect(repository.saved.single['payload'], {'text': '새로운 답안'});
    await controller.goToQuestion(1);
    expect(controller.currentIndex, 1);
    expect(controller.answers['writing']?['text'], '새로운 답안');
    controller.dispose();
  });

  testWidgets(
      'writing enforces the requested character count and submits real text',
      (tester) async {
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(MaterialApp(
        home: KoreanActivityView(
      question: const TemplateQuestion(
          id: 'writing',
          questionType: QuestionType.longText,
          prompt: '자료를 설명하십시오.',
          instruction: 'Tulis 200–300 karakter termasuk spasi.',
          responseConfig: ResponseConfig(maxLength: 300)),
      currentQuestion: 1,
      totalQuestions: 104,
      onAnswered: (payload) => submitted = payload,
    )));
    await tester.enterText(find.byType(TextField), '가' * 100);
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '가' * 200);
    await tester.pump();
    await tester.ensureVisible(find.text('Simpan jawaban'));
    await tester.tap(find.text('Simpan jawaban'));
    expect((submitted?['text'] as String).runes.length, 200);
  });

  testWidgets(
      'missing Korean voice reports an error and keeps listening choices disabled',
      (tester) async {
    const channel =
        MethodChannel('com.balebelajar.bale_belajar_app/korean_speech');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'speak') {
        throw PlatformException(
            code: 'KOREAN_VOICE_MISSING', message: 'Instal voice pack Korea.');
      }
      return null;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    await tester.pumpWidget(MaterialApp(
        home: KoreanActivityView(
      question: const TemplateQuestion(
          id: 'listening',
          questionType: QuestionType.audioChoice,
          prompt: '듣고 고르십시오.',
          media: TemplateMedia(
              type: 'tts', url: 'tts:ko-KR', transcript: '오후 세 시에 만나요.'),
          options: [TemplateOption(id: 'O1', label: '세 시')]),
      currentQuestion: 1,
      totalQuestions: 104,
      onAnswered: (_) {},
    )));
    await tester.tap(find.text('Putar / ulangi'));
    await tester.pumpAndSettle();
    expect(find.text('Instal voice pack Korea.'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
        isNull);
  });
}
