import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/features/home/app_home.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:camp_meet/features/auth/presentation/pages/login_page.dart';

class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({super.key});
  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  bool _googleBusy = false;

  Future<void> _signInWithGoogle() async {
    if (_googleBusy) return;
    setState(() => _googleBusy = true);
    try {
      await FirebaseAuthService().signInWithGoogle();
      final user = FirebaseAuthService().currentUser;
      final profile = ref.read(userProfileProvider);
      final email = (user?.email ?? '').toLowerCase();
      // Profil lokal anlegen/anpassen (unverifiziert bis zum Abgleich)
      final base = profile ?? UserProfile.defaultProfile();
      await ref.read(userProfileProvider.notifier).saveProfile(base.copyWith(
            id: user?.uid ?? base.id,
            email: email,
            name: (user?.displayName?.trim().isNotEmpty ?? false)
                ? user!.displayName!.split(' ').first
                : base.name,
            isVerified: false,
          ));
      await ref.read(userProfileProvider.notifier).refreshVerification();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AppHome()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.code != 'canceled') {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _googleBusy = false);
    }
  }

  void _showLegalSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LegalBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0F0B24).withOpacity(0.55),
                const Color(0xFF2A1160).withOpacity(0.85),
                const Color(0xFF0F0B24).withOpacity(0.97),
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // ── Info Button oben rechts ──────────────────────────────

                // ── Hauptinhalt ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),
                      SvgPicture.asset(
                        'assets/images/CampMeet_Login_Logo_1500px.svg',
                        height: 220,
                        fit: BoxFit.contain,
                      ),
                      const Spacer(),
                      _AuthButton(
                        text: 'Mit .edu E-Mail registrieren',
                        icon: CupertinoIcons.envelope_fill,
                        backgroundColor: Colors.white,
                        textColor: const Color(0xFF9B30FF),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const ProfileSetupPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _AuthButton(
                        text: 'Weiter mit Google',
                        icon: CupertinoIcons.globe,
                        backgroundColor: Colors.transparent,
                        textColor: Colors.white,
                        onPressed: _googleBusy ? () {} : _signInWithGoogle,
                      ),
                      const SizedBox(height: 28),
                      Row(children: [
                        Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.2),
                                thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('oder',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 13)),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.white.withOpacity(0.2),
                                thickness: 1)),
                      ]),
                      const SizedBox(height: 16),
                      Text(
                        'Du hast schon ein Profil?',
                        style: TextStyle(fontSize: 14, color: Colors.white60),
                      ),
                      const SizedBox(height: 10),
                      _AuthButton(
                        text: 'Einloggen',
                        icon: CupertinoIcons.person_crop_circle_fill,
                        backgroundColor: Colors.white.withOpacity(0.12),
                        textColor: Colors.white,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginPage()),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _showLegalSheet,
                        child: Text(
                          'Durch die Anmeldung stimmst du unseren\nAGB und Datenschutzbestimmungen zu.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white38,
                            decoration: TextDecoration.underline,
                            decorationColor: Colors.white30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Legal Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _LegalBottomSheet extends StatefulWidget {
  const _LegalBottomSheet();

  @override
  State<_LegalBottomSheet> createState() => _LegalBottomSheetState();
}

class _LegalBottomSheetState extends State<_LegalBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Color(0xFF0F0C29),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Handle ─────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Header ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CupertinoIcons.doc_text_fill,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  'Rechtliches',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(CupertinoIcons.xmark, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Tab Bar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFFF2D9B),
                      Color(0xFF9B30FF),
                      Color(0xFF5B2BF0)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle:
                    TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: TextStyle(fontSize: 14),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'Impressum'),
                  Tab(text: 'Datenschutz'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Tab Content ────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ImpressumTab(),
                _DatenschutzTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Impressum Tab ─────────────────────────────────────────────────────────────
class _ImpressumTab extends StatelessWidget {
  const _ImpressumTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        _LegalSection(
          icon: CupertinoIcons.building_2_fill,
          title: 'Angaben gemäß § 5 TMG',
          content:
              'CampMeet\nMehmet [Nachname]\nMusterstraße 1\n10115 Berlin\nDeutschland',
        ),
        _LegalSection(
          icon: CupertinoIcons.person_fill,
          title: 'Vertreten durch',
          content: 'Mehmet [Nachname]\n(Geschäftsführer)',
        ),
        _LegalSection(
          icon: CupertinoIcons.envelope_fill,
          title: 'Kontakt',
          content: 'E-Mail: kontakt@campmeet.app\nWebsite: www.campmeet.app',
        ),
        _LegalSection(
          icon: CupertinoIcons.doc_text,
          title: 'Plattform der EU-Kommission zur Online-Streitbeilegung',
          content:
              'https://ec.europa.eu/consumers/odr\n\nWir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.',
        ),
        _LegalSection(
          icon: CupertinoIcons.info_circle,
          title: 'Urheberrecht',
          content:
              'Die durch die Seitenbetreiber erstellten Inhalte und Werke auf diesen Seiten unterliegen dem deutschen Urheberrecht. Die Vervielfältigung, Bearbeitung, Verbreitung und jede Art der Verwertung außerhalb der Grenzen des Urheberrechtes bedürfen der schriftlichen Zustimmung des jeweiligen Autors bzw. Erstellers.',
        ),
        _LegalSection(
          icon: CupertinoIcons.info_circle_fill,
          title: 'Haftungsausschluss',
          content:
              'Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene Inhalte auf diesen Seiten nach den allgemeinen Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen.',
        ),
      ],
    );
  }
}

