import 'package:camp_meet/features/wg/presentation/pages/wg_listings_page.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:camp_meet/core/widgets/sliders_icon.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/features/discovery/data/matches_repository.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/features/discovery/presentation/widgets/match_dialog.dart';
import 'package:camp_meet/features/profile/presentation/pages/profile_page.dart';
import 'package:camp_meet/features/chat/presentation/pages/chat_list_page.dart';
import 'package:camp_meet/features/discovery/presentation/pages/likes_page.dart';
import 'package:camp_meet/features/discovery/presentation/pages/student_profile_page.dart';
import 'package:camp_meet/features/discovery/presentation/pages/radar_page.dart';
import 'package:camp_meet/core/services/payment_service.dart';
import 'package:camp_meet/core/services/ad_service.dart';
import 'package:camp_meet/features/profile/presentation/pages/premium_page.dart';

class DiscoveryPage extends ConsumerStatefulWidget {
  const DiscoveryPage({super.key});

  @override
  ConsumerState<DiscoveryPage> createState() => _DiscoveryPageState();
}

class _DiscoveryPageState extends ConsumerState<DiscoveryPage> {
  final CardSwiperController _controller = CardSwiperController();
  final List<Student> _matchedStudents = [];
  int _currentTopCardIndex = 0;

  // ── Super Like: 1 kostenlos pro Monat (kein Badge) ─────────────────────────
  int _freeSuperLikesLeft = 1;
  DateTime _superLikeResetDate = DateTime(
    DateTime.now().year,
    DateTime.now().month + 1,
    1,
  );
  // Gekaufte / geschenkte Super Likes (Badge wird angezeigt), im Profil gespeichert
  int get _purchasedSuperLikes =>
      ref.read(userProfileProvider)?.superLikes ?? 0;

