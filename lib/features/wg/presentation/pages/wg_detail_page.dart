import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/core/widgets/glass_button.dart';
import 'package:camp_meet/features/chat/presentation/pages/chat_detail_page.dart';
import 'package:camp_meet/features/discovery/data/matches_repository.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';
import 'package:camp_meet/features/discovery/presentation/pages/student_profile_page.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/features/wg/data/wg_listing.dart';
import 'package:camp_meet/features/wg/data/wg_repository.dart';
import 'package:camp_meet/features/wg/presentation/pages/wg_form_page.dart';
import 'package:camp_meet/features/wg/presentation/pages/wg_listings_page.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoActionSheet,
        CupertinoActionSheetAction,
        CupertinoAlertDialog,
        CupertinoDialogAction,
        CupertinoIcons,
        showCupertinoDialog,
        showCupertinoModalPopup;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WgDetailPage extends ConsumerStatefulWidget {
  final String listingId;
  const WgDetailPage({super.key, required this.listingId});
  @override
  ConsumerState<WgDetailPage> createState() => _WgDetailPageState();
}

class _WgDetailPageState extends ConsumerState<WgDetailPage> {
  int _page = 0;

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Student? _ownerStudent(WgListing l) {
    for (final s in mockStudents) {
      if (s.id == l.ownerId) return s;
    }
    return null;
  }

