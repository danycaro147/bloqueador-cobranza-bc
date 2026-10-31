import 'package:flutter/services.dart';

/// Puente con Android. Todo se guarda del lado nativo para que el servicio de
/// filtrado funcione aunque la app esté cerrada.
class NativeBridge {
  static const channel = MethodChannel('bloqueador/native');

  static Future<BlockerState> getState() async {
    final m = await channel.invokeMapMethod<String, dynamic>('getState');
    return BlockerState.fromMap(m ?? {});
  }

  static Future<void> requestRole() => channel.invokeMethod('requestRole');
  static Future<void> requestContacts() =>
      channel.invokeMethod('requestContacts');
  static Future<void> openAppSettings() =>
      channel.invokeMethod('openAppSettings');
  static Future<void> clearLog() => channel.invokeMethod('clearLog');

  static Future<void> setSetting(String key, bool value) =>
      channel.invokeMethod('setSetting', {'key': key, 'value': value});

  static Future<void> setLong(String key, int value) =>
      channel.invokeMethod('setLong', {'key': key, 'value': value});

  static Future<void> setList(String name, List<String> items) =>
      channel.invokeMethod('setList', {'name': name, 'items': items});

  static Future<bool> openUrl(String url) async =>
      (await channel.invokeMethod<bool>('openUrl', {'url': url})) ?? false;
}

class LogEntry {
  final String number;
  final String digits;
  final DateTime time;
  final bool blocked;
  final String reason;

  LogEntry({
    required this.number,
    required this.digits,
    required this.time,
    required this.blocked,
    required this.reason,
  });

  factory LogEntry.fromMap(Map m) => LogEntry(
        number: (m['number'] ?? '') as String,
        digits: (m['digits'] ?? '') as String,
        time: DateTime.fromMillisecondsSinceEpoch((m['time'] ?? 0) as int),
        blocked: (m['blocked'] ?? false) as bool,
        reason: (m['reason'] ?? '') as String,
      );
}

class BlockerState {
  final bool roleHeld;
  final bool roleAvailable;
  final bool contactsGranted;
  final bool onboardingDone;
  final int promoHiddenUntil;
  final String appVersion;
  final Map<String, bool> settings;
  final List<String> blocklist;
  final List<String> whitelist;
  final List<LogEntry> log;

  BlockerState({
    required this.roleHeld,
    required this.roleAvailable,
    required this.contactsGranted,
    required this.onboardingDone,
    required this.promoHiddenUntil,
    required this.appVersion,
    required this.settings,
    required this.blocklist,
    required this.whitelist,
    required this.log,
  });

  factory BlockerState.fromMap(Map<String, dynamic> m) {
    List<String> strs(dynamic v) =>
        (v as List? ?? const []).map((e) => e.toString()).toList();
    return BlockerState(
      roleHeld: (m['roleHeld'] ?? false) as bool,
      roleAvailable: (m['roleAvailable'] ?? true) as bool,
      contactsGranted: (m['contactsGranted'] ?? false) as bool,
      onboardingDone: (m['onboardingDone'] ?? false) as bool,
      promoHiddenUntil: (m['promoHiddenUntil'] ?? 0) as int,
      appVersion: (m['appVersion'] ?? '') as String,
      settings: ((m['settings'] as Map?) ?? const {})
          .map((k, v) => MapEntry(k.toString(), v == true)),
      blocklist: strs(m['blocklist']),
      whitelist: strs(m['whitelist']),
      log: (m['log'] as List? ?? const [])
          .map((e) => LogEntry.fromMap(e as Map))
          .toList(),
    );
  }

  bool get(String k) => settings[k] ?? false;

  bool get isActive => roleHeld && get('enabled');

  ProtectionLevel get level => levelOf(settings);

  int blockedSince(DateTime from) =>
      log.where((e) => e.blocked && !e.time.isBefore(from)).length;

  int get blockedTotal => log.where((e) => e.blocked).length;
}

// ---------------------------------------------------------------------------
// Niveles de protección (atajos sobre los ajustes detallados)
// ---------------------------------------------------------------------------

enum ProtectionLevel { recomendado, estricto, soloLista, personalizado }

const Map<ProtectionLevel, Map<String, bool>> levelPresets = {
  ProtectionLevel.recomendado: {
    'blockUnknown': true,
    'allowRepeat': true,
    'blockHidden': true,
    'blockSpoofed': true,
  },
  ProtectionLevel.estricto: {
    'blockUnknown': true,
    'allowRepeat': false,
    'blockHidden': true,
    'blockSpoofed': true,
  },
  ProtectionLevel.soloLista: {
    'blockUnknown': false,
    'allowRepeat': true,
    'blockHidden': false,
    'blockSpoofed': true,
  },
};

ProtectionLevel levelOf(Map<String, bool> s) {
  for (final e in levelPresets.entries) {
    if (e.value.entries.every((kv) => (s[kv.key] ?? false) == kv.value)) {
      return e.key;
    }
  }
  return ProtectionLevel.personalizado;
}

Future<void> applyLevel(ProtectionLevel level) async {
  final p = levelPresets[level];
  if (p == null) return;
  for (final e in p.entries) {
    await NativeBridge.setSetting(e.key, e.value);
  }
}

String levelName(ProtectionLevel l) => switch (l) {
      ProtectionLevel.recomendado => 'Recomendado',
      ProtectionLevel.estricto => 'Estricto',
      ProtectionLevel.soloLista => 'Solo mi lista',
      ProtectionLevel.personalizado => 'Personalizado',
    };

/// "+52 1 55 1234 5678" -> "55 1234 5678"
String formatNumber(String raw) {
  var d = raw.replaceAll(RegExp(r'[^0-9]'), '');
  if (d.isEmpty) return raw;
  if (d.length > 10 && (d.startsWith('52') || d.startsWith('521'))) {
    d = d.substring(d.length - 10);
  }
  if (d.length == 10) {
    return '${d.substring(0, 2)} ${d.substring(2, 6)} ${d.substring(6)}';
  }
  return raw;
}
