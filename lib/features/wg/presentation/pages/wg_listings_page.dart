import 'dart:io';
import 'dart:math' as math;
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/core/widgets/glass_button.dart';
import 'package:camp_meet/features/discovery/presentation/pages/discovery_page.dart'
    show BottomNavBar, GlassTopBar;
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/features/profile/presentation/pages/profile_page.dart';
import 'package:camp_meet/features/wg/data/wg_listing.dart';
import 'package:camp_meet/features/wg/data/wg_repository.dart';
import 'package:camp_meet/features/wg/presentation/pages/wg_detail_page.dart';
import 'package:camp_meet/features/wg/presentation/pages/wg_form_page.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoActivityIndicator,
        CupertinoAlertDialog,
        CupertinoButton,
        CupertinoDialogAction,
        showCupertinoDialog,
        CupertinoIcons,
        CupertinoSlider,
        CupertinoSwitch,
        CupertinoTextField,
        OverlayVisibilityMode,
        showCupertinoModalPopup;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

ImageProvider wgImage(String url) {
  if (url.startsWith('http')) return NetworkImage(url);
  return FileImage(File(url));
}

class WgListingsPage extends ConsumerStatefulWidget {
  const WgListingsPage({super.key});
  @override
  ConsumerState<WgListingsPage> createState() => _WgListingsPageState();
}

class _WgListingsPageState extends ConsumerState<WgListingsPage> {
  bool _mine = false;
  String _city = 'Alle';
  String _district = ''; // leer = alle Stadtteile
  double? _maxRent; // null = kein Limit
  String _availability = 'Alle';
  static const _availOptions = [
    'Alle',
    'Sofort',
    'Innerhalb 30 Tage',
    'Später'
  ];

  bool _matchesFilter(WgListing l) {
    if (_city != 'Alle' &&
        !l.city.toLowerCase().contains(_city.trim().toLowerCase())) {
      return false;
    }
    if (_district.isNotEmpty &&
        !l.district.toLowerCase().contains(_district.toLowerCase())) {
      return false;
    }
    if (_maxRent != null && l.warmRent > _maxRent!) return false;
    final days = l.availableFrom.difference(DateTime.now()).inDays;
    switch (_availability) {
      case 'Sofort':
        return !l.availableFrom.isAfter(DateTime.now());
      case 'Innerhalb 30 Tage':
        return days <= 30;
      case 'Später':
        return days > 30;
    }
    return true;
  }

  bool get _filtered =>
      _city != 'Alle' ||
      _district.isNotEmpty ||
      _maxRent != null ||
      _availability != 'Alle';

