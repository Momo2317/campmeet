import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Admin User Model
// ─────────────────────────────────────────────────────────────────────────────
class AdminUser {
  final String id;
  final String name;
  final String email;
  final String university;
  final String avatarUrl;
  final bool isVerified;
  final bool isBanned;
  final bool isFlagged;
  final bool isPlatinum;
  final DateTime joinedAt;
  final int matchCount;
  final int reportCount;
  final String status; // 'active', 'inactive', 'banned'
  final String gender; // 'male', 'female'

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    required this.university,
    required this.avatarUrl,
    required this.isVerified,
    required this.isBanned,
    required this.isFlagged,
    this.isPlatinum = false,
    required this.joinedAt,
    required this.matchCount,
    required this.reportCount,
    required this.status,
    required this.gender,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Report Model
// ─────────────────────────────────────────────────────────────────────────────
class UserReport {
  final String id;
  final String reporterName;
  final String reportedName;
  final String reportedAvatarUrl;
  final String reason;
  final DateTime reportedAt;
  final String status; // 'pending', 'resolved', 'dismissed'

  UserReport({
    required this.id,
    required this.reporterName,
    required this.reportedName,
    required this.reportedAvatarUrl,
    required this.reason,
    required this.reportedAt,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock Data
// ─────────────────────────────────────────────────────────────────────────────
final List<AdminUser> mockAdminUsers = [
  AdminUser(
    id: 'u1',
    name: 'Chloe Evans',
    email: 'chloe@stanford.edu',
    university: 'Stanford University',
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
    isVerified: true,
    isBanned: false,
    isFlagged: false,
    isPlatinum: true,
    joinedAt: DateTime(2024, 9, 15),
    matchCount: 23,
    reportCount: 0,
    status: 'active',
    gender: 'female',
  ),
  AdminUser(
    id: 'u2',
    name: 'James Wilson',
    email: 'james@stanford.edu',
    university: 'Stanford University',
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    isVerified: true,
    isBanned: false,
    isFlagged: false,
    isPlatinum: false,
    joinedAt: DateTime(2024, 10, 3),
    matchCount: 15,
    reportCount: 0,
    status: 'active',
    gender: 'male',
  ),
  AdminUser(
    id: 'u3',
    name: 'Sophia Chen',
    email: 'sophia@stanford.edu',
    university: 'Stanford University',
    avatarUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    isVerified: true,
    isBanned: false,
    isFlagged: true,
    isPlatinum: false,
    joinedAt: DateTime(2024, 11, 20),
    matchCount: 8,
    reportCount: 2,
    status: 'active',
    gender: 'female',
  ),
  AdminUser(
    id: 'u4',
    name: 'Michael Torres',
    email: 'michael@berkeley.edu',
    university: 'Berkeley',
    avatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
    isVerified: false,
    isBanned: true,
    isFlagged: true,
    isPlatinum: false,
    joinedAt: DateTime(2025, 1, 5),
    matchCount: 3,
    reportCount: 5,
    status: 'banned',
    gender: 'male',
  ),
  AdminUser(
    id: 'u5',
    name: 'Emily Parker',
    email: 'emily@mit.edu',
    university: 'MIT',
    avatarUrl:
        'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=200',
    isVerified: true,
    isBanned: false,
    isFlagged: false,
    isPlatinum: true,
    joinedAt: DateTime(2025, 2, 14),
    matchCount: 31,
    reportCount: 0,
    status: 'active',
    gender: 'female',
  ),
  AdminUser(
    id: 'u6',
    name: 'Max Müller',
    email: 'max@tu-berlin.de',
    university: 'TU Berlin',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200',
    isVerified: false,
    isBanned: false,
    isFlagged: false,
    isPlatinum: false,
    joinedAt: DateTime(2025, 3, 1),
    matchCount: 7,
    reportCount: 0,
    status: 'inactive',
    gender: 'male',
  ),
];

class UserMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isMe;

  UserMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isMe = false,
  });
}

final mockUserMessages = {
  'u1': [
    UserMessage(
        id: 'm1',
        senderId: 'u1',
        senderName: 'James Wilson',
        text: 'Hey, wie geht\'s dir? 😊',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isMe: true),
    UserMessage(
        id: 'm2',
        senderId: 'other',
        senderName: 'Sarah',
        text: 'Gut, danke! Und dir?',
        timestamp:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 45))),
    UserMessage(
        id: 'm3',
        senderId: 'u1',
        senderName: 'James Wilson',
        text: 'Auch gut! Lust auf einen Kaffee am Campus?',
        timestamp:
            DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
        isMe: true),
  ],
  'u2': [
    UserMessage(
        id: 'm4',
        senderId: 'other',
        senderName: 'Michael',
        text: 'Hast du die Hausaufgabe für Info II fertig?',
        timestamp: DateTime.now().subtract(const Duration(days: 1))),
    UserMessage(
        id: 'm5',
        senderId: 'u2',
        senderName: 'Chloe Evans',
        text: 'Fast, sitze gerade noch an Aufgabe 3.',
        timestamp: DateTime.now().subtract(const Duration(hours: 23)),
        isMe: true),
  ],
  'u3': [
    UserMessage(
        id: 'm6',
        senderId: 'u3',
        senderName: 'Sophia Chen',
        text: 'Hey, hab dich heute in der Mensa gesehen!',
        timestamp: DateTime.now().subtract(const Duration(hours: 5)),
        isMe: true),
    UserMessage(
        id: 'm7',
        senderId: 'other',
        senderName: 'Lukas',
        text: 'Echt? Hättest was sagen sollen! 😂',
        timestamp: DateTime.now().subtract(const Duration(hours: 4))),
  ],
};