  Future<void> _contact(WgListing l) async {
    final owner = _ownerStudent(l);
    if (owner == null) {
      _snack('Das Profil der inserierenden Person ist nicht verfügbar.');
      return;
    }
    await ref.read(matchesProvider.notifier).addMatch(owner);
    if (!mounted) return;
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => ChatDetailPage(student: owner)));
  }

  Future<void> _report(WgListing l) async {
    final reason = await showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text('Anzeige melden'),
        actions: [
          for (final r in kWgReportReasons)
            CupertinoActionSheetAction(
                onPressed: () => Navigator.pop(ctx, r), child: Text(r)),
        ],
        cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen')),
      ),
    );
    if (reason == null) return;
    await ref.read(wgProvider.notifier).report(l.id, reason);
    if (!mounted) return;
    _snack('Danke für deine Meldung. Die Anzeige wird für dich ausgeblendet.');
    Navigator.pop(context);
  }

  Future<bool> _confirm(String title, String text, String ok) async {
    final r = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          CupertinoDialogAction(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Abbrechen')),
          CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ok)),
        ],
      ),
    );
    return r ?? false;
  }

  Widget _backButton() => Align(
        child: GlassButton(
          width: 40,
          height: 40,
          onTap: () => Navigator.maybePop(context),
          child: Icon(CupertinoIcons.back, color: context.fg, size: 20),
        ),
      );

  Widget _glassLabel(String t, {Color? color}) => Text(t,
      style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color ?? context.fg));

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(wgProvider);
    final me = ref.watch(userProfileProvider);
    final matches = st.listings.where((x) => x.id == widget.listingId);
    if (matches.isEmpty) {
      return Scaffold(
        backgroundColor: context.bg,
        appBar: AppBar(
            backgroundColor: context.bg,
            foregroundColor: context.fg,
            elevation: 0,
            leadingWidth: 64,
            leading: _backButton()),
        body: Center(
            child: Text('Diese Anzeige existiert nicht mehr.',
                style: TextStyle(color: context.fgA(0.6)))),
      );
    }
    final l = matches.first;
    final isOwner = me != null && me.id == l.ownerId;
    final notify = ref.read(wgProvider.notifier);
    final owner = _ownerStudent(l);
    final unavailable = !l.isActive();

    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        foregroundColor: context.fg,
        elevation: 0,
        leadingWidth: 64,
        leading: _backButton(),
        actions: [
          if (!isOwner)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GlassButton(
                  width: 40,
                  height: 40,
                  onTap: () => _report(l),
                  child: Icon(CupertinoIcons.flag_fill,
                      color: context.fg, size: 18),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: isOwner
              ? _ownerActions(l, me.id, notify)
              : _contactBar(l, unavailable),
        ),
      ),
      body: ListView(padding: const EdgeInsets.only(bottom: 24), children: [
        _gallery(l),
        Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (unavailable)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFFFF4B6E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Text(
                    l.status == WgStatus.rented
                        ? 'Dieses Zimmer ist bereits vergeben.'
                        : 'Diese Anzeige ist abgelaufen.',
                    style: const TextStyle(
                        color: const Color(0xFFFF4B6E),
                        fontWeight: FontWeight.bold)),
              ),
            Text(l.title,
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.fg)),
            const SizedBox(height: 4),
            Text(l.district.isEmpty ? l.city : '${l.city} · ${l.district}',
                style: TextStyle(fontSize: 16, color: context.fgA(0.6))),
            const SizedBox(height: 16),
            _section('Kosten'),
            _row('Warmmiete', '${l.warmRent} € / Monat'),
            _row('Kaution',
                l.deposit == null ? 'keine Angabe' : '${l.deposit} €'),
            _section('Zimmer & Zeitraum'),
            _row('Zimmergröße', '${l.sizeSqm} m²'),
            _row('Mitbewohner', '${l.flatmates}'),
            _row('Einzug ab', wgDate(l.availableFrom)),
            _row('Mietart', l.isTemporary ? 'Zwischenmiete' : 'Unbefristet'),
            if (l.isTemporary) _row('Bis', wgDate(l.availableUntil!)),
            _section('Das Zimmer'),
            Text(l.roomDescription,
                style: TextStyle(height: 1.4, color: context.fg)),
            if (l.flatDescription.isNotEmpty) ...[
              _section('Das WG-Leben'),
              Text(l.flatDescription,
                  style: TextStyle(height: 1.4, color: context.fg)),
            ],
            if (l.amenities.isNotEmpty) ...[
              _section('Ausstattung'),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final a in l.amenities)
                  GlassButton(
                    height: 34,
                    onTap: null,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(a,
                        style: TextStyle(fontSize: 14, color: context.fg)),
                  ),
              ]),
            ],
            _section('Inseriert von'),
            _ownerCard(isOwner, me?.name, me?.avatarUrl, me?.university, owner),
            const SizedBox(height: 8),
            Text(
                unavailable
                    ? ''
                    : 'Läuft in ${l.daysLeft()} Tagen ab · genaue Adresse nach Absprache im Chat.',
                style: TextStyle(fontSize: 12, color: context.fgA(0.5))),
          ]),
        ),
      ]),
    );
  }

  Widget _gallery(WgListing l) {
    if (l.images.isEmpty) {
      return Container(
          height: 220,
          color: context.fgA(0.08),
          child: Icon(CupertinoIcons.bed_double_fill,
              size: 56, color: context.fgA(0.3)));
    }
    return SizedBox(
      height: 260,
      child: Stack(children: [
        PageView.builder(
          itemCount: l.images.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) => Image(
              image: wgImage(l.images[i]),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                  color: context.fgA(0.08),
                  child: Icon(CupertinoIcons.photo, color: context.fgA(0.3)))),
        ),
        if (l.images.length > 1)
          Positioned(
            bottom: 10,
            left: 0,
            right: 0,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < l.images.length; i++)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _page ? Colors.white : Colors.white54),
                ),
            ]),
          ),
      ]),
    );
  }

  Widget _section(String t) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: context.fg)),
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Expanded(child: Text(k, style: TextStyle(color: context.fgA(0.6)))),
          Text(v,
              style: TextStyle(fontWeight: FontWeight.w600, color: context.fg)),
        ]),
      );

  Widget _ownerCard(bool isOwner, String? myName, String? myAvatar,
      String? myUni, Student? owner) {
    final name = isOwner ? (myName ?? 'Du') : (owner?.name ?? 'Unbekannt');
    final avatar = isOwner ? myAvatar : owner?.imageUrl;
    final sub = isOwner
        ? (myUni ?? '')
        : (owner == null ? '' : '${owner.university} · ${owner.major}');
    return GestureDetector(
      onTap: owner == null || isOwner
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      StudentProfilePage(student: owner, isDatingMode: false))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: context.card, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          CircleAvatar(
              radius: 26,
              backgroundColor: context.fgA(0.1),
              backgroundImage:
                  (avatar == null || avatar.isEmpty) ? null : wgImage(avatar),
              child: (avatar == null || avatar.isEmpty)
                  ? const Icon(CupertinoIcons.person_fill)
                  : null),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.fg)),
              if (sub.isNotEmpty)
                Text(sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.fgA(0.6))),
            ]),
          ),
          if (owner != null && !isOwner)
            Icon(CupertinoIcons.chevron_right, color: context.fgA(0.4)),
        ]),
      ),
    );
  }

  Widget _contactBar(WgListing l, bool unavailable) => GlassButton(
        height: 52,
        tint: unavailable ? null : context.fg,
        onTap: unavailable ? null : () => _contact(l),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(CupertinoIcons.chat_bubble_fill, color: context.fg, size: 20),
          const SizedBox(width: 8),
          _glassLabel(
              unavailable ? 'Nicht mehr verfügbar' : 'Nachricht senden'),
        ]),
      );

  Widget _ownerActions(WgListing l, String uid, WgNotifier n) {
    final showRenew = l.isExpired() || l.daysLeft() <= 7;
    final rented = l.status == WgStatus.rented;
    return Row(children: [
      Expanded(
        child: GlassButton(
          height: 52,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => WgFormPage(existing: l))),
          child: _glassLabel('Bearbeiten'),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: GlassButton(
          height: 52,
          tint: context.fg,
          onTap: () async {
            if (rented || showRenew) {
              final ok = rented
                  ? await n.reactivate(l.id, userId: uid)
                  : await n.renew(l.id, userId: uid);
              _snack(ok
                  ? 'Anzeige für $kWgListingDays Tage aktiv.'
                  : 'Aktion nicht erlaubt.');
            } else if (await _confirm(
                'Als vergeben markieren?',
                'Die Anzeige erscheint dann nicht mehr in der Suche.',
                'Vergeben')) {
              await n.markRented(l.id, userId: uid);
            }
          },
          child: _glassLabel(rented
              ? 'Reaktivieren'
              : showRenew
                  ? 'Verlängern'
                  : 'Vergeben'),
        ),
      ),
      const SizedBox(width: 10),
      GlassButton(
        width: 52,
        height: 52,
        onTap: () async {
          if (await _confirm('Anzeige löschen?',
              'Das kann nicht rückgängig gemacht werden.', 'Löschen')) {
            await n.delete(l.id, userId: uid);
            if (mounted) Navigator.pop(context);
          }
        },
        child: const Icon(CupertinoIcons.trash,
            color: Color(0xFFFF4B6E), size: 20),
      ),
    ]);
  }
}
