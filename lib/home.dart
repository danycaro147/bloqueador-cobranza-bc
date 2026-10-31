import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'braincode.dart';
import 'bridge.dart';
import 'privacy.dart';
import 'theme.dart';
import 'widgets.dart';

class HomePage extends StatefulWidget {
  final BlockerState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onReplayGuide;
  final int initialTab;

  const HomePage({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onReplayGuide,
    this.initialTab = 0,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int _tab = widget.initialTab;

  BlockerState get s => widget.state;

  Future<void> _setSetting(String k, bool v) async {
    await NativeBridge.setSetting(k, v);
    await widget.onRefresh();
  }

  Future<void> _addTo(String list, String pattern) async {
    final items = [...(list == 'blocklist' ? s.blocklist : s.whitelist)];
    if (!items.contains(pattern)) items.insert(0, pattern);
    await NativeBridge.setList(list, items);
    // Un número no puede estar en ambas listas.
    final other = list == 'blocklist' ? 'whitelist' : 'blocklist';
    final otherItems = [...(other == 'blocklist' ? s.blocklist : s.whitelist)]
      ..remove(pattern);
    await NativeBridge.setList(other, otherItems);
    await widget.onRefresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(list == 'blocklist'
              ? '${formatNumber(pattern)} se bloqueará siempre'
              : '${formatNumber(pattern)} siempre podrá llamarte')));
    }
  }

  Future<void> _removeFrom(String list, String pattern) async {
    final items = [...(list == 'blocklist' ? s.blocklist : s.whitelist)]
      ..remove(pattern);
    await NativeBridge.setList(list, items);
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProtectionTab(
        state: s,
        onSetting: _setSetting,
        onLevel: (l) async {
          await applyLevel(l);
          await widget.onRefresh();
        },
        onHidePromo: () async {
          await NativeBridge.setLong(
              'promoHiddenUntil',
              DateTime.now()
                  .add(const Duration(days: 30))
                  .millisecondsSinceEpoch);
          await widget.onRefresh();
        },
      ),
      ListsTab(state: s, onAdd: _addTo, onRemove: _removeFrom),
      HistoryTab(
        state: s,
        onAdd: _addTo,
        onClear: () async {
          await NativeBridge.clearLog();
          await widget.onRefresh();
        },
        onRefresh: widget.onRefresh,
      ),
    ];
    const titles = ['Bloqueador Cobranza', 'Listas', 'Historial'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_tab]),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Más opciones',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (v) {
              switch (v) {
                case 'guide':
                  widget.onReplayGuide();
                case 'privacy':
                  Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PrivacyPage()));
                case 'about':
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AboutPage(version: s.appVersion)));
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                  value: 'guide',
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.school_outlined),
                      title: Text('Guía de configuración'))),
              PopupMenuItem(
                  value: 'privacy',
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.lock_outline_rounded),
                      title: Text('Privacidad'))),
              PopupMenuItem(
                  value: 'about',
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.info_outline_rounded),
                      title: Text('Acerca de'))),
            ],
          ),
        ],
      ),
      body: SafeArea(bottom: false, child: pages[_tab]),
      floatingActionButton: _tab == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                final p = await askNumber(context, block: true);
                if (p != null) await _addTo('blocklist', p);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Bloquear número'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield_rounded),
              label: 'Protección'),
          NavigationDestination(
              icon: Icon(Icons.list_alt_outlined),
              selectedIcon: Icon(Icons.list_alt_rounded),
              label: 'Listas'),
          NavigationDestination(
              icon: Icon(Icons.history_rounded), label: 'Historial'),
        ],
      ),
    );
  }
}

