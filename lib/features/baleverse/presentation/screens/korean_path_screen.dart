import 'package:flutter/material.dart';

import '../../../quests/data/quest_repository.dart';
import '../../../quests/domain/quest_models.dart';
import '../../../quests/presentation/quest_screen.dart';
import '../../data/worlds_repository.dart';

class KoreanPathScreen extends StatefulWidget {
  const KoreanPathScreen({super.key});

  @override
  State<KoreanPathScreen> createState() => _KoreanPathScreenState();
}

class _KoreanPathScreenState extends State<KoreanPathScreen> {
  final _worlds = WorldsRepository();
  final _quests = QuestRepository();
  late Future<(Map<String, dynamic>, QuestDailyProgress)> _future;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<(Map<String, dynamic>, QuestDailyProgress)> _load() async {
    final results = await Future.wait<dynamic>([
      _worlds.fetchKoreanPath(),
      _quests.fetchTodayAll('korean-learning'),
    ]);
    return (
      results[0] as Map<String, dynamic>,
      results[1] as QuestDailyProgress
    );
  }

  Future<void> _refresh() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _openLesson() async {
    if (_opening) return;
    setState(() => _opening = true);
    try {
      final today = await _quests.fetchTodayAll('korean-learning');
      if (!mounted) return;
      final needsNext = today.assignments.isNotEmpty &&
          today.assignments.last.attemptStatus == 'SUBMITTED';
      if (needsNext && !today.canRequestNext) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Target hari ini selesai. Tambah sesi per hari untuk lanjut, atau kembali besok.'),
        ));
        return;
      }
      await Navigator.of(context).push<bool>(MaterialPageRoute(
        builder: (_) =>
            QuestScreen(worldKey: 'korean-learning', requestNext: needsNext),
      ));
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _setDailyCount(int value) async {
    try {
      await _quests.updateDailyQuestCount(value);
      if (mounted) await _refresh();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$error')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3C6),
      appBar: AppBar(title: const Text('Belajar Bahasa Korea')),
      body: FutureBuilder<(Map<String, dynamic>, QuestDailyProgress)>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.cloud_off_rounded, size: 48),
                const SizedBox(height: 12),
                const Text('Jalur Korea belum bisa dimuat.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('${snapshot.error}', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () {
                      setState(() => _future = _load());
                    },
                    child: const Text('Coba lagi')),
              ]),
            ));
          }
          final (path, daily) = snapshot.data!;
          final total = path['lessonCount'] as int;
          final completed = path['completedLessonCount'] as int;
          final units = (path['units'] as List).cast<Map<String, dynamic>>();
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(padding: const EdgeInsets.all(16), children: [
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('한국어 · Langkah kecil setiap hari',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('$completed dari $total pelajaran selesai'),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                              value: total == 0 ? 0 : completed / total),
                          const SizedBox(height: 12),
                          Text(
                              'Nilai lulus ${path['passScore']} · sekitar 20 menit per pelajaran'),
                          Row(children: [
                            const Expanded(child: Text('Sesi per hari')),
                            DropdownButton<int>(
                                value: daily.dailyQuestCount,
                                items: List.generate(
                                    5,
                                    (index) => DropdownMenuItem(
                                        value: index + 1,
                                        child: Text('${index + 1}'))),
                                onChanged: _opening
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          _setDailyCount(value);
                                        }
                                      }),
                          ]),
                          SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _opening ? null : _openLesson,
                                icon: Icon(path['nextLessonCode'] == null
                                    ? Icons.replay
                                    : Icons.play_arrow_rounded),
                                label: Text(_opening
                                    ? 'Memuat…'
                                    : path['nextLessonCode'] == null
                                        ? 'Latihan ulang'
                                        : 'Lanjutkan belajar'),
                              )),
                        ],
                      ))),
              for (final unit in units) ...[
                Padding(
                    padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
                    child: Text(
                      '${unit['levelName']} · ${unit['title']}',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    )),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(unit['goal'] as String? ?? '')),
                const SizedBox(height: 8),
                for (final lesson
                    in (unit['lessons'] as List).cast<Map<String, dynamic>>())
                  Card(
                      child: ListTile(
                    enabled: lesson['state'] != 'LOCKED',
                    leading: CircleAvatar(
                      backgroundColor: lesson['state'] == 'COMPLETED'
                          ? Colors.green
                          : lesson['state'] == 'AVAILABLE'
                              ? Colors.amber
                              : Colors.grey.shade300,
                      child: Icon(
                          lesson['state'] == 'COMPLETED'
                              ? Icons.check
                              : lesson['state'] == 'AVAILABLE'
                                  ? Icons.play_arrow
                                  : Icons.lock_outline,
                          color: Colors.black87),
                    ),
                    title: Text(lesson['title'] as String),
                    subtitle: Text(lesson['state'] == 'COMPLETED'
                        ? 'Selesai'
                        : lesson['state'] == 'LOCKED'
                            ? 'Lulus pelajaran sebelumnya untuk membuka'
                            : '${lesson['activityCount']} latihan · ${lesson['xpReward']} XP'),
                    trailing: lesson['state'] == 'AVAILABLE'
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: lesson['state'] == 'AVAILABLE' && !_opening
                        ? _openLesson
                        : null,
                  )),
              ],
              const SizedBox(height: 24),
            ]),
          );
        },
      ),
    );
  }
}
