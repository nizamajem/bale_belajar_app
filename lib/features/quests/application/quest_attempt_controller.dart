import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../../core/api/api_client.dart';
import '../data/quest_repository.dart';
import '../domain/quest_models.dart';

enum QuestLoadStatus { loading, ready, submitting, submitted, error }

/// State holder untuk satu sesi mengerjakan Quest - pola tangan
/// (ChangeNotifier) yang sama seperti BaleVerseProgressService, karena app
/// ini memang tidak pakai Provider/Riverpod di level manapun.
///
/// Jawaban disimpan TERSTRUKTUR per tipe soal (`Map<String,dynamic>` payload),
/// bukan di-toString() seperti bug yang ditemukan di alur placement test
/// lama (`simple_auth_screen.dart`) - supaya matching/ordering/hotspot/dst
/// terkirim dengan bentuk yang benar ke backend.
class QuestAttemptController extends ChangeNotifier {
  QuestAttemptController({
    required this.worldKey,
    this.requestNext = false,
    this.competencyId,
    QuestRepository? repository,
  }) : _repository = repository ?? QuestRepository();

  final String worldKey;
  final String? competencyId;
  // true = ambil misi TAMBAHAN hari ini (POST /student/quests/next) alih-alih
  // misi utama hari ini (GET /student/quests/today) - dipakai tombol "Misi
  // Lagi" di WorldCurriculumScreen setelah StudentQuestSetting.dailyQuestCount
  // mengizinkan lebih dari 1 misi/hari.
  final bool requestNext;
  final QuestRepository _repository;

  QuestLoadStatus status = QuestLoadStatus.loading;
  String? errorMessage;
  bool isSavingAnswer = false;
  QuestSummary? quest;
  String? _attemptId;
  int currentIndex = 0;
  final Map<String, Map<String, dynamic>> answers = {};
  QuestSubmitResult? result;
  DateTime? expiresAt;
  Timer? _clock;
  Timer? _draftTimer;
  Future<void>? _draftSave;
  ({String questionId, Map<String, dynamic> payload})? _pendingDraft;
  bool _expiredSubmitStarted = false;
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  bool get isTimedExam => quest?.isTimedExam ?? false;
  int get remainingSeconds => expiresAt == null
      ? 0
      : expiresAt!
          .difference(DateTime.now())
          .inSeconds
          .clamp(0, 100000)
          .toInt();
  bool get examExpired =>
      isTimedExam && expiresAt != null && remainingSeconds <= 0;

  @override
  void dispose() {
    _disposed = true;
    _clock?.cancel();
    _draftTimer?.cancel();
    super.dispose();
  }