/// Diálogo para capturar un número o prefijo.
Future<String?> askNumber(BuildContext context, {required bool block}) async {
  final ctrl = TextEditingController();
  final r = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(block ? 'Bloquear número' : 'Permitir siempre'),
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
              labelText: 'Número',
              hintText: '55 1234 5678',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            block
                ? 'Tip: termina con * para bloquear todos los que empiecen igual, '
                    'por ejemplo 5588*.'
                : 'Útil para banco, escuela o paquetería que no tienes guardados.',
            style: Theme.of(ctx).textTheme.bodySmall,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Agregar')),
      ],
    ),
  );
  if (r == null || r.replaceAll(RegExp(r'[^0-9]'), '').isEmpty) return null;
  return r;
}

// ---------------------------------------------------------------------------
// Pestaña Protección
// ---------------------------------------------------------------------------

class ProtectionTab extends StatelessWidget {
  final BlockerState state;
  final Future<void> Function(String, bool) onSetting;
  final Future<void> Function(ProtectionLevel) onLevel;
  final Future<void> Function() onHidePromo;

  const ProtectionTab({
    super.key,
    required this.state,
    required this.onSetting,
    required this.onLevel,
    required this.onHidePromo,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final showPromo = s.isActive &&
        now.millisecondsSinceEpoch > s.promoHiddenUntil;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _StatusHero(state: s, onSetting: onSetting),
        const SizedBox(height: 12),
        Row(
          children: [
            _Stat(value: s.blockedSince(today), label: 'Hoy'),
            const SizedBox(width: 10),
            _Stat(
                value: s.blockedSince(today.subtract(const Duration(days: 6))),
                label: 'Últimos 7 días'),
            const SizedBox(width: 10),
            _Stat(value: s.blockedTotal, label: 'Total'),
          ],
        ),
        if (s.roleHeld && !s.contactsGranted && s.get('blockUnknown')) ...[
          const SizedBox(height: 12),
          _ActionBanner(
            icon: Icons.contacts_rounded,
            text: 'Da permiso de contactos para bloquear números desconocidos.',
            action: 'Permitir',
            onTap: NativeBridge.requestContacts,
          ),
        ],
        const SectionTitle('Nivel de protección'),
        LevelSelector(selected: s.level, onChanged: onLevel),
        const SizedBox(height: 2),
        Card(
          child: Theme(
            data: Theme.of(context)
                .copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: const Icon(Icons.tune_rounded),
              title: const Text('Ajustes detallados',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.only(bottom: 8),
              children: [
                _switch(context, 'blockUnknown', Icons.person_off_rounded,
                    'Bloquear desconocidos', 'Números que no están en tus contactos.'),
                _switch(
                    context,
                    'allowRepeat',
                    Icons.replay_rounded,
                    'Dejar pasar si insiste',
                    '2 llamadas del mismo número en 3 minutos.',
                    enabled: s.get('blockUnknown')),
                _switch(context, 'blockHidden', Icons.visibility_off_rounded,
                    'Bloquear números ocultos', 'Llamadas con número privado.'),
                _switch(context, 'blockSpoofed', Icons.gpp_bad_rounded,
                    'Bloquear falsificados',
                    'Cuando el operador indica que el número no es real.'),
              ],
            ),
          ),
        ),
        if (showPromo) ...[
          const SizedBox(height: 24),
          BrainCodePromoCard(onDismiss: onHidePromo),
        ],
        const SizedBox(height: 12),
        const MadeByBrainCode(),
      ],
    );
  }

  Widget _switch(BuildContext context, String key, IconData icon, String title,
      String sub,
      {bool enabled = true}) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(sub),
      value: state.get(key),
      onChanged: enabled ? (v) => onSetting(key, v) : null,
    );
  }
}

class _StatusHero extends StatelessWidget {
  final BlockerState state;
  final Future<void> Function(String, bool) onSetting;
  const _StatusHero({required this.state, required this.onSetting});

