import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../domain/quest_models.dart';

/// Panggil 5 endpoint `student-quests` di backend - lihat
/// `BALE_BELAJAR_BE/src/modules/student-quests`.
class QuestRepository {
  QuestRepository({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient(tokenProvider: const SecureTokenStore().read);

  final ApiClient _apiClient;

  Future<QuestSummary> getTodayQuest(
    String worldKey, {
    String? competencyId,
  }) async {
    final data = await _apiClient.get(
      '/student/quests/today',
      query: {
        'worldKey': worldKey,
        if (competencyId != null && competencyId.isNotEmpty)
          'competencyId': competencyId,
      },
    );
    return QuestSummary.fromJson(data as Map<String, dynamic>);
  }

  /// Berapa misi per hari yang mau siswa ambil (1-5, default 1) - lihat
  /// StudentQuestSetting di backend.
  Future<int> fetchDailyQuestCount() async {
    final data = await _apiClient.get('/student/quests/setting');
    return (data as Map<String, dynamic>)['dailyQuestCount'] as int;
  }

  Future<int> updateDailyQuestCount(int dailyQuestCount) async {
    final data = await _apiClient.put(
      '/student/quests/setting',
      body: {'dailyQuestCount': dailyQuestCount},
    );
    return (data as Map<String, dynamic>)['dailyQuestCount'] as int;
  }

  Future<QuestDailyProgress> fetchTodayAll(String worldKey) async {
    final data = await _apiClient.get(
      '/student/quests/today-all',
      query: {'worldKey': worldKey},
    );
    return QuestDailyProgress.fromJson(data as Map<String, dynamic>);
  }

  Future<QuestHistory> fetchHistory({String? worldKey}) async {
    final data = await _apiClient.get(
      '/student/quests/history',
      query: {
        if (worldKey != null && worldKey.isNotEmpty) 'worldKey': worldKey,
      },
    );
    return QuestHistory.fromJson(data as Map<String, dynamic>);
  }

  /// Minta misi tambahan hari ini (sequence 2+) - backend menolak (400) kalau
  /// sudah menyentuh dailyQuestCount atau misi terakhir belum SUBMITTED.
  Future<QuestSummary> requestNextQuest(
    String worldKey, {
    String? competencyId,
  }) async {
    final data = await _apiClient.post(
      '/student/quests/next',
      query: {
        'worldKey': worldKey,
        if (competencyId != null && competencyId.isNotEmpty)
          'competencyId': competencyId,
      },
    );
    return QuestSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<String> startAttempt(String assignmentId) async {
    final data = await startAttemptInfo(assignmentId);
    return data['id'] as String;
  }

  Future<Map<String, dynamic>> startAttemptInfo(String assignmentId) async {
    final data = await _apiClient.post('/student/quests/$assignmentId/start');
    return data as Map<String, dynamic>;
  }

  Future<void> saveAnswer({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> payload,
  }) {
    return _apiClient.put(
      '/student/quest-attempts/$attemptId/answers/$questionId',
      body: {'payload': payload},
    );
  }

  Future<QuestSubmitResult> submitAttempt(String attemptId) async {
    final data =
        await _apiClient.post('/student/quest-attempts/$attemptId/submit');
    return QuestSubmitResult.fromJson(data as Map<String, dynamic>);
  }

  Future<QuestSubmitResult> getResult(String attemptId) async {
    final data =
        await _apiClient.get('/student/quest-attempts/$attemptId/result');
    return QuestSubmitResult.fromJson(data as Map<String, dynamic>);
  }
}
