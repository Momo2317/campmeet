import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camp_meet/features/chat/presentation/pages/audio_call_page.dart';
import 'package:camp_meet/core/security/encryption_service.dart';
import 'package:camp_meet/features/chat/data/chat_model.dart';
import 'package:camp_meet/features/chat/data/chat_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main Page
// ─────────────────────────────────────────────────────────────────────────────
class ChatDetailPage extends ConsumerStatefulWidget {
  final Student student;
  const ChatDetailPage({super.key, required this.student});

  @override
  ConsumerState<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends ConsumerState<ChatDetailPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Recording state
  bool _isRecording = false;
  bool _recordingCancelled = false;
  double _recordingSeconds = 0.0;
  Timer? _recordingTimer;
  final List<double> _recordingWaveform = [];
  late AnimationController _pulseController;

  // Typing state
  bool _hasText = false;

  ChatMessage? _replyingToMessage;

  void _replyToMessage(ChatMessage msg) {
    setState(() => _replyingToMessage = msg);
  }

  void _cancelReply() {
    setState(() => _replyingToMessage = null);
  }

  String _getPreviewText(ChatMessage msg) {
    if (msg.type == MessageType.text) return msg.text ?? "";
    if (msg.type == MessageType.image) return "Foto";
    if (msg.type == MessageType.video) return "Video";
    if (msg.type == MessageType.audio) return "Sprachnachricht";
    return "";
  }

  late final AudioRecorder _audioRecorder;
  String? _recordedFilePath;

  late final AudioPlayer _chatAudioPlayer;
  int? _currentlyPlayingIndex;

  final EncryptionService _encryptionService = EncryptionService();

  List<ChatMessage> get _messages =>
      ref.watch(chatMessagesFamily(widget.student.id));

  void _addMessage(ChatMessage msg) {
    ref.read(chatMessagesFamily(widget.student.id).notifier).sendMessage(msg);
    _scrollToBottom();
  }

  void _deleteMessage(int index) {
    ref
        .read(chatMessagesFamily(widget.student.id).notifier)
        .deleteMessage(index);
  }