  // Filter State
  double _maxDistance = 50.0;
  RangeValues _ageRange = const RangeValues(18, 30);
  String _cityFilter = ''; // leer = alle Städte
  final _cityCtrl = TextEditingController();
  String _discoveryMode = 'Dating'; // 'Dating' oder 'Study Buddy'
  bool get _isDatingMode => _discoveryMode != 'Study Buddy';
  bool _isShowingAd = false;
  List<Widget> _cards = [];
  List<Student> _currentFilteredStudents = [];

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _cards = _buildCardList();
    // Initial prüfen, ob die erste Karte Werbung ist
    _currentTopCardIndex = 0;
    _isShowingAd = _cards.isNotEmpty && _cards[0] is AdDiscoveryCard;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _precacheUpcomingImages();
    });
  }

  /// Lädt die Fotos der nächsten Profile vorab, damit die Karte dahinter
  /// beim Wischen nicht schwarz / leer ist, sondern sofort sichtbar.
  void _precacheUpcomingImages() {
    final start = _currentTopCardIndex.clamp(0, _cards.length);
    final end = (start + 5).clamp(0, _cards.length);
    for (final card in _cards.sublist(start, end)) {
      if (card is! DiscoveryCard || card.student.images.isEmpty) continue;
      for (final url in card.student.images) {
        precacheImage(NetworkImage(url), context).catchError((_) {});
      }
    }
  }

  /// Hauptseite mit der Karte des nächsten Profils. Wird hinter der geöffneten
  /// Profilseite gezeigt, während sie weggewischt wird.
  Widget _buildNextBackdrop(Widget Function() nextCard) {
    final topHeight = kToolbarHeight + MediaQuery.paddingOf(context).top;
    return Material(
      color: Colors.transparent,
      child: Container(
        color: context.bg,
        child: Stack(
          children: [
            Positioned.fill(child: nextCard()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topHeight,
              child: IgnorePointer(
                child: GlassTopBar(
                  fg: Colors.white,
                  mode: _discoveryMode,
                  onFilter: () {},
                  onSearch: () {},
                  onWg: () {},
                  onMode: (_) {},
                ),
              ),
            ),
            Positioned(
              bottom: 94,
              left: 0,
              right: 0,
              child: _buildActionButtons(),
            ),
            const Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: BottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardList() {
    final ads = AdService().getAdCards();
    final List<Widget> cards = [];
    int adIndex = 0;

    // Filter auf mockStudents anwenden
    _currentFilteredStudents = mockStudents.where((s) {
      // 1. Modus-Filter (Dating vs Study Buddy)
      if (_isDatingMode) {
        if (s.preferredMode == 'Study Buddy') return false;
      } else {
        if (s.preferredMode == 'Dating') return false;
      }
      // 2. Alters-Filter
      if (s.age < _ageRange.start.round() || s.age > _ageRange.end.round()) {
        return false;
      }
      // 3. Distanz-Filter
      if (s.distance > _maxDistance) {
        return false;
      }
      // 4. Stadt-Filter (freie Eingabe, Studierende in dieser Stadt)
      if (_cityFilter.isNotEmpty &&
          !s.city.toLowerCase().contains(_cityFilter.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    // Reihenfolge der Karten (Profile + Werbung) zuerst festlegen, damit der
    // Hintergrund hinter der Profilseite die wirklich nächste Karte zeigt.
    final entries = <({Student? student, AdCard? ad})>[];
    for (int i = 0; i < _currentFilteredStudents.length; i++) {
      entries.add((student: _currentFilteredStudents[i], ad: null));
      // Alle X Profile eine Werbekarte einfügen (nur wenn im Admin aktiviert)
      if (AdService.isAdsEnabled &&
          (i + 1) % AdService.profilesBetweenAds == 0 &&
          ads.isNotEmpty) {
        entries.add((student: null, ad: ads[adIndex % ads.length]));
        adIndex++;
      }
    }

    for (int i = 0; i < entries.length; i++) {
      final student = entries[i].student;
      final ad = entries[i].ad;
      if (student == null) {
        cards.add(AdDiscoveryCard(ad: ad!));
        continue;
      }
      final next = i + 1 < entries.length ? entries[i + 1] : null;
      cards.add(DiscoveryCard(
        key: ValueKey('card_${student.id}'),
        student: student,
        backdropBuilder: next == null
            ? null
            : () => _buildNextBackdrop(() {
                  final nextStudent = next.student;
                  if (nextStudent == null) return AdDiscoveryCard(ad: next.ad!);
                  return DiscoveryCard(
                    key: ValueKey('backdrop_${nextStudent.id}'),
                    reportBackdrop: false,
                    student: nextStudent,
                    controller: _controller,
                    isDatingMode: _isDatingMode,
                    onSuperLike: () {},
                  );
                }),
        controller: _controller,
        isDatingMode: _isDatingMode,
        onSuperLike: _onSuperLike,
      ));
    }
    return cards;
  }

  /// Gibt den Student zurück, der zur Card am Index gehört (Ad-Karten überspringend)
  Student? _studentAtCardIndex(int cardIndex) {
    int studentIdx = 0;
    for (int i = 0; i < _cards.length; i++) {
      if (_cards[i] is! AdDiscoveryCard) {
        if (i == cardIndex && studentIdx < _currentFilteredStudents.length) {
          return _currentFilteredStudents[studentIdx];
        }
        studentIdx++;
      } else if (i == cardIndex) {
        return null; // ist eine Ad
      }
    }
    return null;
  }

  bool _onSwipe(
      int previousIndex, int? currentIndex, CardSwiperDirection direction) {
    int index = previousIndex;
    if (index < 0 || index >= _cards.length) return false;

    final card = _cards[index];

    // Die Karte, die JETZT oben liegt, ist index + 1
    final nextIndex = index + 1;
    setState(() {
      _currentTopCardIndex = currentIndex ?? _cards.length;
      if (currentIndex != null && currentIndex < _cards.length) {
        _isShowingAd = _cards[currentIndex] is AdDiscoveryCard;
      } else {
        _isShowingAd = false;
      }
    });

    debugPrint(
        '📢 Karte $previousIndex weggeswipt. Jetzt oben: $currentIndex (Ad: $_isShowingAd)');

    _precacheUpcomingImages();

    // 📢 Wenn weggeswipt Karte eine Ad war
    if (card is AdDiscoveryCard) {
      if (direction == CardSwiperDirection.right) {
        AdService().onAdClicked(card.ad);
      } else {
        AdService().onAdDismissed(card.ad);
      }
      return true;
    }

    // Normales Profil
    if (direction == CardSwiperDirection.right) {
      final student = _studentAtCardIndex(index);
      if (student != null) {
        // In Matches & Swiped Provider speichern
        ref.read(matchesProvider.notifier).addMatch(student);
        ref.read(swipedHistoryProvider.notifier).recordSwipe(student.id);

        final myProfile = ref.read(userProfileProvider);

        setState(() {
          _matchedStudents.add(student);
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (context) => MatchDialog(
              student: student,
              isDatingMode: _isDatingMode,
              currentUserAvatar: myProfile?.avatarUrl,
            ),
          );
        });
      }
    } else if (direction == CardSwiperDirection.left) {
      final student = _studentAtCardIndex(index);
      if (student != null) {
        ref.read(swipedHistoryProvider.notifier).recordSwipe(student.id);
      }
    }
    return true;
  }

  void _onSuperLike() {
    // Monats-Reset prüfen
    if (DateTime.now().isAfter(_superLikeResetDate)) {
      setState(() {
        _freeSuperLikesLeft = 1;
        _superLikeResetDate = DateTime(
          DateTime.now().year,
          DateTime.now().month + 1,
          1,
        );
      });
    }

    // Zuerst gekaufte/geschenkte Super Likes verbrauchen
    if (_purchasedSuperLikes > 0) {
      ref.read(userProfileProvider.notifier).consumeSuperLike();
      _controller.swipe(CardSwiperDirection.top);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⭐ Super Like gesendet!', style: TextStyle()),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    } else if (_freeSuperLikesLeft > 0) {
      // Kostenlosen Monats-Super-Like nutzen (kein Badge)
      setState(() => _freeSuperLikesLeft--);
      _controller.swipe(CardSwiperDirection.top);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⭐ Super Like gesendet!', style: TextStyle()),
          backgroundColor: Colors.blueAccent,
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      _showSuperLikeDepletedDialog();
    }
  }

  void _showSuperLikeDepletedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PurchaseBottomSheet(
        icon: Icons.star_rounded,
        iconColor: Colors.blueAccent,
        title: 'Kein Super Like mehr',
        subtitle:
            'Du hast deinen kostenlosen Super Like für diesen Monat verwendet. '
            'Hole dir CampMeet Premium für unbegrenzte Super Likes!',
        resetDate: _superLikeResetDate,
        primaryAction: 'Premium holen',
        primaryPrice: null,
        onPrimary: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PremiumPage()),
          );
        },
        // 🎬 Option: Super Like durch Werbung-Profil verdienen
        extraWidget: GestureDetector(
          onTap: () {
            Navigator.pop(ctx);
            ref.read(userProfileProvider.notifier).addCredits(superLikes: 1);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⭐ +1 Super Like verdient!', style: TextStyle()),
                backgroundColor: Colors.blueAccent,
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.play_circle_fill,
                    color: Colors.blueAccent, size: 20),
                const SizedBox(width: 10),
                Text(
                  '🎬 Video schauen für 1 Super Like',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBoostPurchaseDialog() {
    final payments = PaymentService();
    final boostPrice =
        payments.getPriceString(ProductIds.boost1, fallback: '4,99 €');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PurchaseBottomSheet(
        icon: Icons.bolt_rounded,
        iconColor: const Color(0xFF9B30FF),
        title: 'Profil boosten',
        subtitle:
            'Dein Profil wird für 30 Minuten ganz oben in deiner Region angezeigt. '
            'Im Schnitt bekommst du 10× mehr Matches!',
        resetDate: null,
        primaryAction: 'Jetzt für $boostPrice boosten',
        primaryPrice: boostPrice,
        onPrimary: () async {
          Navigator.pop(ctx);
          final result = await payments.purchaseConsumable(ProductIds.boost1);
          if (!mounted) return;
          if (result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('🚀 Boost aktiviert! Du bist jetzt ganz oben.',
                    style: TextStyle()),
                backgroundColor: const Color(0xFF9B30FF),
                duration: const Duration(seconds: 3),
              ),
            );
          } else if (!result.cancelled && result.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Kauf fehlgeschlagen: ${result.error}',
                    style: TextStyle()),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      ),
    );
  }

  // Herz-Wasserzeichen in der Kartenmitte, solange man nach rechts wischt
  // Die Struktur bleibt immer gleich (Stack), sonst wird die Karte beim Start/Ende
  // jeder Wisch-Bewegung neu aufgebaut und das Foto flackert schwarz.
  Widget _withSwipeWatermark(Widget card, int horizontalPercentage) {
    if (card is AdDiscoveryCard) return card;
    // Rechts: grünes Herz, links: rotes X – beide werden mit dem Wischen eingeblendet
    final isRight = horizontalPercentage > 0;
    return Stack(
      children: [
        card,
        Positioned.fill(
          child: IgnorePointer(
            child: Center(
              child: Opacity(
                opacity:
                    (horizontalPercentage.abs() / 100).clamp(0.0, 1.0) * 0.4,
                child: Icon(
                  isRight ? CupertinoIcons.heart_fill : CupertinoIcons.xmark,
                  size: 160,
                  color: isRight
                      ? const Color(0xFF2BD9A0)
                      : const Color(0xFFFF4B6E),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    // 📢 Absolut sicher prüfen, welcher Typ die aktuelle Karte wirklich ist
    bool isAd = _isShowingAd;
    if (_currentTopCardIndex >= 0 && _currentTopCardIndex < _cards.length) {
      isAd = _cards[_currentTopCardIndex] is AdDiscoveryCard;
    }

    // Wenn es Werbung ist, blenden wir die Icons komplett aus
    if (isAd)
      return const SizedBox(height: 100); // Platzhalter für die Bottom-Bar Höhe

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal:
              20), // 📢 Keine vertikale Padding mehr nötig da Positioned
      child: Row(
        mainAxisAlignment: isAd
            ? MainAxisAlignment.spaceAround
            : MainAxisAlignment.spaceEvenly,
        children: [
          // Rewind – nur bei Profilen
          if (!isAd)
            _SwipeActionButton(
              icon: CupertinoIcons.arrow_counterclockwise,
              color: const Color(0xFFFFB400),
              size: 45,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Rewind ist ein Premium-Feature.'),
                    backgroundColor: const Color(0xFF2A2A2C),
                  ),
                );
              },
            ),
          // ❌ Nope
          Transform.translate(
            offset: Offset.zero,
            child: _SwipeActionButton(
              icon: CupertinoIcons.xmark,
              color: const Color(0xFFFF4B6E),
              size: 62,
              onPressed: () => _controller.swipe(CardSwiperDirection.left),
            ),
          ),
          // Super Like – nur bei Profilen
          if (!isAd)
            Stack(
              clipBehavior: Clip.none,
              children: [
                _SwipeActionButton(
                  icon: CupertinoIcons.star_fill,
                  color: (_purchasedSuperLikes > 0 || _freeSuperLikesLeft > 0)
                      ? const Color(0xFF3FA7FF)
                      : context.fgA(0.3),
                  size: 45,
                  onPressed: _onSuperLike,
                ),
                if (_purchasedSuperLikes > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF9B30FF),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$_purchasedSuperLikes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          // ❤️ Like / Ad öffnen
          Transform.translate(
            offset: Offset.zero,
            child: _SwipeActionButton(
              icon: CupertinoIcons.heart_fill,
              color: const Color(0xFF2BD9A0),
              size: 62,
              onPressed: () => _controller.swipe(CardSwiperDirection.right),
            ),
          ),
          // Boost – nur bei Profilen
          if (!isAd)
            _SwipeActionButton(
              icon: CupertinoIcons.bolt_fill,
              color: const Color(0xFF9B30FF),
              size: 45,
              onPressed: _showBoostPurchaseDialog,
            ),
        ],
      ),
    );
  }

  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _SearchSheet(
        students: mockStudents,
        onStudentTap: (student) {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            studentProfileRoute(
              StudentProfilePage(student: student, isDatingMode: _isDatingMode),
            ),
          );
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => AnimatedPadding(
          duration: const Duration(milliseconds: 150),
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: BoxDecoration(
              color: context.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: context.fg,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Abbrechen',
                          style: TextStyle(color: context.fgA(0.54))),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                _FilterSection(
                  title: 'Max. Distanz: ${_maxDistance.round()} km',
                  child: Slider(
                    value: _maxDistance,
                    max: 200,
                    divisions: 40,
                    activeColor: const Color(0xFF9B30FF),
                    inactiveColor: context.fgA(0.1),
                    onChanged: (v) {
                      setSheetState(() => _maxDistance = v);
                      setState(() {}); // Update main page if needed
                    },
                  ),
                ),
                const SizedBox(height: 25),
                _FilterSection(
                  title:
                      'Alter: ${_ageRange.start.round()} - ${_ageRange.end.round()}',
                  child: RangeSlider(
                    values: _ageRange,
                    max: 40,
                    min: 18,
                    divisions: 22,
                    activeColor: const Color(0xFF9B30FF),
                    inactiveColor: context.fgA(0.1),
                    onChanged: (v) {
                      setSheetState(() => _ageRange = v);
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 30),
                _FilterSection(
                  title: 'Stadt',
                  child: TextField(
                    controller: _cityCtrl,
                    style: TextStyle(color: context.fg),
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'Stadt eingeben, z. B. Berlin',
                      hintStyle: TextStyle(color: context.fgA(0.4)),
                      prefixIcon: Icon(CupertinoIcons.search,
                          size: 18, color: context.fgA(0.5)),
                      filled: true,
                      fillColor: context.fgA(0.08),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    onChanged: (v) => _cityFilter = v.trim(),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _cards = _buildCardList();
                        _currentTopCardIndex = 0;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9B30FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Filter anwenden',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setMode(String mode) => setState(() {
        _discoveryMode = mode;
        _cards = _buildCardList();
        _controller.moveTo(0); // Karten zurücksetzen
      });

  @override
  Widget build(BuildContext context) {
    // Rebuild, wenn sich der Super-Like-Stand im Profil ändert
    ref.watch(userProfileProvider.select((u) => u?.superLikes));
    final topFg = _cards.isEmpty ? context.fg : Colors.white;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(kToolbarHeight + MediaQuery.paddingOf(context).top),
        child: GlassTopBar(
          fg: topFg,
          mode: _discoveryMode,
          onFilter: () => _showFilterSheet(context),
          onSearch: () => _showSearchSheet(context),
          onWg: () async {
            // Die WG-Seite meldet beim Zurückwechseln den gewählten Modus
            final mode = await Navigator.push<String>(context,
                MaterialPageRoute(builder: (_) => const WgListingsPage()));
            if (mode != null && mounted) _setMode(mode);
          },
          onMode: _setMode,
        ),
      ),
      body: Container(
        color: context.bg,
        child: SafeArea(
          top: false, // Vollbild: das Foto reicht bis zur Statusleiste
          bottom: false, // 📢 Maximal nach unten versetzen
          child: Stack(children: [
            Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (_cards.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: context.fgA(0.06),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                      CupertinoIcons
                                          .person_crop_circle_badge_xmark,
                                      size: 40,
                                      color: context.fgA(0.6)),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Keine Profile gefunden',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: context.fg),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'In deiner ausgewählten Stadt-, Alters- oder Distanz-Auswahl gibt es gerade keine passenden Profile.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: context.fgA(0.6),
                                      fontSize: 14,
                                      height: 1.4),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _maxDistance = 200;
                                      _ageRange = const RangeValues(18, 40);
                                      _cityFilter = '';
                                      _cityCtrl.clear();
                                      _cards = _buildCardList();
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF9B30FF),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Filter zurücksetzen'),
                                ),
                              ],
                            ),
                          ),
                        )
                      else ...[
                        // Die Karten nehmen nun den maximalen Platz ein
                        Padding(
                          padding: EdgeInsets
                              .zero, // Vollbild: kein Rand um die Karte
                          child: CardSwiper(
                            controller: _controller,
                            onSwipe: _onSwipe,
                            onEnd: () => setState(() => _isShowingAd = false),
                            // Nächste Karte liegt in voller Größe direkt hinter der
                            // obersten und wird beim Ziehen sichtbar (wie Tinder)
                            numberOfCardsDisplayed:
                                _cards.length < 2 ? _cards.length : 2,
                            scale: 1.0,
                            backCardOffset: Offset.zero,
                            padding: EdgeInsets.zero,
                            cardBuilder: (context,
                                    index,
                                    horizontalThresholdPercentage,
                                    verticalThresholdPercentage) =>
                                _withSwipeWatermark(_cards[index],
                                    horizontalThresholdPercentage),
                            cardsCount: _cards.length,
                          ),
                        ),
                        // Die Buttons schweben nun über dem unteren Teil der Karte
                        Positioned(
                          bottom: 94,
                          left: 0,
                          right: 0,
                          child: _buildActionButtons(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: BottomNavBar(),
            ),
          ]),
        ),
      ),
    );
  }
}

/// Obere Leiste: Filter, Modus-Auswahl mit gleitender Glas-Linse und Suche –
/// alles in einer gemeinsamen Liquid-Glass-Ebene (ein Backdrop-Sample).
class GlassTopBar extends StatelessWidget {
  const GlassTopBar({
    super.key,
    required this.fg,
    required this.mode,
    required this.onFilter,
    required this.onWg,
    required this.onMode,
    this.onSearch,
    this.wgActive = false,
  });

  final Color fg;
  final String mode;
  final VoidCallback onFilter;
  final VoidCallback? onSearch;
  final VoidCallback onWg;

  /// Auf der Seite „WG & Zimmer“ ist dieser Tab aktiv statt Dating/Study Buddy.
  final bool wgActive;
  final ValueChanged<String> onMode;

  static const double _h = 30;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    Widget tab(String text, VoidCallback onTap, bool active) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.center,
            height: _h,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: active ? Colors.black.withValues(alpha: 0.3) : null,
              borderRadius: BorderRadius.circular(_h / 2),
              border: active
                  ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                  : null,
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? fg : fg.withValues(alpha: 0.9),
              ),
            ),
          ),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(12, top + (kToolbarHeight - _h) / 2, 12, 0),
      child: SizedBox(
        height: _h,
        child: Row(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onFilter,
              child: SizedBox.square(
                dimension: _h,
                child: Center(child: SlidersIcon(color: fg, size: 20)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              // Rechter Rand blendet aus, da die Tabs weiter scrollen
              child: ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  colors: [Colors.white, Colors.white, Colors.transparent],
                  stops: [0, 0.85, 1],
                ).createShader(r),
                blendMode: BlendMode.dstIn,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      tab('Dating', () => onMode('Dating'),
                          !wgActive && mode != 'Study Buddy'),
                      tab('Study Buddy', () => onMode('Study Buddy'),
                          !wgActive && mode == 'Study Buddy'),
                      tab('WG & Zimmer', onWg, wgActive),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onSearch,
              child: SizedBox.square(
                dimension: _h,
                child: onSearch == null
                    ? null
                    : Center(
                        child: Icon(CupertinoIcons.search, color: fg, size: 20),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onPressed;

  const _SwipeActionButton(
      {required this.icon,
      required this.color,
      required this.size,
      required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return _GlassButton(
      size: size,
      onTap: onPressed,
      child: Icon(icon, color: color, size: size * 0.44),
    );
  }
}

/// Runder Liquid-Glass-Button (iOS 27) – gleiche Optik wie die Tab-Leiste.
class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.child,
    required this.onTap,
    this.size = 44,
  });

  final Widget child;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: LiquidGlass.withOwnLayer(
          settings: LiquidGlassSettings.ios27Regular(
              brightness: Brightness.dark, tintAmount: 1),
          appearance: LiquidGlassAppearance.ios27Regular(
              brightness: Brightness.dark, tint: Colors.transparent),
          shape: LiquidRoundedSuperellipse(borderRadius: size / 2),
          child: Container(
            color: Colors.transparent,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Helligkeit (0 = dunkel, 1 = hell) des unteren Fotobereichs hinter der
/// Tab-Leiste. Die Leiste passt Glas und Icon-Farbe automatisch daran an.
final ValueNotifier<double> navBackdropLuminance = ValueNotifier<double>(0);

Future<double?> _bottomLuminance(ImageProvider provider) async {
  final completer = Completer<ui.Image?>();
  final stream =
      ResizeImage(provider, width: 48).resolve(ImageConfiguration.empty);
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) {
      if (!completer.isCompleted) completer.complete(info.image);
      stream.removeListener(listener);
    },
    onError: (_, __) {
      if (!completer.isCompleted) completer.complete(null);
      stream.removeListener(listener);
    },
  );
  stream.addListener(listener);
  final image = await completer.future;
  if (image == null) return null;
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;
  final w = image.width, h = image.height;
  var sum = 0.0;
  var count = 0;
  for (var y = (h * 0.78).floor(); y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = (y * w + x) * 4;
      sum += 0.299 * data.getUint8(i) +
          0.587 * data.getUint8(i + 1) +
          0.114 * data.getUint8(i + 2);
      count++;
    }
  }
  return count == 0 ? null : sum / count / 255;
}

class DiscoveryCard extends StatefulWidget {
  final Student student;
  final CardSwiperController controller;
  final bool isDatingMode;
  final VoidCallback onSuperLike;
  final Widget Function()? backdropBuilder;
  final bool reportBackdrop;
  const DiscoveryCard(
      {super.key,
      this.backdropBuilder,
      this.reportBackdrop = true,
      required this.student,
      required this.controller,
      required this.isDatingMode,
      required this.onSuperLike});

  @override
  State<DiscoveryCard> createState() => _DiscoveryCardState();
}

class _DiscoveryCardState extends State<DiscoveryCard> {
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _reportLuminance();
  }

  @override
  void didUpdateWidget(covariant DiscoveryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.student.id != widget.student.id) {
      _currentImageIndex = 0;
      _reportLuminance();
    }
  }

  Future<void> _reportLuminance() async {
    if (!widget.reportBackdrop || widget.student.images.isEmpty) return;
    final index = _currentImageIndex;
    final id = widget.student.id;
    try {
      final lum =
          await _bottomLuminance(NetworkImage(widget.student.images[index]));
      if (lum == null || !mounted) return;
      if (index != _currentImageIndex || id != widget.student.id) return;
      navBackdropLuminance.value = lum;
    } on Exception {
      // Bei Ladefehler bleibt die letzte (dunkle) Standardleiste.
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.student.images.length - 1) {
      setState(() {
        _currentImageIndex++;
      });
      _reportLuminance();
    }
  }

  void _previousImage() {
    if (_currentImageIndex > 0) {
      setState(() {
        _currentImageIndex--;
      });
      _reportLuminance();
    }
  }

  Widget _cardLine(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(icon,
                  size: 16, color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );

  Widget _cardChip(IconData icon, String value) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.w500)),
        ],
      );

  Widget _chipWrap(List<Widget> chips) => Wrap(
        spacing: 16,
        runSpacing: 10,
        children: chips,
      );

  Future<void> _openProfile() async {
    // Like-Buttons auf der Profilseite geben die Richtung zurück
    final direction = await Navigator.push<CardSwiperDirection>(
      context,
      studentProfileRoute(
        StudentProfilePage(
          student: widget.student,
          backdropBuilder: widget.backdropBuilder,
          isDatingMode: widget.isDatingMode,
          initialImageIndex: _currentImageIndex,
        ),
      ),
    );
    if (!mounted || direction == null) return;
    if (direction == CardSwiperDirection.none) {
      widget.onSuperLike();
    } else {
      widget.controller.swipe(direction);
    }
  }

  /// Abschnitte, die nur bei vorhandenen Daten erscheinen.
  /// Foto 2 -> erster Abschnitt, Foto 3 -> zweiter usw.
  List<Widget> _sections() {
    final st = widget.student;
    final list = <Widget>[];
    if (st.bio.trim().isNotEmpty) {
      list.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(st.bio,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16, color: Colors.white, height: 1.35)),
      ]));
    }
    final details = <Widget>[
      if (st.gender != null && st.gender!.isNotEmpty)
        _cardChip(CupertinoIcons.person, st.gender!),
      if (st.orientation != null && st.orientation!.isNotEmpty)
        _cardChip(CupertinoIcons.compass, st.orientation!),
      if (st.zodiac != null && st.zodiac!.isNotEmpty)
        _cardChip(CupertinoIcons.sparkles, st.zodiac!),
      if (st.languages.isNotEmpty)
        _cardChip(CupertinoIcons.globe, st.languages.join(', ')),
    ];
    if (details.isNotEmpty) {
      list.add(_chipWrap(details));
    }
    if (st.lifestyle.isNotEmpty) {
      list.add(_chipWrap(st.lifestyle.entries
          .map((e) => _cardChip(lifestyleIcon(e.key), e.value))
          .toList()));
    }
    if (st.interests.isNotEmpty) {
      list.add(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: st.interests
              .map((i) => _InterestBadge(label: interestWithEmoji(i)))
              .toList(),
        ),
      ]));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    final Widget? section =
        (_currentImageIndex >= 1 && _currentImageIndex - 1 < sections.length)
            ? sections[_currentImageIndex - 1]
            : null;
    return Container(
      color: const Color(0xFF0F0B24),
      child: ClipRect(
        child: Stack(
          children: [
            // Image
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2140),
                image: DecorationImage(
                  image:
                      NetworkImage(widget.student.images[_currentImageIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Image Switching Tap Areas
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _previousImage,
                    child: Container(),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _nextImage,
                    child: Container(),
                  ),
                ),
              ],
            ),

            // Foto-Indikator: kleine Punkte unter der Glas-Leiste
            if (widget.student.images.length > 1)
              Positioned(
                top: MediaQuery.paddingOf(context).top - 2,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0;
                        index < widget.student.images.length;
                        index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: index == _currentImageIndex ? 6 : 4,
                        height: index == _currentImageIndex ? 6 : 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentImageIndex
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

            // Beziehungsstatus wird nur auf der Profilseite gezeigt

            // Bottom Info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(18, 60, 14, 176),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.5, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '${widget.student.name}, ${widget.student.age}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(
                                      CupertinoIcons.checkmark_seal_fill,
                                      color: Color(0xFF3FA7FF),
                                      size: 22,
                                    ),
                                  ],
                                ),
                                if (section == null) ...[
                                  if (widget.student.relationshipType !=
                                      null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(top: 2),
                                          child: Icon(CupertinoIcons.heart_fill,
                                              size: 16,
                                              color: Color(0xFFFF2D9B)),
                                        ),
                                        const SizedBox(width: 8),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ich suche',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                              ),
                                            ),
                                            Text(
                                              widget.student.relationshipType!,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.book_fill,
                                          size: 16,
                                          color: Colors.white
                                              .withValues(alpha: 0.7)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${widget.student.university.toUpperCase()} • ${widget.student.major.toUpperCase()}',
                                          maxLines: 2,
                                          style: TextStyle(
                                            fontSize: 14,
                                            letterSpacing: 1.2,
                                            color: Colors.white
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(CupertinoIcons.location_solid,
                                          size: 16,
                                          color: Colors.white
                                              .withValues(alpha: 0.7)),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${widget.student.city} • ${widget.student.distance} km',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.white
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else ...[
                                  const SizedBox(height: 10),
                                  section,
                                ],
                              ],
                            ),
                          ),
                          // Öffnet das Profil nur über den Pfeil
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _openProfile,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                  color: Colors.white, shape: BoxShape.circle),
                              child: Transform.rotate(
                                angle: 3.141592653589793,
                                child: const Icon(CupertinoIcons.chevron_down,
                                    color: Color(0xFF0F0B24), size: 24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.fgA(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.fgA(0.24)),
      ),
      child: Text(
        interestWithEmoji(label),
        style: TextStyle(color: context.fg, fontSize: 12),
      ),
    );
  }
}