  void _showLockedDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Nur für verifizierte Studierende'),
        content: const Text(
            'Dating und Study Buddy sind erst nach der Verifizierung verfügbar. Bis dahin kannst du WG & Zimmer nutzen. Verifiziere dich in deinem Profil mit deiner Uni-Mail oder deinem Studentenausweis.'),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text('Später')),
          CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()));
              },
              child: const Text('Zum Profil')),
        ],
      ),
    );
  }

  void _create() {
    final me = ref.read(userProfileProvider);
    if (me == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte melde dich an, um eine Anzeige zu erstellen.')));
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const WgFormPage()));
  }

  Widget _pill(
      BuildContext ctx, String label, bool selected, VoidCallback onTap) {
    return GlassButton(
      height: 36,
      tint: selected ? ctx.fg : null,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: onTap,
      child: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: ctx.fg)),
    );
  }

  void _openFilter(List<String> cities) {
    var city = _city;
    var district = _district;
    final districtCtrl = TextEditingController(text: _district);
    final cityCtrl = TextEditingController(text: _city == 'Alle' ? '' : _city);
    var rent = _maxRent ?? 1500;
    var noLimit = _maxRent == null;
    var avail = _availability;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Material(
          color: ctx.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                20 +
                    math.max(MediaQuery.of(ctx).padding.bottom,
                        MediaQuery.of(ctx).viewInsets.bottom)),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                          color: ctx.fgA(0.25),
                          borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  Text('Filter',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: ctx.fg)),
                  const SizedBox(height: 16),
                  Text('Stadt', style: TextStyle(color: ctx.fgA(0.7))),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: cityCtrl,
                    placeholder: 'Stadt eingeben',
                    prefix: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(CupertinoIcons.search,
                          size: 18, color: ctx.fgA(0.5)),
                    ),
                    style: TextStyle(color: ctx.fg),
                    placeholderStyle: TextStyle(color: ctx.fgA(0.4)),
                    decoration: BoxDecoration(
                        color: ctx.fgA(0.08),
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    onChanged: (v) =>
                        setS(() => city = v.trim().isEmpty ? 'Alle' : v.trim()),
                  ),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final c in ['Alle', ...cities])
                      _pill(ctx, c, city == c, () {
                        cityCtrl.text = c == 'Alle' ? '' : c;
                        setS(() => city = c);
                      }),
                  ]),
                  const SizedBox(height: 16),
                  Text('Stadtteil', style: TextStyle(color: ctx.fgA(0.7))),
                  const SizedBox(height: 8),
                  CupertinoTextField(
                    controller: districtCtrl,
                    placeholder: 'Stadtteil eingeben',
                    style: TextStyle(color: ctx.fg),
                    placeholderStyle: TextStyle(color: ctx.fgA(0.4)),
                    decoration: BoxDecoration(
                        color: ctx.fgA(0.08),
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    onChanged: (v) => district = v.trim(),
                  ),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: Text(
                            noLimit
                                ? 'Max. Warmmiete: egal'
                                : 'Max. Warmmiete: ${rent.round()} €',
                            style: TextStyle(color: ctx.fgA(0.7)))),
                    CupertinoSwitch(
                        value: !noLimit,
                        onChanged: (v) => setS(() => noLimit = !v)),
                  ]),
                  CupertinoSlider(
                    min: 200,
                    max: 2000,
                    divisions: 36,
                    value: rent.clamp(200, 2000).toDouble(),
                    onChanged: noLimit ? null : (v) => setS(() => rent = v),
                  ),
                  const SizedBox(height: 8),
                  Text('Verfügbarkeit', style: TextStyle(color: ctx.fgA(0.7))),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final a in _availOptions)
                      _pill(ctx, a, avail == a, () => setS(() => avail = a)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: GlassButton(
                        height: 48,
                        onTap: () {
                          setState(() {
                            _city = 'Alle';
                            _district = '';
                            _maxRent = null;
                            _availability = 'Alle';
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text('Zurücksetzen',
                            style: TextStyle(
                                color: ctx.fg, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GlassButton(
                        height: 48,
                        tint: ctx.fg,
                        onTap: () {
                          setState(() {
                            _city = city;
                            _district = district;
                            _maxRent = noLimit ? null : rent;
                            _availability = avail;
                          });
                          Navigator.pop(ctx);
                        },
                        child: Text('Anwenden',
                            style: TextStyle(
                                color: ctx.fg, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    ).whenComplete(
        () => Future<void>.delayed(const Duration(milliseconds: 500), () {
              cityCtrl.dispose();
              districtCtrl.dispose();
            }));
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(wgProvider);
    final me = ref.watch(userProfileProvider);
    final restricted = ref.watch(restrictedAccessProvider);
    final active = activeListings(st);
    final cities = {for (final l in active) l.city}.toList()..sort();
    final shown = _mine
        ? (me == null ? <WgListing>[] : ownListings(st, me.id))
        : active.where(_matchesFilter).toList();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: PreferredSize(
        preferredSize:
            Size.fromHeight(kToolbarHeight + MediaQuery.paddingOf(context).top),
        child: GlassTopBar(
          fg: context.fg,
          mode: 'Dating',
          wgActive: true,
          onFilter: () {
            if (!_mine) _openFilter(cities);
          },
          onWg: () {},
          onMode: (m) =>
              restricted ? _showLockedDialog() : Navigator.pop(context, m),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: GlassButton(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          onTap: _create,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(CupertinoIcons.plus, color: context.fg, size: 20),
            const SizedBox(width: 8),
            Text('Anzeige',
                style:
                    TextStyle(color: context.fg, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
      body: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: GlassSegmented(
                tint: context.fg,
                labels: const ['Suchen', 'Meine Anzeigen'],
                selected: _mine ? 1 : 0,
                inactiveColor: context.fg,
                onChanged: (i) {
                  // Erneutes Tippen auf "Suchen" öffnet die Filter
                  if (i == 0 && !_mine) {
                    _openFilter(cities);
                    return;
                  }
                  setState(() => _mine = i == 1);
                },
              ),
            ),
          ),
          Expanded(child: _body(st, shown, me?.id)),
        ]),
        Positioned(
          bottom: 12,
          left: 0,
          right: 0,
          child: BottomNavBar(leaveToHome: true, restricted: restricted),
        ),
      ]),
    );
  }

  Widget _body(WgState st, List<WgListing> shown, String? myId) {
    if (!st.loaded) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (st.error != null) {
      return _message(CupertinoIcons.exclamationmark_circle, st.error!,
          action: CupertinoButton(
              onPressed: () => ref.read(wgProvider.notifier).load(),
              child: const Text('Erneut versuchen')));
    }
    if (_mine && myId == null) {
      return _message(CupertinoIcons.lock_fill,
          'Melde dich an, um deine Anzeigen zu verwalten.');
    }
    if (shown.isEmpty) {
      return _mine
          ? _message(
              CupertinoIcons.house_fill, 'Du hast noch keine Anzeige erstellt.',
              action: CupertinoButton.filled(
                  onPressed: _create, child: const Text('Anzeige erstellen')))
          : _message(
              CupertinoIcons.search,
              _filtered
                  ? 'Keine Zimmer für diese Filter gefunden.'
                  : 'Aktuell gibt es keine aktiven Anzeigen.',
              action: _filtered
                  ? CupertinoButton(
                      onPressed: () => setState(() {
                            _city = 'Alle';
                            _district = '';
                            _maxRent = null;
                            _availability = 'Alle';
                          }),
                      child: const Text('Filter zurücksetzen'))
                  : null);
    }
    return RefreshIndicator(
      onRefresh: () => ref.read(wgProvider.notifier).load(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 170),
        itemCount: shown.length,
        separatorBuilder: (_, __) => const SizedBox(height: 14),
        itemBuilder: (_, i) => WgCard(listing: shown[i], showStatus: _mine),
      ),
    );
  }

  Widget _message(IconData icon, String text, {Widget? action}) => ListView(
        children: [
          const SizedBox(height: 120),
          Icon(icon, size: 56, color: context.fgA(0.3)),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(text,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: context.fgA(0.6))),
          ),
          if (action != null) Center(child: action),
        ],
      );
}

class WgCard extends StatelessWidget {
  final WgListing listing;
  final bool showStatus;
  const WgCard({super.key, required this.listing, this.showStatus = false});

  @override
  Widget build(BuildContext context) {
    final l = listing;
    String? badge;
    if (showStatus) {
      badge = l.status == WgStatus.rented
          ? 'Vergeben'
          : (l.isExpired() ? 'Abgelaufen' : null);
    }
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => WgDetailPage(listingId: l.id))),
      child: Container(
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Stack(children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: l.images.isEmpty
                  ? Container(
                      color: context.fgA(0.08),
                      child: Icon(CupertinoIcons.bed_double_fill,
                          size: 48, color: context.fgA(0.3)))
                  : Image(
                      image: wgImage(l.images.first),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                          color: context.fgA(0.08),
                          child: Icon(CupertinoIcons.photo,
                              color: context.fgA(0.3)))),
            ),
            Positioned(
              left: 10,
              top: 10,
              child: _pill(l.isTemporary ? 'Zwischenmiete' : 'Unbefristet'),
            ),
            if (badge != null)
              Positioned(right: 10, top: 10, child: _pill(badge, warn: true)),
          ]),
          Padding(
            padding: const EdgeInsets.all(14),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: context.fg)),
              const SizedBox(height: 4),
              Text(l.district.isEmpty ? l.city : '${l.city} · ${l.district}',
                  style: TextStyle(color: context.fgA(0.6))),
              const SizedBox(height: 10),
              Wrap(spacing: 14, runSpacing: 6, children: [
                _fact(context, CupertinoIcons.money_euro_circle,
                    '${l.warmRent} € warm'),
                _fact(context, CupertinoIcons.arrow_up_left_arrow_down_right,
                    '${l.sizeSqm} m²'),
                _fact(context, CupertinoIcons.calendar,
                    'ab ${wgDate(l.availableFrom)}'),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _pill(String t, {bool warn = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: warn ? const Color(0xFFFF4B6E) : Colors.black54,
            borderRadius: BorderRadius.circular(14)),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
      );

  Widget _fact(BuildContext c, IconData i, String t) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(i, size: 16, color: c.fgA(0.6)),
        const SizedBox(width: 4),
        Text(t,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: c.fg)),
      ]);
}