// ── Datenschutz Tab ───────────────────────────────────────────────────────────
class _DatenschutzTab extends StatelessWidget {
  const _DatenschutzTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        _LegalSection(
          icon: CupertinoIcons.shield_fill,
          title: 'Datenschutz auf einen Blick',
          content:
              'Diese Datenschutzerklärung klärt dich über die Art, den Umfang und Zweck der Verarbeitung von personenbezogenen Daten innerhalb unserer App auf. Wir nehmen den Schutz deiner persönlichen Daten sehr ernst.',
        ),
        _LegalSection(
          icon: CupertinoIcons.search,
          title: 'Welche Daten wir erheben',
          content:
              '• Name und Vorname\n• E-Mail-Adresse (Uni-E-Mail)\n• Profilfotos und -videos\n• Standortdaten (nur mit Zustimmung)\n• Universität und Studienfach\n• Geburtsdatum / Alter\n• Interessen und Angaben zur Person\n• Gerätedaten und App-Nutzungsdaten',
        ),
        _LegalSection(
          icon: CupertinoIcons.archivebox_fill,
          title: 'Zweck der Datenverarbeitung',
          content:
              '• Bereitstellung der Matching-Funktion\n• Personalisierung des Profils\n• Standortbasierte Nutzersuche (Opt-in)\n• Verbesserung der App und Nutzererfahrung\n• Sicherheit und Missbrauchsprävention\n• Versand von Push-Benachrichtigungen (Opt-in)',
        ),
        _LegalSection(
          icon: CupertinoIcons.lock_fill,
          title: 'Datensicherheit',
          content:
              'Alle Nachrichten in der App sind Ende-zu-Ende-verschlüsselt (E2EE). Deine Profildaten werden verschlüsselt auf Servern in der EU gespeichert. Es erfolgt keine Weitergabe an Dritte ohne deine ausdrückliche Zustimmung.',
        ),
        _LegalSection(
          icon: Icons.share_rounded,
          title: 'Weitergabe von Daten',
          content:
              'Deine Daten werden nicht an Dritte verkauft. Eine Weitergabe erfolgt nur:\n• An von dir explizit gewählte Kontakte\n• Bei gesetzlicher Verpflichtung\n• An Dienstleister, die uns beim App-Betrieb unterstützen (z.B. Server-Hosting in der EU)',
        ),
        _LegalSection(
          icon: CupertinoIcons.checkmark_shield_fill,
          title: 'Deine Rechte (DSGVO)',
          content:
              'Du hast jederzeit das Recht auf:\n• Auskunft über deine gespeicherten Daten\n• Berichtigung unrichtiger Daten\n• Löschung deiner Daten ("Recht auf Vergessenwerden")\n• Einschränkung der Verarbeitung\n• Datenübertragbarkeit\n• Widerspruch gegen die Verarbeitung\n\nKontakt: datenschutz@campmeet.app',
        ),
        _LegalSection(
          icon: CupertinoIcons.person_2_fill,
          title: 'Mindestalter',
          content:
              'CampMeet ist ausschließlich für Personen ab 18 Jahren bestimmt. Minderjährige dürfen die App nicht nutzen. Bei Bekanntwerden einer Nutzung durch Minderjährige wird das Konto umgehend gelöscht.',
        ),
        _LegalSection(
          icon: CupertinoIcons.bell_fill,
          title: 'Push-Benachrichtigungen',
          content:
              'Push-Benachrichtigungen können jederzeit in den App-Einstellungen deines Gerätes deaktiviert werden. Wir nutzen Firebase Cloud Messaging (Google LLC) für den Versand.',
        ),
        _LegalSection(
          icon: CupertinoIcons.arrow_2_circlepath,
          title: 'Änderungen dieser Datenschutzerklärung',
          content:
              'Wir behalten uns vor, diese Datenschutzerklärung anzupassen, um sie an geänderte Rechtslagen oder Änderungen des Dienstes anzupassen. Du wirst über wesentliche Änderungen informiert.\n\nLetzte Aktualisierung: April 2026',
        ),
      ],
    );
  }
}

// ── Shared Legal Section Widget ───────────────────────────────────────────────
class _LegalSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  const _LegalSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFB26BFF), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Auth Button
// ─────────────────────────────────────────────────────────────────────────────
class _AuthButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;

  const _AuthButton({
    required this.text,
    required this.icon,
    required this.onPressed,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
            side: backgroundColor == Colors.transparent
                ? const BorderSide(color: Colors.white70, width: 1.5)
                : BorderSide.none,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
