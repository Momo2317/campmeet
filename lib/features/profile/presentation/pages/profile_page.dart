import 'package:camp_meet/features/discovery/presentation/pages/discovery_page.dart'
    show BottomNavBar;
import 'dart:io';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/features/profile/presentation/pages/settings_page.dart';
import 'package:camp_meet/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:camp_meet/features/profile/presentation/pages/security_page.dart';
import 'package:camp_meet/features/verification/presentation/widgets/verification_tile.dart';
import 'package:camp_meet/features/profile/presentation/pages/help_support_page.dart';
import 'package:camp_meet/features/profile/presentation/widgets/premium_carousel.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  static const int _maxHighlights = 2;

  ImageProvider _resolveAvatarImage(String url) {
    if (url.startsWith('http')) {
      return NetworkImage(url);
    }
    return FileImage(File(url));
  }

  IconData _themeIcon(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return CupertinoIcons.sun_max;
      case ThemeMode.dark:
        return CupertinoIcons.moon;
      default:
        return CupertinoIcons.circle_lefthalf_fill;
    }
  }

  /// Wechselt direkt per Tipp auf das Icon: Auto → Hell → Dunkel → Auto.
  void _cycleTheme(WidgetRef ref, ThemeMode current) {
    final next = switch (current) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    ref.read(themeModeProvider.notifier).set(next);
  }

  void _edit(BuildContext context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const EditProfilePage()),
      );

  static const Color _accent = Color(0xFF9B30FF);

  Widget _divider(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Divider(height: 1, thickness: 1, color: context.fgA(0.08)),
      );

  Widget _label(BuildContext context, String t, {String? trailing}) => Row(
        children: [
          Expanded(
            child: Text(t.toUpperCase(),
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                    color: context.fgA(0.5))),
          ),
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: _accent)),
        ],
      );

  Widget _iconBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, color: context.fgA(0.8), size: 22),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _fact(BuildContext context, IconData icon, String label,
      {bool missing = false}) {
    return InkWell(
      onTap: () => _edit(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: missing ? _accent : context.fgA(0.55)),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    color: missing ? _accent : context.fgA(0.85))),
          ],
        ),
      ),
    );
  }

  Widget _photoSlot(BuildContext context, ImageProvider? img) {
    return GestureDetector(
      onTap: () => _edit(context),
      child: AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(
            color: context.fgA(0.05),
            borderRadius: BorderRadius.circular(8),
            image: img != null
                ? DecorationImage(image: img, fit: BoxFit.cover)
                : null,
          ),
          child: img == null
              ? Icon(CupertinoIcons.add, color: context.fgA(0.35), size: 22)
              : null,
        ),
      ),
    );
  }

  Widget _highlight(BuildContext context, {MapEntry<String, String>? entry}) {
    return InkWell(
      onTap: () => _edit(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(left: 14),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
                color: entry == null ? context.fgA(0.15) : _accent, width: 2),
          ),
        ),
        child: entry == null
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text('Antwort hinzufügen',
                    style: TextStyle(fontSize: 15, color: context.fgA(0.45))),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.key,
                      style: TextStyle(fontSize: 13, color: context.fgA(0.55))),
                  const SizedBox(height: 4),
                  Text(entry.value,
                      style: TextStyle(
                          fontSize: 17,
                          height: 1.3,
                          fontWeight: FontWeight.w500,
                          color: context.fg)),
                ],
              ),
      ),
    );
  }

  int _completionPercent(UserProfile user) {
    final checks = <bool>[
      user.university.isNotEmpty,
      user.major.isNotEmpty,
      user.semester > 0,
      user.orientation.isNotEmpty,
      user.relationshipType != null,
      user.height != null,
      user.zodiac != null,
      user.bio.isNotEmpty,
      user.interests.isNotEmpty,
    ];
    final done = checks.where((c) => c).length;
    return (done * 100 / checks.length).round();
  }

  Widget _completion(BuildContext context, int percent) {
    return InkWell(
      onTap: () => _edit(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: context.fgA(0.12)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text('Profil vervollständigen',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.fg)),
              ),
              Text('$percent %',
                  style: TextStyle(fontSize: 14, color: context.fgA(0.6))),
            ]),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: percent / 100,
                minHeight: 3,
                backgroundColor: context.fgA(0.08),
                valueColor: const AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 13, color: context.fgA(0.55))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider) ?? UserProfile.defaultProfile();
    final avatar = _resolveAvatarImage(user.avatarUrl);
    final highlights = user.prompts.entries
        .where((e) => e.value.trim().isNotEmpty)
        .take(_maxHighlights)
        .toList();
    final missingHighlights = _maxHighlights - highlights.length;
    final percent = _completionPercent(user);

    return Scaffold(
      backgroundColor: context.bg,
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BottomNavBar(
              selected: 'profile',
              restricted: ref.watch(restrictedAccessProvider)),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _iconBtn(context, _themeIcon(ref.watch(themeModeProvider)),
                      () => _cycleTheme(ref, ref.read(themeModeProvider))),
                  _iconBtn(
                      context,
                      CupertinoIcons.gear,
                      () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          )),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 36, backgroundImage: avatar),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.4,
                                color: context.fg)),
                        const SizedBox(height: 2),
                        GestureDetector(
                          onTap: () => _edit(context),
                          child: Text('Profil bearbeiten',
                              style: TextStyle(
                                  fontSize: 14,
                                  decoration: TextDecoration.underline,
                                  decorationColor: context.fgA(0.3),
                                  color: context.fgA(0.6))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (percent < 100) ...[
                const SizedBox(height: 20),
                _completion(context, percent),
              ],
              const SizedBox(height: 20),
              const VerificationTile(),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 0,
                children: [
                  _fact(context, CupertinoIcons.book, user.university,
                      missing: user.university.isEmpty),
                  _fact(context, CupertinoIcons.book, user.major,
                      missing: user.major.isEmpty),
                  _fact(context, CupertinoIcons.calendar,
                      '${user.semester}. Semester',
                      missing: user.semester <= 0),
                  _fact(context, CupertinoIcons.compass, user.orientation,
                      missing: user.orientation.isEmpty),
                  _fact(context, CupertinoIcons.heart,
                      user.relationshipType ?? 'Beziehungsart',
                      missing: user.relationshipType == null),
                  _fact(context, CupertinoIcons.arrow_up_down,
                      user.height != null ? '${user.height} cm' : 'Größe',
                      missing: user.height == null),
                  _fact(context, CupertinoIcons.sparkles,
                      user.zodiac ?? 'Sternzeichen',
                      missing: user.zodiac == null),
                ],
              ),
              if (user.bio.isNotEmpty || user.interests.isNotEmpty) ...[
                _divider(context),
                _label(context, 'Über mich'),
                const SizedBox(height: 12),
                if (user.bio.isNotEmpty)
                  Text(user.bio,
                      style: TextStyle(
                          fontSize: 16, height: 1.5, color: context.fg)),
                if (user.bio.isNotEmpty && user.interests.isNotEmpty)
                  const SizedBox(height: 16),
                if (user.interests.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final i in user.interests)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            border: Border.all(color: context.fgA(0.18)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(i,
                              style: TextStyle(
                                  fontSize: 13, color: context.fgA(0.85))),
                        ),
                    ],
                  ),
              ],
              _divider(context),
              _label(context, 'Fotos'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 4 / 5,
                children: [
                  _photoSlot(context, avatar),
                  for (var i = 0; i < 5; i++) _photoSlot(context, null),
                ],
              ),
              const SizedBox(height: 10),
              Text('Profile mit sechs Fotos bekommen mehr Likes.',
                  style: TextStyle(fontSize: 13, color: context.fgA(0.55))),
              _divider(context),
              _label(context, 'Highlights',
                  trailing: missingHighlights > 0
                      ? '$missingHighlights offen'
                      : null),
              const SizedBox(height: 16),
              for (var i = 0; i < _maxHighlights; i++) ...[
                if (i > 0) const SizedBox(height: 18),
                _highlight(context,
                    entry: i < highlights.length ? highlights[i] : null),
              ],
              _divider(context),
              _label(context, 'Guthaben'),
              const SizedBox(height: 14),
              Row(children: [
                _stat(context, '${user.superLikes}', 'Super-Likes'),
                _stat(context, '${user.boosts}', 'Boosts'),
                _stat(
                    context, user.isPlatinum ? 'Platinum' : 'Kostenlos', 'Abo'),
              ]),
              _divider(context),
              _ProfileMenuTile(
                icon: CupertinoIcons.shield,
                title: 'Sicherheit',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SecurityPage()),
                ),
              ),
              _ProfileMenuTile(
                icon: CupertinoIcons.question_circle,
                title: 'Hilfe & Support',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const HelpSupportPage()),
                ),
              ),
              _divider(context),
              _label(context, 'Mehr aus CampusMatch'),
              const SizedBox(height: 12),
              const PremiumCarousel(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ProfileMenuTile(
      {required this.icon, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: context.fgA(0.7), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: TextStyle(color: context.fg, fontSize: 16)),
            ),
            Icon(CupertinoIcons.chevron_right,
                color: context.fgA(0.3), size: 20),
          ],
        ),
      ),
    );
  }
}