  @override
  Widget build(BuildContext context) {
    final s = state;
    final active = s.isActive;
    final tt = Theme.of(context).textTheme;
    final title = active
        ? 'Protección activa'
        : !s.roleHeld
            ? 'Falta activar el filtro'
            : 'Protección en pausa';
    final sub = active
        ? 'Nivel ${levelName(s.level).toLowerCase()}'
        : !s.roleHeld
            ? 'Sin esto no se puede bloquear ninguna llamada.'
            : 'Las llamadas entran sin filtrar.';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: active
              ? const [AppColors.brand, AppColors.brandDeep]
              : const [Color(0xFF8A5A12), Color(0xFF5E3B08)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: Colors.white.withAlpha(36),
                    borderRadius: BorderRadius.circular(16)),
                child: Icon(
                    active ? Icons.verified_user_rounded : Icons.gpp_maybe_rounded,
                    color: Colors.white,
                    size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: tt.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(sub,
                        style: tt.bodyMedium
                            ?.copyWith(color: Colors.white.withAlpha(215))),
                  ],
                ),
              ),
              if (s.roleHeld)
                Switch(
                  value: s.get('enabled'),
                  onChanged: (v) => onSetting('enabled', v),
                  activeTrackColor: Colors.white,
                  thumbColor: WidgetStateProperty.resolveWith((st) =>
                      st.contains(WidgetState.selected)
                          ? AppColors.brandDeep
                          : null),
                ),
            ],
          ),
          if (!s.roleHeld) ...[
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF5E3B08),
                  minimumSize: const Size.fromHeight(48)),
              onPressed: s.roleAvailable ? NativeBridge.requestRole : null,
              child: const Text('Activar filtro'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$value',
                  style: tt.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()])),
              const SizedBox(height: 2),
              Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBanner extends StatelessWidget {
  final IconData icon;
  final String text, action;
  final Future<void> Function() onTap;
  const _ActionBanner(
      {required this.icon,
      required this.text,
      required this.action,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
      decoration: BoxDecoration(
          color: cs.tertiaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Icon(icon, color: cs.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: cs.onTertiaryContainer, height: 1.3))),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña Listas
// ---------------------------------------------------------------------------

class ListsTab extends StatefulWidget {
  final BlockerState state;
  final Future<void> Function(String list, String pattern) onAdd;
  final Future<void> Function(String list, String pattern) onRemove;

  const ListsTab(
      {super.key,
      required this.state,
      required this.onAdd,
      required this.onRemove});

  @override
  State<ListsTab> createState() => _ListsTabState();
}

class _ListsTabState extends State<ListsTab> {
  String _list = 'blocklist';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final block = _list == 'blocklist';
    final items = block ? widget.state.blocklist : widget.state.whitelist;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      children: [
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
                value: 'blocklist',
                icon: const Icon(Icons.block_rounded),
                label: Text('Bloqueados (${widget.state.blocklist.length})')),
            ButtonSegment(
                value: 'whitelist',
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text('Permitidos (${widget.state.whitelist.length})')),
          ],
          selected: {_list},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _list = v.first),
        ),
        const SizedBox(height: 16),
        Text(
          block
              ? 'Se bloquean siempre, aunque “Bloquear desconocidos” esté apagado.'
              : 'Siempre pueden llamarte aunque no estén en tus contactos.',
          style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              children: [
                Icon(block ? Icons.block_rounded : Icons.verified_rounded,
                    size: 48, color: cs.outline),
                const SizedBox(height: 12),
                Text(block ? 'Aún no bloqueas números' : 'Sin números permitidos',
                    style: tt.titleMedium),
                const SizedBox(height: 4),
                Text(
                  block
                      ? 'Agrégalos aquí o desde el Historial.'
                      : 'Agrega banco, escuela o paquetería.',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (!block) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final p = await askNumber(context, block: false);
                      if (p != null) await widget.onAdd('whitelist', p);
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Agregar permitido'),
                  ),
                ],
              ],
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (final (i, p) in items.indexed) ...[
                  if (i > 0) const Divider(indent: 68),
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          block ? cs.errorContainer : cs.secondaryContainer,
                      child: Icon(
                          p.trim().endsWith('*')
                              ? Icons.dialpad_rounded
                              : (block
                                  ? Icons.block_rounded
                                  : Icons.check_rounded),
                          color: block
                              ? cs.onErrorContainer
                              : cs.onSecondaryContainer,
                          size: 20),
                    ),
                    title: Text(
                        p.trim().endsWith('*') ? p.trim() : formatNumber(p),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontFeatures: [FontFeature.tabularFigures()])),
                    subtitle: p.trim().endsWith('*')
                        ? const Text('Todos los que empiecen así')
                        : null,
                    trailing: IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => widget.onRemove(_list, p),
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (!block && items.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final p = await askNumber(context, block: false);
              if (p != null) await widget.onAdd('whitelist', p);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Agregar permitido'),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Pestaña Historial
// ---------------------------------------------------------------------------

class HistoryTab extends StatefulWidget {
  final BlockerState state;
  final Future<void> Function(String list, String pattern) onAdd;
  final Future<void> Function() onClear;
  final Future<void> Function() onRefresh;

  const HistoryTab({
    super.key,
    required this.state,
    required this.onAdd,
    required this.onClear,
    required this.onRefresh,
  });

  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  int _filter = 0; // 0 todas, 1 bloqueadas, 2 permitidas

  static const _months = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic'
  ];

  String _day(DateTime t) {
    final now = DateTime.now();
    final d = DateTime(t.year, t.month, t.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Hoy';
    if (diff == 1) return 'Ayer';
    return '${t.day} ${_months[t.month - 1]} ${t.year}';
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _actions(LogEntry e) {
    if (e.digits.isEmpty) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(formatNumber(e.number),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 18)),
              subtitle: Text(e.reason),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.block_rounded),
              title: const Text('Bloquear siempre'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAdd('blocklist', e.number);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: const Text('Permitir siempre'),
              onTap: () {
                Navigator.pop(ctx);
                widget.onAdd('whitelist', e.number);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copiar número'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: e.number));
                Navigator.pop(ctx);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final all = widget.state.log;
    final list = all
        .where((e) => _filter == 0 || (_filter == 1 ? e.blocked : !e.blocked))
        .toList();

    final children = <Widget>[
      Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final (i, label)
                      in ['Todas', 'Bloqueadas', 'Permitidas'].indexed)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(label),
                        selected: _filter == i,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _filter = i),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (all.isNotEmpty)
            IconButton(
              tooltip: 'Borrar historial',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('¿Borrar historial?'),
                    content: const Text(
                        'Tus listas y ajustes no se borran.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar')),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Borrar')),
                    ],
                  ),
                );
                if (ok == true) await widget.onClear();
              },
            ),
        ],
      ),
    ];

    if (list.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.phone_callback_rounded, size: 48, color: cs.outline),
            const SizedBox(height: 12),
            Text('Sin llamadas por aquí', style: tt.titleMedium),
            const SizedBox(height: 4),
            Text('Aquí verás cada llamada que la app revise.',
                style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          ],
        ),
      ));
    } else {
      String? lastDay;
      List<Widget> group = [];
      void flush() {
        if (group.isEmpty) return;
        children.add(Card(child: Column(children: group)));
        group = [];
      }

      for (final e in list) {
        final d = _day(e.time);
        if (d != lastDay) {
          flush();
          children.add(SectionTitle(d));
          lastDay = d;
        } else {
          group.add(const Divider(indent: 68));
        }
        group.add(ListTile(
          onTap: () => _actions(e),
          leading: CircleAvatar(
            backgroundColor:
                e.blocked ? cs.errorContainer : cs.secondaryContainer,
            child: Icon(
                e.blocked ? Icons.call_end_rounded : Icons.call_received_rounded,
                size: 20,
                color: e.blocked ? cs.onErrorContainer : cs.onSecondaryContainer),
          ),
          title: Text(formatNumber(e.number),
              style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFeatures: [FontFeature.tabularFigures()])),
          subtitle: Text(e.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Text(_time(e.time),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ));
      }
      flush();
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: children,
      ),
    );
  }
}
