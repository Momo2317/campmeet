import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/core/theme/app_theme.dart';

/// Route für die Profilseite: blendet ein, statt von rechts zu wischen
Route<T> studentProfileRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

class StudentProfilePage extends StatefulWidget {
  final Student student;
  final bool isDatingMode;
  final int initialImageIndex;
  // Hauptseite mit dem nächsten Profil: wird beim Wischen hinter der Seite sichtbar
  final Widget Function()? backdropBuilder;

  const StudentProfilePage({
    super.key,
    required this.student,
    this.backdropBuilder,
    this.initialImageIndex = 0,
    this.isDatingMode = true,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;

  // Wisch-Strecke seit Beginn der Geste (links negativ, rechts positiv)
  double _dragX = 0;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      // Gleiche Dauer wie die Karten auf der Entdeckungsseite
      duration: const Duration(milliseconds: 200),
    );
    _currentImage = widget.initialImageIndex < widget.student.images.length
        ? widget.initialImageIndex
        : 0;
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  // Schiebt die Seite von der aktuellen Position zu [target]
  void _animateTo(double target, {VoidCallback? onEnd}) {
    final animation = Tween<double>(begin: _dragX, end: target).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    void update() => setState(() => _dragX = animation.value);
    animation.addListener(update);
    _slideController.forward(from: 0).then((_) {
      animation.removeListener(update);
      onEnd?.call();
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _slideController.stop();
    setState(() => _dragX += details.delta.dx);
  }

  // Wie auf der Entdeckungsseite: nach rechts Like, nach links Nope
  void _onDragEnd(DragEndDetails details) {
    final width = MediaQuery.sizeOf(context).width;
    final velocity = details.primaryVelocity ?? 0;
    if (_dragX > 80 || velocity > 400) {
      _animateTo(width * 1.2, onEnd: () {
        if (mounted) Navigator.pop(context, CardSwiperDirection.right);
      });
    } else if (_dragX < -80 || velocity < -400) {
      _animateTo(-width * 1.2, onEnd: () {
        if (mounted) Navigator.pop(context, CardSwiperDirection.left);
      });
    } else {
      _animateTo(0);
    }
  }

  // Herz bzw. X in der Mitte, das mit der Wischstrecke eingeblendet wird
  Widget _buildWatermark() {
    if (_dragX == 0) return const SizedBox.shrink();
    final width = MediaQuery.sizeOf(context).width;
    final isRight = _dragX > 0;
    final opacity = (_dragX.abs() / (width * 0.3)).clamp(0.0, 1.0) * 0.4;
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Opacity(
            opacity: opacity,
            child: Icon(
              isRight ? CupertinoIcons.heart_fill : CupertinoIcons.xmark,
              size: 180,
              color: isRight ? Color(0xFF2BD9A0) : Color(0xFFFF4B6E),
            ),
          ),
        ),
      ),
    );
  }

  // Dahinter liegt die Hauptseite mit der Karte des nächsten Profils
  Widget _buildBackdrop() {
    final builder = widget.backdropBuilder;
    return Positioned.fill(
      child: builder == null
          ? Container(color: context.bg)
          : IgnorePointer(child: builder()),
    );
  }

  void _showSnack(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle()),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _confirmBlock() async {
    final name = widget.student.name;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.card,
        title: Text('$name blockieren?', style: TextStyle(color: context.fg)),
        content: Text(
            'Ihr könnt euch gegenseitig nicht mehr sehen oder schreiben.',
            style: TextStyle(color: context.fgA(0.7))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Abbrechen', style: TextStyle()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                Text('Blockieren', style: TextStyle(color: Color(0xFFFF4B6E))),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _showSnack('$name wurde blockiert.', color: Color(0xFFFF4B6E));
      Navigator.of(context).pop();
    }
  }

  final List<GlobalKey> _photoKeys = [];

