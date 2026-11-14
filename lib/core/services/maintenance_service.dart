import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider für den Wartungsmodus Status (Modern Riverpod 3.0 Syntax)
final maintenanceProvider = NotifierProvider<MaintenanceNotifier, bool>(() {
  return MaintenanceNotifier();
});

class MaintenanceNotifier extends Notifier<bool> {
  static const _key = 'is_maintenance_mode';
  SharedPreferences? _prefs;

  @override
  bool build() {
    _init();
    return false; // Standardwert während der Initialisierung
  }

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
    state = _prefs?.getBool(_key) ?? false;
  }

  Future<void> toggle(bool value) async {
    state = value;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_key, value);
  }
}