class _BioBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isProminent;
  const _BioBadge(
      {required this.icon, required this.label, this.isProminent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isProminent
            ? Colors.purple.withValues(alpha: 0.6)
            : context.fgA(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isProminent
              ? const Color(0xFF9B30FF).withValues(alpha: 0.5)
              : context.fgA(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 14, color: isProminent ? context.fg : context.fgA(0.7)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isProminent ? FontWeight.bold : FontWeight.normal,
              color: context.fg,
            ),
          ),
        ],
      ),
    );
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({
    super.key,
    this.selected = 'home',
    this.leaveToHome = false,
    this.restricted = false,
  });

  final String selected;

  /// Eingeschränkter Zugang: nur WG & Zimmer (Home) und Profil.
  final bool restricted;

  /// Für Unterseiten von Home (z. B. WG & Zimmer): Tipp auf Home geht zurück.
  final bool leaveToHome;

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _NavTab {
  const _NavTab(this.key, this.label, this.icon, this.page, {this.badge = 0});
  final String key;
  final String label;
  final IconData icon;
  final Widget Function() page;
  final int badge;
}

class _BottomNavBarState extends State<BottomNavBar> {
  static const double _barHeight = 70;
  late int _index = _tabs.indexWhere((t) => t.key == widget.selected);

  late final List<_NavTab> _tabs = [
    _NavTab(
        'home',
        widget.restricted ? 'WG' : 'Home',
        widget.restricted
            ? CupertinoIcons.house_fill
            : CupertinoIcons.heart_fill,
        () => const SizedBox()),
    _NavTab('radar', 'Radar', CupertinoIcons.dot_radiowaves_left_right,
        () => const RadarPage()),
    _NavTab(
        'likes', 'Likes', CupertinoIcons.person_2_fill, () => const LikesPage(),
        badge: mockStudents.length),
    _NavTab('chat', 'Nachrichten', CupertinoIcons.chat_bubble_fill,
        () => const ChatListPage(),
        badge: 3),
    _NavTab('profile', 'Profil', CupertinoIcons.person_crop_circle_fill,
        () => const ProfilePage()),
  ]
      .where((t) => !widget.restricted || t.key == 'home' || t.key == 'profile')
      .toList();