  Widget _buildPhoto(int index, double photoHeight) {
    while (_photoKeys.length <= index) {
      _photoKeys.add(GlobalKey());
    }
    return SizedBox(
      key: _photoKeys[index],
      height: photoHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              widget.student.images[_currentImage],
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_currentImage > 0) setState(() => _currentImage--);
                    },
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      if (_currentImage < widget.student.images.length - 1) {
                        setState(() => _currentImage++);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 15,
            left: 15,
            right: 15,
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.student.images.length,
                  (i) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _currentImage
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (index == 0) ...[
            // Verlauf oben, damit die Indikatoren und das Menü lesbar bleiben
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Menü oben rechts auf dem Foto
            Positioned(
              top: 0,
              right: 4,
              child: PopupMenuButton<String>(
                icon: const Icon(CupertinoIcons.ellipsis, color: Colors.white),
                color: context.card,
                onSelected: (value) {
                  if (value == 'report') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Profil gemeldet. Wir werden es umgehend prüfen.',
                            style: TextStyle()),
                        backgroundColor: Color(0xFFFF4B6E),
                      ),
                    );
                  }
                },
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(CupertinoIcons.flag,
                            color: Color(0xFFFF4B6E), size: 20),
                        const SizedBox(width: 12),
                        Text('Profil melden',
                            style: TextStyle(color: Color(0xFFFF4B6E))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _flowSection(String title, Widget child) {
    return Container(
      color: context.bg,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: context.fg,
            ),
          ),
          const SizedBox(height: 15),
          child,
        ],
      ),
    );
  }

  // Wie bei Tinder: Abschnitte mit Daten und die weiteren Fotos im Wechsel
  Widget _qaRow(IconData icon, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: context.fgA(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(question,
                    style: TextStyle(color: context.fgA(0.6), fontSize: 13)),
                const SizedBox(height: 2),
                Text(answer,
                    style: TextStyle(
                        color: context.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFlow(double photoHeight) {
    final st = widget.student;
    final sections = <Widget>[];

    if (st.bio.trim().isNotEmpty) {
      sections.add(_flowSection(
        'Über mich',
        Text(
          st.bio,
          style: TextStyle(
            fontSize: 16,
            color: context.fgA(0.8),
            height: 1.5,
          ),
        ),
      ));
    }

    final hasDetails = st.height != null ||
        st.gender != null ||
        st.languages.isNotEmpty ||
        st.zodiac != null ||
        (widget.isDatingMode &&
            (st.relationshipType != null || st.orientation != null));
    if (hasDetails) {
      sections.add(_flowSection(
        'Meine Details',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (st.height != null)
              _qaRow(CupertinoIcons.resize_v, 'Größe', '${st.height} cm'),
            if (st.gender != null)
              _qaRow(CupertinoIcons.person, 'Geschlecht', st.gender!),
            if (st.languages.isNotEmpty)
              _qaRow(CupertinoIcons.globe, 'Sprache', st.languages.join(', ')),
            if (st.zodiac != null)
              _qaRow(CupertinoIcons.sparkles, 'Sternzeichen', st.zodiac!),
            if (widget.isDatingMode && st.relationshipType != null)
              _qaRow(CupertinoIcons.heart, 'Beziehung', st.relationshipType!),
            if (widget.isDatingMode && st.orientation != null)
              _qaRow(CupertinoIcons.compass, 'Orientierung', st.orientation!),
          ],
        ),
      ));
    }

    if (st.lifestyle.isNotEmpty) {
      sections.add(_flowSection(
        'Lifestyle',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: st.lifestyle.entries
              .map((e) => _qaRow(lifestyleIcon(e.key),
                  lifestyleQuestions[e.key] ?? e.key, e.value))
              .toList(),
        ),
      ));
    }

    if (st.interests.isNotEmpty) {
      sections.add(_flowSection(
        'Interessen',
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: st.interests.map((i) => _InterestBadge(label: i)).toList(),
        ),
      ));
    }

    final prompts = st.prompts;
    if (prompts != null && prompts.isNotEmpty) {
      sections.add(_flowSection(
        'Campus Icebreaker',
        Column(
          children: prompts.entries
              .map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF9B30FF).withValues(alpha: 0.15),
                            const Color(0xFF9B30FF).withValues(alpha: 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Color(0xFF9B30FF).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9B30FF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            entry.value,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: context.fg,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        ),
      ));
    }

    final result = <Widget>[...sections];
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _buildBackdrop(),
        Positioned.fill(child: _buildSwipeable(context)),
      ],
    );
  }

  Widget _buildSwipeable(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topPadding = MediaQuery.paddingOf(context).top;
    // Höhe des Fotos. Name, Foto und Inhalt scrollen gemeinsam.
    final photoHeight = screenHeight * 0.55;

    // Die ganze Seite reagiert auf Wischen, auch der Bereich um die Buttons
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Transform.translate(
        offset: Offset(_dragX, 0),
        // Leichte Drehung wie bei der Karte auf der Entdeckungsseite
        child: Transform.rotate(
          angle: _dragX / MediaQuery.sizeOf(context).width * 0.2,
          child: Stack(
            children: [
              Positioned.fill(
                child: Scaffold(
                  floatingActionButtonLocation:
                      FloatingActionButtonLocation.centerFloat,
                  floatingActionButton: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _CircleAction(
                          icon: CupertinoIcons.xmark,
                          color: Color(0xFFFF4B6E),
                          onTap: () =>
                              Navigator.pop(context, CardSwiperDirection.left),
                        ),
                        const SizedBox(width: 12),
                        _CircleAction(
                          icon: CupertinoIcons.star_fill,
                          color: Color(0xFF3FA7FF),
                          onTap: () =>
                              // Der Stern hat keine Wischrichtung, daher "none"
                              Navigator.pop(context, CardSwiperDirection.none),
                        ),
                        const SizedBox(width: 12),
                        _CircleAction(
                          icon: CupertinoIcons.heart_fill,
                          color: Color(0xFF2BD9A0),
                          onTap: () =>
                              Navigator.pop(context, CardSwiperDirection.right),
                        ),
                      ],
                    ),
                  ),
                  body: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Kopfzeile: Name und Alter links, Pfeil nach unten rechts (zurück zum Swipen)
                        Padding(
                          padding:
                              EdgeInsets.fromLTRB(24, topPadding + 12, 24, 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: widget.student.name,
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.bold,
                                          color: context.fg,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' ${widget.student.age}',
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w400,
                                          color: context.fg,
                                        ),
                                      ),
                                    ],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                      color: context.fg,
                                      shape: BoxShape.circle),
                                  child: Icon(CupertinoIcons.chevron_down,
                                      color: context.bg, size: 24),
                                ),
                              ),
                            ],
                          ),
                        ),

                        _buildPhoto(0, photoHeight),
                        Container(
                          color: context.bg,
                          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: context.fgA(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                        CupertinoIcons.checkmark_seal_fill,
                                        color: Color(0xFF3FA7FF),
                                        size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verifiziert',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF3FA7FF),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.book,
                                      color: context.fgA(0.7), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${widget.student.university} • ${widget.student.major}',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: context.fgA(0.7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(CupertinoIcons.location,
                                      color: context.fgA(0.7), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${widget.student.city} • ${widget.student.distance} km entfernt',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: context.fgA(0.7)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ..._buildFlow(photoHeight),
                        Container(
                          color: context.bg,
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 32),
                              _ProfileTextAction(
                                icon: CupertinoIcons.share,
                                label: '${widget.student.name} teilen',
                                color: context.fg,
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text:
                                          'Schau dir ${widget.student.name} auf CampusMatch an!'));
                                  _showSnack(
                                      'Link in die Zwischenablage kopiert.');
                                },
                              ),
                              _ProfileTextAction(
                                icon: CupertinoIcons.flag,
                                label: '${widget.student.name} melden',
                                color: Color(0xFFFF4B6E),
                                onTap: () => _showSnack(
                                    'Profil gemeldet. Wir werden es umgehend prüfen.',
                                    color: Color(0xFFFF4B6E)),
                              ),
                              _ProfileTextAction(
                                icon: CupertinoIcons.nosign,
                                label: '${widget.student.name} blockieren',
                                color: Color(0xFFFF4B6E),
                                onTap: _confirmBlock,
                              ),
                              const SizedBox(
                                  height: 100), // Platz für die Aktionsbuttons
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              _buildWatermark(),
            ],
          ),
        ),
      ),
    );
  }
}

IconData lifestyleIcon(String key) {
  switch (key) {
    case 'Trinken':
      return CupertinoIcons.drop;
    case 'Rauchen':
      return CupertinoIcons.smoke;
    case 'Sport':
      return CupertinoIcons.sportscourt;
    case 'Social Media':
      return CupertinoIcons.device_phone_portrait;
    case 'Ernährung':
      return CupertinoIcons.cart;
    case 'Haustiere':
      return CupertinoIcons.paw;
    case 'Schlafrhythmus':
      return CupertinoIcons.moon;
    default:
      return CupertinoIcons.circle;
  }
}

class _ProfileTextAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ProfileTextAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Text(label,
                  style: TextStyle(
                      color: color, fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailTag extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailTag({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFF9B30FF), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: context.fg, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

class _InterestBadge extends StatelessWidget {
  final String label;
  const _InterestBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF9B30FF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: const Color(0xFF9B30FF).withValues(alpha: 0.5)),
      ),
      child: Text(
        interestWithEmoji(label),
        style: TextStyle(color: context.fg, fontSize: 13),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 62;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.46),
      ),
    );
  }
}
