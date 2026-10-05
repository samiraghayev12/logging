import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A backend the app can be switched to from the log page.
///
/// ```dart
/// dio.addDebugLogger(environments: [
///   DebugEnvironment('Dev', baseUrl: 'https://dev.api.example.com'),
///   DebugEnvironment('Prod', baseUrl: 'https://api.example.com'),
/// ]);
/// ```
@immutable
class DebugEnvironment {
  const DebugEnvironment(this.name, {required this.baseUrl, this.color});

  /// Name shown in the switcher. Environments with the same name on different
  /// Dio instances are switched together.
  final String name;

  /// Base URL used for requests while this environment is selected.
  final String baseUrl;

  /// Optional color for the badge on the floating button.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is DebugEnvironment &&
      other.name == name &&
      other.baseUrl == baseUrl;

  @override
  int get hashCode => Object.hash(name, baseUrl);

  @override
  String toString() => 'DebugEnvironment($name, $baseUrl)';
}

/// Keeps the selected environment and remembers it between app starts.
///
/// Usually used through `DioDebugLogger`; exposed for advanced use.
class DebugEnvironments extends ChangeNotifier {
  DebugEnvironments._();

  static final DebugEnvironments instance = DebugEnvironments._();

  static const storageKey = 'dio_debug_logger.environment';

  final List<List<DebugEnvironment>> _groups = [];
  List<DebugEnvironment> _global = const [];
  String? _selected;
  Future<void>? _loading;

  /// Called after the user picks an environment (`null` = app default).
  void Function(String? name)? onChanged;

  /// Completes when the stored selection has been loaded.
  Future<void> get ready => _loading ?? Future<void>.value();

  Iterable<List<DebugEnvironment>> get _allGroups => [_global, ..._groups];

  /// Environments set with [setGlobal]; used by every Dio that doesn't pass
  /// its own list.
  List<DebugEnvironment> get global => _global;

  /// Environment names in the order they were first registered.
  List<String> get names {
    final seen = <String>{};
    return [
      for (final group in _allGroups)
        for (final env in group)
          if (seen.add(env.name)) env.name,
    ];
  }

  bool get isEmpty => _allGroups.every((group) => group.isEmpty);

  /// All environments with [name], one per distinct base URL.
  List<DebugEnvironment> byName(String name) {
    final seen = <DebugEnvironment>{};
    return [
      for (final group in _allGroups)
        for (final env in group)
          if (env.name == name && seen.add(env)) env,
    ];
  }

  /// The selected environment name, or `null` when the app's own base URLs
  /// are used.
  String? get selected =>
      _selected != null && names.contains(_selected) ? _selected : null;

  /// Sets the app-wide environments, available before any Dio exists.
  void setGlobal(List<DebugEnvironment> environments) {
    _checkUnique(environments);
    _global = List.unmodifiable(environments);
    if (environments.isNotEmpty) _loading ??= _load();
    notifyListeners();
  }

  /// Registers the environments of one Dio instance.
  void register(List<DebugEnvironment> environments) {
    if (environments.isEmpty) return;
    _checkUnique(environments);
    _groups.add(List.unmodifiable(environments));
    _loading ??= _load();
    notifyListeners();
  }

  void _checkUnique(List<DebugEnvironment> environments) {
    assert(
      environments.map((e) => e.name).toSet().length == environments.length,
      'Environment names must be unique per list',
    );
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _selected = prefs.getString(storageKey);
      notifyListeners();
    } catch (e) {
      _log('could not load environment: $e');
    }
  }

  /// Selects an environment by name. `null` goes back to the app default.
  Future<void> select(String? name) async {
    if (name != null && !names.contains(name)) {
      throw ArgumentError.value(name, 'name', 'Unknown environment');
    }
    await ready;
    if (name == selected) return;
    _selected = name;
    notifyListeners();
    onChanged?.call(name);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (name == null) {
        await prefs.remove(storageKey);
      } else {
        await prefs.setString(storageKey, name);
      }
    } catch (e) {
      _log('could not save environment: $e');
    }
  }

  /// The base URL to use for a request of a Dio with the environments [group].
  ///
  /// Only rewrites [baseUrl] when it is one of the group's URLs, so requests
  /// to other hosts are left alone. Returns `null` for no change.
  String? resolve(List<DebugEnvironment> group, String baseUrl) {
    final name = selected;
    if (name == null) return null;
    final target = group.where((e) => e.name == name).firstOrNull;
    if (target == null) return null;
    final current = _normalize(baseUrl);
    if (!group.any((e) => _normalize(e.baseUrl) == current)) return null;
    return current == _normalize(target.baseUrl) ? null : target.baseUrl;
  }

  static String _normalize(String url) =>
      url.endsWith('/') ? url.substring(0, url.length - 1) : url;

  static void _log(String message) {
    if (kDebugMode) debugPrint('dio_debug_logger: $message');
  }

  /// Clears everything. For tests only.
  @visibleForTesting
  void reset() {
    _groups.clear();
    _global = const [];
    _selected = null;
    _loading = null;
    onChanged = null;
    notifyListeners();
  }
}
