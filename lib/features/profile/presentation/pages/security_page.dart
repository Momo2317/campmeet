import 'package:flutter/material.dart';
import 'package:camp_meet/core/theme/app_theme.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  bool _twoFactorEnabled = false;
  bool _profileVisible = true;
  bool _showOnlyUni = false;
  bool _hideExactLocation = true;

  final List<Map<String, String>> _blockedUsers = [
    {'name': 'Lars M.', 'uni': 'FU Berlin'},
    {'name': 'Nina K.', 'uni': 'HU Berlin'},
  ];

  final List<Map<String, String>> _activeSessions = [
    {'device': 'iPhone 14 Pro', 'location': 'Berlin', 'active': 'Jetzt aktiv'},
    {'device': 'MacBook Pro', 'location': 'Berlin', 'active': 'Vor 2 Stunden'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Sicherheit', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.fg),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // --- Account-Schutz ---
          _buildSectionHeader('🔐 Account-Schutz', icon: Icons.lock_outline),
          _buildActionTile(
            icon: Icons.password_outlined,
            iconColor: const Color(0xFF9B30FF),
            title: 'Passwort ändern',
            subtitle: 'Zuletzt geändert vor 30 Tagen',
            onTap: () => _showChangePasswordSheet(context),
          ),
          _buildSwitchTile(
            icon: Icons.verified_user_outlined,
            iconColor: const Color(0xFF9B30FF),
            title: '2-Faktor-Authentifizierung',
            subtitle: _twoFactorEnabled
                ? 'Per SMS aktiv'
                : 'Empfohlen – fügt eine Sicherheitsebene hinzu',
            value: _twoFactorEnabled,
            onChanged: (v) {
              setState(() => _twoFactorEnabled = v);
              if (v) _showTwoFactorSetupSheet(context);
            },
          ),
          _buildActionTile(
            icon: Icons.devices_outlined,
            iconColor: const Color(0xFF8E44AD),
            title: 'Angemeldete Geräte',
            subtitle: '${_activeSessions.length} aktive Sitzungen',
            onTap: () => _showActiveSessionsSheet(context),
          ),
          Divider(color: context.fgA(0.1), height: 32),

          // --- Datenschutz ---
          _buildSectionHeader('👁️ Sichtbarkeit & Datenschutz',
              icon: Icons.privacy_tip_outlined),
          _buildSwitchTile(
            icon: Icons.visibility_outlined,
            iconColor: const Color(0xFF27AE60),
            title: 'Profil sichtbar',
            subtitle: 'Dein Profil in der Entdecken-Ansicht anzeigen',
            value: _profileVisible,
            onChanged: (v) => setState(() => _profileVisible = v),
          ),
          _buildSwitchTile(
            icon: Icons.school_outlined,
            iconColor: const Color(0xFFE67E22),
            title: 'Nur Uni-Nutzer sehen mich',
            subtitle:
                'Nur Studierende deiner Universität können dich entdecken',
            value: _showOnlyUni,
            onChanged: (v) => setState(() => _showOnlyUni = v),
          ),
          _buildSwitchTile(
            icon: Icons.location_off_outlined,
            iconColor: const Color(0xFFE74C3C),
            title: 'Genauen Standort ausblenden',
            subtitle: 'Nur Stadt anzeigen, kein genauer Standort',
            value: _hideExactLocation,
            onChanged: (v) => setState(() => _hideExactLocation = v),
          ),
          Divider(color: context.fgA(0.1), height: 32),

          // --- Blockierte Nutzer ---
          _buildSectionHeader('🚫 Blockierte Nutzer',
              icon: Icons.block_outlined),
          _blockedUsers.isEmpty
              ? _buildEmptyState('Keine blockierten Nutzer')
              : Column(
                  children: _blockedUsers
                      .map((u) => _buildBlockedUserTile(u))
                      .toList(),
                ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.block, size: 16),
              label: Text('Nutzer blockieren', style: TextStyle()),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent, width: 1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Divider(color: context.fgA(0.1), height: 32),

          // --- Konto pausieren / löschen ---
          _buildSectionHeader('⚠️ Konto-Verwaltung',
              icon: Icons.manage_accounts_outlined),
          _buildActionTile(
            icon: Icons.pause_circle_outline,
            iconColor: Colors.orangeAccent,
            title: 'Konto pausieren',
            subtitle: 'Profil temporär deaktivieren (z.B. Prüfungszeit)',
            onTap: () => _showPauseAccountDialog(context),
          ),
          _buildActionTile(
            icon: Icons.delete_forever_outlined,
            iconColor: Colors.redAccent,
            title: 'Konto löschen',
            subtitle: 'Alle Daten dauerhaft löschen',
            onTap: () => _showDeleteAccountDialog(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.purpleAccent,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: context.fg, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
      trailing:
          Icon(Icons.arrow_forward_ios, color: context.fgA(0.24), size: 14),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: TextStyle(
              color: context.fg, fontSize: 15, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF9B30FF),
        activeTrackColor: const Color(0xFF9B30FF).withOpacity(0.3),
      ),
    );
  }

  Widget _buildBlockedUserTile(Map<String, String> user) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: context.fgA(0.12),
        child: Text(user['name']![0], style: TextStyle(color: context.fg)),
      ),
      title: Text(user['name']!,
          style: TextStyle(color: context.fg, fontSize: 15)),
      subtitle: Text(user['uni']!,
          style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
      trailing: TextButton(
        onPressed: () {
          setState(() => _blockedUsers.remove(user));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${user['name']} entsperrt', style: TextStyle()),
              backgroundColor: const Color(0xFF27AE60),
            ),
          );
        },
        child: Text('Entsperren',
            style: TextStyle(color: Colors.purpleAccent, fontSize: 13)),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(message,
          style: TextStyle(color: context.fgA(0.38), fontSize: 14)),
    );
  }

  // ================= BOTTOM SHEETS & DIALOGS =================

  void _showChangePasswordSheet(BuildContext context) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool showCurrent = false;
    bool showNew = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
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
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Passwort ändern',
                  style: TextStyle(
                      color: context.fg,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildPasswordField(
                  'Aktuelles Passwort',
                  currentCtrl,
                  showCurrent,
                  () => setSheetState(() => showCurrent = !showCurrent)),
              const SizedBox(height: 12),
              _buildPasswordField('Neues Passwort', newCtrl, showNew,
                  () => setSheetState(() => showNew = !showNew)),
              const SizedBox(height: 12),
              _buildPasswordField(
                  'Neues Passwort wiederholen', confirmCtrl, showNew, () {}),
              const SizedBox(height: 8),
              Text(
                '• Mindestens 8 Zeichen  • Groß- und Kleinbuchstaben  • Mindestens 1 Zahl',
                style: TextStyle(color: context.fgA(0.38), fontSize: 11),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Passwort erfolgreich geändert',
                              style: TextStyle()),
                          backgroundColor: const Color(0xFF27AE60)),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF9B30FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text('Passwort speichern',
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

  Widget _buildPasswordField(String label, TextEditingController ctrl,
      bool show, VoidCallback onToggle) {
    return TextField(
      controller: ctrl,
      obscureText: !show,
      style: TextStyle(color: context.fg),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.fgA(0.54)),
        filled: true,
        fillColor: context.fgA(0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        suffixIcon: IconButton(
          icon: Icon(
              show ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              color: context.fgA(0.38),
              size: 20),
          onPressed: onToggle,
        ),
      ),
    );
  }

  void _showTwoFactorSetupSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: context.fgA(0.24),
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.verified_user, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            Text('2-Faktor-Authentifizierung',
                style: TextStyle(
                    color: context.fg,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Schütze deinen Account mit einem zusätzlichen Bestätigungsschritt.',
              style: TextStyle(color: context.fgA(0.54), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildOptionTile(ctx, Icons.sms_outlined, 'Per SMS',
                'Code wird an deine Handynummer gesendet'),
            const SizedBox(height: 8),
            _buildOptionTile(ctx, Icons.qr_code_outlined, 'Authenticator App',
                'Google Authenticator, Authy, etc.'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(
      BuildContext ctx, IconData icon, String title, String subtitle) {
    return ListTile(
      onTap: () => Navigator.pop(ctx),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.fgA(0.1)),
      ),
      leading: Icon(icon, color: Colors.purpleAccent),
      title: Text(title,
          style: TextStyle(color: context.fg, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle,
          style: TextStyle(color: context.fgA(0.38), fontSize: 12)),
      trailing:
          Icon(Icons.arrow_forward_ios, color: context.fgA(0.24), size: 14),
    );
  }

  void _showActiveSessionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(builder: (ctx, setSheetState) {
        return Padding(
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
              Text('Angemeldete Geräte',
                  style: TextStyle(
                      color: context.fg,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ..._activeSessions.map((s) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: context.fgA(0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Icon(
                        s['device']!.contains('iPhone')
                            ? Icons.phone_iphone
                            : Icons.laptop_mac,
                        color: context.fgA(0.7),
                      ),
                    ),
                    title: Text(s['device']!,
                        style: TextStyle(
                            color: context.fg, fontWeight: FontWeight.w500)),
                    subtitle: Text('${s['location']} • ${s['active']}',
                        style:
                            TextStyle(color: context.fgA(0.38), fontSize: 12)),
                    trailing: s['active'] == 'Jetzt aktiv'
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: const Color(0xFF27AE60).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                            child: Text('Aktiv',
                                style: TextStyle(
                                    color: const Color(0xFF27AE60),
                                    fontSize: 11)),
                          )
                        : TextButton(
                            onPressed: () {
                              setSheetState(() => _activeSessions.remove(s));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Gerät abgemeldet',
                                        style: TextStyle()),
                                    backgroundColor: Colors.orangeAccent),
                              );
                            },
                            child: Text('Abmelden',
                                style: TextStyle(
                                    color: Colors.redAccent, fontSize: 13)),
                          ),
                  )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Alle anderen Geräte abgemeldet',
                              style: TextStyle()),
                          backgroundColor: Colors.orangeAccent),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                      Text('Alle anderen Geräte abmelden', style: TextStyle()),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      }),
    );
  }

  void _showPauseAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Konto pausieren?',
            style: TextStyle(color: context.fg, fontWeight: FontWeight.bold)),
        content: Text(
          'Dein Profil wird temporär ausgeblendet. Deine Matches und Nachrichten bleiben erhalten. Du kannst es jederzeit wieder aktivieren.',
          style: TextStyle(color: context.fgA(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Abbrechen', style: TextStyle(color: context.fgA(0.54))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Konto pausiert', style: TextStyle()),
                    backgroundColor: Colors.orangeAccent),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Pausieren', style: TextStyle(color: context.fg)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Konto löschen?',
                style:
                    TextStyle(color: context.fg, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Diese Aktion ist unwiderruflich. Alle deine Daten, Matches und Nachrichten werden dauerhaft gelöscht.',
          style: TextStyle(color: context.fgA(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Abbrechen', style: TextStyle(color: context.fgA(0.54))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Löschen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
