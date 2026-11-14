import 'package:camp_meet/core/theme/app_theme.dart';
import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camp_meet/features/admin/data/admin_models.dart';
import 'package:camp_meet/core/services/ad_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/core/services/maintenance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_meet/core/services/notification_simulator.dart';

class AdminDashboardPage extends ConsumerStatefulWidget {
  const AdminDashboardPage({super.key});
  @override
  ConsumerState<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends ConsumerState<AdminDashboardPage> {
  int _selectedSection = 0;
  List<AdminUser> _users = List.from(mockAdminUsers);
  List<UserReport> _reports = List.from(mockReports);
  List<StaffMember> _staff = List.from(mockStaff);
  final _notificationController = TextEditingController();
  final _userSearchController = TextEditingController();
  String _userFilter = 'all';
  String _userSort = 'name';
  String _userSearchQuery = '';

  static const _sections = [
    'Overview',
    'Users',
    'Moderation',
    'Analytics',
    'Notifications',
    'Team',
    'Werbung',
    'Settings'
  ];
  static const _sectionIcons = [
    Icons.dashboard_rounded,
    Icons.people_rounded,
    Icons.shield_rounded,
    Icons.bar_chart_rounded,
    Icons.send_rounded,
    Icons.admin_panel_settings,
    Icons.campaign_rounded,
    Icons.settings_rounded,
  ];

  @override
  void dispose() {
    _notificationController.dispose();
    _userSearchController.dispose();
    super.dispose();
  }

  void _showChatInsight(AdminUser user) {
    final messages = mockUserMessages[user.id] ?? [];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          children: [
            Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            Row(
              children: [
                CircleAvatar(
                    backgroundImage: NetworkImage(user.avatarUrl), radius: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat-Protokoll: ${user.name}',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Text(
                          'Moderations-Einsicht · ${messages.length} Nachrichten',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            if (messages.isEmpty)
              Expanded(
                  child: Center(
                      child: Text('Keine Nachrichten gefunden.',
                          style: TextStyle(color: Colors.white24))))
            else
              Expanded(
                child: ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final m = messages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: m.isMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          if (!m.isMe)
                            Padding(
                              padding:
                                  const EdgeInsets.only(left: 4, bottom: 4),
                              child: Text(m.senderName,
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 10)),
                            ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: m.isMe
                                  ? const Color(0xFF9B30FF)
                                  : Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: m.isMe
                                    ? const Radius.circular(0)
                                    : const Radius.circular(16),
                                bottomLeft: m.isMe
                                    ? const Radius.circular(16)
                                    : const Radius.circular(0),
                              ),
                            ),
                            child: Text(m.text,
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14)),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                top: 4, right: 4, left: 4),
                            child: Text(
                                '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                    color: Colors.white24, fontSize: 9)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.redAccent.withOpacity(0.2))),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.redAccent, size: 16),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          'Diese Einsicht wird protokolliert. Missbrauch führt zum Entzug der Admin-Rechte.',
                          style: TextStyle(
                              color: Colors.redAccent, fontSize: 11))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSystemLogs() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
                child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System-Logs',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    Text('Ereignisse der letzten 48 Stunden',
                        style: TextStyle(color: Colors.white38, fontSize: 13)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: mockSystemLogs.length,
                itemBuilder: (ctx, i) {
                  final log = mockSystemLogs[i];
                  Color typeColor = Colors.blueAccent;
                  IconData typeIcon = Icons.info_outline;

                  if (log.type == 'success') {
                    typeColor = Colors.greenAccent;
                    typeIcon = Icons.check_circle_outline;
                  } else if (log.type == 'warning') {
                    typeColor = Colors.orangeAccent;
                    typeIcon = Icons.warning_amber_rounded;
                  } else if (log.type == 'error') {
                    typeColor = Colors.redAccent;
                    typeIcon = Icons.error_outline;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: typeColor.withOpacity(0.1)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: typeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(typeIcon, color: typeColor, size: 20),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(log.action,
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
                                  Text(
                                      '${log.timestamp.hour}:${log.timestamp.minute.toString().padLeft(2, '0')} Uhr',
                                      style: TextStyle(
                                          color: Colors.white24, fontSize: 11)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(log.detail,
                                  style: TextStyle(
                                      color: Colors.white60, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                  '${log.timestamp.day}.${log.timestamp.month}.${log.timestamp.year}',
                                  style: TextStyle(
                                      color: Colors.white12, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  AdminUser _updateUser(AdminUser u,
      {bool? isVerified, bool? isBanned, bool? isPlatinum}) {
    return AdminUser(
      id: u.id,
      name: u.name,
      email: u.email,
      university: u.university,
      avatarUrl: u.avatarUrl,
      isFlagged: u.isFlagged,
      joinedAt: u.joinedAt,
      matchCount: u.matchCount,
      reportCount: u.reportCount,
      isVerified: isVerified ?? u.isVerified,
      isBanned: isBanned ?? u.isBanned,
      isPlatinum: isPlatinum ?? u.isPlatinum,
      status: (isBanned ?? u.isBanned) ? 'banned' : 'active',
      gender: u.gender,
    );
  }

  void _showUserDetail(AdminUser user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final idx = _users.indexWhere((u) => u.id == user.id);
          final u = idx >= 0 ? _users[idx] : user;
          return Container(
            height: MediaQuery.of(context).size.height * 0.70,
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D20),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Column(
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                // Avatar + Name
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(u.avatarUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.white12,
                          child: const Icon(Icons.person,
                              color: Colors.white54, size: 40))),
                ),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(u.name,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const SizedBox(width: 8),
                  if (u.isVerified)
                    const Icon(Icons.verified,
                        color: Colors.purpleAccent, size: 18),
                  if (u.isPlatinum)
                    const Icon(Icons.diamond,
                        color: Colors.amberAccent, size: 18),
                  if (u.isBanned)
                    const Icon(Icons.block, color: Colors.redAccent, size: 18),
                ]),
                Text(u.email,
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                    '${u.university} · Beigetreten ${u.joinedAt.day}.${u.joinedAt.month}.${u.joinedAt.year}',
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
                const SizedBox(height: 16),
                // Stats row
                Row(children: [
                  _StatChip(
                      label: 'Matches',
                      value: '${u.matchCount}',
                      color: const Color(0xFFE91E63)),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Meldungen',
                      value: '${u.reportCount}',
                      color: Colors.orangeAccent),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Status',
                      value: u.status,
                      color:
                          u.isBanned ? Colors.redAccent : Colors.greenAccent),
                ]),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                // Actions grid
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.8,
                    children: [
                      _ActionButton(
                        icon: u.isVerified
                            ? Icons.verified_outlined
                            : Icons.verified,
                        label: u.isVerified
                            ? 'Verifikation entziehen'
                            : 'Verifizieren',
                        color: Colors.purpleAccent,
                        onTap: () {
                          setState(() {
                            _users[idx] =
                                _updateUser(u, isVerified: !u.isVerified);
                          });
                          setSheet(() {});
                        },
                      ),
                      _ActionButton(
                        icon: u.isBanned ? Icons.lock_open : Icons.block,
                        label: u.isBanned ? 'Entsperren' : 'Sperren',
                        color: Colors.redAccent,
                        onTap: () {
                          setState(() {
                            _users[idx] = _updateUser(u, isBanned: !u.isBanned);
                          });
                          setSheet(() {});
                        },
                      ),
                      _ActionButton(
                        icon: u.isPlatinum
                            ? Icons.diamond_outlined
                            : Icons.diamond,
                        label: u.isPlatinum
                            ? 'Premium entziehen'
                            : 'Premium geben',
                        color: Colors.amberAccent,
                        onTap: () {
                          setState(() {
                            _users[idx] =
                                _updateUser(u, isPlatinum: !u.isPlatinum);
                          });
                          setSheet(() {});
                        },
                      ),
                      _ActionButton(
                        icon: Icons.mail_outline,
                        label: 'Nachricht senden',
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('📨 Nachricht an ${u.name} gesendet!',
                                style: TextStyle()),
                            backgroundColor: Colors.blueAccent,
                          ));
                        },
                      ),
                      _ActionButton(
                        icon: Icons.password,
                        label: 'Passwort reset',
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '🔑 Reset-Mail an ${u.email} gesendet!',
                                style: TextStyle()),
                            backgroundColor: Colors.orangeAccent,
                          ));
                        },
                      ),
                      _ActionButton(
                        icon: Icons.delete_outline,
                        label: 'Konto löschen',
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.pop(ctx);
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: const Color(0xFF0D0D20),
                              title: Text('Konto löschen?',
                                  style: TextStyle(color: Colors.white)),
                              content: Text(
                                  'Das Konto von ${u.name} wird unwiderruflich gelöscht.',
                                  style: TextStyle(color: Colors.white54)),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Abbrechen',
                                        style:
                                            TextStyle(color: Colors.white38))),
                                TextButton(
                                  onPressed: () {
                                    setState(() => _users
                                        .removeWhere((x) => x.id == u.id));
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      content: Text('🗑️ ${u.name} gelöscht.',
                                          style: TextStyle()),
                                      backgroundColor: Colors.redAccent,
                                    ));
                                  },
                                  child: Text('Löschen',
                                      style: TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(builder: (context) => _buildDark(context)),
    );
  }

  Widget _buildDark(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04040A),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF070712),
        border:
            Border(right: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            // Logo
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [
                  Color(0xFFFF2D9B),
                  Color(0xFF9B30FF),
                  Color(0xFF5B2BF0)
                ]),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(height: 20),
            ...List.generate(
                _sections.length,
                (i) => _SidebarItem(
                      icon: _sectionIcons[i],
                      label: _sections[i],
                      isSelected: _selectedSection == i,
                      badge: i == 2
                          ? _reports.where((r) => r.status == 'pending').length
                          : 0,
                      onTap: () => setState(() => _selectedSection = i),
                    )),
            const Spacer(),
            _SidebarItem(
              icon: Icons.logout_rounded,
              label: 'Logout',
              isSelected: false,
              badge: 0,
              onTap: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Content Router ────────────────────────────────────────────────────────
  Widget _buildContent() {
    switch (_selectedSection) {
      case 0:
        return _buildOverview();
      case 1:
        return _buildUserManagement();
      case 2:
        return _buildModeration();
      case 3:
        return _buildAnalytics();
      case 4:
        return _buildNotifications();
      case 5:
        return _buildTeamManagement();
      case 6:
        return _buildAdManagement();
      case 7:
        return _buildSettings();
      default:
        return _buildOverview();
    }
  }

  // ── Overview ──────────────────────────────────────────────────────────────
  Widget _buildOverview() {
    final s = mockStats;
    return _PageShell(
      title: 'Dashboard Overview',
      subtitle: 'Willkommen zurück, Admin 👋',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI Row
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.55,
              children: [
                _KpiCard(
                    label: 'Gesamt Nutzer',
                    value: '${s.totalUsers}',
                    icon: Icons.people,
                    color: const Color(0xFF9B30FF),
                    trend: '+12%'),
                _KpiCard(
                    label: 'Heute Aktiv',
                    value: '${s.activeToday}',
                    icon: Icons.online_prediction,
                    color: const Color(0xFF00C853),
                    trend: '+8%'),
                _KpiCard(
                    label: 'Matches Heute',
                    value: '${s.matchesToday}',
                    icon: Icons.favorite,
                    color: const Color(0xFFE91E63),
                    trend: '+23%'),
                _KpiCard(
                    label: 'Nachrichten Heute',
                    value: '${s.messagesToday}',
                    icon: Icons.message,
                    color: const Color(0xFF2196F3),
                    trend: '+5%'),
                _KpiCard(
                    label: 'Umsatz Heute',
                    value: '${s.revenueToday.toStringAsFixed(0)} €',
                    icon: Icons.euro,
                    color: const Color(0xFFFF9800),
                    trend: '+31%'),
                _KpiCard(
                    label: 'Monats-Umsatz',
                    value: '${s.revenueMonth.toStringAsFixed(0)} €',
                    icon: Icons.trending_up,
                    color: const Color(0xFF00BCD4),
                    trend: '+18%'),
                _KpiCard(
                    label: 'Premium Nutzer',
                    value: '${s.premiumUsers}',
                    icon: Icons.diamond,
                    color: const Color(0xFF9C27B0),
                    trend: '+4%'),
                _KpiCard(
                    label: 'Offene Meldungen',
                    value: '${s.pendingReports}',
                    icon: Icons.flag,
                    color: const Color(0xFFF44336),
                    trend: '-2'),
              ],
            ),
            const SizedBox(height: 10),
            // Revenue summary row
            Row(children: [
              // Gesamter Umsatz
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A4A2E), Color(0xFF0D2D1B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.greenAccent.withOpacity(0.25)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.account_balance_wallet,
                              color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                              child: Text('Gesamter Umsatz',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text('${s.revenueTotal.toStringAsFixed(0)} €',
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text('+22% ges.',
                            style: TextStyle(
                                color: Colors.greenAccent.withOpacity(0.6),
                                fontSize: 9)),
                      ]),
                ),
              ),
              const SizedBox(width: 10),
              // Wochenumsatz
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A3A4A), Color(0xFF0D1F2D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border:
                        Border.all(color: Colors.cyanAccent.withOpacity(0.25)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.calendar_view_week,
                              color: Colors.cyanAccent, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                              child: Text('Wochenumsatz',
                                  style: TextStyle(
                                      color: Colors.white54, fontSize: 10),
                                  overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                              '${s.weeklyRevenue.fold(0.0, (a, b) => a + b).toStringAsFixed(0)} €',
                              style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ),
                        Text('+15% vs. Vorwoche',
                            style: TextStyle(
                                color: Colors.cyanAccent.withOpacity(0.6),
                                fontSize: 9)),
                      ]),
                ),
              ),
            ]),
            const SizedBox(height: 24),
            // Mini chart
            _SectionHeader(title: 'Matches dieser Woche'),
            const SizedBox(height: 12),
            _BarChartWidget(
                data: s.weeklyMatches, color: const Color(0xFFE91E63)),
            const SizedBox(height: 24),
            // Weekly revenue chart
            _SectionHeader(title: 'Umsatz diese Woche'),
            const SizedBox(height: 12),
            _RevenueBarChartWidget(data: s.weeklyRevenue),
            const SizedBox(height: 24),
            // University breakdown
            _SectionHeader(title: 'Nutzer nach Universität'),
            const SizedBox(height: 12),
            ...s.universityBreakdown.entries.map((e) => _UniBar(
                  label: e.key,
                  count: e.value,
                  total: s.totalUsers,
                )),
          ],
        ),
      ),
    );
  }

  // ── User Management ───────────────────────────────────────────────────────
  Widget _buildUserManagement() {
    var filtered = _users.where((u) {
      final q = _userSearchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.university.toLowerCase().contains(q);
      if (!matchesSearch) return false;
      if (_userFilter == 'verified') return u.isVerified;
      if (_userFilter == 'banned') return u.isBanned;
      if (_userFilter == 'flagged') return u.isFlagged;
      if (_userFilter == 'premium') return u.isPlatinum;
      if (_userFilter == 'male') return u.gender == 'male';
      if (_userFilter == 'female') return u.gender == 'female';
      return true;
    }).toList();

    filtered.sort((a, b) {
      switch (_userSort) {
        case 'matches':
          return b.matchCount.compareTo(a.matchCount);
        case 'reports':
          return b.reportCount.compareTo(a.reportCount);
        case 'date':
          return b.joinedAt.compareTo(a.joinedAt);
        default:
          return a.name.compareTo(b.name);
      }
    });

    return _PageShell(
      title: 'User Management',
      subtitle: '${filtered.length} von ${_users.length} Nutzern',
      child: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(children: [
                const Icon(Icons.search, color: Colors.white38, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _userSearchController,
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    onChanged: (v) =>
                        setState(() => _userSearchQuery = v.trim()),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Name, E-Mail, Uni suchen...',
                      hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                if (_userSearchQuery.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _userSearchController.clear();
                      setState(() => _userSearchQuery = '');
                    },
                    child: const Icon(Icons.close,
                        color: Colors.white24, size: 16),
                  ),
              ]),
            ),
          ),
          const SizedBox(height: 8),
          // Filter + Sort row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in [
                          ('all', 'Alle'),
                          ('male', 'Männer'),
                          ('female', 'Frauen'),
                          ('verified', '✓ Verifiziert'),
                          ('banned', '⛔ Gesperrt'),
                          ('flagged', '🚩 Gemeldet'),
                          ('premium', '💎 Premium')
                        ])
                          GestureDetector(
                            onTap: () => setState(() => _userFilter = f.$1),
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _userFilter == f.$1
                                    ? const Color(0xFF9B30FF)
                                    : Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(f.$2,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Sort dropdown
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    backgroundColor: const Color(0xFF0D0D20),
                    builder: (_) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 12),
                        Text('Sortieren nach',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 13)),
                        const SizedBox(height: 8),
                        for (final s in [
                          ('name', 'Name A–Z'),
                          ('matches', 'Meiste Matches'),
                          ('reports', 'Meiste Meldungen'),
                          ('date', 'Neueste zuerst')
                        ])
                          ListTile(
                            leading: Icon(
                                _userSort == s.$1
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: _userSort == s.$1
                                    ? const Color(0xFF9B30FF)
                                    : Colors.white38),
                            title: Text(s.$2,
                                style: TextStyle(color: Colors.white)),
                            onTap: () {
                              setState(() => _userSort = s.$1);
                              Navigator.pop(context);
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child:
                        const Icon(Icons.sort, color: Colors.white54, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Results count
          if (_userSearchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                  '${filtered.length} Ergebnis${filtered.length == 1 ? '' : 'se'}',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ),
          const SizedBox(height: 4),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.search_off,
                        color: Colors.white12, size: 48),
                    const SizedBox(height: 12),
                    Text('Keine Nutzer gefunden',
                        style: TextStyle(color: Colors.white24)),
                  ]))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) => _UserTile(
                      user: filtered[i],
                      onTap: () => _showUserDetail(filtered[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Moderation ─────────────────────────────────────────────────────────────
  Widget _buildModeration() {
    final pending = _reports.where((r) => r.status == 'pending').toList();
    final resolved = _reports.where((r) => r.status != 'pending').toList();
    return _PageShell(
      title: 'Moderation Queue',
      subtitle: '${pending.length} ausstehend',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (pending.isNotEmpty) ...[
            _SectionHeader(title: '🚨 Ausstehend (${pending.length})'),
            const SizedBox(height: 8),
            ...pending.map((r) => _ReportTile(
                  report: r,
                  onResolve: () => setState(() {
                    final idx = _reports.indexWhere((x) => x.id == r.id);
                    _reports[idx] = UserReport(
                      id: r.id,
                      reporterName: r.reporterName,
                      reportedName: r.reportedName,
                      reportedAvatarUrl: r.reportedAvatarUrl,
                      reason: r.reason,
                      reportedAt: r.reportedAt,
                      status: 'resolved',
                    );
                  }),
                  onDismiss: () => setState(() {
                    final idx = _reports.indexWhere((x) => x.id == r.id);
                    _reports[idx] = UserReport(
                      id: r.id,
                      reporterName: r.reporterName,
                      reportedName: r.reportedName,
                      reportedAvatarUrl: r.reportedAvatarUrl,
                      reason: r.reason,
                      reportedAt: r.reportedAt,
                      status: 'dismissed',
                    );
                  }),
                )),
            const SizedBox(height: 20),
          ],
          _SectionHeader(title: '✅ Erledigt (${resolved.length})'),
          const SizedBox(height: 8),
          ...resolved.map(
              (r) => _ReportTile(report: r, onResolve: null, onDismiss: null)),
        ],
      ),
    );
  }

  // ── Analytics ─────────────────────────────────────────────────────────────
  Widget _buildAnalytics() {
    return _PageShell(
      title: 'Analytics',
      subtitle: 'Wachstum & Trends',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SectionHeader(title: 'Neuanmeldungen (7 Tage)'),
          const SizedBox(height: 12),
          _BarChartWidget(
              data: mockStats.weeklySignups, color: const Color(0xFF9B30FF)),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Matches (7 Tage)'),
          const SizedBox(height: 12),
          _BarChartWidget(
              data: mockStats.weeklyMatches, color: const Color(0xFFE91E63)),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Umsatz-Übersicht'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _RevenueCard(
                    label: 'Boosts verkauft',
                    value: '${mockStats.boostsPurchased}',
                    icon: Icons.bolt,
                    color: Colors.purpleAccent)),
            const SizedBox(width: 12),
            Expanded(
                child: _RevenueCard(
                    label: 'Premium Abos',
                    value: '${mockStats.premiumUsers}',
                    icon: Icons.diamond,
                    color: Colors.amberAccent)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _RevenueCard(
                    label: 'Heute',
                    value: '${mockStats.revenueToday.toStringAsFixed(2)} €',
                    icon: Icons.today,
                    color: Colors.greenAccent)),
            const SizedBox(width: 12),
            Expanded(
                child: _RevenueCard(
                    label: 'Monat',
                    value: '${mockStats.revenueMonth.toStringAsFixed(2)} €',
                    icon: Icons.calendar_month,
                    color: Colors.blueAccent)),
          ]),
        ],
      ),
    );
  }

  // ── Notifications ─────────────────────────────────────────────────────────
  Widget _buildNotifications() {
    final templates = {
      '🎯 Engagement': [
        '💜 Du hast neue Likes! Jetzt anschauen.',
        '🔥 Jemand hat dein Profil 5× besucht – schau mal rein!',
        '💬 Du hast eine ungelesene Nachricht – antworte jetzt!',
        '👀 Neues Match wartet auf dich. Nicht verpassen!',
        '⭐ Dein Profil wurde heute ${3} Mal geliked.',
      ],
      '🚀 Aktionen & Features': [
        '🎉 Neue Features verfügbar! Schau mal rein.',
        '🆕 CampMeet Update: Uni Radar ist jetzt live!',
        '🧪 Neu: Study Buddy Mode – finde Lernpartner für deine Uni!',
        '📍 Uni Radar zeigt, wer gerade auf dem Campus ist. Probier es aus!',
        '🎊 Wir haben ${1000} neue Nutzer – danke für deine Treue!',
      ],
      '💎 Premium & Boosts': [
        '🚀 Boost dein Profil – jetzt für 5 €!',
        '💎 Nur heute: Silver-Abo 20% günstiger!',
        '⚡ Mit Premium wirst du 3× häufiger gesehen. Jetzt upgraden!',
        '🎁 Exklusiv für Premium-Nutzer: Super Likes ohne Limit!',
        '⌛ Dein Boost läuft ab – jetzt verlängern und sichtbar bleiben!',
      ],
      '📅 Events & Study Sessions': [
        '🎉 Neues Event auf dem Campus – jetzt auf dem Uni Radar entdecken!',
        '📚 Study Session in deiner Nähe – tritt jetzt bei!',
        '🗓️ Events diese Woche: Schau nach, was auf dem Campus los ist!',
        '☕ Lerngruppe gesucht? Erstelle jetzt deine Study Session!',
        '🏛️ Campus heute besonders aktiv – schau auf dem Uni Radar vorbei!',
      ],
      '🔔 System & Info': [
        '🔐 Sicherheitshinweis: Bitte aktualisiere dein Passwort.',
        '📋 Neue Nutzungsbedingungen – bitte einmal bestätigen.',
        '⚠️ Kurze Wartung am Sonntag ab 02:00 Uhr – kurze Auszeit.',
        '✅ Dein Profil wurde erfolgreich verifiziert!',
        '🌐 CampMeet ist jetzt an ${3} neuen Universitäten verfügbar!',
      ],
    };

    return _PageShell(
      title: 'Push-Benachrichtigungen',
      subtitle: 'Sende Nachrichten an alle Nutzer',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(title: 'Neue Benachrichtigung'),
            const SizedBox(height: 16),
            _AdminInputField(
                controller: _notificationController,
                hint: 'Nachricht eingeben...',
                maxLines: 4),
            const SizedBox(height: 16),
            _SectionHeader(title: 'Zielgruppe wählen'),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _NotifTargetChip(
                      label: 'Alle Nutzer',
                      icon: Icons.people,
                      color: Colors.blueAccent,
                      onTap: () => _sendNotif('Alle Nutzer'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _NotifTargetChip(
                      label: 'Premium',
                      icon: Icons.diamond,
                      color: Colors.amber,
                      onTap: () => _sendNotif('Premium-Nutzer'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _NotifTargetChip(
                      label: 'Inaktiv',
                      icon: Icons.bedtime,
                      color: Colors.orangeAccent,
                      onTap: () => _sendNotif('Inaktive Nutzer'))),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                  child: _NotifTargetChip(
                      label: 'Frauen',
                      icon: Icons.female,
                      color: Colors.pinkAccent,
                      onTap: () => _sendNotif('Frauen'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _NotifTargetChip(
                      label: 'Männer',
                      icon: Icons.male,
                      color: Colors.lightBlueAccent,
                      onTap: () => _sendNotif('Männer'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _NotifTargetChip(
                      label: 'Neu',
                      icon: Icons.fiber_new,
                      color: Colors.greenAccent,
                      onTap: () => _sendNotif('Neu registrierte Nutzer'))),
            ]),
            const SizedBox(height: 28),
            ...templates.entries.map((category) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: category.key),
                    const SizedBox(height: 10),
                    ...category.value.map((t) => GestureDetector(
                          onTap: () => _notificationController.text = t,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.07)),
                            ),
                            child: Row(children: [
                              Expanded(
                                  child: Text(t,
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13))),
                              const Icon(Icons.north_west,
                                  color: Colors.white24, size: 14),
                            ]),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  void _sendNotif(String target) {
    final msg = _notificationController.text.trim();
    if (msg.isEmpty) return;

    // 📢 Nachricht an den Simulator senden
    ref.read(notificationSimulatorProvider.notifier).notifyUsers(msg, target);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('📣 Push an $target gesendet!', style: TextStyle()),
      backgroundColor: const Color(0xFF9B30FF),
    ));
    _notificationController.clear();
  }

  // ── Team Management ────────────────────────────────────────────────────────
  Widget _buildTeamManagement() {
    return _PageShell(
      title: 'Team & Rechte',
      subtitle: 'Verwalte Admins und Moderatoren',
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _staff.length,
            itemBuilder: (context, index) {
              final s = _staff[index];
              final color = s.role == 'Super Admin'
                  ? Colors.purpleAccent
                  : (s.role == 'Admin'
                      ? Colors.blueAccent
                      : Colors.orangeAccent);
              return Card(
                color: const Color(0xFF0F0B24),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.white.withOpacity(0.05))),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  leading: GestureDetector(
                    onTap: () => _pickStaffAvatar(index, s),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: color.withOpacity(0.2),
                          backgroundImage: s.localAvatarPath != null
                              ? FileImage(File(s.localAvatarPath!))
                                  as ImageProvider
                              : (s.avatarUrl != null && s.avatarUrl!.isNotEmpty
                                  ? NetworkImage(s.avatarUrl!)
                                  : null),
                          child: (s.localAvatarPath == null &&
                                  (s.avatarUrl == null || s.avatarUrl!.isEmpty))
                              ? Icon(
                                  s.role == 'Moderator'
                                      ? Icons.shield
                                      : Icons.admin_panel_settings,
                                  color: color)
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B30FF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF151528), width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt,
                                color: Colors.white, size: 9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  title: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(s.name,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: color.withOpacity(0.3))),
                        child: Text(s.role,
                            style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.bold)),
                      ),
                      if (s.status == 'revoked')
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.redAccent.withOpacity(0.3))),
                          child: Text('Gesperrt',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  subtitle:
                      Text(s.email, style: TextStyle(color: Colors.white54)),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white54),
                    color: const Color(0xFF0D0D25),
                    itemBuilder: (context) => [
                      if (s.status == 'active' && s.role != 'Super Admin')
                        PopupMenuItem(
                            value: 'revoke',
                            child: Text('Rechte entziehen',
                                style: TextStyle(color: Colors.orangeAccent))),
                      if (s.status == 'revoked')
                        PopupMenuItem(
                            value: 'restore',
                            child: Text('Konto reaktivieren',
                                style: TextStyle(color: Colors.green))),
                      if (s.role == 'Moderator' && s.status == 'active')
                        PopupMenuItem(
                            value: 'promote',
                            child: Text('Zum Admin befördern',
                                style: TextStyle(color: Colors.blueAccent))),
                      if (s.role == 'Admin' && s.status == 'active')
                        PopupMenuItem(
                            value: 'demote',
                            child: Text('Zum Moderator herabstufen',
                                style: TextStyle(color: Colors.orangeAccent))),
                      if (s.role != 'Super Admin')
                        PopupMenuItem(
                            value: 'change_avatar',
                            child: Text('Profilbild ändern',
                                style: TextStyle(color: Colors.tealAccent))),
                      if (s.role != 'Super Admin')
                        PopupMenuItem(
                            value: 'change_password',
                            child: Text('Passwort ändern',
                                style: TextStyle(color: Colors.white))),
                      if (s.role != 'Super Admin')
                        PopupMenuItem(
                            value: 'delete',
                            child: Text('Mitarbeiter löschen',
                                style: TextStyle(color: Colors.redAccent))),
                    ],
                    onSelected: (value) {
                      if (value == 'change_password') {
                        _showChangeStaffPasswordDialog(s.name);
                        return;
                      }
                      if (value == 'change_avatar') {
                        _pickStaffAvatar(index, s);
                        return;
                      }

                      setState(() {
                        if (value == 'revoke') {
                          _staff[index] = StaffMember(
                              id: s.id,
                              name: s.name,
                              email: s.email,
                              role: s.role,
                              status: 'revoked',
                              addedAt: s.addedAt,
                              avatarUrl: s.avatarUrl,
                              localAvatarPath: s.localAvatarPath);
                        } else if (value == 'restore') {
                          _staff[index] = StaffMember(
                              id: s.id,
                              name: s.name,
                              email: s.email,
                              role: s.role,
                              status: 'active',
                              addedAt: s.addedAt,
                              avatarUrl: s.avatarUrl,
                              localAvatarPath: s.localAvatarPath);
                        } else if (value == 'promote') {
                          _staff[index] = StaffMember(
                              id: s.id,
                              name: s.name,
                              email: s.email,
                              role: 'Admin',
                              status: s.status,
                              addedAt: s.addedAt,
                              avatarUrl: s.avatarUrl,
                              localAvatarPath: s.localAvatarPath);
                        } else if (value == 'demote') {
                          _staff[index] = StaffMember(
                              id: s.id,
                              name: s.name,
                              email: s.email,
                              role: 'Moderator',
                              status: s.status,
                              addedAt: s.addedAt,
                              avatarUrl: s.avatarUrl,
                              localAvatarPath: s.localAvatarPath);
                        } else if (value == 'delete') {
                          _staff.removeAt(index);
                        }
                      });

                      if (value == 'delete') {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('🗑️ Mitarbeiter ${s.name} entfernt',
                                style: TextStyle()),
                            backgroundColor: Colors.redAccent));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Status aktualisiert: ${s.name}',
                                style: TextStyle()),
                            backgroundColor: Colors.green));
                      }
                    },
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton.extended(
              onPressed: () => _showAddStaffDialog(),
              backgroundColor: const Color(0xFF9B30FF),
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: Text('Mitarbeiter hinzufügen',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final avatarCtrl = TextEditingController();
    String role = 'Moderator';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final insets = MediaQuery.of(context).viewInsets.bottom;
          return Container(
            padding:
                EdgeInsets.fromLTRB(24, 24, 24, insets > 0 ? insets + 24 : 40),
            decoration: const BoxDecoration(
              color: Color(0xFF0A0A1A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text('Neues Teammitglied',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      hintText: 'Name',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      hintText: 'E-Mail',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: avatarCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                      hintText: 'Profilbild URL (optional)',
                      hintStyle: const TextStyle(color: Colors.white38),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 24),
                Text('Rollen-Auswahl:',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => role = 'Admin'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: role == 'Admin'
                                  ? Colors.blueAccent
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                              child: Text('Admin',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setSheetState(() => role = 'Moderator'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                              color: role == 'Moderator'
                                  ? Colors.orangeAccent
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Center(
                              child: Text('Moderator',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold))),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty || emailCtrl.text.isEmpty)
                        return;
                      setState(() {
                        _staff.add(StaffMember(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameCtrl.text,
                          email: emailCtrl.text,
                          role: role,
                          status: 'active',
                          addedAt: DateTime.now(),
                          avatarUrl: avatarCtrl.text.isNotEmpty
                              ? avatarCtrl.text
                              : null,
                        ));
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              '✅ ${nameCtrl.text} als $role hinzugefügt!',
                              style: TextStyle()),
                          backgroundColor: Colors.green));
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B30FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    child: Text('Mitglied hinzufügen',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _pickStaffAvatar(int index, StaffMember s) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Color(0xFF0A0A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            Text('Profilbild für ${s.name}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _AvatarSourceButton(
                    icon: Icons.photo_library,
                    label: 'Galerie',
                    color: Colors.purpleAccent,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.gallery, imageQuality: 80);
                      if (picked != null) {
                        setState(() {
                          _staff[index] = StaffMember(
                            id: s.id,
                            name: s.name,
                            email: s.email,
                            role: s.role,
                            status: s.status,
                            addedAt: s.addedAt,
                            avatarUrl: s.avatarUrl,
                            localAvatarPath: picked.path,
                          );
                        });
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '🖼️ Profilbild von ${s.name} aktualisiert',
                                  style: TextStyle()),
                              backgroundColor: Colors.green));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AvatarSourceButton(
                    icon: Icons.camera_alt,
                    label: 'Kamera',
                    color: Colors.tealAccent,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(
                          source: ImageSource.camera, imageQuality: 80);
                      if (picked != null) {
                        setState(() {
                          _staff[index] = StaffMember(
                            id: s.id,
                            name: s.name,
                            email: s.email,
                            role: s.role,
                            status: s.status,
                            addedAt: s.addedAt,
                            avatarUrl: s.avatarUrl,
                            localAvatarPath: picked.path,
                          );
                        });
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  '🖼️ Profilbild von ${s.name} aktualisiert',
                                  style: TextStyle()),
                              backgroundColor: Colors.green));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (s.localAvatarPath != null ||
                (s.avatarUrl != null && s.avatarUrl!.isNotEmpty))
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _staff[index] = StaffMember(
                      id: s.id,
                      name: s.name,
                      email: s.email,
                      role: s.role,
                      status: s.status,
                      addedAt: s.addedAt,
                    );
                  });
                },
                icon: const Icon(Icons.delete_outline,
                    color: Colors.redAccent, size: 18),
                label: Text('Bild entfernen',
                    style: TextStyle(color: Colors.redAccent)),
              ),
          ],
        ),
      ),
    );
  }

  void _showChangeStaffPasswordDialog(String name) {
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Passwort ändern',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Neues Passwort für $name festlegen:',
                style: TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Neues Passwort',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              if (passCtrl.text.isEmpty) return;
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('🔑 Passwort für $name erfolgreich geändert!',
                    style: TextStyle()),
                backgroundColor: Colors.green,
              ));
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9B30FF),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: Text('Speichern',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangeAdminPasswordDialog() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool obscure = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (context, setSheetState) {
        final insets = MediaQuery.of(context).viewInsets.bottom;
        return Container(
          padding:
              EdgeInsets.fromLTRB(24, 24, 24, insets > 0 ? insets + 24 : 40),
          decoration: const BoxDecoration(
            color: Color(0xFF0A0A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text('Admin Passwort ändern',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  'Sicherheitshinweis: Das Passwort wird lokal auf diesem Gerät gespeichert.',
                  style: TextStyle(color: Colors.white38, fontSize: 13)),
              const SizedBox(height: 24),
              TextField(
                controller: oldPassCtrl,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: _adminInputDecoration(
                    'Aktuelles Passwort',
                    Icons.lock_open,
                    obscure,
                    () => setSheetState(() => obscure = !obscure)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPassCtrl,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: _adminInputDecoration(
                    'Neues Passwort', Icons.lock_outline, null, null),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPassCtrl,
                obscureText: obscure,
                style: const TextStyle(color: Colors.white),
                decoration: _adminInputDecoration('Neues Passwort bestätigen',
                    Icons.lock_outline, null, null),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    final currentStored =
                        prefs.getString('admin_password') ?? 'admin123';

                    if (oldPassCtrl.text != currentStored) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('❌ Aktuelles Passwort ist falsch',
                                style: TextStyle()),
                            backgroundColor: Colors.redAccent));
                      return;
                    }
                    if (newPassCtrl.text.isEmpty ||
                        newPassCtrl.text.length < 4) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                '❌ Passwort muss mindestens 4 Zeichen lang sein',
                                style: TextStyle()),
                            backgroundColor: Colors.redAccent));
                      return;
                    }
                    if (newPassCtrl.text != confirmPassCtrl.text) {
                      if (mounted)
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('❌ Passwörter stimmen nicht überein',
                                style: TextStyle()),
                            backgroundColor: Colors.redAccent));
                      return;
                    }

                    await prefs.setString('admin_password', newPassCtrl.text);
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              '✅ Admin Passwort erfolgreich geändert!',
                              style: TextStyle()),
                          backgroundColor: Colors.green));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9B30FF),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text('Passwort speichern',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  InputDecoration _adminInputDecoration(
      String hint, IconData icon, bool? obscure, VoidCallback? onToggle) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      suffixIcon: onToggle != null
          ? IconButton(
              icon: Icon(obscure! ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white38, size: 20),
              onPressed: onToggle)
          : null,
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // ── Settings ──────────────────────────────────────────────────────────────
  Widget _buildSettings() {
    return _PageShell(
      title: 'Einstellungen',
      subtitle: 'App-Konfiguration',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _SettingsTile(
              icon: Icons.lock_reset,
              title: 'Admin Passwort ändern',
              onTap: () => _showChangeAdminPasswordDialog()),
          _SettingsTile(
              icon: Icons.verified_user,
              title: 'Automatische Verifizierung',
              trailing: Switch(
                  value: true,
                  onChanged: (_) {},
                  activeColor: const Color(0xFF9B30FF))),
          _SettingsTile(
              icon: Icons.school,
              title: 'Erlaubte Uni-Domains verwalten',
              onTap: () {}),
          Consumer(
            builder: (context, ref, child) {
              final isMaintenance = ref.watch(maintenanceProvider);
              return _SettingsTile(
                icon: Icons.shield_moon,
                title: 'Maintenance Mode',
                trailing: Switch(
                  value: isMaintenance,
                  onChanged: (val) =>
                      ref.read(maintenanceProvider.notifier).toggle(val),
                  activeColor: const Color(0xFF9B30FF),
                ),
              );
            },
          ),
          _SettingsTile(
              icon: Icons.data_usage,
              title: 'Datenbank-Backup',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('💾 Backup gestartet!', style: TextStyle()),
                  backgroundColor: Colors.green,
                ));
              }),
          _SettingsTile(
              icon: Icons.bug_report,
              title: 'System-Logs anzeigen',
              onTap: () => _showSystemLogs()),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.greenAccent.withOpacity(0.2)),
            ),
            child: Row(children: [
              Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                      color: Colors.greenAccent, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('System Status: Online',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold)),
                Text('Alle Services laufen normal.',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }

  void _showAdFrequencyDialog() {
    double tempVal = AdService.profilesBetweenAds.toDouble();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Werbung Frequenz',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Zeige Werbung alle ${tempVal.toInt()} Profile',
                  style: TextStyle(color: Colors.white70)),
              Slider(
                value: tempVal,
                min: 1,
                max: 20,
                divisions: 19,
                activeColor: Colors.purpleAccent,
                label: tempVal.toInt().toString(),
                onChanged: (val) {
                  setDialogState(() => tempVal = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Abbrechen', style: TextStyle(color: Colors.white38)),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt('ads_frequency', tempVal.toInt());
                setState(() {
                  AdService.profilesBetweenAds = tempVal.toInt();
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        '✅ Frequenz auf ${tempVal.toInt()} aktualisiert',
                        style: TextStyle()),
                    backgroundColor: Colors.green,
                  ));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9B30FF),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text('Speichern',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  // ── Ad Management ──────────────────────────────────────────────────────────
  Widget _buildAdManagement() {
    return _PageShell(
      title: 'Werbe-Management',
      subtitle: 'Native Ads im Swipe-Deck steuern',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.blueAccent, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tinder-Style Ads',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(
                        'Werbung wird als native Profil-Karten direkt im Discovery-Feed angezeigt. '
                        'Premium-Nutzer sehen diese Karten grundsätzlich nicht.',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Switch Row
          _SectionHeader(title: 'Allgemeine Einstellungen'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Werbung aktivieren',
                      style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      'Schaltet Werbekarten im Swipe-Deck global ein/aus.',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  value: AdService.isAdsEnabled,
                  activeColor: Colors.purpleAccent,
                  inactiveTrackColor: Colors.white10,
                  onChanged: (val) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('ads_enabled', val);
                    setState(() {
                      AdService.isAdsEnabled = val;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(
                            val
                                ? '✅ Werbung aktiviert'
                                : '🚫 Werbung deaktiviert',
                            style: TextStyle()),
                        backgroundColor:
                            val ? Colors.greenAccent : Colors.redAccent,
                      ));
                    }
                  },
                ),
                const Divider(color: Colors.white10, height: 24),
                // Interactive setting for frequency
                ListTile(
                  title:
                      Text('Frequenz', style: TextStyle(color: Colors.white)),
                  subtitle: Text(
                      'Alle ${AdService.profilesBetweenAds} Profile eine Werbung anzeigen.',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                  trailing:
                      const Icon(Icons.edit, color: Colors.white54, size: 18),
                  onTap: () => _showAdFrequencyDialog(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Preview section
          _SectionHeader(title: 'Werbe-Partner (Vorschau)'),
          const SizedBox(height: 12),
          Text(
            'Diese Partner werden als Karten angezeigt:',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // Simple list of mock partners
          _buildPartnerTile('StudySmarter',
              'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=400'),
          _buildPartnerTile('Spotify Premium',
              'https://images.unsplash.com/photo-1611339555312-e607c8352fd7?w=400'),
          _buildPartnerTile('Lieferando',
              'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400'),
        ],
      ),
    );
  }

  Widget _buildPartnerTile(String name, String img) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(img, width: 40, height: 40, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Text(name,
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Colors.white24),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _PageShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _PageShell(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(subtitle,
                  style: TextStyle(fontSize: 13, color: Colors.white38)),
            ]),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;
  const _SidebarItem(
      {required this.icon,
      required this.label,
      required this.isSelected,
      required this.badge,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF9B30FF).withOpacity(0.25)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(color: const Color(0xFF9B30FF).withOpacity(0.5))
                  : null,
            ),
            child: Icon(icon,
                color: isSelected ? Colors.white : Colors.white38, size: 22),
          ),
          if (badge > 0)
            Positioned(
              top: 4,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                    color: Colors.redAccent, shape: BoxShape.circle),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, trend;
  final IconData icon;
  final Color color;
  const _KpiCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color,
      required this.trend});

  @override
  Widget build(BuildContext context) {
    final isPositive = trend.startsWith('+');
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: (isPositive ? Colors.greenAccent : Colors.redAccent)
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(trend,
                  style: TextStyle(
                      color: isPositive ? Colors.greenAccent : Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
            ),
          ]),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(fontSize: 10, color: Colors.white38),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white70));
  }
}

