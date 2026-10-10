import 'package:flutter/material.dart';

import '../../data/game_profile_repository.dart';
import '../../domain/baleverse_models.dart';
import 'korean_path_screen.dart';

const _homeBg = Color(0xFFFFF3C6);
const _homeInk = Color(0xFF3B2318);
const _homeYellow = Color(0xFFF4B400);
const _homeGreen = Color(0xFF4CAF50);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    required this.selectedWorld,
    this.backendData,
    required this.realUserName,
    required this.gameProfile,
    required this.masteryAverage,
    required this.realWorlds,
    required this.worldMasteryAverages,
    required this.selectedBackendWorldKey,
    required this.onSelectWorld,
    super.key,
  });

  final BaleWorld selectedWorld;
  final Map<String, dynamic>? backendData;
  // Data akun REAL dari GET /student/game-profile dan /student/mastery -
  // null berarti belum termuat/gagal, layar harus menampilkannya jujur
  // (placeholder '-'), BUKAN diam-diam pakai baleUser dummy.
  final String? realUserName;
  final GameProfileSummary? gameProfile;
  final double? masteryAverage;
  // Daftar dunia dari GET /student/worlds, dan rata-rata mastery PER dunia
  // (key lowercase) dari GET /student/mastery per dunia - Peta Perjalanan
  // menampilkan progres di semua dunia, bukan langkah di satu dunia saja.
  final List<Map<String, dynamic>> realWorlds;
  final Map<String, double> worldMasteryAverages;
  final String selectedBackendWorldKey;
  final ValueChanged<Map<String, dynamic>> onSelectWorld;

  @override
  Widget build(BuildContext context) {
    final backendProfile = backendData?['profile'] as Map<String, dynamic>?;
    final backendStats = backendData?['stats'] as Map<String, dynamic>?;
    final compact = MediaQuery.sizeOf(context).height < 900;

    return Container(
      color: _homeBg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(14, compact ? 10 : 18, 14, 10),
        child: Column(
          children: [
            _HeroStatsCard(
              userName: backendProfile?['name'] as String? ??
                  realUserName ??
                  'Pengguna',
              gameProfile: gameProfile,
              backendStats: backendStats,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 14),
            Card(
              child: ListTile(
                leading: const CircleAvatar(
                    child: Text('한',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                title: const Text('Belajar Bahasa Korea',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Hangul → percakapan sehari-hari'),
                trailing: const Icon(Icons.arrow_forward_rounded),
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const KoreanPathScreen())),
              ),
            ),
            SizedBox(height: compact ? 8 : 14),
            Expanded(
              child: _JourneyMapCard(
                worlds: realWorlds,
                masteryAverages: worldMasteryAverages,
                selectedBackendWorldKey: selectedBackendWorldKey,
                compact: compact,
                onSelectWorld: onSelectWorld,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroStatsCard extends StatelessWidget {
  const _HeroStatsCard({
    required this.userName,
    required this.gameProfile,
    required this.backendStats,
    required this.compact,
  });

  final String userName;
  final GameProfileSummary? gameProfile;
  final Map<String, dynamic>? backendStats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.fromLTRB(18, compact ? 14 : 20, 18, compact ? 14 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_homeYellow, Color(0xFFFFC94D)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33F4B400),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selamat datang di BaleVerse',
                      style: TextStyle(
                        color: Color(0xCC3B2318),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hai, $userName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 20 : 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: compact ? 44 : 52,
                height: compact ? 44 : 52,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1F000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.waving_hand_rounded,
                  color: _homeYellow,
                  size: compact ? 22 : 26,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 18),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 14,
              vertical: compact ? 10 : 14,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _StatItem(
                    icon: Icons.star_rounded,
                    color: _homeYellow,
                    label: compact ? 'XP' : 'XP Total',
                    value: backendStats?['xp'] != null
                        ? '${backendStats!['xp']}'
                        : gameProfile == null
                            ? '-'
                            : '${gameProfile!.accountXp}',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFFF6B2C),
                    label: 'Nyala',
                    value: backendStats?['streak'] != null
                        ? '${backendStats!['streak']}'
                        : gameProfile == null
                            ? '-'
                            : '${gameProfile!.streakCurrent}',
                  ),
                ),
                const _StatDivider(),
                Expanded(
                  child: _StatItem(
                    icon: Icons.workspace_premium_rounded,
                    color: const Color(0xFF8B5CF6),
                    label: 'Rank',
                    value: gameProfile == null
                        ? '-'
                        : _formatRank(gameProfile!.rank),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _formatRank(String rank) {
  final lower = rank.toLowerCase().replaceAll('_', ' ');
  return lower
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 5),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF60646F),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _homeInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: const Color(0xFFFFE0A1),
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _JourneyMapCard extends StatelessWidget {
  const _JourneyMapCard({
    required this.worlds,
    required this.masteryAverages,
    required this.selectedBackendWorldKey,
    required this.compact,
    required this.onSelectWorld,
  });

  final List<Map<String, dynamic>> worlds;
  final Map<String, double> masteryAverages;
  final String selectedBackendWorldKey;
  final bool compact;
  final ValueChanged<Map<String, dynamic>> onSelectWorld;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, compact ? 12 : 16, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFFD05A), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: compact ? 34 : 42,
                height: compact ? 34 : 42,
                decoration: BoxDecoration(
                  color: _homeGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.route_rounded,
                  color: _homeGreen,
                  size: compact ? 20 : 24,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Peta Perjalanan',
                      style: TextStyle(
                        color: _homeInk,
                        fontSize: compact ? 16 : 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (!compact)
                      const Text(
                        'Progresmu di setiap dunia.',
                        style: TextStyle(
                          color: Color(0xFF60646F),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 14),
          if (worlds.isEmpty)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: _homeYellow),
              ),
            )
          else
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minNodeHeight = 54.0;
                  const maxNodeHeight = 110.0;
                  const baseNodeHeight = 96.0;
                  var visibleCount = worlds.length.clamp(1, 6);
                  var nodeHeight = constraints.maxHeight / visibleCount;
                  while (nodeHeight < minNodeHeight && visibleCount > 1) {
                    visibleCount--;
                    nodeHeight = constraints.maxHeight / visibleCount;
                  }
                  nodeHeight = nodeHeight.clamp(minNodeHeight, maxNodeHeight);
                  final scale = (nodeHeight / baseNodeHeight).clamp(0.58, 1.15);
                  final visibleWorlds = worlds;
                  return ListView(
                    children: [
                      for (final entry in visibleWorlds.asMap().entries)
                        SizedBox(
                          height: nodeHeight,
                          child: _JourneyNode(
                            world: entry.value,
                            index: entry.key,
                            isLast: entry.key == visibleWorlds.length - 1,
                            scale: scale,
                            selected: (entry.value['key'] as String?)
                                    ?.toLowerCase() ==
                                selectedBackendWorldKey,
                            masteryPercent: masteryAverages[
                                    (entry.value['key'] as String?)
                                            ?.toLowerCase() ??
                                        '']
                                ?.round(),
                            onTap: () => onSelectWorld(entry.value),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

Color _worldColor(Object? key) => switch (key) {
      'NUMERIA' => const Color(0xFF2D8CFF),
      'KODEX' => const Color(0xFF4CAF50),
      'DETECTIVIA' => const Color(0xFF8D5E34),
      _ => _homeYellow,
    };

IconData _worldIcon(Object? key) => switch (key) {
      'NUMERIA' => Icons.calculate_rounded,
      'KODEX' => Icons.code_rounded,
      'DETECTIVIA' => Icons.search_rounded,
      _ => Icons.public_rounded,
    };

class _JourneyNode extends StatelessWidget {
  const _JourneyNode({
    required this.world,
    required this.index,
    required this.isLast,
    required this.scale,
    required this.selected,
    required this.masteryPercent,
    required this.onTap,
  });

  final Map<String, dynamic> world;
  final int index;
  final bool isLast;
  final double scale;
  final bool selected;
  final int? masteryPercent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _worldColor(world['key']);
    final started = (masteryPercent ?? 0) > 0;
    final alignRight = index.isOdd;
    final name = world['name'] as String? ?? 'Dunia';
    final subject = world['subject'] as String? ?? '';
    final node = _JourneyBubble(
      color: color,
      icon: _worldIcon(world['key']),
      selected: selected,
      scale: scale,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        children: [
          if (!isLast)
            Positioned(
              left: 0,
              right: 0,
              top: 50 * scale,
              child: Center(
                child: Container(
                  width: 6,
                  height: 58 * scale,
                  decoration: BoxDecoration(
                    color: started
                        ? color.withValues(alpha: 0.36)
                        : const Color(0xFFFFE0A1),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
            ),
          Align(
            alignment:
                alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.72,
              child: Row(
                textDirection:
                    alignRight ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  node,
                  SizedBox(width: 10 * scale),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.all(10 * scale),
                      decoration: BoxDecoration(
                        color: selected
                            ? const Color(0xFFFFF7D6)
                            : const Color(0xFFFFFAEA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color:
                              selected ? _homeYellow : const Color(0xFFFFE0A1),
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: alignRight
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign:
                                alignRight ? TextAlign.right : TextAlign.left,
                            style: TextStyle(
                              color: _homeInk,
                              fontSize: (14 * scale).clamp(11.0, 16.0),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (subject.isNotEmpty)
                            Text(
                              subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign:
                                  alignRight ? TextAlign.right : TextAlign.left,
                              style: TextStyle(
                                color: const Color(0xFF60646F),
                                fontSize: (11 * scale).clamp(9.0, 12.0),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          SizedBox(height: 5 * scale),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: alignRight
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            children: [
                              SizedBox(
                                width: 46 * scale,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: ((masteryPercent ?? 0) / 100).clamp(
                                      0,
                                      1,
                                    ),
                                    minHeight: 6 * scale,
                                    color: color,
                                    backgroundColor: const Color(0xFFFFE0A1),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6 * scale),
                              Text(
                                masteryPercent == null
                                    ? '-'
                                    : started
                                        ? '$masteryPercent%'
                                        : 'Belum mulai',
                                style: TextStyle(
                                  color: _homeInk,
                                  fontSize: (10 * scale).clamp(8.0, 11.0),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              if (selected) ...[
                                SizedBox(width: 6 * scale),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6 * scale,
                                    vertical: 2 * scale,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _homeGreen,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Aktif',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: (9 * scale).clamp(8.0, 10.0),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyBubble extends StatelessWidget {
  const _JourneyBubble({
    required this.color,
    required this.icon,
    required this.selected,
    required this.scale,
  });

  final Color color;
  final IconData icon;
  final bool selected;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final size = (62 * scale).clamp(40.0, 62.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: (4 * scale).clamp(2.0, 4.0),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 12,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: (30 * scale).clamp(20.0, 30.0),
          ),
        ),
        if (selected)
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: _homeGreen,
                size: (18 * scale).clamp(14.0, 18.0),
              ),
            ),
          ),
      ],
    );
  }
}
