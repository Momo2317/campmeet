import 'dart:ui';
import 'dart:io';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/features/profile/presentation/pages/premium_page.dart';
import 'package:camp_meet/features/discovery/presentation/pages/student_profile_page.dart';
import 'package:camp_meet/features/discovery/presentation/pages/discovery_page.dart'
    show BottomNavBar;
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';

class LikesPage extends ConsumerStatefulWidget {
  const LikesPage({super.key});

  @override
  ConsumerState<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends ConsumerState<LikesPage> {
  static const _filters = ['Für dich', 'Zuletzt', 'Beliebt', 'In der Nähe'];
  int _filter = 0;

  List<Student> _items() {
    final base = mockStudents.take(8).toList();
    switch (_filter) {
      case 1:
        return base.reversed.toList();
      case 2:
        return (mockStudents.where((s) => s.isPlatinum).toList()
              ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore)))
            .take(10)
            .toList();
      case 3:
        return base.toList()..sort((a, b) => a.name.compareTo(b.name));
      default:
        return base;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final isPremium = userProfile?.isPlatinum ?? false;
    final items = _items();
    final isTop = _filter == 2;

    return Scaffold(
      backgroundColor: context.bg,
      bottomNavigationBar: const SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: BottomNavBar(selected: 'likes'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                  child: Row(
                    children: [
                      Text('Likes',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: context.fg)),
                      const SizedBox(width: 10),
                      Text('${mockStudents.take(8).length}',
                          style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9B30FF))),
                    ],
                  ),
                ),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final sel = i == _filter;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = i),
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF9B30FF) : null,
                            border: sel
                                ? null
                                : Border.all(color: context.fgA(0.2)),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Text(_filters[i],
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      sel ? Colors.white : context.fgA(0.8))),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Text(
                      isTop
                          ? 'Die Beliebtesten'
                          : 'Diese Personen haben dich geliked',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: context.fgA(0.6))),
                ),
                Expanded(
                  child: GridView.builder(
                    padding:
                        EdgeInsets.fromLTRB(16, 8, 16, isPremium ? 20 : 110),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _LikeCard(
                      student: items[index],
                      isBlurred: !isTop && !isPremium && index > 0,
                      isTopPick: isTop,
                      rank: isTop ? index + 1 : null,
                    ),
                  ),
                ),
              ],
            ),
            if (!isPremium)
              Positioned(
                left: 30,
                right: 30,
                bottom: 12,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFFFF2D9B),
                        Color(0xFF9B30FF),
                        Color(0xFF5B2BF0)
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF9B30FF).withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PremiumPage()),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CupertinoIcons.heart_fill,
                            color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Alle Likes & Top 10 freischalten',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LikeCard extends StatelessWidget {
  final Student student;
  final bool isBlurred;
  final bool isTopPick;
  final int? rank;

  const _LikeCard({
    required this.student,
    this.isBlurred = false,
    this.isTopPick = false,
    this.rank,
  });

  ImageProvider _resolveImage(String url) {
    if (url.startsWith('http')) return NetworkImage(url);
    return FileImage(File(url));
  }

  LinearGradient _rankGradient(int r) {
    if (r == 1) {
      return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)]); // Gold
    } else if (r == 2) {
      return const LinearGradient(
          colors: [Color(0xFFE0E0E0), Color(0xFF9E9E9E)]); // Silber
    } else if (r == 3) {
      return const LinearGradient(
          colors: [Color(0xFFCD7F32), Color(0xFF8B4513)]); // Bronze
    }
    return const LinearGradient(
        colors: [Color(0xFF8A2387), Color(0xFFE94057)]); // Platin
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (isBlurred) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PremiumPage()),
          );
        } else {
          Navigator.push(
            context,
            studentProfileRoute(StudentProfilePage(student: student)),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: context.fgA(0.06),
          image: DecorationImage(
            image: _resolveImage(student.images.isNotEmpty
                ? student.images[0]
                : student.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Blur Effekt für gesperrte Profile
              if (isBlurred)
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    color: Colors.black.withOpacity(0.35),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.24),
                              width: 1.5),
                        ),
                        child: Icon(CupertinoIcons.lock_fill,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),

              // Obere Badges: Rang, Likes & Platinum
              Positioned(
                top: 10,
                left: 10,
                right: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Wrap(
                      spacing: 6,
                      children: [
                        if (isTopPick && rank != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: _rankGradient(rank!),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(color: Colors.black45, blurRadius: 4)
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (rank == 1) ...[
                                  Icon(CupertinoIcons.rosette,
                                      color: Colors.white, size: 12),
                                  const SizedBox(width: 3),
                                ],
                                Text(
                                  '#$rank',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    if (student.isPlatinum)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE5E4E2), Color(0xFFB4B4B4)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 3)
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.star_fill,
                                color: Color(0xFF4A4A4A), size: 10),
                            const SizedBox(width: 3),
                            Text(
                              'PLATINUM',
                              style: TextStyle(
                                color: const Color(0xFF4A4A4A),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Unterer Info-Bereich: Name, Uni & Beliebtheit
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 24, 12, 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.92),
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isBlurred
                                  ? 'Geheimes Profil'
                                  : '${student.name}, ${student.age}',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isBlurred
                            ? 'Tippe zum Freischalten'
                            : student.university,
                        style: TextStyle(
                          color: isBlurred
                              ? const Color(0xFFD9A8FF)
                              : Colors.white70,
                          fontSize: 12,
                          fontWeight:
                              isBlurred ? FontWeight.bold : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