  void _updateMessage(int index, ChatMessage updated) {
    ref
        .read(chatMessagesFamily(widget.student.id).notifier)
        .updateMessage(index, updated);
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _messageController.addListener(() {
      setState(() => _hasText = _messageController.text.isNotEmpty);
    });

    _audioRecorder = AudioRecorder();
    _chatAudioPlayer = AudioPlayer();
    _chatAudioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed && _currentlyPlayingIndex != null) {
        setState(() {
          _messages[_currentlyPlayingIndex!].isAudioPlaying = false;
          _messages[_currentlyPlayingIndex!].audioProgress = 0.0;
          _currentlyPlayingIndex = null;
        });
      }
    });
    _chatAudioPlayer.onPositionChanged.listen((pos) {
      if (_currentlyPlayingIndex != null) {
        final msg = _messages[_currentlyPlayingIndex!];
        setState(() {
          msg.audioProgress =
              pos.inMilliseconds / ((msg.audioDurationSec ?? 1) * 1000);
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    _chatAudioPlayer.dispose();
    _audioRecorder.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Text send ──────────────────────────────────────────────────────────────
  void _sendText() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // E2EE Simulation
    final encryptedHash = _encryptionService.encryptMessage(text);
    debugPrint("🚀 Sende an Firestore: $encryptedHash");

    _addMessage(ChatMessage(
      text: text,
      isMe: true,
      time: _nowTime(),
      type: MessageType.text,
      repliedMessage: _replyingToMessage,
    ));
    _messageController.clear();
    _cancelReply();
  }

  // ── Media Options (Image/Video) ────────────────────────────────────────────
  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildAttachmentButton(
                ctx,
                icon: CupertinoIcons.camera_fill,
                label: 'Foto',
                color: const Color(0xFF3FA7FF),
                onTap: () => _pickMedia(ImageSource.camera, false),
              ),
              _buildAttachmentButton(
                ctx,
                icon: CupertinoIcons.videocam_fill,
                label: 'Video',
                color: const Color(0xFFFF4B6E),
                onTap: () => _pickMedia(ImageSource.camera, true),
              ),
              _buildAttachmentButton(
                ctx,
                icon: CupertinoIcons.photo_fill,
                label: 'Galerie',
                color: const Color(0xFF9B30FF),
                onTap: () => _pickGalleryMedia(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentButton(BuildContext ctx,
      {required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.fg, size: 36),
          const SizedBox(height: 10),
          Text(label,
              style: TextStyle(
                  color: context.fgA(0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _pickMedia(ImageSource source, bool isVideo) async {
    try {
      if (isVideo) {
        final XFile? video = await _picker.pickVideo(source: source);
        if (video != null)
          await _showMediaPreviewDialog(video.path, MessageType.video);
      } else {
        final XFile? image = await _picker.pickImage(source: source);
        if (image != null)
          await _showMediaPreviewDialog(image.path, MessageType.image);
      }
    } catch (e) {
      debugPrint("Error picking media: $e");
    }
  }

  Future<void> _pickGalleryMedia() async {
    try {
      final XFile? media = await _picker.pickMedia();
      if (media != null) {
        final ext = media.path.toLowerCase();
        final isVideo = ext.endsWith('.mp4') || ext.endsWith('.mov');
        await _showMediaPreviewDialog(
            media.path, isVideo ? MessageType.video : MessageType.image);
      }
    } catch (e) {
      debugPrint("Error picking media from gallery: $e");
    }
  }

  // ── Media Preview Dialog (with View Once Support) ────────────────────────
  Future<void> _showMediaPreviewDialog(String path, MessageType type) async {
    bool isViewOnce = false;
    final captionCtrl = TextEditingController();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => StatefulBuilder(
          builder: (context, setPreviewState) {
            return Scaffold(
              backgroundColor: Colors.black,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(CupertinoIcons.xmark, color: context.fg),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Use fit: BoxFit.contain explicitly
              body: Center(
                child: type == MessageType.video
                    ? _VideoPlayerWidget(path: path, autoPlay: true)
                    : Image.file(File(path), fit: BoxFit.contain),
              ),
              bottomNavigationBar: Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                color: Colors.black54,
                child: SafeArea(
                  child: Row(
                    children: [
                      // ViewOnce Toggle Button
                      GestureDetector(
                        onTap: () =>
                            setPreviewState(() => isViewOnce = !isViewOnce),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: isViewOnce
                                ? const Color(0xFF9B30FF)
                                : context.fgA(0.24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(CupertinoIcons.number_circle,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                isViewOnce ? 'Einmalansicht' : 'Dauerhaft',
                                style: TextStyle(
                                    color: context.fg,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Caption Input
                      Expanded(
                        child: TextField(
                          controller: captionCtrl,
                          style: TextStyle(color: context.fg),
                          decoration: InputDecoration(
                            hintText: 'Nachricht hinzufügen...',
                            hintStyle: TextStyle(color: context.fgA(0.54)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: context.fgA(0.12),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Send Button
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _addMessage(ChatMessage(
                            mediaPath: path,
                            text: captionCtrl.text.isNotEmpty
                                ? captionCtrl.text
                                : null,
                            isMe: true,
                            time: _nowTime(),
                            type: type,
                            isViewOnce: isViewOnce,
                            repliedMessage: _replyingToMessage,
                          ));
                          _cancelReply();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: Icon(CupertinoIcons.arrow_up,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── View Once Full Screen Viewer ───────────────────────────────────────────
  void _openViewOnceMedia(ChatMessage msg, int index) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(CupertinoIcons.xmark, color: context.fg),
              onPressed: () => Navigator.pop(ctx),
            ),
          ),
          body: Center(
            child: msg.type == MessageType.audio
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.mic_fill,
                          color: Colors.purpleAccent, size: 80),
                      const SizedBox(height: 20),
                      Text('Sprachnachricht',
                          style: TextStyle(color: context.fg, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text('Wird abgespielt...',
                          style: TextStyle(
                              color: context.fgA(0.54), fontSize: 14)),
                    ],
                  )
                : msg.type == MessageType.video
                    ? _VideoPlayerWidget(path: msg.mediaPath!, autoPlay: true)
                    : (msg.mediaPath!.startsWith('http')
                        ? Image.network(msg.mediaPath!, fit: BoxFit.contain)
                        : Image.file(File(msg.mediaPath!),
                            fit: BoxFit.contain)),
          ),
        ),
      ),
    );
    // Mark as viewed once closed
    final latest = _messages[index];
    latest.isViewed = true;
    _updateMessage(index, latest);
  }

  // ── Recording ──────────────────────────────────────────────────────────────
  void _startRecording() async {
    HapticFeedback.mediumImpact();
    if (await _audioRecorder.hasPermission()) {
      final dir = await getTemporaryDirectory();
      _recordedFilePath =
          '${dir.path}/recorded_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: _recordedFilePath!,
      );

      setState(() {
        _isRecording = true;
        _recordingCancelled = false;
        _recordingSeconds = 0.0;
        _recordingWaveform.clear();
      });

      _recordingTimer =
          Timer.periodic(const Duration(milliseconds: 100), (t) async {
        if (await _audioRecorder.isRecording()) {
          final amplitude = await _audioRecorder.getAmplitude();
          final normalizedAmp =
              min(1.0, max(0.1, (amplitude.current + 50) / 50.0));
          setState(() {
            _recordingSeconds += 0.1;
            _recordingWaveform.add(normalizedAmp);
            if (_recordingWaveform.length > 40) _recordingWaveform.removeAt(0);
          });
        }
        if (_recordingSeconds >= 60) _stopAndSendRecording();
      });
    }
  }

  void _stopAndSendRecording() async {
    _recordingTimer?.cancel();
    final path = await _audioRecorder.stop();
    final duration = _recordingSeconds;
    final waveform = List<double>.from(_recordingWaveform);

    setState(() {
      _isRecording = false;
    });

    if (!_recordingCancelled && duration > 0.5 && path != null) {
      HapticFeedback.lightImpact();
      await _showAudioPreviewDialog(path, duration, waveform);
    }

    setState(() {
      _recordingCancelled = false;
    });
  }

  Future<void> _showAudioPreviewDialog(
      String filePath, double duration, List<double> waveform) async {
    bool isViewOnce = false;
    final AudioPlayer previewPlayer = AudioPlayer();
    bool isPlaying = false;
    double playProgress = 0.0;

    StreamSubscription? posSub;
    StreamSubscription? stateSub;

    await showModalBottomSheet(
        context: context,
        backgroundColor: context.card,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(builder: (context, setPreviewState) {
              posSub ??= previewPlayer.onPositionChanged.listen((p) {
                if (mounted) {
                  setPreviewState(() {
                    playProgress =
                        p.inMilliseconds / (max(0.1, duration) * 1000);
                  });
                }
              });
              stateSub ??= previewPlayer.onPlayerStateChanged.listen((state) {
                if (mounted) {
                  setPreviewState(() {
                    isPlaying = state == PlayerState.playing;
                    if (state == PlayerState.completed) {
                      playProgress = 0.0;
                    }
                  });
                }
              });

              return SafeArea(
                  child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                        left: 16,
                        right: 16,
                        top: 24,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Sprachnachricht senden',
                              style: TextStyle(
                                  color: context.fg,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          // Playback bar
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                  color: context.fgA(0.05),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(children: [
                                GestureDetector(
                                  onTap: () async {
                                    if (isPlaying) {
                                      await previewPlayer.pause();
                                    } else {
                                      if (playProgress >= 1.0)
                                        playProgress = 0.0;
                                      await previewPlayer
                                          .play(DeviceFileSource(filePath));
                                    }
                                  },
                                  child: Icon(
                                      isPlaying
                                          ? CupertinoIcons.pause_circle_fill
                                          : CupertinoIcons.play_circle_fill,
                                      color: context.fg,
                                      size: 36),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: SizedBox(
                                  height: 30,
                                  child: Stack(
                                    children: [
                                      _RecordingWaveform(
                                          amplitudes: waveform,
                                          color: context.fgA(0.24)),
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          widthFactor:
                                              playProgress.clamp(0.0, 1.0),
                                          child: _RecordingWaveform(
                                              amplitudes: waveform,
                                              color: const Color(0xFF9B30FF)),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(width: 12),
                                Text(_formatDuration(duration),
                                    style: TextStyle(color: context.fgA(0.7))),
                              ])),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => setPreviewState(
                                    () => isViewOnce = !isViewOnce),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isViewOnce
                                        ? const Color(0xFF9B30FF)
                                        : context.fgA(0.24),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(CupertinoIcons.number_circle,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        isViewOnce
                                            ? 'Einmalansicht'
                                            : 'Dauerhaft',
                                        style: TextStyle(
                                            color: context.fg,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                  onTap: () async {
                                    await previewPlayer.stop();
                                    await previewPlayer.dispose();
                                    if (mounted) Navigator.pop(context);
                                    _addMessage(ChatMessage(
                                      isMe: true,
                                      time: _nowTime(),
                                      type: MessageType.audio,
                                      mediaPath: filePath,
                                      waveform: waveform,
                                      audioDurationSec: duration.ceil(),
                                      isViewOnce: isViewOnce,
                                    ));
                                    _cancelReply();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: AppTheme.primaryGradient),
                                    child: Icon(CupertinoIcons.arrow_up,
                                        color: Colors.white, size: 22),
                                  ))
                            ],
                          )
                        ],
                      )));
            })).then((_) async {
      await previewPlayer.stop();
      await previewPlayer.dispose();
      posSub?.cancel();
      stateSub?.cancel();
    });
  }

  void _cancelRecording() async {
    _recordingTimer?.cancel();
    await _audioRecorder.stop();
    HapticFeedback.heavyImpact();
    setState(() {
      _isRecording = false;
      _recordingCancelled = true;
    });
  }

  // ── Audio Playback ──────────────────────────────────────────────────────────
  void _togglePlayback(int index) async {
    final msg = _messages[index];
    if (msg.type != MessageType.audio) return;

    if (_currentlyPlayingIndex == index) {
      if (msg.isAudioPlaying) {
        await _chatAudioPlayer.pause();
        setState(() => msg.isAudioPlaying = false);
      } else {
        await _chatAudioPlayer.resume();
        setState(() => msg.isAudioPlaying = true);
      }
    } else {
      if (_currentlyPlayingIndex != null) {
        setState(() {
          _messages[_currentlyPlayingIndex!].isAudioPlaying = false;
          _messages[_currentlyPlayingIndex!].audioProgress = 0.0;
        });
      }

      await _chatAudioPlayer.stop();
      setState(() {
        _currentlyPlayingIndex = index;
        msg.isAudioPlaying = true;
        msg.audioProgress = 0.0;
      });

      if (msg.mediaPath != null) {
        if (msg.mediaPath!.startsWith('http')) {
          await _chatAudioPlayer.play(UrlSource(msg.mediaPath!));
        } else if (msg.mediaPath! == 'demo') {
          // Skip fake demo to prevent errors
          setState(() => msg.isAudioPlaying = false);
        } else {
          await _chatAudioPlayer.play(DeviceFileSource(msg.mediaPath!));
        }
      }
    }
  }

  void _seekAudio(int index, double progress) async {
    final msg = _messages[index];
    if (msg.type != MessageType.audio ||
        msg.mediaPath == null ||
        msg.mediaPath == 'demo') return;

    setState(() => msg.audioProgress = progress.clamp(0.0, 1.0));

    if (_currentlyPlayingIndex == index) {
      final dur = await _chatAudioPlayer.getDuration();
      if (dur != null) {
        final seekMs = (dur.inMilliseconds * progress).round();
        await _chatAudioPlayer.seek(Duration(milliseconds: seekMs));
      }
    }
  }

  String _nowTime() {
    final t = TimeOfDay.now();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(double seconds) {
    final s = seconds.floor();
    final m = s ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bg,
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildMessageList()),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _isRecording ? _buildRecordingBar() : _buildMessageInput(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: context.bg,
        border: Border(bottom: BorderSide(color: context.fgA(0.08))),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(CupertinoIcons.chevron_left,
                    color: Color(0xFF9B30FF), size: 26),
              ),
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(widget.student.imageUrl),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _showSecurityCodeVerification,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(widget.student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: context.fg)),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                          widget.student.isPlatinum
                              ? CupertinoIcons.checkmark_seal_fill
                              : CupertinoIcons.lock_fill,
                          size: 15,
                          color: widget.student.isPlatinum
                              ? const Color(0xFF3FA7FF)
                              : context.fgA(0.45)),
                    ],
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(CupertinoIcons.ellipsis,
                    color: context.fgA(0.8), size: 22),
                color: context.card,
                onSelected: (value) {
                  if (value == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Profil gemeldet. Wir werden es umgehend prüfen.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  } else if (value == 'profile') {
                    // Profilansicht öffnen (Platzhalter)
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.person,
                            color: context.fg, size: 20),
                        const SizedBox(width: 12),
                        Text('Profil anzeigen',
                            style: TextStyle(color: context.fg)),
                      ],
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.flag,
                            color: Colors.redAccent, size: 20),
                        SizedBox(width: 12),
                        Text('Profil melden',
                            style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(int index, ChatMessage msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: ["👍", "❤️", "😂", "😮", "😢", "🙏"]
                      .map((emoji) => GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            msg.reaction = emoji;
                            _updateMessage(index, msg);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: context.fgA(0.1),
                                shape: BoxShape.circle),
                            child: Text(emoji,
                                style: const TextStyle(fontSize: 24)),
                          )))
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              Divider(color: context.fgA(0.1)),
              if (msg.type == MessageType.text && msg.text != null)
                ListTile(
                  leading: Icon(CupertinoIcons.doc_on_doc,
                      color: context.fg, size: 24),
                  title: Text('Text kopieren',
                      style: TextStyle(color: context.fg, fontSize: 16)),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: msg.text!));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Kopiert!', style: TextStyle())),
                    );
                  },
                ),
              if (!msg.isMe)
                ListTile(
                  leading: const Icon(CupertinoIcons.flag,
                      color: Colors.redAccent, size: 24),
                  title: Text('Nachricht melden',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _reportMessage(msg);
                  },
                ),
              if (msg.isMe)
                ListTile(
                  leading: const Icon(CupertinoIcons.delete,
                      color: Colors.redAccent, size: 24),
                  title: Text('Nachricht löschen',
                      style: TextStyle(color: Colors.redAccent, fontSize: 16)),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showDeleteDialog(index);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportMessage(ChatMessage msg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nachricht melden',
            style: TextStyle(color: context.fg, fontWeight: FontWeight.bold)),
        content: Text(
          'Möchtest du diese Nachricht wirklich melden? Wir werden den Inhalt umgehend prüfen.',
          style: TextStyle(color: context.fgA(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                Text('Abbrechen', style: TextStyle(color: context.fgA(0.38))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Vielen Dank. Die Nachricht wurde zur Prüfung gemeldet.',
                      style: TextStyle()),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text('Melden',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int index) {
    final msg = _messages[index];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nachricht löschen?',
            style: TextStyle(color: context.fg, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (msg.isMe) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _performDelete(index, forEveryone: true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                child: Text('Für alle löschen',
                    style: TextStyle(color: context.fg, fontSize: 16)),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performDelete(index, forEveryone: false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    msg.isMe ? context.fgA(0.12) : Colors.redAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text('Für mich löschen',
                  style: TextStyle(color: context.fg, fontSize: 16)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('Abbrechen',
                  style: TextStyle(color: context.fgA(0.54), fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _performDelete(int index, {required bool forEveryone}) {
    _deleteMessage(index);

    // Stop playback if the deleted message was currently playing
    if (_currentlyPlayingIndex == index) {
      _chatAudioPlayer.stop();
      _currentlyPlayingIndex = null;
    } else if (_currentlyPlayingIndex != null &&
        _currentlyPlayingIndex! > index) {
      // Shift index if a previous message was deleted
      _currentlyPlayingIndex = _currentlyPlayingIndex! - 1;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            forEveryone
                ? 'Nachricht für alle gelöscht'
                : 'Nachricht für dich gelöscht',
            style: TextStyle()),
        backgroundColor: const Color(0xFF27AE60),
      ),
    );
  }

  Widget _buildE2EESystemBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24, top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF9B30FF).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(CupertinoIcons.lock_fill,
              color: Color(0xFF9B30FF), size: 20),
          const SizedBox(height: 8),
          Text(
            'Nachrichten und Anrufe sind Ende-zu-Ende-verschlüsselt. Niemand außerhalb dieses Chats, nicht einmal CampMeet, kann sie lesen oder anhören.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: context.fgA(0.65), fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _showSecurityCodeVerification,
            child: Text(
              'Tippe hier zum Verifizieren',
              style: TextStyle(
                  color: const Color(0xFF9B30FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
            ),
          )
        ],
      ),
    );
  }

  void _showSecurityCodeVerification() {
    final code = _encryptionService.getSecurityCode(widget.student.name);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 24),
                Icon(CupertinoIcons.qrcode, size: 120, color: context.fg),
                const SizedBox(height: 20),
                Text('Sicherheitscode prüfen',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: context.fg)),
                const SizedBox(height: 12),
                Text(
                    'Um sicherzugehen, dass Nachrichten Ende-zu-Ende verschlüsselt sind, kannst du diesen Code scannen oder mit ${widget.student.name} vergleichen.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: context.fgA(0.7))),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.fgA(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 18,
                        color: context.fg,
                        letterSpacing: 2,
                        height: 1.5),
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9B30FF),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25))),
                    child: Text('Fertig',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msgIndex = index;
        final msg = _messages[msgIndex];
        Widget bubble = const SizedBox.shrink();

        // Handle View Once messages
        if (msg.isViewOnce) {
          bubble = _ViewOnceBubble(
            msg: msg,
            onTap: () {
              if (!msg.isMe && !msg.isViewed) {
                _openViewOnceMedia(msg, msgIndex);
              }
            },
          );
        } else {
          switch (msg.type) {
            case MessageType.text:
              bubble =
                  _TextBubble(msg: msg, avatarUrl: widget.student.imageUrl);
              break;
            case MessageType.image:
              bubble = _MediaBubble(msg: msg, isVideo: false);
              break;
            case MessageType.video:
              bubble = _MediaBubble(msg: msg, isVideo: true);
              break;
            case MessageType.audio:
              bubble = _AudioBubble(
                msg: msg,
                onPlayPause: () => _togglePlayback(msgIndex),
                onSeek: (p) => _seekAudio(msgIndex, p),
              );
              break;
          }
        }

        return Dismissible(
          key: UniqueKey(),
          direction: msg.isMe
              ? DismissDirection.endToStart
              : DismissDirection.startToEnd,
          confirmDismiss: (direction) async {
            _replyToMessage(msg);
            return false;
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(CupertinoIcons.reply, color: context.fgA(0.54)),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Icon(CupertinoIcons.reply, color: context.fgA(0.54)),
          ),
          child: GestureDetector(
            onLongPress: () => _showMessageOptions(msgIndex, msg),
            child: bubble,
          ),
        );
      },
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────────────────
  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: context.fgA(0.05),
        border: Border(bottom: BorderSide(color: context.fgA(0.1))),
      ),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                  color: const Color(0xFF9B30FF),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_replyingToMessage!.isMe ? "Du" : widget.student.name,
                    style: TextStyle(
                        color: const Color(0xFF9B30FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(_getPreviewText(_replyingToMessage!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.fgA(0.54), fontSize: 13)),
              ],
            ),
          ),
          IconButton(
            icon:
                Icon(CupertinoIcons.xmark, color: context.fgA(0.54), size: 20),
            onPressed: _cancelReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        child: Row(
          children: [
            // Media picker (Image/Video)
            _InputIconButton(
              icon: CupertinoIcons.plus,
              onTap: _showAttachmentOptions,
            ),
            const SizedBox(width: 10),
            // Text field
            Expanded(
              child: _Glass(
                height: 52,
                radius: 28,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _messageController,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(color: context.fg, fontSize: 17),
                  decoration: InputDecoration(
                    hintText: 'Nachricht schreiben',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: context.fgA(0.4), fontSize: 17),
                  ),
                  onSubmitted: (_) => _sendText(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Send / Mic button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _hasText
                  ? _SendButton(key: const ValueKey('send'), onTap: _sendText)
                  : _MicButton(
                      key: const ValueKey('mic'),
                      onLongPressStart: (_) => _startRecording(),
                      onLongPressEnd: (_) => _stopAndSendRecording(),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recording Bar ─────────────────────────────────────────────────────────
  Widget _buildRecordingBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.card,
        border: Border(top: BorderSide(color: context.fgA(0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Cancel
            GestureDetector(
              onTap: _cancelRecording,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.trash,
                    color: Colors.redAccent, size: 22),
              ),
            ),
            const SizedBox(width: 12),
            // Waveform + Timer
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 28,
                    child: _RecordingWaveform(
                        amplitudes: _recordingWaveform,
                        color: Colors.purpleAccent),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(
                                alpha: 0.4 + 0.6 * _pulseController.value),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDuration(_recordingSeconds),
                        style: TextStyle(
                            color: context.fgA(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '< Wischen zum Abbrechen',
                        style: TextStyle(color: context.fgA(0.3), fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Stop & Send
            GestureDetector(
              onTap: _stopAndSendRecording,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                ),
                child: Icon(CupertinoIcons.arrow_up,
                    color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video Player Widget
// ─────────────────────────────────────────────────────────────────────────────
class _VideoPlayerWidget extends StatefulWidget {
  final String path;
  final bool autoPlay;
  final ValueChanged<bool>? onPlaying;
  const _VideoPlayerWidget(
      {required this.path, this.autoPlay = false, this.onPlaying});

  @override
  State<_VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<_VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.path.startsWith('http')
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));

    _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isInit = true;
          if (widget.autoPlay) {
            _controller.play();
            widget.onPlaying?.call(true);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit)
      return const Center(
          child: CircularProgressIndicator(color: Colors.purpleAccent));

    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          GestureDetector(
            onTap: () {
              setState(() {
                if (_controller.value.isPlaying) {
                  _controller.pause();
                  widget.onPlaying?.call(false);
                } else {
                  _controller.play();
                  widget.onPlaying?.call(true);
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(CupertinoIcons.play_fill,
                        color: context.fg, size: 32),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black87],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final pos = value.position;
                      final min = pos.inMinutes.toString().padLeft(2, '0');
                      final sec =
                          (pos.inSeconds % 60).toString().padLeft(2, '0');
                      return Text('$min:$sec',
                          style: TextStyle(color: context.fg, fontSize: 12));
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      colors: VideoProgressColors(
                        playedColor: Colors.purpleAccent,
                        bufferedColor: context.fgA(0.3),
                        backgroundColor: context.fgA(0.12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, VideoPlayerValue value, child) {
                      final pos = value.duration;
                      final min = pos.inMinutes.toString().padLeft(2, '0');
                      final sec =
                          (pos.inSeconds % 60).toString().padLeft(2, '0');
                      return Text('$min:$sec',
                          style: TextStyle(color: context.fg, fontSize: 12));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubble Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ViewOnceBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onTap;
  const _ViewOnceBubble({required this.msg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isVideo = msg.type == MessageType.video;
    final isAudio = msg.type == MessageType.audio;
    final isOpened = msg.isViewed;

    IconData displayIcon;
    String displayText;
    if (isAudio) {
      displayIcon = CupertinoIcons.mic;
      displayText = 'Sprachnachricht';
    } else if (isVideo) {
      displayIcon = CupertinoIcons.videocam;
      displayText = 'Video';
    } else {
      displayIcon = CupertinoIcons.camera;
      displayText = 'Foto';
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: EdgeInsets.only(
                bottom: 4,
                left: msg.isMe ? 60 : 0,
                right: msg.isMe ? 0 : 60,
              ),
              decoration: BoxDecoration(
                gradient: msg.isMe ? AppTheme.primaryGradient : null,
                color: msg.isMe ? null : context.fgA(0.08),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(msg.isMe ? 20 : 0),
                  bottomRight: Radius.circular(msg.isMe ? 0 : 20),
                ),
                border: isOpened && !msg.isMe
                    ? Border.all(color: context.fgA(0.24))
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isOpened ? CupertinoIcons.checkmark_circle : displayIcon,
                    color: isOpened
                        ? context.fgA(0.54)
                        : (msg.isMe ? Colors.white : context.fg),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isOpened ? 'Geöffnet' : displayText,
                    style: TextStyle(
                      color: isOpened
                          ? context.fgA(0.54)
                          : (msg.isMe ? Colors.white : context.fg),
                      fontSize: 15,
                      fontStyle: isOpened ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  if (!isOpened) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.fgA(0.24),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CupertinoIcons.number_circle,
                          color: Colors.white, size: 10),
                    )
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time,
                    style: TextStyle(
                        color: (msg.isMe ? Colors.white54 : context.fgA(0.4)),
                        fontSize: 10)),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  _MessageStatusIndicator(status: msg.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RepliedMessageWidget extends StatelessWidget {
  final ChatMessage msg;
  final bool isMe;
  const _RepliedMessageWidget({required this.msg, required this.isMe});

  String _getPreviewText(ChatMessage m) {
    if (m.type == MessageType.text) return m.text ?? "";
    if (m.type == MessageType.image) return "Foto";
    if (m.type == MessageType.video) return "Video";
    if (m.type == MessageType.audio) return "Sprachnachricht";
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 3,
                height: 35,
                color: isMe ? context.fgA(0.7) : const Color(0xFF9B30FF)),
            const SizedBox(width: 8),
            Flexible(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(msg.isMe ? "Du" : "Antwort",
                      style: TextStyle(
                          color: isMe ? context.fg : const Color(0xFF9B30FF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  Text(_getPreviewText(msg),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: (msg.isMe ? Colors.white70 : context.fgA(0.7)),
                          fontSize: 12)),
                ]))
          ],
        ));
  }
}

class _ReactionWidget extends StatelessWidget {
  final String reaction;
  final bool isMe;
  const _ReactionWidget({required this.reaction, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.card,
        shape: BoxShape.circle,
        border: Border.all(color: context.fgA(0.1)),
      ),
      child: Text(reaction, style: const TextStyle(fontSize: 16)),
    );
  }
}

class _TextBubble extends StatelessWidget {
  final ChatMessage msg;
  final String? avatarUrl;
  const _TextBubble({required this.msg, this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final mine = msg.isMe;
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        gradient: mine
            ? const LinearGradient(
                colors: [Color(0xFF9B30FF), Color(0xFF5B2BF0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: mine
            ? null
            : (context.isDark ? context.fgA(0.12) : const Color(0xFFEDEBF3)),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(20),
          topRight: const Radius.circular(20),
          bottomLeft: Radius.circular(mine ? 20 : 6),
          bottomRight: Radius.circular(mine ? 6 : 20),
        ),
      ),
      child: Text(
        msg.text ?? '',
        style: TextStyle(
            color: mine ? Colors.white : context.fg, fontSize: 16, height: 1.3),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                mine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!mine && avatarUrl != null) ...[
                CircleAvatar(
                    radius: 22, backgroundImage: NetworkImage(avatarUrl!)),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Padding(
                  padding: EdgeInsets.only(
                      left: mine ? 56 : 0, right: mine ? 0 : 40),
                  child: bubble,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                top: 4, bottom: 12, left: mine || avatarUrl == null ? 0 : 52),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time,
                    style: TextStyle(color: context.fgA(0.5), fontSize: 12)),
                if (mine) ...[
                  const SizedBox(width: 4),
                  _MessageStatusIndicator(status: msg.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Combine Image and Video Bubbles since they are similar layouts
class _MediaBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isVideo;
  const _MediaBubble({required this.msg, required this.isVideo});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              bottom: 4,
              left: msg.isMe ? 60 : 0,
              right: msg.isMe ? 0 : 60,
            ),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: msg.isMe
                  ? const Color(0xFF9B30FF).withOpacity(0.2)
                  : context.fgA(0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(msg.isMe ? 20 : 0),
                bottomRight: Radius.circular(msg.isMe ? 0 : 20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullScreenMediaPage(msg: msg, isVideo: isVideo),
                      ),
                    );
                  },
                  child: Hero(
                    tag: msg.mediaPath!,
                    child: ConstrainedBox(
                      constraints:
                          const BoxConstraints(maxWidth: 240, maxHeight: 300),
                      child: isVideo
                          ? AbsorbPointer(
                              child: _VideoPlayerWidget(path: msg.mediaPath!))
                          : (msg.mediaPath!.startsWith('http')
                              ? Image.network(msg.mediaPath!,
                                  fit: BoxFit.cover, width: 240)
                              : Image.file(File(msg.mediaPath!),
                                  fit: BoxFit.cover, width: 240)),
                    ),
                  ),
                ),
                if (msg.text != null && msg.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      msg.text!,
                      style: TextStyle(color: context.fg, fontSize: 15),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(msg.time,
                    style: TextStyle(
                        color: (msg.isMe ? Colors.white54 : context.fgA(0.4)),
                        fontSize: 10)),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  _MessageStatusIndicator(status: msg.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Audio Bubble ─────────────────────────────────────────────────────────────
class _AudioBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onPlayPause;
  final ValueChanged<double> onSeek;

  const _AudioBubble(
      {required this.msg, required this.onPlayPause, required this.onSeek});

  @override
  Widget build(BuildContext context) {
    final waveform = msg.waveform ?? List.generate(25, (_) => 0.5);
    final dur = msg.audioDurationSec ?? 5;
    final remainingSec = dur - (msg.audioProgress * dur).round();
    final timeLabel =
        '${(remainingSec ~/ 60).toString().padLeft(2, '0')}:${(remainingSec % 60).toString().padLeft(2, '0')}';

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            width: 240,
            margin: EdgeInsets.only(
              bottom: 4,
              left: msg.isMe ? 60 : 0,
              right: msg.isMe ? 0 : 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: msg.isMe ? AppTheme.primaryGradient : null,
              color: msg.isMe ? null : context.fgA(0.08),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(msg.isMe ? 20 : 0),
                bottomRight: Radius.circular(msg.isMe ? 0 : 20),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onPlayPause,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: context.fgA(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      msg.isAudioPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: (msg.isMe ? Colors.white : context.fg),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 28,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (details) {
                                final pct = (details.localPosition.dx /
                                        constraints.maxWidth)
                                    .clamp(0.0, 1.0);
                                onSeek(pct);
                              },
                              onTapDown: (details) {
                                final pct = (details.localPosition.dx /
                                        constraints.maxWidth)
                                    .clamp(0.0, 1.0);
                                onSeek(pct);
                              },
                              child: _PlaybackWaveform(
                                amplitudes: waveform,
                                progress: msg.audioProgress,
                                isMe: msg.isMe,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: context.fgA(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.mic_fill,
                    color: context.fgA(0.24), size: 10),
                const SizedBox(width: 2),
                Text(msg.time,
                    style: TextStyle(color: context.fgA(0.24), fontSize: 10)),
                if (msg.isMe) ...[
                  const SizedBox(width: 4),
                  _MessageStatusIndicator(status: msg.status),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Waveform Painters
// ─────────────────────────────────────────────────────────────────────────────
class _PlaybackWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final double progress;
  final bool isMe;

  const _PlaybackWaveform(
      {required this.amplitudes, required this.progress, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(
        amplitudes: amplitudes,
        progress: progress,
        activeColor: context.fg,
        inactiveColor: context.fgA(0.3),
      ),
      size: const Size(double.infinity, 28),
    );
  }
}

class _RecordingWaveform extends StatelessWidget {
  final List<double> amplitudes;
  final Color color;

  const _RecordingWaveform({required this.amplitudes, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WaveformPainter(
        amplitudes: amplitudes,
        progress: 1.0,
        activeColor: color,
        inactiveColor: color.withOpacity(0.3),
      ),
      size: const Size(double.infinity, 28),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _WaveformPainter({
    required this.amplitudes,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    const barWidth = 3.0;
    const gap = 2.0;
    final totalBars = amplitudes.length;
    final totalWidth = totalBars * (barWidth + gap);
    final startX = (size.width - totalWidth) / 2;
    final progressIndex = (progress * totalBars).floor();

    for (int i = 0; i < totalBars; i++) {
      final amp = amplitudes[i].clamp(0.1, 1.0);
      final isActive = i <= progressIndex;
      final paint = Paint()
        ..color = isActive ? activeColor : inactiveColor
        ..strokeCap = StrokeCap.round
        ..strokeWidth = barWidth;

      final x = startX + i * (barWidth + gap) + barWidth / 2;
      final barHeight = amp * size.height;
      final top = (size.height - barHeight) / 2;
      final bottom = top + barHeight;

      canvas.drawLine(Offset(x, top), Offset(x, bottom), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.amplitudes != amplitudes;
}

// ─────────────────────────────────────────────────────────────────────────────
// Small Widget Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _MessageStatusIndicator extends StatelessWidget {
  final MessageStatus status;

  const _MessageStatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == MessageStatus.sending) {
      return Icon(CupertinoIcons.clock, color: context.fgA(0.3), size: 12);
    }

    final isRead = status == MessageStatus.read;
    final isDelivered = status == MessageStatus.delivered || isRead;
    final color = isRead ? const Color(0xFF9B30FF) : context.fgA(0.54);

    final double size = 12.0;

    return SizedBox(
      width: isDelivered ? size + (size - 4) : size,
      height: size,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Icon(
                isRead
                    ? CupertinoIcons.checkmark_alt_circle_fill
                    : CupertinoIcons.checkmark_alt_circle,
                color: color,
                size: size),
          ),
          if (isDelivered)
            Positioned(
              left: size - 4, // 4 pixels overlap
              child: Icon(
                  isRead
                      ? CupertinoIcons.checkmark_alt_circle_fill
                      : CupertinoIcons.checkmark_alt_circle,
                  color: color,
                  size: size),
            ),
        ],
      ),
    );
  }
}

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _InputIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _Glass(size: 52, child: Icon(icon, color: context.fg, size: 26)),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppTheme.primaryGradient,
        ),
        child: Icon(CupertinoIcons.arrow_up, color: Colors.white, size: 22),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final GestureLongPressStartCallback onLongPressStart;
  final GestureLongPressEndCallback onLongPressEnd;
  const _MicButton({
    super.key,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: onLongPressStart,
      onLongPressEnd: onLongPressEnd,
      child: _Glass(
          size: 52,
          child: Icon(CupertinoIcons.mic, color: context.fg, size: 24)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fullscreen Media Viewer
// ─────────────────────────────────────────────────────────────────────────────
class FullScreenMediaPage extends StatefulWidget {
  final ChatMessage msg;
  final bool isVideo;

  const FullScreenMediaPage(
      {super.key, required this.msg, required this.isVideo});

  @override
  State<FullScreenMediaPage> createState() => _FullScreenMediaPageState();
}

class _FullScreenMediaPageState extends State<FullScreenMediaPage> {
  bool _showUI = true;

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
      if (_showUI) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      }
    });
  }

  @override
  void dispose() {
    // Restore normal system UI when closing fullscreen
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black45,
              elevation: 0,
              iconTheme: IconThemeData(color: context.fg),
              title: Column(
                children: [
                  Text(
                    widget.msg.isMe ? 'Du' : 'User',
                    style: TextStyle(
                        color: context.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    widget.msg.time,
                    style: TextStyle(color: context.fgA(0.7), fontSize: 12),
                  ),
                ],
              ),
            )
          : null,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Dismissible(
          key: const Key('fullscreen_media'),
          direction: DismissDirection.vertical,
          onDismissed: (_) => Navigator.pop(context),
          child: Container(
            color: Colors
                .transparent, // Ensures GestureDetector catches taps anywhere
            child: Center(
              child: Hero(
                tag: widget.msg.mediaPath!,
                child: widget.isVideo
                    ? _VideoPlayerWidget(
                        path: widget.msg.mediaPath!,
                        autoPlay: true,
                        onPlaying: (playing) {
                          if (playing && _showUI) {
                            _toggleUI();
                          } else if (!playing && !_showUI) {
                            _toggleUI();
                          }
                        },
                      )
                    : InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: widget.msg.mediaPath!.startsWith('http')
                            ? Image.network(widget.msg.mediaPath!)
                            : Image.file(File(widget.msg.mediaPath!)),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Liquid-Glass Container (echtes Glas via liquid_glass_renderer)
class _Glass extends StatelessWidget {
  final Widget child;
  final double? size;
  final double? height;
  final double radius;
  final EdgeInsets? padding;
  const _Glass({
    required this.child,
    this.size,
    this.height,
    this.radius = 100,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final r = size != null ? min(radius, size! / 2) : radius;
    return SizedBox(
      width: size,
      height: size ?? height,
      child: LiquidGlass.withOwnLayer(
        settings: LiquidGlassSettings.ios27Regular(
            brightness: context.isDark ? Brightness.dark : Brightness.light),
        shape: LiquidRoundedSuperellipse(borderRadius: r),
        child: Container(
          alignment: Alignment.center,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
