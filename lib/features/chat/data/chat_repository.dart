import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_meet/features/chat/data/chat_model.dart';

const String _kChatPrefix = 'campmeet_chat_';

/// Provider für den Chatverlauf mit einem bestimmten Studenten
final chatMessagesFamily =
    NotifierProvider.family<ChatNotifier, List<ChatMessage>, String>(
  ChatNotifier.new,
);

class ChatNotifier extends Notifier<List<ChatMessage>> {
  ChatNotifier(this.studentId);

  final String studentId;
  SharedPreferences? _prefs;

  @override
  List<ChatMessage> build() {
    _loadMessages();
    return _initialDefaultMessages();
  }

  List<ChatMessage> _initialDefaultMessages() {
    return [
      ChatMessage(
        text: 'Hey! Schön dich hier zu matchen. Wie läuft dein Semester? ☕️',
        isMe: false,
        time: '14:20',
        type: MessageType.text,
      ),
    ];
  }

  Future<void> _loadMessages() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = _prefs?.getString('$_kChatPrefix$studentId');
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        final List list = json.decode(jsonStr);
        final loaded = list.map((m) => ChatMessage.fromMap(m)).toList();
        state = loaded;
      } catch (_) {}
    }
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = json.encode(state.map((m) => m.toMap()).toList());
    await _prefs?.setString('$_kChatPrefix$studentId', jsonStr);
  }

  /// Sendet eine neue Nachricht und speichert sie
  Future<void> sendMessage(ChatMessage message) async {
    state = [...state, message];
    await _persist();

    // Simulierte intelligente Antwort nach 2 Sekunden
    if (message.isMe && message.type == MessageType.text) {
      Future.delayed(const Duration(milliseconds: 2200), () {
        _simulateReply(message.text ?? '');
      });
    }
  }

  /// Aktualisiert z.B. Reaktionen oder ViewOnce Status
  Future<void> updateMessage(int index, ChatMessage updated) async {
    if (index >= 0 && index < state.length) {
      final list = List<ChatMessage>.from(state);
      list[index] = updated;
      state = list;
      await _persist();
    }
  }

  /// Entfernt eine Nachricht
  Future<void> deleteMessage(int index) async {
    if (index >= 0 && index < state.length) {
      final list = List<ChatMessage>.from(state);
      list.removeAt(index);
      state = list;
      await _persist();
    }
  }

  void _simulateReply(String userText) {
    final replies = [
      'Das klingt richtig gut! Wollen wir uns die Woche auf einen Kaffee treffen? ☕️',
      'Hahaha ja voll! Ich bin heute Nachmittag in der Bib, falls du da bist 📚',
      'Sehr cool! Welches Fach macht dir im Moment am meisten Spaß? 🎓',
      'Klingt spannend! Lass uns unbedingt die Tage mal am Campus quatschen 😊',
    ];
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final randomReply = replies[Random().nextInt(replies.length)];

    final replyMessage = ChatMessage(
      text: randomReply,
      isMe: false,
      time: timeStr,
      type: MessageType.text,
    );

    state = [...state, replyMessage];
    _persist();
  }
}
