import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_meet/features/wg/data/wg_listing.dart';

const String _kListingsKey = 'campmeet_wg_listings_v1';
const String _kReportsKey = 'campmeet_wg_reports_v1';

class WgState {
  final bool loaded;
  final String? error;
  final List<WgListing> listings;

  /// IDs der Anzeigen, die dieser Nutzer gemeldet hat (für ihn ausgeblendet).
  final Set<String> reported;
  const WgState(
      {this.loaded = false,
      this.error,
      this.listings = const [],
      this.reported = const {}});

  WgState copyWith(
          {bool? loaded,
          String? error,
          bool clearError = false,
          List<WgListing>? listings,
          Set<String>? reported}) =>
      WgState(
        loaded: loaded ?? this.loaded,
        error: clearError ? null : (error ?? this.error),
        listings: listings ?? this.listings,
        reported: reported ?? this.reported,
      );
}

final wgProvider = NotifierProvider<WgNotifier, WgState>(() => WgNotifier());

/// Aktive, nicht abgelaufene, nicht gemeldete Anzeigen (öffentliche Suche).
List<WgListing> activeListings(WgState s) =>
    s.listings.where((l) => l.isActive() && !s.reported.contains(l.id)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

List<WgListing> ownListings(WgState s, String userId) =>
    s.listings.where((l) => l.ownerId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

class WgNotifier extends Notifier<WgState> {
  SharedPreferences? _prefs;

  @override
  WgState build() {
    load();
    return const WgState();
  }

  Future<void> load() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs!.getString(_kListingsKey);
      final reported = (_prefs!.getStringList(_kReportsKey) ?? []).toSet();
      final listings = raw == null ? _seed() : WgListing.decodeList(raw);
      state = WgState(loaded: true, listings: listings, reported: reported);
      if (raw == null) await _persist();
    } catch (e) {
      state = WgState(
          loaded: true,
          error: 'Anzeigen konnten nicht geladen werden.',
          listings: const []);
    }
  }

  Future<void> _persist() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!
        .setString(_kListingsKey, WgListing.encodeList(state.listings));
  }

  String newId() => 'wg_${DateTime.now().microsecondsSinceEpoch}';

  DateTime _newExpiry() =>
      DateTime.now().add(const Duration(days: kWgListingDays));

  /// Erstellt eine Anzeige; ownerId ist immer der angemeldete Nutzer.
  Future<void> create(WgListing draft, {required String userId}) async {
    final l = WgListing(
      id: newId(),
      ownerId: userId,
      title: draft.title,
      city: draft.city,
      district: draft.district,
      sizeSqm: draft.sizeSqm,
      warmRent: draft.warmRent,
      deposit: draft.deposit,
      availableFrom: draft.availableFrom,
      availableUntil: draft.availableUntil,
      flatmates: draft.flatmates,
      roomDescription: draft.roomDescription,
      flatDescription: draft.flatDescription,
      amenities: draft.amenities,
      images: draft.images,
      createdAt: DateTime.now(),
      expiresAt: _newExpiry(),
    );
    state = state.copyWith(listings: [l, ...state.listings]);
    await _persist();
  }

  WgListing? _own(String id, String userId) {
    for (final l in state.listings) {
      if (l.id == id) return l.ownerId == userId ? l : null;
    }
    return null;
  }

  Future<bool> _mutate(
      String id, String userId, WgListing Function(WgListing) f) async {
    final cur = _own(id, userId);
    if (cur == null) return false; // fremde oder unbekannte Anzeige
    state = state.copyWith(
        listings: [for (final l in state.listings) l.id == id ? f(l) : l]);
    await _persist();
    return true;
  }

  Future<bool> update(WgListing edited, {required String userId}) =>
      _mutate(edited.id, userId, (_) => edited);

  Future<bool> markRented(String id, {required String userId}) =>
      _mutate(id, userId, (l) => l.copyWith(status: WgStatus.rented));

  Future<bool> reactivate(String id, {required String userId}) => _mutate(
      id,
      userId,
      (l) => l.copyWith(status: WgStatus.active, expiresAt: _newExpiry()));

  Future<bool> renew(String id, {required String userId}) =>
      _mutate(id, userId, (l) => l.copyWith(expiresAt: _newExpiry()));

  Future<bool> delete(String id, {required String userId}) async {
    if (_own(id, userId) == null) return false;
    state = state.copyWith(
        listings: state.listings.where((l) => l.id != id).toList());
    await _persist();
    return true;
  }

  /// Meldet eine Anzeige; sie verschwindet für den Meldenden sofort.
  Future<void> report(String id, String reason) async {
    final set = {...state.reported, id};
    state = state.copyWith(reported: set);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setStringList(_kReportsKey, set.toList());
  }

  List<WgListing> _seed() {
    final now = DateTime.now();
    WgListing mk(
            String id,
            String owner,
            String title,
            String city,
            String district,
            int sqm,
            int rent,
            int? dep,
            int fromDays,
            int? untilDays,
            int mates,
            String room,
            String flat,
            List<String> am,
            String img,
            int ageDays) =>
        WgListing(
          id: id,
          ownerId: owner,
          title: title,
          city: city,
          district: district,
          sizeSqm: sqm,
          warmRent: rent,
          deposit: dep,
          availableFrom: now.add(Duration(days: fromDays)),
          availableUntil:
              untilDays == null ? null : now.add(Duration(days: untilDays)),
          flatmates: mates,
          roomDescription: room,
          flatDescription: flat,
          amenities: am,
          images: [img],
          createdAt: now.subtract(Duration(days: ageDays)),
          expiresAt: now
              .subtract(Duration(days: ageDays))
              .add(const Duration(days: kWgListingDays)),
        );
    const img1 =
        'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?w=800';
    const img2 =
        'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?w=800';
    const img3 =
        'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?w=800';
    return [
      mk(
          'wg_seed_1',
          '2',
          'Helles Zimmer in Altbau-WG',
          'Berlin',
          'Neukölln',
          16,
          480,
          960,
          5,
          null,
          2,
          'Helles Zimmer mit Dielenboden und großem Fenster, teilmöbliert.',
          'Entspannte 3er-WG, wir kochen oft zusammen und gehen gern zum Uni-Sport.',
          ['Möbliert', 'WLAN', 'Waschmaschine', 'Rauchfrei'],
          img1,
          3),
      mk(
          'wg_seed_2',
          '3',
          'Zwischenmiete nahe TU Berlin',
          'Berlin',
          'Charlottenburg',
          12,
          390,
          null,
          0,
          120,
          1,
          'Kleines, ruhiges Zimmer für ein Semester, komplett möbliert.',
          'Zweier-WG, beide Informatik-Studierende, ruhig zum Lernen.',
          ['Möbliert', 'WLAN', 'Spülmaschine'],
          img2,
          10),
      mk(
          'wg_seed_3',
          '6',
          'WG-Zimmer mit Balkon',
          'München',
          'Schwabing',
          20,
          720,
          1440,
          30,
          null,
          3,
          'Großes Zimmer mit Zugang zum Balkon, unmöbliert.',
          'Vierer-WG nahe LMU, Fahrradkeller und gemeinsame Küche.',
          ['Balkon', 'WLAN', 'Fahrradkeller', 'Aufzug'],
          img3,
          1),
      mk(
          'wg_seed_4',
          '8',
          'Gemütliches Zimmer, Mitbewohnerin gesucht',
          'Berlin',
          'Prenzlauer Berg',
          14,
          520,
          1040,
          14,
          null,
          1,
          'Ruhiges Hofzimmer, Bett und Schrank können bleiben.',
          'Wir sind zu zweit, sehr sauber und offen für Gäste.',
          ['Möbliert', 'WLAN', 'Waschmaschine', 'Haustiere erlaubt'],
          img1,
          5),
    ];
  }
}
