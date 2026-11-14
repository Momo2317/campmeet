import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_meet/features/discovery/data/student_model.dart';

const String _kMatchesKey = 'campmeet_matches_ids';
const String _kSwipedKey = 'campmeet_swiped_ids';

/// Provider für alle gematchten Studenten
final matchesProvider = NotifierProvider<MatchesNotifier, List<Student>>(() {
  return MatchesNotifier();
});

class MatchesNotifier extends Notifier<List<Student>> {
  SharedPreferences? _prefs;

  @override
  List<Student> build() {
    _loadMatches();
    return [];
  }

  Future<void> _loadMatches() async {
    _prefs ??= await SharedPreferences.getInstance();
    final idsJson = _prefs?.getStringList(_kMatchesKey);
    if (idsJson != null && idsJson.isNotEmpty) {
      final loaded = <Student>[];
      for (final id in idsJson) {
        final found = mockStudents.where((s) => s.id == id).toList();
        if (found.isNotEmpty) {
          loaded.add(found.first);
        }
      }
      if (loaded.isNotEmpty) {
        state = loaded;
      }
    }
  }

  Future<void> addMatch(Student student) async {
    if (state.any((s) => s.id == student.id)) return;
    final updated = [student, ...state];
    state = updated;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(
        _kMatchesKey, updated.map((s) => s.id).toList());
  }

  Future<void> removeMatch(String studentId) async {
    final updated = state.where((s) => s.id != studentId).toList();
    state = updated;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(
        _kMatchesKey, updated.map((s) => s.id).toList());
  }
}

/// Provider für die Historie der bereits geswipten Profile
final swipedHistoryProvider =
    NotifierProvider<SwipedHistoryNotifier, Set<String>>(() {
  return SwipedHistoryNotifier();
});

class SwipedHistoryNotifier extends Notifier<Set<String>> {
  SharedPreferences? _prefs;

  @override
  Set<String> build() {
    _load();
    return {};
  }

  Future<void> _load() async {
    _prefs ??= await SharedPreferences.getInstance();
    final list = _prefs?.getStringList(_kSwipedKey) ?? [];
    state = list.toSet();
  }

  Future<void> recordSwipe(String studentId) async {
    final updated = {...state, studentId};
    state = updated;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setStringList(_kSwipedKey, updated.toList());
  }

  Future<void> resetSwipes() async {
    state = {};
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_kSwipedKey);
  }
}
