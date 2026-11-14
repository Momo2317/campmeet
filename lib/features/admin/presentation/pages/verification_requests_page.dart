import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/features/verification/presentation/providers/verification_providers.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VerificationRequestsPage extends ConsumerWidget {
  const VerificationRequestsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(builder: (context) => _buildDark(context, ref)),
    );
  }

  Widget _buildDark(BuildContext context, WidgetRef ref) {
    final pendingRequests = ref.watch(pendingVerificationRequestsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Verifizierungsanfragen',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pendingRequests.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF9B30FF)),
        ),
        error: (error, stack) => Center(
          child: Text(
            'Fehler beim Laden: $error',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        data: (requests) {
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 64,
                    color: Colors.white30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Keine ausstehenden Anfragen',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Alle Nutzer sind verifiziert',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              return _VerificationRequestTile(
                requestId: request.id,
                userId: request.userId,
                imageUrl: request.imageUrl,
                submittedAt: request.submittedAt,
              );
            },
          );
        },
      ),
    );
  }
}

/// Individual verification request tile
class _VerificationRequestTile extends ConsumerWidget {
  final String requestId;
  final String userId;
  final String imageUrl;
  final DateTime submittedAt;

  const _VerificationRequestTile({
    required this.requestId,
    required this.userId,
    required this.imageUrl,
    required this.submittedAt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestWithUser = ref.watch(
      verificationRequestWithUserProvider(requestId),
    );

    return requestWithUser.when(
      loading: () => _buildLoadingTile(),
      error: (error, stack) => _buildErrorTile(error),
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        final userInfo = data['user'] as Map<String, dynamic>;
        final userName = userInfo['name'] as String;
        final userEmail = userInfo['email'] as String;
        final userUniversity = userInfo['university'] as String;
        final userAvatar = userInfo['avatarUrl'] as String?;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundImage: userAvatar != null
                      ? CachedNetworkImageProvider(userAvatar)
                      : null,
                  backgroundColor: const Color(0xFF9B30FF).withOpacity(0.3),
                  child: userAvatar == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                title: Text(
                  userName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      userEmail,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      userUniversity,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 200,
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black26,
                ),
                child: GestureDetector(
                  onTap: () => _showFullScreenImage(context, imageUrl),
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF9B30FF),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.white10,
                      child: const Icon(
                        Icons.error_outline,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Eingereicht: ${_formatDate(submittedAt)}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        ref,
                        'Ablehnen',
                        Colors.redAccent,
                        () => _showRejectDialog(context, ref),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        ref,
                        'Genehmigen',
                        const Color(0xFF27AE60),
                        () => _approveRequest(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingTile() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF9B30FF)),
      ),
    );
  }

  Widget _buildErrorTile(Object error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Text(
        'Fehler: $error',
        style: TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.2),
          side: BorderSide(color: color, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _approveRequest(BuildContext context, WidgetRef ref) async {
    final adminNotifier = ref.read(adminVerificationProvider.notifier);
    final currentUserId = ref.read(currentUserIdProvider);

    if (currentUserId == null) return;

    await adminNotifier.approveVerification(
      userId: userId,
      requestId: requestId,
      approvedBy: currentUserId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Verifizierung genehmigt',
            style: TextStyle(),
          ),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );

      // Refresh requests
      ref.invalidate(pendingVerificationRequestsProvider);
    }
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Verifizierung ablehnen',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Grund für Ablehnung:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'z.B. Bild zu unscharf, Ausweis nicht lesbar...',
                hintStyle: TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.06),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Abbrechen',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final adminNotifier =
                  ref.read(adminVerificationProvider.notifier);
              final currentUserId = ref.read(currentUserIdProvider);

              if (currentUserId != null) {
                await adminNotifier.rejectVerification(
                  userId: userId,
                  requestId: requestId,
                  reason: reasonCtrl.text.isNotEmpty
                      ? reasonCtrl.text
                      : 'Kein Grund angegeben',
                  rejectedBy: currentUserId,
                );

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Verifizierung abgelehnt',
                          style: TextStyle(),
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );

                    // Refresh requests
                    ref.invalidate(pendingVerificationRequestsProvider);
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              'Ablehnen',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        child: GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF9B30FF)),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inHours < 1) {
      return 'vor ${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      return 'vor ${diff.inHours}h';
    } else {
      return 'vor ${diff.inDays}d';
    }
  }
}
