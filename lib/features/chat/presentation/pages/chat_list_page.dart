import 'package:camp_meet/features/discovery/presentation/pages/discovery_page.dart'
    show BottomNavBar;
import 'package:camp_meet/core/theme/app_theme.dart';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:camp_meet/features/discovery/presentation/pages/likes_page.dart';
import 'package:camp_meet/features/profile/presentation/pages/security_page.dart';
import 'package:camp_meet/features/profile/presentation/pages/settings_page.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/features/discovery/data/matches_repository.dart';
import 'package:camp_meet/features/chat/data/chat_model.dart';
import 'package:camp_meet/features/chat/data/chat_repository.dart';
import 'package:camp_meet/features/chat/presentation/pages/chat_detail_page.dart';

ImageProvider _imgOf(String url) {
  if (url.startsWith('http')) return NetworkImage(url);
  return FileImage(File(url));
}

class ChatListPage extends ConsumerWidget {
  const ChatListPage({super.key});

  Widget _circleBtn(BuildContext context, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Icon(icon, color: context.fg, size: 24),
      ),
    );
  }

  Widget _likesCard(BuildContext context) {
    final likeCount = mockStudents.take(8).length;
    final first = mockStudents.first;
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LikesPage())),
      child: SizedBox(
        width: 86,
        child: Column(
          children: [
            Container(
              height: 112,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF9B30FF), width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Image(
                          image: _imgOf(first.imageUrl), fit: BoxFit.cover),
                    ),
                    Center(
                      child: Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: Color(0xFF9B30FF), shape: BoxShape.circle),
                        child: Text('$likeCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text('Likes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.fg)),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(BuildContext context) => SizedBox(
        width: 86,
        child: Column(
          children: [
            Container(
              height: 112,
              decoration: BoxDecoration(
                color: context.fgA(0.07),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 50,
              height: 12,
              decoration: BoxDecoration(
                color: context.fgA(0.07),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(matchesProvider);
    final topBg = context.bg;
    final slots = matches.length < 3 ? 3 - matches.length : 0;

    return Scaffold(
      backgroundColor: topBg,
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: const BottomNavBar(selected: 'chat'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 6, 18),
              child: Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Chats',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                              color: context.fg)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      _circleBtn(
                          context,
                          CupertinoIcons.shield,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SecurityPage()))),
                      _circleBtn(
                          context,
                          CupertinoIcons.gear,
                          () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const SettingsPage()))),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: const Text('Neue Matches',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9B30FF))),
            ),
            SizedBox(
              height: 156,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _likesCard(context),
                  for (final m in matches) ...[
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => ChatDetailPage(student: m))),
                      child: SizedBox(
                        width: 86,
                        child: Column(
                          children: [
                            Container(
                              height: 112,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                image: DecorationImage(
                                    image: _imgOf(m.imageUrl),
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(m.name.split(' ')[0],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: context.fg)),
                          ],
                        ),
                      ),
                    ),
                  ],
                  for (var i = 0; i < slots; i++) ...[
                    const SizedBox(width: 10),
                    _placeholder(context),
                  ],
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
                      child: const Text('Nachrichten',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF9B30FF))),
                    ),
                    Expanded(
                      child: matches.isEmpty
                          ? Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Noch keine Matches. Swipe nach rechts, dann könnt ihr hier schreiben!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: context.fgA(0.54)),
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.only(bottom: 20),
                              itemCount: matches.length,
                              itemBuilder: (context, i) =>
                                  _ChatTile(student: matches[i]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final Student student;
  const _ChatTile({required this.student});

  String _formatPreview(ChatMessage msg) {
    if (msg.type == MessageType.text) return msg.text ?? '';
    if (msg.type == MessageType.image) return 'Foto';
    if (msg.type == MessageType.video) return 'Video';
    if (msg.type == MessageType.audio) return 'Sprachnachricht';
    return '';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(chatMessagesFamily(student.id));
    final last = messages.isNotEmpty ? messages.last : null;
    final theirTurn = last != null && !last.isMe;
    final preview = last == null
        ? 'Neues Match – schreib die erste Nachricht!'
        : (last.isMe ? 'Du: ${_formatPreview(last)}' : _formatPreview(last));

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatDetailPage(student: student)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(left: 20),
        child: Row(
          children: [
            CircleAvatar(radius: 28, backgroundImage: _imgOf(student.imageUrl)),
            const SizedBox(width: 14),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: context.fgA(0.1), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(student.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: context.fg)),
                              ),
                              if (student.isPlatinum) ...[
                                const SizedBox(width: 6),
                                const Icon(CupertinoIcons.checkmark_seal_fill,
                                    size: 16, color: Color(0xFF3FA7FF)),
                              ],
                              if (last == null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF9B30FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text('Neu',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(preview,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 15,
                                  color: theirTurn
                                      ? context.fg
                                      : context.fgA(0.6))),
                        ],
                      ),
                    ),
                    if (theirTurn)
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(left: 8, right: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF9B30FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
