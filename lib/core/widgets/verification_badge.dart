import 'package:flutter/material.dart';

/// Widget for displaying verification badge
class VerificationBadge extends StatelessWidget {
  final bool isVerified;
  final double size;
  final String? verificationMethod;

  const VerificationBadge({
    Key? key,
    required this.isVerified,
    this.size = 24,
    this.verificationMethod,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    return Tooltip(
      message: _getTooltipText(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF2D9B), Color(0xFF9B30FF), Color(0xFF5B2BF0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9B30FF).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.verified,
            color: Colors.white,
            size: size * 0.7,
          ),
        ),
      ),
    );
  }

  String _getTooltipText() {
    if (verificationMethod == 'email') {
      return 'Verifiziert über Email';
    } else if (verificationMethod == 'student_id') {
      return 'Verifiziert via Studienausweis';
    }
    return 'Verifiziert';
  }
}

/// Large verification badge for profile pages
class LargeVerificationBadge extends StatelessWidget {
  final bool isVerified;
  final String? verificationMethod;
  final String? verificationDate;

  const LargeVerificationBadge({
    Key? key,
    required this.isVerified,
    this.verificationMethod,
    this.verificationDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVerified) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF2D9B), Color(0xFF9B30FF), Color(0xFF5B2BF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9B30FF).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            _getVerificationText(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getVerificationText() {
    if (verificationMethod == 'email') {
      return 'Email verifiziert';
    } else if (verificationMethod == 'student_id') {
      return 'Studienausweis verifiziert';
    }
    return 'Verifiziert';
  }
}

/// Animated verification success badge
class VerificationSuccessBadge extends StatefulWidget {
  final Duration duration;
  final VoidCallback? onComplete;

  const VerificationSuccessBadge({
    Key? key,
    this.duration = const Duration(milliseconds: 1500),
    this.onComplete,
  }) : super(key: key);

  @override
  State<VerificationSuccessBadge> createState() =>
      _VerificationSuccessBadgeState();
}

class _VerificationSuccessBadgeState extends State<VerificationSuccessBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF2D9B), Color(0xFF9B30FF), Color(0xFF5B2BF0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B30FF).withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.check_circle,
            color: Colors.white,
            size: 64,
          ),
        ),
      ),
    );
  }
}
