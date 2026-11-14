import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/features/chat/presentation/pages/chat_detail_page.dart';

class MatchDialog extends StatelessWidget {
  final Student student;
  final bool isDatingMode;
  final String? currentUserAvatar;

  const MatchDialog({
    super.key,
    required this.student,
    this.isDatingMode = true,
    this.currentUserAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final myAvatar = currentUserAvatar ??
        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2D9B), Color(0xFF9B30FF), Color(0xFF5B2BF0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isDatingMode ? "It's a Match!" : 'Study Buddy!',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Du und ${student.name} habt euch gegenseitig geliked.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              height: 150,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(-48, 0),
                    child: Transform.rotate(
                      angle: -6 * math.pi / 180,
                      child: _AvatarCircle(imageUrl: myAvatar),
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(48, 0),
                    child: Transform.rotate(
                      angle: 6 * math.pi / 180,
                      child: _AvatarCircle(imageUrl: student.imageUrl),
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.heart_fill,
                        color: Color(0xFFFF2D9B), size: 22),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
            _MatchButton(
              text: 'Nachricht senden',
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatDetailPage(student: student)),
                );
              },
              primary: true,
            ),
            const SizedBox(height: 10),
            _MatchButton(
              text: 'Weiter swipen',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final String imageUrl;

  const _AvatarCircle({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final ImageProvider<Object> imageProvider = imageUrl.startsWith('http')
        ? NetworkImage(imageUrl) as ImageProvider<Object>
        : FileImage(File(imageUrl));

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 4),
        image: DecorationImage(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _MatchButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool primary;

  const _MatchButton({
    required this.text,
    required this.onPressed,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primary ? Colors.white : Colors.transparent,
          foregroundColor: primary ? const Color(0xFF9B30FF) : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
            side: primary
                ? BorderSide.none
                : const BorderSide(color: Colors.white54),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
