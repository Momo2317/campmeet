import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/core/widgets/glass_button.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/features/wg/data/wg_listing.dart';
import 'package:camp_meet/features/wg/data/wg_repository.dart';
import 'package:camp_meet/features/wg/presentation/pages/wg_listings_page.dart';
import 'package:flutter/cupertino.dart'
    show
        CupertinoActivityIndicator,
        CupertinoDatePicker,
        CupertinoDatePickerMode,
        CupertinoIcons,
        showCupertinoModalPopup;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class WgFormPage extends ConsumerStatefulWidget {
  final WgListing? existing;
  const WgFormPage({super.key, this.existing});
  @override
  ConsumerState<WgFormPage> createState() => _WgFormPageState();
}

class _WgFormPageState extends ConsumerState<WgFormPage> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _title,
      _city,
      _district,
      _size,
      _rent,
      _deposit,
      _mates,
      _room,
      _flat;
  late DateTime? _from;
  DateTime? _until;
  late bool _temporary;
  late List<String> _images;
  late Set<String> _amenities;
  bool _saving = false;
  String? _dateError;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title);
    _city = TextEditingController(text: e?.city);
    _district = TextEditingController(text: e?.district);
    _size = TextEditingController(text: e?.sizeSqm.toString());
    _rent = TextEditingController(text: e?.warmRent.toString());
    _deposit = TextEditingController(text: e?.deposit?.toString());
    _mates = TextEditingController(text: e?.flatmates.toString());
    _room = TextEditingController(text: e?.roomDescription);
    _flat = TextEditingController(text: e?.flatDescription);
    _from = e?.availableFrom;
    _until = e?.availableUntil;
    _temporary = e?.isTemporary ?? false;
    _images = [...?e?.images];
    _amenities = {...?e?.amenities};
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _city,
      _district,
      _size,
      _rent,
      _deposit,
      _mates,
      _room,
      _flat
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _req(String? v, {int min = 1, String name = 'Feld'}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return '$name ist erforderlich';
    if (t.length < min) return '$name: mindestens $min Zeichen';
    return null;
  }

  String? _intIn(String? v, int min, int max, String name,
      {bool optional = false}) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return optional ? null : '$name ist erforderlich';
    final n = int.tryParse(t);
    if (n == null) return 'Bitte eine ganze Zahl eingeben';
    if (n < min || n > max) return '$name: $min bis $max';
    return null;
  }

  Future<void> _pickDate(bool from) async {
    final now = DateTime.now();
    final initial = (from ? _from : _until) ?? (from ? now : (_from ?? now));
    final first =
        from ? DateTime(now.year, now.month, now.day) : (_from ?? now);
    final last = DateTime(now.year + 3);
    var picked = initial.isBefore(first) ? first : initial;
    final confirmed = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        height: 330,
        decoration: BoxDecoration(
          color: ctx.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(children: [
          const SizedBox(height: 12),
          Expanded(
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: picked,
              minimumDate: first,
              maximumDate: last,
              onDateTimeChanged: (v) => picked = v,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            child: GlassButton(
              width: double.infinity,
              height: 48,
              onTap: () => Navigator.pop(ctx, true),
              child: Text('Fertig',
                  style: TextStyle(color: ctx.fg, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
      ),
    );
    final d = confirmed == true ? picked : null;
    if (d != null) {
      setState(() {
        if (from) {
          _from = d;
          if (_until != null && !_until!.isAfter(d)) _until = null;
        } else {
          _until = d;
        }
        _dateError = null;
      });
    }
  }

  Future<void> _addImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(imageQuality: 80);
      if (picked.isEmpty) return;
      setState(() {
        _images = [..._images, ...picked.map((x) => x.path)].take(6).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bilder konnten nicht geladen werden.')));
    }
  }

  Future<void> _save() async {
    final me = ref.read(userProfileProvider);
    if (me == null) return;
    final formOk = _key.currentState!.validate();
    String? dateErr;
    if (_from == null) {
      dateErr = 'Bitte „Verfügbar ab“ wählen';
    } else if (_temporary && _until == null) {
      dateErr = 'Bitte ein Enddatum für die Zwischenmiete wählen';
    }
    setState(() => _dateError = dateErr);
    if (!formOk || dateErr != null) return;

    setState(() => _saving = true);
    final deposit = int.tryParse(_deposit.text.trim());
    final draft = WgListing(
      id: widget.existing?.id ?? '',
      ownerId: me.id,
      title: _title.text.trim(),
      city: _city.text.trim(),
      district: _district.text.trim(),
      sizeSqm: int.parse(_size.text.trim()),
      warmRent: int.parse(_rent.text.trim()),
      deposit: deposit,
      availableFrom: _from!,
      availableUntil: _temporary ? _until : null,
      flatmates: int.parse(_mates.text.trim()),
      roomDescription: _room.text.trim(),
      flatDescription: _flat.text.trim(),
      amenities: _amenities.toList(),
      images: _images,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now(),
    );
    final n = ref.read(wgProvider.notifier);
    bool ok = true;
    try {
      if (widget.existing == null) {
        await n.create(draft, userId: me.id);
      } else {
        ok = await n.update(
            widget.existing!.copyWith(
              title: draft.title,
              city: draft.city,
              district: draft.district,
              sizeSqm: draft.sizeSqm,
              warmRent: draft.warmRent,
              deposit: deposit,
              clearDeposit: deposit == null,
              availableFrom: draft.availableFrom,
              availableUntil: draft.availableUntil,
              clearUntil: !_temporary,
              flatmates: draft.flatmates,
              roomDescription: draft.roomDescription,
              flatDescription: draft.flatDescription,
              amenities: draft.amenities,
              images: draft.images,
            ),
            userId: me.id);
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Speichern fehlgeschlagen. Bitte erneut versuchen.')));
      return;
    }
    Navigator.pop(context);
  }

  InputDecoration _dec(String label, {String? hint, String? suffix}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        suffixText: suffix,
        filled: true,
        fillColor: context.fgA(0.06),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none),
      );

  Widget _dateButton(IconData icon, String label, VoidCallback onTap) =>
      GlassButton(
        width: double.infinity,
        height: 48,
        onTap: onTap,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: context.fg, size: 18),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: context.fg, fontWeight: FontWeight.w600)),
        ]),
      );

  Widget _gap() => const SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    final editing = widget.existing != null;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: context.bg,
        foregroundColor: context.fg,
        elevation: 0,
        leadingWidth: 64,
        leading: Align(
          child: GlassButton(
            width: 40,
            height: 40,
            onTap: () => Navigator.maybePop(context),
            child: Icon(CupertinoIcons.back, color: context.fg, size: 20),
          ),
        ),
        title: Text(editing ? 'Anzeige bearbeiten' : 'Neue Anzeige',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.fg)),
      ),
      body: Form(
        key: _key,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextFormField(
              controller: _title,
              maxLength: 80,
              decoration: _dec('Titel', hint: 'z. B. Helles Zimmer in 3er-WG'),
              validator: (v) => _req(v, min: 5, name: 'Titel')),
          _gap(),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: TextFormField(
                    controller: _city,
                    decoration: _dec('Stadt'),
                    validator: (v) => _req(v, min: 2, name: 'Stadt'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextFormField(
                    controller: _district,
                    decoration: _dec('Stadtteil (optional)'))),
          ]),
          const SizedBox(height: 4),
          Text('Eine genaue Adresse ist nicht nötig – ihr klärt sie im Chat.',
              style: TextStyle(fontSize: 12, color: context.fgA(0.5))),
          _gap(),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: TextFormField(
                    controller: _size,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    decoration: _dec('Zimmergröße', suffix: 'm²'),
                    validator: (v) => _intIn(v, 5, 100, 'Größe'))),
            const SizedBox(width: 12),
            Expanded(
                child: TextFormField(
                    controller: _rent,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    decoration: _dec('Warmmiete', suffix: '€'),
                    validator: (v) => _intIn(v, 50, 5000, 'Warmmiete'))),
          ]),
          _gap(),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: TextFormField(
                    controller: _deposit,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    decoration: _dec('Kaution (optional)', suffix: '€'),
                    validator: (v) =>
                        _intIn(v, 0, 10000, 'Kaution', optional: true))),
            const SizedBox(width: 12),
            Expanded(
                child: TextFormField(
                    controller: _mates,
                    keyboardType: TextInputType.number,
                    inputFormatters: digits,
                    decoration: _dec('Mitbewohner'),
                    validator: (v) => _intIn(v, 0, 12, 'Mitbewohner'))),
          ]),
          _gap(),
          GlassSegmented(
            labels: const ['Unbefristet', 'Zwischenmiete'],
            selected: _temporary ? 1 : 0,
            tint: context.fg,
            inactiveColor: context.fg,
            onChanged: (i) => setState(() {
              _temporary = i == 1;
              if (!_temporary) _until = null;
            }),
          ),
          _gap(),
          Row(children: [
            Expanded(
                child: _dateButton(
                    CupertinoIcons.calendar,
                    _from == null ? 'Verfügbar ab' : 'ab ${wgDate(_from!)}',
                    () => _pickDate(true))),
            if (_temporary) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: _dateButton(
                      CupertinoIcons.calendar_badge_minus,
                      _until == null ? 'Bis' : 'bis ${wgDate(_until!)}',
                      () => _pickDate(false))),
            ],
          ]),
          if (_dateError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_dateError!,
                  style: const TextStyle(
                      color: const Color(0xFFFF4B6E), fontSize: 12)),
            ),
          _gap(),
          TextFormField(
              controller: _room,
              maxLines: 4,
              maxLength: 600,
              decoration: _dec('Zimmerbeschreibung'),
              validator: (v) => _req(v, min: 20, name: 'Beschreibung')),
          _gap(),
          TextFormField(
              controller: _flat,
              maxLines: 4,
              maxLength: 600,
              decoration: _dec('Beschreibung des WG-Lebens (optional)')),
          _gap(),
          Text('Ausstattung',
              style: TextStyle(fontWeight: FontWeight.bold, color: context.fg)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final a in kWgAmenities)
              GlassButton(
                  height: 36,
                  tint: _amenities.contains(a) ? context.fg : null,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  onTap: () => setState(() => _amenities.contains(a)
                      ? _amenities.remove(a)
                      : _amenities.add(a)),
                  child: Text(a,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: _amenities.contains(a)
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: context.fg))),
          ]),
          _gap(),
          Text('Bilder (${_images.length}/6)',
              style: TextStyle(fontWeight: FontWeight.bold, color: context.fg)),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView(scrollDirection: Axis.horizontal, children: [
              for (var i = 0; i < _images.length; i++)
                Stack(children: [
                  Container(
                    width: 90,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                            image: wgImage(_images[i]), fit: BoxFit.cover)),
                  ),
                  Positioned(
                    right: 12,
                    top: 4,
                    child: GestureDetector(
                      onTap: () => setState(() => _images.removeAt(i)),
                      child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: Icon(CupertinoIcons.xmark,
                              size: 14, color: Colors.white)),
                    ),
                  ),
                ]),
              if (_images.length < 6)
                GestureDetector(
                  onTap: _addImages,
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                        color: context.fgA(0.06),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(CupertinoIcons.photo_on_rectangle,
                        color: context.fgA(0.5)),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 24),
          GlassButton(
            width: double.infinity,
            height: 52,
            onTap: _saving ? null : _save,
            child: _saving
                ? const CupertinoActivityIndicator()
                : Text(editing ? 'Speichern' : 'Anzeige veröffentlichen',
                    style: TextStyle(
                        color: context.fg,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
