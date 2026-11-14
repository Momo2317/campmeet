import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:camp_meet/core/theme/app_theme.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Wie funktionieren Matches?',
      'a':
          'Du und eine andere Person liken sich gegenseitig – dann ist es ein Match! Ihr könnt anschließend miteinander chatten. Matches verfallen nicht, du kannst also auch Monate später noch schreiben.',
    },
    {
      'q': 'Kann ich meinen Standort ändern?',
      'a':
          'Ja! Gehe zu Einstellungen → Entdeckung → Standort. Du kannst deinen Standort manuell anpassen oder die automatische Ortung verwenden.',
    },
    {
      'q': 'Warum sehe ich nicht viele Profile?',
      'a':
          'Das könnte an deinen Filtereinstellungen liegen. Prüfe die Entfernung, das Altersfilter und ob dein Profil vollständig ausgefüllt ist. Vollständige Profile werden häufiger angezeigt.',
    },
    {
      'q': 'Wie kann ich ein Profil melden?',
      'a':
          'Öffne das Profil der Person → tippe auf die drei Punkte oben rechts → "Melden". Wir bearbeiten alle Meldungen innerhalb von 24 Stunden.',
    },
    {
      'q': 'Wie kündige ich Premium?',
      'a':
          'iOS: Einstellungen → Apple-ID → Abonnements → CampMeet. Android: Play Store → Abonnements → CampMeet → Kündigen.',
    },
    {
      'q': 'Was passiert mit meinen Daten wenn ich das Konto lösche?',
      'a':
          'Beim Löschen werden alle persönlichen Daten, Fotos, Nachrichten und Matches sofort und dauerhaft entfernt. Gemäß DSGVO kannst du vorher eine Kopie deiner Daten anfordern.',
    },
    {
      'q': 'Ich habe mein Passwort vergessen – was tun?',
      'a':
          'Auf dem Login-Bildschirm auf "Passwort vergessen" tippen. Du erhältst eine E-Mail mit einem Link zum Zurücksetzen. Der Link ist 30 Minuten gültig.',
    },
    {
      'q': 'Warum werden meine Fotos nicht angezeigt?',
      'a':
          'Fotos müssen unsere Community-Richtlinien erfüllen und werden innerhalb von 24 Stunden geprüft. Keine freizügigen Inhalte, keine Fremden im Hintergrund ohne Einverständnis.',
    },
  ];

  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('Hilfe & Support',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        leading: IconButton(
          icon:
              const Icon(CupertinoIcons.chevron_left, color: Color(0xFF9B30FF)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Quick Help Cards
          _buildQuickHelpSection(context),
          const SizedBox(height: 24),

          // FAQ
          _buildSectionHeader('Häufige Fragen (FAQ)'),
          ..._faqs.asMap().entries.map((e) => _buildFaqTile(e.key, e.value)),
          Divider(color: context.fgA(0.1), height: 32),

          // Kontakt
          _buildSectionHeader('Support kontaktieren'),
          _buildContactForm(context),
          Divider(color: context.fgA(0.1), height: 32),

          // Nutzer melden
          _buildSectionHeader('Nutzer melden'),
          _buildActionCard(
            icon: CupertinoIcons.flag_fill,
            iconColor: const Color(0xFFFF4B6E),
            title: 'Unangemessenes Verhalten melden',
            subtitle: 'Wir bearbeiten alle Meldungen innerhalb von 24 Stunden',
            buttonText: 'Melden',
            onTap: () => _showReportSheet(context),
          ),
          Divider(color: context.fgA(0.1), height: 32),

          // Sicherheitstipps
          _buildSectionHeader('Sicherheitstipps'),
          _buildSafetyTips(),
          Divider(color: context.fgA(0.1), height: 32),

          // Rechtliches
          _buildSectionHeader('Rechtliches'),
          _buildLinkTile(
              CupertinoIcons.shield_fill,
              'Datenschutzerklärung (DSGVO)',
              () => _showLegalSheet(
                  context, 'Datenschutzerklärung', _datenschutz)),
          _buildLinkTile(
              CupertinoIcons.doc_text_fill,
              'Nutzungsbedingungen (AGB)',
              () => _showLegalSheet(context, 'Nutzungsbedingungen', _agb)),
          _buildLinkTile(
              CupertinoIcons.person_2_fill,
              'Community-Richtlinien',
              () => _showLegalSheet(
                  context, 'Community-Richtlinien', _communityRules)),
          Divider(color: context.fgA(0.1), height: 32),

          // Notfall & Beratung
          _buildSectionHeader('Notfall & Beratung'),
          _buildEmergencySection(),
          Divider(color: context.fgA(0.1), height: 32),

          // App bewerten & Changelog
          _buildSectionHeader('Weiteres'),
          _buildLinkTile(CupertinoIcons.star_fill, 'App bewerten', () {}),
          _buildLinkTile(CupertinoIcons.sparkles, "Was ist neu? (v1.0.0)",
              () => _showChangelogSheet(context)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFFB26BFF),
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildQuickHelpSection(BuildContext context) {
    final items = [
      (CupertinoIcons.chat_bubble_fill, 'Chat-Hilfe', const Color(0xFF9B30FF)),
      (CupertinoIcons.heart_fill, 'Match-Hilfe', const Color(0xFFFF4B6E)),
      (CupertinoIcons.lock_fill, 'Datenschutz', const Color(0xFF2BD9A0)),
      (CupertinoIcons.star_fill, 'Premium', const Color(0xFFFFB400)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Wie können wir helfen?',
            style: TextStyle(
                color: context.fg, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Wähle ein Thema oder schreibe uns direkt.',
            style: TextStyle(color: context.fgA(0.54), fontSize: 14),
          ),
          const SizedBox(height: 16),
          Row(
            children: items.map((item) {
              return Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.fgA(0.1)),
                    ),
                    child: Column(
                      children: [
                        Icon(item.$1, color: item.$3, size: 28),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: TextStyle(
                              color: context.fg,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqTile(int index, Map<String, String> faq) {
    final isExpanded = _expandedFaqIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isExpanded
                ? const Color(0xFF9B30FF).withOpacity(0.5)
                : context.fgA(0.1)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          onExpansionChanged: (expanded) {
            setState(() => _expandedFaqIndex = expanded ? index : null);
          },
          initiallyExpanded: isExpanded,
          iconColor: const Color(0xFFB26BFF),
          collapsedIconColor: context.fgA(0.38),
          title: Text(
            faq['q']!,
            style: TextStyle(
                color: context.fg, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                faq['a']!,
                style: TextStyle(
                    color: context.fgA(0.6), fontSize: 13, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            controller: _subjectCtrl,
            style: TextStyle(color: context.fg),
            decoration: InputDecoration(
              labelText: 'Betreff',
              labelStyle: TextStyle(color: context.fgA(0.54)),
              filled: true,
              fillColor: context.fgA(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              prefixIcon:
                  Icon(CupertinoIcons.text_alignleft, color: context.fgA(0.38)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            style: TextStyle(color: context.fg),
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Deine Nachricht',
              labelStyle: TextStyle(color: context.fgA(0.54)),
              filled: true,
              fillColor: context.fgA(0.06),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (_subjectCtrl.text.isNotEmpty &&
                    _messageCtrl.text.isNotEmpty) {
                  _subjectCtrl.clear();
                  _messageCtrl.clear();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Nachricht gesendet! Wir melden uns innerhalb von 24h.',
                          style: TextStyle()),
                      backgroundColor: const Color(0xFF2BD9A0),
                    ),
                  );
                }
              },
              icon: const Icon(CupertinoIcons.paperplane_fill, size: 18),
              label: Text('Nachricht senden',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF9B30FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.fgA(0.1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: context.fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(color: context.fgA(0.38), fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: iconColor.withOpacity(0.2),
              foregroundColor: iconColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(buttonText,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTips() {
    final tips = [
      {
        'icon': 'map_pin_ellipse',
        'tip': 'Treffe dich beim ersten Date an einem öffentlichen Ort'
      },
      {
        'icon': 'device_phone_portrait',
        'tip': 'Teile deinen Aufenthaltsort mit einer Vertrauensperson'
      },
      {'icon': 'car_fill', 'tip': 'Organisiere deine eigene An- und Abreise'},
      {
        'icon': 'link',
        'tip': 'Gib keine persönlichen Daten (Adresse, Banking) weiter'
      },
      {
        'icon': 'exclamationmark_triangle_fill',
        'tip': 'Vertraue deinem Instinkt – im Zweifel brich das Treffen ab'
      },
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2BD9A0).withOpacity(0.3)),
      ),
      child: Column(
        children: tips
            .map((t) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(_tipIcon(t['icon']!),
                          size: 20, color: const Color(0xFF2BD9A0)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          t['tip']!,
                          style: TextStyle(
                              color: context.fgA(0.7),
                              fontSize: 13,
                              height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }

  IconData _tipIcon(String name) => switch (name) {
        'map_pin_ellipse' => CupertinoIcons.map_pin_ellipse,
        'device_phone_portrait' => CupertinoIcons.device_phone_portrait,
        'car_fill' => CupertinoIcons.car_fill,
        'link' => CupertinoIcons.link,
        _ => CupertinoIcons.exclamationmark_triangle_fill,
      };

  Widget _buildEmergencySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFF4B6E).withOpacity(0.15),
            const Color(0xFF9B30FF).withOpacity(0.15)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF4B6E).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Du brauchst sofortige Hilfe?',
            style: TextStyle(
                color: context.fg, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildEmergencyContact(CupertinoIcons.exclamationmark_triangle_fill,
              'Notruf', '110 / 112', const Color(0xFFFF4B6E)),
          const SizedBox(height: 8),
          _buildEmergencyContact(CupertinoIcons.heart_fill, 'Telefonseelsorge',
              '0800 111 0 111', const Color(0xFF9B30FF)),
          const SizedBox(height: 8),
          _buildEmergencyContact(
              CupertinoIcons.person_fill,
              'Frauennotruf (bundesweit)',
              '08000 116 016',
              const Color(0xFFFF2D9B)),
          const SizedBox(height: 8),
          _buildEmergencyContact(
              CupertinoIcons.book_fill,
              'Psychologische Uni-Beratung',
              'Über deine Universität',
              const Color(0xFFB26BFF)),
          const SizedBox(height: 12),
          Text(
            'Du bist nicht allein. Sprich mit jemandem – die Leitungen sind kostenlos und anonym.',
            style:
                TextStyle(color: context.fgA(0.54), fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact(
      IconData icon, String label, String number, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(color: context.fgA(0.7), fontSize: 12)),
              Text(number,
                  style: TextStyle(
                      color: color, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.fgA(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: context.fgA(0.7), size: 20),
      ),
      title: Text(title, style: TextStyle(color: context.fg, fontSize: 14)),
      trailing:
          Icon(CupertinoIcons.chevron_right, color: context.fgA(0.3), size: 16),
    );
  }

  // ============= SHEETS =============

  void _showReportSheet(BuildContext context) {
    final reasons = [
      'Unangemessene Fotos',
      'Belästigung oder Bedrohung',
      'Fake-Profil / Betrug',
      'Hassrede oder Diskriminierung',
      'Spam',
      'Minderjährig',
      'Sonstiges',
    ];
    int? selectedReason;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              left: 20,
              right: 20,
              top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.fgA(0.24),
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              Text('Nutzer melden',
                  style: TextStyle(
                      color: context.fg,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Wähle den Grund für deine Meldung:',
                  style: TextStyle(color: context.fgA(0.54), fontSize: 13)),
              const SizedBox(height: 16),
              ...reasons.asMap().entries.map((e) => GestureDetector(
                    onTap: () => setSheetState(() => selectedReason = e.key),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: selectedReason == e.key
                            ? const Color(0xFF9B30FF).withOpacity(0.25)
                            : context.fgA(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: selectedReason == e.key
                                ? const Color(0xFF9B30FF)
                                : context.fgA(0.1)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            selectedReason == e.key
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: selectedReason == e.key
                                ? const Color(0xFF9B30FF)
                                : context.fgA(0.38),
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(e.value,
                              style:
                                  TextStyle(color: context.fg, fontSize: 14)),
                        ],
                      ),
                    ),
                  )),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedReason != null
                      ? () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Meldung eingereicht. Danke, dass du die Community schützt!',
                                  style: TextStyle()),
                              backgroundColor: const Color(0xFF2BD9A0),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFFFF4B6E),
                    disabledBackgroundColor: context.fgA(0.12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Meldung absenden',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showLegalSheet(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (ctx, ctrl) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.fgA(0.24),
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 16),
                  Text(title,
                      style: TextStyle(
                          color: context.fg,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: ctrl,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                children: [
                  Text(content,
                      style: TextStyle(
                          color: context.fgA(0.7), fontSize: 13, height: 1.6)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangelogSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.fgA(0.24),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Was ist neu?',
                style: TextStyle(
                    color: context.fg,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Version 1.0.0 – März 2026',
                style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
            const SizedBox(height: 20),
            _changelogItem(CupertinoIcons.sparkles,
                'Neues Profil-Design mit Bio-Tags und Stats'),
            _changelogItem(CupertinoIcons.chat_bubble_fill,
                'Verbesserter Chat mit Story-Navigation'),
            _changelogItem(CupertinoIcons.search,
                'Erweiterte Entdecken-Filter (Uni, Alter, Entfernung)'),
            _changelogItem(CupertinoIcons.star_fill,
                'Premium-Features: Wer hat mich geliked, Super Likes'),
            _changelogItem(CupertinoIcons.lock_fill,
                'Neue Sicherheitsseite mit 2FA und Datenschutz-Einstellungen'),
            _changelogItem(CupertinoIcons.question_circle_fill,
                'Hilfe & Support mit FAQ und Notfall-Ressourcen'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _changelogItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFB26BFF)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: context.fgA(0.7), fontSize: 14))),
        ],
      ),
    );
  }

  // ============= LEGAL TEXTS =============

  static const String _datenschutz = '''
CampMeet Datenschutzerklärung (Stand: März 2026)

1. VERANTWORTLICHER
CampMeet GmbH, Berlin, Deutschland
Datenschutzbeauftragter: datenschutz@campmeet.de

2. ERHOBENE DATEN
Wir erheben folgende personenbezogene Daten:
• Registrierungsdaten: E-Mail, Alter, Universität
• Profildaten: Fotos, Bio, Interessen, Studiengang
• Standortdaten (nur mit ausdrücklicher Zustimmung)
• Gerätedaten und anonymisierte Nutzungsstatistiken

3. RECHTLICHE GRUNDLAGE
Datenverarbeitung erfolgt auf Basis von:
• Art. 6 Abs. 1 lit. a DSGVO (Einwilligung)
• Art. 6 Abs. 1 lit. b DSGVO (Vertragserfüllung)

4. DATENWEITERGABE
Wir geben deine Daten NICHT an Dritte weiter, außer an Auftragsverarbeiter (z. B. Cloud-Dienstleister) unter Einhaltung der DSGVO.

5. DEINE RECHTE
• Auskunft (Art. 15 DSGVO)
• Berichtigung (Art. 16 DSGVO)
• Löschung (Art. 17 DSGVO)
• Einschränkung (Art. 18 DSGVO)
• Datenübertragbarkeit (Art. 20 DSGVO)
• Widerruf (Art. 7 Abs. 3 DSGVO)

Zur Ausübung deiner Rechte: datenschutz@campmeet.de

6. SPEICHERDAUER
Daten werden gelöscht, sobald sie für den Verarbeitungszweck nicht mehr benötigt werden oder du dein Konto löschst.

7. COOKIES & TRACKING
Wir verwenden ausschließlich technisch notwendige Cookies. Kein Tracking durch Drittanbieter.

8. SICHERHEIT
Deine Daten werden verschlüsselt (TLS/SSL) übertragen und gespeichert.
''';

  static const String _agb = '''
CampMeet Nutzungsbedingungen – Stand: März 2026

1. GELTUNGSBEREICH
Diese AGB gelten für alle Nutzer der CampMeet App.

2. NUTZUNGSVORAUSSETZUNGEN
• Mindestalter: 18 Jahre
• Aktiver Studierendenstatus oder Hochschulzugehörigkeit
• Korrekte und vollständige Angaben beim Registrierungsprozess

3. VERHALTEN IM NETZWERK
Folgendes ist ausdrücklich verboten:
• Falsche Identitätsangaben oder Impersonation
• Belästigung, Bedrohung oder Diskriminierung anderer Nutzer
• Teilen von unangemessenen oder illegalen Inhalten
• Kommerzielle Nutzung oder Spam

4. INHALTE
Du bist für alle von dir erstellten Inhalte verantwortlich. Du räumst CampMeet eine nicht-exklusive Lizenz zur Nutzung dieser Inhalte ein.

5. HAFTUNG
CampMeet haftet nicht für die Handlungen der Nutzer oder für Schäden, die durch die Nutzung der App entstehen, soweit dies gesetzlich zulässig ist.

6. KÜNDIGUNG
Wir behalten uns vor, Konten bei Verstößen gegen diese AGB ohne Vorankündigung zu sperren oder zu löschen.

7. ÄNDERUNGEN
Wir behalten uns vor, diese AGB zu ändern. Nutzer werden per E-Mail informiert.
''';

  static const String _communityRules = '''
CampMeet Community-Richtlinien

Unser Ziel ist eine sichere, respektvolle und authentische Community für Studierende.

🟢 ERWÜNSCHT
• Echte Fotos und ehrliche Profilangaben
• Respektvoller Umgang mit anderen Nutzern
• Konstruktive, freundliche Konversationen
• Melden von Verstößen, um die Community zu schützen

🔴 VERBOTEN
• Fake-Profile oder fremde Bilder
• Sexuell explizite Inhalte ohne Einwilligung (ebenfalls verboten)
• Hassrede, Rassismus, Sexismus, Homophobie
• Bedrohungen, Stalking oder Belästigung
• Werbung, Spam oder kommerzielle Angebote
• Inhalte, die Minderjährige betreffen

⚠️ KONSEQUENZEN
Verstöße führen je nach Schwere zu:
1. Verwarnung
2. Temporäre Sperre (1–30 Tage)
3. Permanente Sperrung und Meldung an Behörden

🙋 MELDEN
Nutze den "Melden"-Button auf jedem Profil. Meldungen sind anonym und werden von unserem Team innerhalb von 24 Stunden bearbeitet.

Danke, dass du CampMeet sicher und freundlich hältst! 💜
''';
}
