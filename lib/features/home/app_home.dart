import 'package:camp_meet/features/discovery/presentation/pages/discovery_page.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/features/wg/presentation/pages/wg_listings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Startseite nach dem Login.
/// Verifizierte Konten sehen Discovery, alle anderen (z. B. Google ohne
/// bestätigte Uni-Mail) nur den Bereich "WG & Zimmer".
class AppHome extends ConsumerStatefulWidget {
  const AppHome({super.key});

  @override
  ConsumerState<AppHome> createState() => _AppHomeState();
}

class _AppHomeState extends ConsumerState<AppHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userProfileProvider.notifier).refreshVerification();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final restricted = ref.watch(restrictedAccessProvider);
    return restricted ? const WgListingsPage() : const DiscoveryPage();
  }
}