final List<UserReport> mockReports = [
  UserReport(
    id: 'r1',
    reporterName: 'Emily Parker',
    reportedName: 'Michael Torres',
    reportedAvatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
    reason: 'Unangemessene Fotos',
    reportedAt: DateTime(2025, 3, 28, 14, 32),
    status: 'pending',
  ),
  UserReport(
    id: 'r2',
    reporterName: 'James Wilson',
    reportedName: 'Michael Torres',
    reportedAvatarUrl:
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=200',
    reason: 'Belästigung / Spam',
    reportedAt: DateTime(2025, 3, 28, 16, 10),
    status: 'pending',
  ),
  UserReport(
    id: 'r3',
    reporterName: 'Chloe Evans',
    reportedName: 'Sophia Chen',
    reportedAvatarUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=200',
    reason: 'Verdächtiges Verhalten',
    reportedAt: DateTime(2025, 3, 27, 9, 45),
    status: 'pending',
  ),
  UserReport(
    id: 'r4',
    reporterName: 'Max Müller',
    reportedName: 'James Wilson',
    reportedAvatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
    reason: 'Fake-Profil',
    reportedAt: DateTime(2025, 3, 26, 11, 20),
    status: 'resolved',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Admin Stats Model
// ─────────────────────────────────────────────────────────────────────────────
class AdminStats {
  final int totalUsers;
  final int activeToday;
  final int matchesToday;
  final int messagesToday;
  final double revenueToday;
  final double revenueMonth;
  final double revenueTotal;
  final int boostsPurchased;
  final int premiumUsers;
  final int pendingReports;
  final int verifiedUsers;
  final List<double> weeklySignups;
  final List<double> weeklyMatches;
  final List<double> weeklyRevenue;
  final Map<String, int> universityBreakdown;

  AdminStats({
    required this.totalUsers,
    required this.activeToday,
    required this.matchesToday,
    required this.messagesToday,
    required this.revenueToday,
    required this.revenueMonth,
    required this.revenueTotal,
    required this.boostsPurchased,
    required this.premiumUsers,
    required this.pendingReports,
    required this.verifiedUsers,
    required this.weeklySignups,
    required this.weeklyMatches,
    required this.weeklyRevenue,
    required this.universityBreakdown,
  });
}

final AdminStats mockStats = AdminStats(
  totalUsers: 4821,
  activeToday: 1203,
  matchesToday: 347,
  messagesToday: 8492,
  revenueToday: 145.0,
  revenueMonth: 4230.0,
  revenueTotal: 38750.0,
  boostsPurchased: 29,
  premiumUsers: 846,
  pendingReports: 3,
  verifiedUsers: 3914,
  weeklySignups: [42, 67, 55, 88, 120, 95, 140],
  weeklyMatches: [180, 210, 195, 310, 280, 340, 347],
  weeklyRevenue: [85.0, 120.0, 95.0, 210.0, 175.0, 310.0, 145.0],
  universityBreakdown: {
    'Stanford': 1420,
    'Berkeley': 980,
    'MIT': 760,
    'TU Berlin': 520,
    'Andere': 1141,
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// Team & Staff Model
// ─────────────────────────────────────────────────────────────────────────────
class StaffMember {
  final String id;
  final String name;
  final String email;
  final String role; // 'Super Admin', 'Admin', 'Moderator'
  final String status; // 'active', 'revoked'
  final DateTime addedAt;
  final String? avatarUrl;
  final String? localAvatarPath; // locally picked image from device

  StaffMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.addedAt,
    this.avatarUrl,
    this.localAvatarPath,
  });
}

final List<StaffMember> mockStaff = [
  StaffMember(
    id: 's1',
    name: 'Mehmet',
    email: 'ceo@campmeet.app',
    role: 'Super Admin',
    status: 'active',
    addedAt: DateTime(2023, 1, 1),
    avatarUrl:
        'https://images.unsplash.com/photo-1570295999919-56ceb5ecca61?w=200',
  ),
  StaffMember(
    id: 's2',
    name: 'Sarah Connor',
    email: 'sarah.admin@campmeet.app',
    role: 'Admin',
    status: 'active',
    addedAt: DateTime(2024, 5, 12),
    avatarUrl:
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200',
  ),
  StaffMember(
    id: 's3',
    name: 'Julian Baumann',
    email: 'julian.mod@campmeet.app',
    role: 'Moderator',
    status: 'active',
    addedAt: DateTime(2025, 2, 20),
    avatarUrl:
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200',
  ),
  StaffMember(
    id: 's4',
    name: 'Lena Schmidt',
    email: 'lena.mod@campmeet.app',
    role: 'Moderator',
    status: 'revoked',
    addedAt: DateTime(2024, 11, 5),
  ),
];

class SystemLog {
  final String id;
  final String action;
  final String detail;
  final DateTime timestamp;
  final String type; // 'info', 'warning', 'error', 'success'

  SystemLog({
    required this.id,
    required this.action,
    required this.detail,
    required this.timestamp,
    required this.type,
  });
}

final List<SystemLog> mockSystemLogs = [
  SystemLog(
      id: 'l1',
      action: 'Login Erfolgreich',
      detail: 'Admin "Mehmet" eingeloggt.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      type: 'success'),
  SystemLog(
      id: 'l2',
      action: 'Passwort geändert',
      detail: 'Passwort wurde erfolgreich aktualisiert.',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      type: 'info'),
  SystemLog(
      id: 'l3',
      action: 'Nutzer gesperrt',
      detail: 'Nutzer u3 wurde wegen Belästigung gesperrt.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      type: 'warning'),
  SystemLog(
      id: 'l4',
      action: 'Maintenance Mode',
      detail: 'Maintenance Mode wurde aktiviert.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      type: 'info'),
  SystemLog(
      id: 'l5',
      action: 'System-Fehler',
      detail: 'Verbindung zu FCM-Server unterbrochen.',
      timestamp: DateTime.now().subtract(const Duration(hours: 12)),
      type: 'error'),
  SystemLog(
      id: 'l6',
      action: 'Datenbank Backup',
      detail: 'Automatisches Backup erfolgreich durchgeführt.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      type: 'success'),
  SystemLog(
      id: 'l7',
      action: 'Werbung geschaltet',
      detail: 'Neue Kampagne "Lieferando" aktiviert.',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      type: 'info'),
];
