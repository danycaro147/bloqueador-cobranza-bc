import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const BloqueadorApp());

class BloqueadorApp extends StatelessWidget {
  const BloqueadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF1F3A5F);
    return MaterialApp(
      title: 'Bloqueador Cobranza',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
          colorSchemeSeed: seed, brightness: Brightness.dark, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

// ---------------------------------------------------------------------------
// Puente con Android (todo se guarda del lado nativo para que el servicio de
// filtrado funcione aunque la app esté cerrada).
// ---------------------------------------------------------------------------

class NativeBridge {
  static const _ch = MethodChannel('bloqueador/native');

  static Future<BlockerState> getState() async {
    final m = await _ch.invokeMapMethod<String, dynamic>('getState');
    return BlockerState.fromMap(m ?? {});
  }

  static Future<void> requestRole() => _ch.invokeMethod('requestRole');
  static Future<void> requestContacts() => _ch.invokeMethod('requestContacts');
  static Future<void> clearLog() => _ch.invokeMethod('clearLog');

  static Future<void> setSetting(String key, bool value) =>
      _ch.invokeMethod('setSetting', {'key': key, 'value': value});

  static Future<void> setList(String name, List<String> items) =>
      _ch.invokeMethod('setList', {'name': name, 'items': items});
}

class LogEntry {
  final String number;
  final String digits;
  final DateTime time;
  final bool blocked;
  final String reason;

  LogEntry.fromMap(Map m)
      : number = (m['number'] ?? '') as String,
        digits = (m['digits'] ?? '') as String,
        time = DateTime.fromMillisecondsSinceEpoch((m['time'] ?? 0) as int),
        blocked = (m['blocked'] ?? false) as bool,
        reason = (m['reason'] ?? '') as String;
}

class BlockerState {
  final bool roleHeld;
  final bool contactsGranted;
  final Map<String, bool> settings;
  final List<String> blocklist;
  final List<String> whitelist;
  final List<LogEntry> log;

  BlockerState({
    required this.roleHeld,
    required this.contactsGranted,
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
      contactsGranted: (m['contactsGranted'] ?? false) as bool,
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
}

// ---------------------------------------------------------------------------
// Pantalla principal
// ---------------------------------------------------------------------------

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  BlockerState? _s;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Al volver de los diálogos de permisos / rol, recargamos el estado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await NativeBridge.getState();
    if (mounted) setState(() => _s = s);
  }

  Future<void> _setSetting(String k, bool v) async {
    await NativeBridge.setSetting(k, v);
    await _refresh();
  }

  Future<void> _addTo(String list, String pattern) async {
    final s = _s!;
    final items = [...(list == 'blocklist' ? s.blocklist : s.whitelist)];
    if (!items.contains(pattern)) items.insert(0, pattern);
    await NativeBridge.setList(list, items);
    // Un número no puede estar en ambas listas.
    final other = list == 'blocklist' ? 'whitelist' : 'blocklist';
    final otherItems = [...(other == 'blocklist' ? s.blocklist : s.whitelist)]
      ..remove(pattern);
    await NativeBridge.setList(other, otherItems);
    await _refresh();
  }

  Future<void> _removeFrom(String list, String pattern) async {
    final s = _s!;
    final items = [...(list == 'blocklist' ? s.blocklist : s.whitelist)]
      ..remove(pattern);
    await NativeBridge.setList(list, items);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    final pages = s == null
        ? [const Center(child: CircularProgressIndicator())]
        : [
            _ProtectionTab(state: s, onSetting: _setSetting),
            _ListsTab(state: s, onAdd: _addTo, onRemove: _removeFrom),
            _HistoryTab(
              state: s,
              onAdd: _addTo,
              onClear: () async {
                await NativeBridge.clearLog();
                await _refresh();
              },
              onRefresh: _refresh,
            ),
          ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bloqueador Cobranza'),
        actions: [
          IconButton(
              onPressed: _refresh,
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(child: pages[s == null ? 0 : _tab]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Protección'),
          NavigationDestination(
              icon: Icon(Icons.block_outlined),
              selectedIcon: Icon(Icons.block),
              label: 'Listas'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'Historial'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña 1: Protección
// ---------------------------------------------------------------------------

class _ProtectionTab extends StatelessWidget {
  final BlockerState state;
  final Future<void> Function(String, bool) onSetting;

  const _ProtectionTab({required this.state, required this.onSetting});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = state.roleHeld && state.get('enabled');
    final blockedToday = state.log
        .where((e) =>
            e.blocked &&
            DateUtils.isSameDay(e.time, DateTime.now()))
        .length;
    final blockedTotal = state.log.where((e) => e.blocked).length;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: active ? cs.primaryContainer : cs.errorContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(active ? Icons.verified_user : Icons.gpp_maybe,
                    size: 48,
                    color: active
                        ? cs.onPrimaryContainer
                        : cs.onErrorContainer),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(active ? 'Protección activa' : 'Protección inactiva',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(active
                          ? 'Hoy: $blockedToday bloqueadas · Total: $blockedTotal'
                          : !state.roleHeld
                              ? 'Falta activar el filtro de llamadas.'
                              : 'El interruptor principal está apagado.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (!state.roleHeld)
          _SetupCard(
            icon: Icons.filter_alt,
            title: 'Paso 1: Activar como filtro de llamadas',
            body:
                'Android te preguntará si esta app puede filtrar llamadas. '
                'Esto NO la convierte en tu app de Teléfono: seguirás '
                'contestando y marcando con tu app nativa de siempre.',
            button: 'Activar filtro',
            onTap: NativeBridge.requestRole,
          ),
        if (!state.contactsGranted)
          _SetupCard(
            icon: Icons.contacts,
            title: 'Paso 2: Permitir leer contactos',
            body:
                'Se usa solo para reconocer a tus contactos y nunca '
                'bloquearlos. Sin este permiso, la opción "Bloquear '
                'desconocidos" no se aplica (por seguridad).',
            button: 'Dar permiso',
            onTap: NativeBridge.requestContacts,
          ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.power_settings_new),
                title: const Text('Protección encendida'),
                subtitle: const Text('Interruptor principal'),
                value: state.get('enabled'),
                onChanged: (v) => onSetting('enabled', v),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.person_off),
                title: const Text('Bloquear números desconocidos'),
                subtitle: const Text(
                    'Lo más efectivo contra cobranza: cambian de número '
                    'constantemente. Tus contactos siempre entran.'),
                value: state.get('blockUnknown'),
                onChanged: (v) => onSetting('blockUnknown', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.replay),
                title: const Text('Dejar pasar si insiste'),
                subtitle: const Text(
                    'Si un desconocido llama 2 veces en menos de 3 minutos, '
                    'la segunda sí suena (por si es una emergencia).'),
                value: state.get('allowRepeat'),
                onChanged: state.get('blockUnknown')
                    ? (v) => onSetting('allowRepeat', v)
                    : null,
              ),
              SwitchListTile(
                secondary: const Icon(Icons.visibility_off),
                title: const Text('Bloquear números ocultos'),
                subtitle: const Text('Llamadas con número privado.'),
                value: state.get('blockHidden'),
                onChanged: (v) => onSetting('blockHidden', v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.report),
                title: const Text('Bloquear números falsificados'),
                subtitle: const Text(
                    'Cuando la red del operador indica que el número no es real '
                    '(Android 11+, depende del operador).'),
                value: state.get('blockSpoofed'),
                onChanged: (v) => onSetting('blockSpoofed', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Las llamadas bloqueadas se cuelgan sin sonar y sin notificación. '
            'Quedan en el registro de tu teléfono y en el Historial de esta app. '
            'Las llamadas salientes nunca se tocan.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _SetupCard extends StatelessWidget {
  final IconData icon;
  final String title, body, button;
  final Future<void> Function() onTap;

  const _SetupCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.button,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleMedium)),
            ]),
            const SizedBox(height: 8),
            Text(body),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: onTap, child: Text(button)),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña 2: Listas (bloqueo y siempre permitir)
// ---------------------------------------------------------------------------

class _ListsTab extends StatelessWidget {
  final BlockerState state;
  final Future<void> Function(String list, String pattern) onAdd;
  final Future<void> Function(String list, String pattern) onRemove;

  const _ListsTab(
      {required this.state, required this.onAdd, required this.onRemove});

  Future<void> _askAdd(BuildContext context, String list) async {
    final ctrl = TextEditingController();
    final isBlock = list == 'blocklist';
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isBlock ? 'Bloquear número' : 'Siempre permitir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+*\s-]')),
              ],
              decoration: const InputDecoration(
                hintText: 'Ej. 5512345678 o 5588*',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Termina con * para bloquear todos los números que empiecen '
              'igual (útil cuando un despacho usa muchas líneas seguidas).',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Agregar')),
        ],
      ),
    );
    if (result != null && result.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty) {
      await onAdd(list, result);
    }
  }

  Widget _section(BuildContext context, String list, String title,
      String empty, List<String> items, IconData icon) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title, style: Theme.of(context).textTheme.titleMedium),
            trailing: IconButton.filledTonal(
              tooltip: 'Agregar',
              icon: const Icon(Icons.add),
              onPressed: () => _askAdd(context, list),
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(empty, style: Theme.of(context).textTheme.bodySmall),
            ),
          for (final p in items)
            ListTile(
              dense: true,
              title: Text(p),
              subtitle: p.trim().endsWith('*')
                  ? const Text('Prefijo: todos los que empiecen así')
                  : null,
              trailing: IconButton(
                tooltip: 'Quitar',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => onRemove(list, p),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(
            context,
            'blocklist',
            'Lista de bloqueo',
            'Agrega aquí números de cobranza. Se bloquean siempre, incluso '
                'si "Bloquear desconocidos" está apagado.',
            state.blocklist,
            Icons.block),
        const SizedBox(height: 8),
        _section(
            context,
            'whitelist',
            'Siempre permitir',
            'Números que no tienes en contactos pero que sí quieres recibir '
                '(banco, escuela, paquetería...).',
            state.whitelist,
            Icons.check_circle_outline),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña 3: Historial
// ---------------------------------------------------------------------------

class _HistoryTab extends StatelessWidget {
  final BlockerState state;
  final Future<void> Function(String list, String pattern) onAdd;
  final Future<void> Function() onClear;
  final Future<void> Function() onRefresh;

  const _HistoryTab({
    required this.state,
    required this.onAdd,
    required this.onClear,
    required this.onRefresh,
  });

  String _fmt(DateTime t) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.day)}/${two(t.month)}/${t.year} ${two(t.hour)}:${two(t.minute)}';
  }

  void _actions(BuildContext context, LogEntry e) {
    if (e.digits.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(e.number),
              subtitle: Text(e.reason),
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Bloquear siempre este número'),
              onTap: () {
                Navigator.pop(ctx);
                onAdd('blocklist', e.number);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: const Text('Permitir siempre este número'),
              onTap: () {
                Navigator.pop(ctx);
                onAdd('whitelist', e.number);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copiar número'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: e.number));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (state.log.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          children: const [
            SizedBox(height: 120),
            Icon(Icons.phone_disabled, size: 56),
            SizedBox(height: 12),
            Center(child: Text('Aún no hay llamadas filtradas.')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: state.log.length + 1,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Toca una llamada para bloquear o permitir',
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  TextButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Borrar'),
                  ),
                ],
              ),
            );
          }
          final e = state.log[i - 1];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor:
                  e.blocked ? cs.errorContainer : cs.secondaryContainer,
              child: Icon(e.blocked ? Icons.call_end : Icons.call_received,
                  color: e.blocked
                      ? cs.onErrorContainer
                      : cs.onSecondaryContainer),
            ),
            title: Text(e.number),
            subtitle: Text('${e.blocked ? "Bloqueada" : "Permitida"} · ${e.reason}'),
            trailing: Text(_fmt(e.time),
                style: Theme.of(context).textTheme.bodySmall),
            onTap: () => _actions(context, e),
          );
        },
      ),
    );
  }
}
