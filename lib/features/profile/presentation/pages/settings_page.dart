import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart'
    show CupertinoIcons, CupertinoSlidingSegmentedControl, CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/features/auth/presentation/pages/auth_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Abmelden?',
            style: TextStyle(color: context.fg, fontWeight: FontWeight.bold)),
        content: Text(
          'Möchtest du dich wirklich von CampMeet abmelden?',
          style: TextStyle(color: context.fgA(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Abbrechen', style: TextStyle(color: context.fgA(0.54))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userProfileProvider.notifier).logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9B30FF),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Abmelden',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Account unwiderruflich löschen?',
            style: TextStyle(
                color: const Color(0xFFFF4B6E), fontWeight: FontWeight.bold)),
        content: Text(
          'Alle deine Fotos, Matches und Chatverläufe werden dauerhaft gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(color: context.fgA(0.7), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Abbrechen', style: TextStyle(color: context.fgA(0.54))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userProfileProvider.notifier).deleteAccount();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dein Account wurde gelöscht.'),
                    backgroundColor: Color(0xFFFF4B6E),
                  ),
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Endgültig löschen',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider) ?? UserProfile.defaultProfile();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon:
              const Icon(CupertinoIcons.chevron_left, color: _accent, size: 24),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text('Einstellungen',
            style: TextStyle(
                color: context.fg, fontWeight: FontWeight.w800, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
        children: [
          _section(context, 'Account', [
            _row(context, CupertinoIcons.mail_solid, 'E-Mail',
                user.email.isNotEmpty ? user.email : 'student@uni.de'),
            _row(context, CupertinoIcons.building_2_fill, 'Campus',
                user.university),
            _row(context, CupertinoIcons.book_fill, 'Studiengang', user.major),
          ]),
          _section(context, 'Entdeckung', [
            _row(context, CupertinoIcons.location_solid, 'Standort',
                '${user.city}, Deutschland'),
            _row(
                context, CupertinoIcons.heart_fill, 'Aktiver Modus', user.mode),
            _row(context, CupertinoIcons.arrow_left_right, 'Max. Entfernung',
                '10 km'),
            _row(context, CupertinoIcons.person_2_fill, 'Altersspanne',
                '18 - 26'),
          ]),
          _section(context, 'Darstellung', [
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<ThemeMode>(
                  groupValue: ref.watch(themeModeProvider),
                  thumbColor: _accent,
                  backgroundColor: context.fgA(0.08),
                  children: {
                    ThemeMode.system: _segment('Auto', ThemeMode.system, ref),
                    ThemeMode.light: _segment('Hell', ThemeMode.light, ref),
                    ThemeMode.dark: _segment('Dunkel', ThemeMode.dark, ref),
                  },
                  onValueChanged: (v) {
                    if (v != null) {
                      ref.read(themeModeProvider.notifier).set(v);
                    }
                  },
                ),
              ),
            ),
          ]),
          _section(context, 'Benachrichtigungen', [
            _switchRow(
                context, CupertinoIcons.heart_circle_fill, 'Neue Matches'),
            _switchRow(
                context, CupertinoIcons.chat_bubble_fill, 'Nachrichten & Chat'),
          ]),
          const SizedBox(height: 8),
          _actionButton(context, 'Abmelden', context.fg,
              () => _showLogoutDialog(context, ref)),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: () => _showDeleteAccountDialog(context, ref),
              child: const Text('Account löschen',
                  style: TextStyle(
                      color: Color(0xFFFF4B6E), fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text('CampMeet Version 1.0.0 (build 1)',
                style: TextStyle(color: context.fgA(0.3), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  static const Color _accent = Color(0xFF9B30FF);

  Widget _segment(String label, ThemeMode mode, WidgetRef ref) {
    final selected = ref.watch(themeModeProvider) == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : null)),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> rows) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(Divider(
            height: 1, indent: 52, thickness: 0.5, color: context.fgA(0.1)));
      }
      children.add(rows[i]);
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 0, 8),
            child: Text(title,
                style: const TextStyle(
                    color: _accent, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
          Container(
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _leadingIcon(IconData icon) {
    return Icon(icon, color: _accent, size: 22);
  }

  Widget _row(BuildContext context, IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        children: [
          _leadingIcon(icon),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: context.fg, fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: TextStyle(color: context.fgA(0.54), fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _switchRow(BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: Row(
        children: [
          _leadingIcon(icon),
          const SizedBox(width: 16),
          Expanded(
            child:
                Text(title, style: TextStyle(color: context.fg, fontSize: 16)),
          ),
          CupertinoSwitch(
            value: true,
            activeTrackColor: _accent,
            onChanged: (v) {},
          ),
        ],
      ),
    );
  }

  Widget _actionButton(
      BuildContext context, String label, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: context.fgA(0.2)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w700, fontSize: 16)),
      ),
    );
  }
}
