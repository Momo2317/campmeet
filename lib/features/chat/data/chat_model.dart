import 'dart:convert';

enum MessageType { text, image, video, audio }

enum MessageStatus { sending, sent, delivered, read }

class ChatMessage {
  final String id;
  final String? text;
  final String? mediaPath; // used for image, video, or audio
  final List<double>? waveform;
  final int? audioDurationSec;
  final bool isMe;
  final String time;
  final MessageType type;
  bool isAudioPlaying;
  double audioProgress;
  final bool isViewOnce;
  bool isViewed;
  MessageStatus status;
  String? reaction;
  ChatMessage? repliedMessage;

  ChatMessage({
    String? id,
    this.text,
    this.mediaPath,
    this.waveform,
    this.audioDurationSec,
    required this.isMe,
    required this.time,
    required this.type,
    this.isAudioPlaying = false,
    this.audioProgress = 0.0,
    this.isViewOnce = false,
    this.isViewed = false,
    this.status = MessageStatus.sent,
    this.reaction,
    this.repliedMessage,
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'mediaPath': mediaPath,
      'waveform': waveform,
      'audioDurationSec': audioDurationSec,
      'isMe': isMe,
      'time': time,
      'type': type.name,
      'isViewOnce': isViewOnce,
      'isViewed': isViewed,
      'status': status.name,
      'reaction': reaction,
      'repliedText': repliedMessage?.text,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString(),
      text: map['text'],
      mediaPath: map['mediaPath'],
      waveform: map['waveform'] != null
          ? List<double>.from(
              (map['waveform'] as List).map((x) => (x as num).toDouble()))
          : null,
      audioDurationSec: map['audioDurationSec']?.toInt(),
      isMe: map['isMe'] ?? true,
      time: map['time'] ?? '12:00',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      isViewOnce: map['isViewOnce'] ?? false,
      isViewed: map['isViewed'] ?? false,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => MessageStatus.sent,
      ),
      reaction: map['reaction'],
      repliedMessage: map['repliedText'] != null
          ? ChatMessage(
              text: map['repliedText'],
              isMe: false,
              time: '',
              type: MessageType.text,
            )
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ChatMessage.fromJson(String source) =>
      ChatMessage.fromMap(json.decode(source));
}
