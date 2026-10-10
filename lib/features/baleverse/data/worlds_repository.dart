import '../../../core/api/api_client.dart';
import '../../../core/auth/token_store.dart';
import '../domain/world_curriculum_models.dart';

/// Ambil daftar Dunia sungguhan dari backend (`GET /student/worlds`).
/// Sebelumnya belum ada satu pun bagian aplikasi yang memanggil endpoint
/// ini - layar Dunia hanya menampilkan data dummy atau blob prototype lama.
class WorldsRepository {
  WorldsRepository({ApiClient? apiClient})
      : _apiClient = apiClient ??
            ApiClient(tokenProvider: const SecureTokenStore().read);

  final ApiClient _apiClient;

  Future<Map<String, dynamic>> fetchKoreanPath() async {
    final data = await _apiClient.get('/student/korean/path');
    return Map<String, dynamic>.from(data as Map<String, dynamic>);
  }

  /// Bentuk hasilnya disesuaikan supaya cocok dengan yang dipakai
  /// world_detail_screen.dart dan baleverse_demo_screen.dart (key
  /// UPPERCASE, dst).
  Future<List<Map<String, dynamic>>> fetchWorlds() async {
    final data = await _apiClient.get('/student/worlds');
    final list = (data as List).cast<Map<String, dynamic>>();
    return list.map((world) {
      final subject = world['subject'] as Map<String, dynamic>?;
      return <String, dynamic>{
        'key': (world['key'] as String? ?? '').toUpperCase(),
        // 'kind' dipakai untuk membedakan dunia Quest biasa (Numeria, dst)
        // dari dunia berbasis kosakata (Dunia Korea/Inggris) - lihat
        // baleverse_demo_screen.dart._startMission yang membranch navigasi
        // berdasarkan ini alih-alih masuk ke WorldCurriculumScreen.
        'kind': world['kind'] ?? 'QUEST',
        'name': world['name'],
        'subject': subject?['name'] ?? '',
        'description': world['themeDescription'] ?? '',
        'exampleMission': world['exampleMission'],
        'activeQuestionCount': world['activeQuestionCount'] ?? 0,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> fetchAdaptivePlan({
    required String worldKey,
  }) async {
    final data = await _apiClient.get(
      '/student/worlds/$worldKey/adaptive-plan',
    );
    return Map<String, dynamic>.from(data as Map<String, dynamic>);
  }

  Future<WorldCurriculum> fetchCurriculum({required String worldKey}) async {
    final data = await _apiClient.get('/student/worlds/$worldKey/curriculum');
    return WorldCurriculum.fromJson(data as Map<String, dynamic>);
  }
}