class _BarChartWidget extends StatelessWidget {
  final List<double> data;
  final Color color;
  const _BarChartWidget({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final maxVal = data.reduce(max);
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(data.length, (i) {
          final h = (data[i] / maxVal) * 80;
          return Expanded(
            child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(
                height: h,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(days[i],
                  style: TextStyle(color: Colors.white30, fontSize: 10)),
            ]),
          );
        }),
      ),
    );
  }
}

class _RevenueBarChartWidget extends StatelessWidget {
  final List<double> data;
  const _RevenueBarChartWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    const days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final maxVal = data.reduce(max);
    final total = data.fold(0.0, (a, b) => a + b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 160,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.12)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(data.length, (i) {
              final h = (data[i] / maxVal) * 90;
              final isMax = data[i] == maxVal;
              return Expanded(
                child:
                    Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(
                    '${data[i].toInt()}€',
                    style: TextStyle(
                      color: isMax ? Colors.greenAccent : Colors.white38,
                      fontSize: 8,
                      fontWeight: isMax ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: h,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.greenAccent.withOpacity(0.4),
                          Colors.greenAccent.withOpacity(0.85)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isMax
                          ? [
                              BoxShadow(
                                  color: Colors.greenAccent.withOpacity(0.3),
                                  blurRadius: 8)
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(days[i],
                      style: TextStyle(color: Colors.white30, fontSize: 10)),
                ]),
              );
            }),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          _SmallStatBadge(
              label: 'Gesamt Woche',
              value: '${total.toStringAsFixed(0)} €',
              color: Colors.greenAccent),
          const SizedBox(width: 10),
          _SmallStatBadge(
              label: 'Bester Tag',
              value: '${maxVal.toStringAsFixed(0)} €',
              color: Colors.amberAccent),
          const SizedBox(width: 10),
          _SmallStatBadge(
              label: 'Ø pro Tag',
              value: '${(total / data.length).toStringAsFixed(0)} €',
              color: Colors.blueAccent),
        ]),
      ],
    );
  }
}