  Route<void> _instantRoute(Widget page) => PageRouteBuilder<void>(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );

  void _select(int i) {
    if (i == _index) {
      if (widget.leaveToHome && _tabs[i].key == 'home') {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      return;
    }
    setState(() => _index = i);
  }

  /// Erst gleitet die Glas-Linse zum Tab, dann wird die Seite gewechselt.
  Future<void> _commit() async {
    final tab = _tabs[_index];
    if (tab.key == widget.selected) return;
    await Future<void>.delayed(const Duration(milliseconds: 260));
    if (!mounted) return;
    final nav = Navigator.of(context);
    if (tab.key == 'home') {
      nav.popUntil((route) => route.isFirst);
    } else if (widget.selected == 'home') {
      nav.push(_instantRoute(tab.page()));
    } else {
      nav.pushReplacement(_instantRoute(tab.page()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.leaveToHome) {
      final light = Theme.of(context).brightness == Brightness.light;
      return _buildBar(context, light ? 1 : 0);
    }
    if (widget.selected != 'home') return _buildBar(context, 0);
    return ValueListenableBuilder<double>(
      valueListenable: navBackdropLuminance,
      builder: (context, lum, _) => _buildBar(context, lum),
    );
  }

  Widget _buildBar(BuildContext context, double lum) {
    final onLight = lum > 0.55;
    final brightness = onLight ? Brightness.light : Brightness.dark;
    final settings =
        LiquidGlassSettings.ios27Regular(brightness: brightness, tintAmount: 0);
    final strong = onLight ? Colors.black : Colors.white;
    final weak = onLight ? Colors.black54 : Colors.white70;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(builder: (context, c) {
        final itemW = c.maxWidth / _tabs.length;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: (d) => _select(
              (d.localPosition.dx / itemW).floor().clamp(0, _tabs.length - 1)),
          onHorizontalDragEnd: (_) => _commit(),
          child: SizedBox(
            height: _barHeight,
            child: Stack(
              children: [
                Positioned.fill(
                  child: LiquidGlassCapture(
                    child: LiquidGlassLayer(
                      settings: settings,
                      defaultAppearance: LiquidGlassAppearance.ios27Regular(
                          brightness: brightness),
                      child: Stack(
                        children: [
                          const Positioned.fill(
                            child: LiquidGlass(
                              shape:
                                  LiquidRoundedSuperellipse(borderRadius: 38),
                              child: SizedBox.expand(),
                            ),
                          ),
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutBack,
                            left: _index * itemW + 4,
                            top: 4,
                            width: itemW - 8,
                            height: _barHeight - 8,
                            child: LiquidGlassLayer(
                              settings: settings,
                              defaultAppearance:
                                  LiquidGlassAppearance.ios27Regular(
                                      brightness: brightness),
                              child: const LiquidStretch(
                                child: LiquidGlass(
                                  shape: LiquidRoundedSuperellipse(
                                      borderRadius: 34),
                                  child: SizedBox.expand(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(
                        child: _NavItem(
                          tab: _tabs[i],
                          selected: i == _index,
                          strong: strong,
                          weak: weak,
                          onTap: () {
                            _select(i);
                            _commit();
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.strong,
    required this.weak,
    required this.onTap,
  });

  final _NavTab tab;
  final bool selected;
  final Color strong;
  final Color weak;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? strong : weak;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(tab.icon, size: 25, color: color),
              if (tab.badge > 0)
                Positioned(
                  top: -5,
                  right: -9,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF4B6E),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        tab.badge > 9 ? '9+' : tab.badge.toString(),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              tab.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _FilterSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
              color: context.fgA(0.7),
              fontSize: 14,
              fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 10),
        child,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  const _FilterChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF9B30FF).withValues(alpha: 0.2)
            : context.fgA(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isSelected ? const Color(0xFF9B30FF) : context.fgA(0.1)),
      ),
      child: Text(label,
          style: TextStyle(
              color: isSelected ? const Color(0xFF9B30FF) : context.fgA(0.7),
              fontSize: 13)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Purchase Bottom Sheet (Super Like & Boost)
// ─────────────────────────────────────────────────────────────────────────────
class _PurchaseBottomSheet extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final DateTime? resetDate;
  final String primaryAction;
  final String? primaryPrice;
  final VoidCallback onPrimary;
  final Widget? extraWidget;

  const _PurchaseBottomSheet({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.resetDate,
    required this.primaryAction,
    this.primaryPrice,
    required this.onPrimary,
    this.extraWidget,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomInset),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
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
          // Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.15),
              border:
                  Border.all(color: iconColor.withValues(alpha: 0.4), width: 2),
            ),
            child: Icon(icon, color: iconColor, size: 40),
          ),
          const SizedBox(height: 16),
          // Title
          Text(
            title,
            style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: context.fg),
          ),
          const SizedBox(height: 10),
          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: context.fgA(0.6), height: 1.5),
          ),
          // Reset date info
          if (resetDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.fgA(0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '🔄 Nächster kostenloser Super Like am ${resetDate!.day}.${resetDate!.month}.${resetDate!.year}',
                style: TextStyle(fontSize: 12, color: context.fgA(0.54)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          // Primary CTA Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: iconColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(27)),
                elevation: 0,
              ),
              child: Text(
                primaryAction,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.fg),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Extra Widget (z.B. Rewarded Ad Button)
          if (extraWidget != null) ...[
            extraWidget!,
            const SizedBox(height: 8),
          ],
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Vielleicht später',
              style: TextStyle(color: context.fgA(0.38), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _SearchSheet extends StatefulWidget {
  final List<Student> students;
  final ValueChanged<Student> onStudentTap;
  const _SearchSheet({required this.students, required this.onStudentTap});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Student> _results = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _results = widget.students;
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text.toLowerCase().trim();
        if (_query.isEmpty) {
          _results = widget.students;
        } else {
          _results = widget.students.where((s) {
            return s.name.toLowerCase().contains(_query) ||
                s.university.toLowerCase().contains(_query) ||
                s.major.toLowerCase().contains(_query) ||
                s.city.toLowerCase().contains(_query) ||
                s.interests.any((i) => i.toLowerCase().contains(_query));
          }).toList();
        }
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, scrollController) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
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
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: context.fgA(0.08),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                      color: const Color(0xFF9B30FF).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: context.fgA(0.54), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        style: TextStyle(color: context.fg, fontSize: 16),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Name, Uni, Studiengang, Stadt...',
                          hintStyle:
                              TextStyle(color: context.fgA(0.3), fontSize: 15),
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () => _searchController.clear(),
                        child: Icon(Icons.close,
                            color: context.fgA(0.38), size: 20),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Quick filter chips
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  'Stanford',
                  'Berkeley',
                  'MIT',
                  'Design',
                  'Kaffee',
                  'Sport',
                  'Musik'
                ]
                    .map((tag) => GestureDetector(
                          onTap: () {
                            _searchController.text = tag;
                            _searchController.selection =
                                TextSelection.fromPosition(
                              TextPosition(offset: tag.length),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9B30FF)
                                  .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF9B30FF)
                                      .withValues(alpha: 0.3)),
                            ),
                            child: Text(tag,
                                style: TextStyle(
                                    color: const Color(0xFF9B30FF),
                                    fontSize: 13)),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Divider + results count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    _query.isEmpty
                        ? 'Alle Profile'
                        : '${_results.length} Ergebnis${_results.length == 1 ? '' : 'se'}',
                    style: TextStyle(color: context.fgA(0.54), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Results
            Expanded(
              child: _results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off,
                              color: context.fgA(0.24), size: 64),
                          const SizedBox(height: 16),
                          Text('Niemanden gefunden',
                              style: TextStyle(
                                  color: context.fgA(0.38), fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('Versuche einen anderen Begriff',
                              style: TextStyle(
                                  color: context.fgA(0.24), fontSize: 13)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _results.length,
                      itemBuilder: (ctx, i) {
                        final s = _results[i];
                        return GestureDetector(
                          onTap: () => widget.onStudentTap(s),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.fgA(0.05),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: context.fgA(0.08)),
                            ),
                            child: Row(
                              children: [
                                // Avatar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.network(
                                    s.imageUrl,
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 60,
                                      height: 60,
                                      color: context.fgA(0.12),
                                      child: Icon(Icons.person,
                                          color: context.fgA(0.54)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '${s.name}, ${s.age}',
                                            style: TextStyle(
                                              color: context.fg,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (s.isPlatinum) ...[
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified,
                                                color: const Color(0xFF9B30FF),
                                                size: 16),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${s.university} · ${s.major}',
                                        style: TextStyle(
                                            color: context.fgA(0.54),
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(CupertinoIcons.location_solid,
                                              color: context.fgA(0.3),
                                              size: 12),
                                          const SizedBox(width: 3),
                                          Text(
                                            '${s.city} · ${s.distance} km',
                                            style: TextStyle(
                                                color: context.fgA(0.3),
                                                fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      // Interest tags
                                      Wrap(
                                        spacing: 6,
                                        children:
                                            s.interests.take(3).map((interest) {
                                          final isMatch = interest
                                                  .toLowerCase()
                                                  .contains(_query) &&
                                              _query.isNotEmpty;
                                          return Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isMatch
                                                  ? const Color(0xFF9B30FF)
                                                      .withValues(alpha: 0.25)
                                                  : context.fg
                                                      .withValues(alpha: 0.07),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: isMatch
                                                  ? Border.all(
                                                      color: const Color(
                                                              0xFF9B30FF)
                                                          .withValues(
                                                              alpha: 0.5))
                                                  : null,
                                            ),
                                            child: Text(
                                              interestWithEmoji(interest),
                                              style: TextStyle(
                                                color: isMatch
                                                    ? const Color(0xFF9B30FF)
                                                    : context.fgA(0.54),
                                                fontSize: 11,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right,
                                    color: context.fgA(0.24)),
                              ],
                            ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Ad Discovery Card – sieht aus wie ein Profil, ist aber Werbung
// ─────────────────────────────────────────────────────────────────────────────
class AdDiscoveryCard extends StatelessWidget {
  final AdCard ad;

  const AdDiscoveryCard({super.key, required this.ad});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F0B24),
      child: ClipRect(
        child: Stack(
          children: [
            // Hintergrundbild (wie Profilbild)
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(ad.imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 0.7, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),

            // "Gesponsert"-Badge oben links
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: ad.accentColor.withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.campaign_rounded,
                        color: ad.accentColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      ad.subtitle,
                      style: TextStyle(
                        color: ad.accentColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info-Bereich unten (Name, Beschreibung, CTA)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Firmenname
                    Text(
                      ad.title,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Beschreibung
                    Text(
                      ad.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // CTA Button
                    if (ad.ctaText != null)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: ad.accentColor,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: ad.accentColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                ad.ctaText!,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.black, size: 16),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Hinweis
                    Center(
                      child: Text(
                        '❤️ Swipe rechts um zu öffnen',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.38),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// In-App Ad Browser – öffnet die Werbung als Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _InAppAdBrowser extends StatelessWidget {
  final String url;
  const _InAppAdBrowser({required this.url});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header mit URL und Close-Button
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
                decoration: BoxDecoration(
                  color: context.fgA(0.05),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    // Drag Handle
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.fgA(0.24),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // URL
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.fgA(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline,
                                color: Colors.greenAccent, size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                url,
                                style: TextStyle(
                                    color: context.fgA(0.54), fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Close
                    IconButton(
                      icon: Icon(Icons.close, color: context.fgA(0.54)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Platzhalter für echten WebView
              // ⚠️ TODO: Ersetze durch WebViewWidget wenn webview_flutter installiert ist
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.language_rounded,
                          color: context.fgA(0.24), size: 60),
                      const SizedBox(height: 16),
                      Text(
                        'Wird geladen...',
                        style:
                            TextStyle(color: context.fgA(0.54), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        url,
                        style:
                            TextStyle(color: context.fgA(0.24), fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '⚠️ WebView-Stub aktiv\nwebview_flutter installieren für echtes Browsing',
                        style:
                            TextStyle(color: context.fgA(0.12), fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