  void _startExamClock() {
    _clock?.cancel();
    if (!isTimedExam) return;
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (status != QuestLoadStatus.ready) return;
      if (examExpired && !_expiredSubmitStarted && !isSavingAnswer) {
        _expiredSubmitStarted = true;
        submit();
      } else {
        notifyListeners();
      }
    });
  }

  void saveCurrentDraft(Map<String, dynamic> payload) {
    if (!isTimedExam || examExpired || status != QuestLoadStatus.ready) return;
    final questionId = currentQuestion.id as String;
    answers[questionId] = payload;
    _pendingDraft = (questionId: questionId, payload: payload);
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 500), () {
      final previous = _draftSave;
      _draftSave = () async {
        await previous;
        await _flushDraft();
      }();
    });
  }

  Future<void> _flushDraft() async {
    _draftTimer?.cancel();
    final draft = _pendingDraft;
    _pendingDraft = null;
    if (draft == null || _attemptId == null || examExpired) return;
    try {
      await _repository.saveAnswer(
          attemptId: _attemptId!,
          questionId: draft.questionId,
          payload: draft.payload);
    } catch (_) {
      if (status == QuestLoadStatus.ready) {
        errorMessage =
            'Draf belum tersimpan. Tekan Simpan jawaban untuk mencoba lagi.';
      }
    }
  }

  Future<void> goToQuestion(int index) async {
    if (!isTimedExam ||
        isSavingAnswer ||
        index < 0 ||
        index >= totalQuestions ||
        examExpired) {
      return;
    }
    await _draftSave;
    await _flushDraft();
    currentIndex = index;
    notifyListeners();
  }

  int get totalQuestions => quest?.questions.length ?? 0;
  bool get isLastQuestion => currentIndex >= totalQuestions - 1;
  dynamic get currentQuestion => quest!.questions[currentIndex];

  Future<void> load() async {
    status = QuestLoadStatus.loading;
    errorMessage = null;
    notifyListeners();
    try {
      final summary = await _loadQuestSummary();
      if (summary.questions.isEmpty) {
        throw Exception(
          'Misi ini belum punya soal aktif. Coba kembali lalu pilih misi lagi.',
        );
      }
      var attemptId = summary.attemptId;
      quest = summary;
      _attemptId = attemptId;
      currentIndex = 0;
      answers.clear();
      for (final question in summary.questions) {
        if (question.savedAnswer != null) {
          answers[question.id] = question.savedAnswer!;
        }
      }
      expiresAt = summary.expiresAt;
      if (attemptId != null && summary.attemptStatus == 'SUBMITTED') {
        result = await _repository.getResult(attemptId);
        status = QuestLoadStatus.submitted;
        notifyListeners();
        return;
      }
      if (attemptId == null) {
        final started =
            await _repository.startAttemptInfo(summary.assignmentId);
        attemptId = started['id'] as String;
        expiresAt = DateTime.tryParse(started['expiresAt'] as String? ?? '');
      }
      _attemptId = attemptId;
      status = QuestLoadStatus.ready;
      _startExamClock();
    } catch (error) {
      errorMessage = error.toString();
      status = QuestLoadStatus.error;
    }
    notifyListeners();
  }

  Future<QuestSummary> _loadQuestSummary() async {
    if (!requestNext) {
      return _repository.getTodayQuest(worldKey, competencyId: competencyId);
    }

    try {
      return await _repository.requestNextQuest(
        worldKey,
        competencyId: competencyId,
      );
    } on BaleApiException catch (error) {
      final shouldFallback =
          error.statusCode == 400 && error.message.contains('misi hari ini');
      if (!shouldFallback) rethrow;
      return _repository.getTodayQuest(worldKey, competencyId: competencyId);
    }
  }

  /// Simpan jawaban soal saat ini lalu maju ke soal berikutnya, atau submit
  /// kalau ini soal terakhir.
  Future<void> answerCurrentAndAdvance(Map<String, dynamic> payload) async {
    if (examExpired) {
      await submit();
      return;
    }
    _draftTimer?.cancel();
    _pendingDraft = null;
    await _draftSave;
    final question = currentQuestion;
    answers[question.id as String] = payload;
    isSavingAnswer = true;
    errorMessage = null;
    notifyListeners();

    final attemptId = _attemptId;
    if (attemptId != null) {
      var saved = false;
      try {
        await _repository.saveAnswer(
          attemptId: attemptId,
          questionId: question.id as String,
          payload: payload,
        );
        saved = true;
      } catch (_) {
        try {
          await _repository.saveAnswer(
            attemptId: attemptId,
            questionId: question.id as String,
            payload: payload,
          );
          saved = true;
        } catch (error) {
          errorMessage =
              'Jawaban belum tersimpan. Cek koneksi lalu tekan tombol jawab lagi.';
        }
      }
      if (!saved) {
        isSavingAnswer = false;
        notifyListeners();
        return;
      }
    }

    isSavingAnswer = false;
    if (isLastQuestion && !isTimedExam) {
      await submit();
    } else if (!isLastQuestion) {
      currentIndex += 1;
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  Future<void> submit() async {
    final attemptId = _attemptId;
    if (attemptId == null) return;
    if (status == QuestLoadStatus.submitting ||
        status == QuestLoadStatus.submitted) {
      return;
    }
    status = QuestLoadStatus.submitting;
    notifyListeners();
    await _draftSave;
    await _flushDraft();
    try {
      result = await _repository.submitAttempt(attemptId);
      status = QuestLoadStatus.submitted;
    } catch (error) {
      errorMessage =
          'Jawaban tersimpan, tapi submit belum berhasil. Coba kirim lagi.';
      status = QuestLoadStatus.ready;
    }
    notifyListeners();
  }
}