class _SmallStatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _SmallStatBadge(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _UniBar extends StatelessWidget {
  final String label;
  final int count, total;
  const _UniBar(
      {required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final pct = count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: TextStyle(color: Colors.white54, fontSize: 12))),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.06),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF9B30FF)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('$count', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }
}

class _UserTile extends StatelessWidget {
  final AdminUser user;
  final VoidCallback onTap;
  const _UserTile({required this.user, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: user.isBanned
              ? Colors.redAccent.withOpacity(0.08)
              : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: user.isFlagged
                  ? Colors.orangeAccent.withOpacity(0.4)
                  : Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(user.avatarUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    width: 48,
                    height: 48,
                    color: Colors.white12,
                    child: const Icon(Icons.person, color: Colors.white54))),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Text(user.name,
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(width: 6),
                  if (user.isVerified)
                    const Icon(Icons.verified,
                        color: Colors.purpleAccent, size: 14),
                  if (user.isPlatinum)
                    const Icon(Icons.diamond,
                        color: Colors.amberAccent, size: 14),
                  if (user.isBanned)
                    const Icon(Icons.block, color: Colors.redAccent, size: 14),
                  if (user.isFlagged)
                    const Icon(Icons.flag,
                        color: Colors.orangeAccent, size: 14),
                ]),
                Text(user.email,
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
                Text('${user.university} · ${user.matchCount} Matches',
                    style: TextStyle(color: Colors.white24, fontSize: 11)),
              ])),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Colors.white12, size: 16),
        ]),
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  final UserReport report;
  final VoidCallback? onResolve, onDismiss;
  const _ReportTile(
      {required this.report, required this.onResolve, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isPending = report.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending
            ? Colors.redAccent.withOpacity(0.07)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPending
                ? Colors.redAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.07)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(report.reportedAvatarUrl,
                width: 38,
                height: 38,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 38, height: 38, color: Colors.white12)),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('${report.reportedName} gemeldet',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                Text('von ${report.reporterName}',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isPending
                  ? Colors.redAccent.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
                isPending
                    ? 'Ausstehend'
                    : report.status == 'resolved'
                        ? 'Gelöst'
                        : 'Abgelehnt',
                style: TextStyle(
                    color: isPending ? Colors.redAccent : Colors.greenAccent,
                    fontSize: 11)),
          ),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8)),
          child: Text('Grund: ${report.reason}',
              style: TextStyle(color: Colors.white60, fontSize: 12)),
        ),
        if (isPending && onResolve != null) ...[
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: GestureDetector(
              onTap: onResolve,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text('✅ Lösen',
                        style: TextStyle(
                            color: Colors.greenAccent, fontSize: 13))),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10)),
                child: Center(
                    child: Text('❌ Ablehnen',
                        style: TextStyle(color: Colors.white54, fontSize: 13))),
              ),
            )),
          ]),
        ],
      ]),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _RevenueCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value,
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: Colors.white38, fontSize: 12)),
      ]),
    );
  }
}

class _AdminInputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _AdminInputField(
      {required this.controller, required this.hint, this.maxLines = 1});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white30),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}

class _NotifTargetChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _NotifTargetChip(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 11),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  const _SettingsTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(children: [
          Icon(icon, color: Colors.white54, size: 20),
          const SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: TextStyle(color: Colors.white, fontSize: 14)),
                if (subtitle != null)
                  Text(subtitle!,
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
              ])),
          trailing ??
              (onTap != null
                  ? const Icon(Icons.chevron_right, color: Colors.white24)
                  : const SizedBox()),
        ]),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
          Text(label, style: TextStyle(color: Colors.white38, fontSize: 10)),
        ]),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: color, fontSize: 11),
                  overflow: TextOverflow.ellipsis)),
        ]),
      ),
    );
  }
}

class _AvatarSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AvatarSourceButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }
}
