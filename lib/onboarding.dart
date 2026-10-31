import 'package:flutter/material.dart';

import 'braincode.dart';
import 'bridge.dart';
import 'theme.dart';
import 'widgets.dart';

/// Guía de configuración en 5 pasos:
/// Bienvenida → Filtro de llamadas → Contactos → Nivel → Listo.
class OnboardingFlow extends StatefulWidget {
  final BlockerState state;
  final Future<void> Function() onRefresh;
  final VoidCallback onFinished;
  final int initialPage;

  const OnboardingFlow({
    super.key,
    required this.state,
    required this.onRefresh,
    required this.onFinished,
    this.initialPage = 0,
  });

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _pages = 5;
  late final PageController _pc = PageController(initialPage: widget.initialPage);
  late int _page = widget.initialPage;
  late ProtectionLevel _level = widget.state.level == ProtectionLevel.personalizado
      ? ProtectionLevel.recomendado
      : widget.state.level;
  int _contactAttempts = 0;
  bool _busy = false;

  BlockerState get s => widget.state;

  void _go(int p) {
    setState(() => _page = p);
    _pc.animateToPage(p,
        duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    setState(() => _busy = true);
    await applyLevel(_level);
    await NativeBridge.setSetting('enabled', true);
    await NativeBridge.setSetting('onboardingDone', true);
    await widget.onRefresh();
    widget.onFinished();
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final showTop = _page > 0 && _page < _pages - 1;
    return PopScope(
      canPop: _page == 0 || _page == _pages - 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _go(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 56,
                child: showTop
                    ? Row(
                        children: [
                          IconButton(
                            tooltip: 'Atrás',
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => _go(_page - 1),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _page / (_pages - 1),
                                minHeight: 6,
                                backgroundColor: cs.surfaceContainerHighest,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text('Paso $_page de ${_pages - 2}',
                                style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      )
                    : null,
              ),
              Expanded(
                child: PageView(
                  controller: _pc,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _welcome(context),
                    _roleStep(context),
                    _contactsStep(context),
                    _levelStep(context),
                    _doneStep(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Plantilla común de cada paso ---------------------------------------
  Widget _stepLayout({
    required Widget art,
    required String title,
    required String body,
    List<Widget> extra = const [],
    required List<Widget> actions,
  }) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, c) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight - 32),
          child: IntrinsicHeight(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Center(child: art),
                const SizedBox(height: 28),
                Text(title,
                    textAlign: TextAlign.center,
                    style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800, height: 1.2)),
                const SizedBox(height: 12),
                Text(body,
                    textAlign: TextAlign.center,
                    style: tt.bodyLarge
                        ?.copyWith(color: cs.onSurfaceVariant, height: 1.45)),
                const SizedBox(height: 20),
                ...extra,
                const Spacer(),
                const SizedBox(height: 16),
                ...actions,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _doneChip(String text) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: AppColors.success.withAlpha(36),
            borderRadius: BorderRadius.circular(30)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: 20),
          const SizedBox(width: 8),
          Text(text,
              style: const TextStyle(
                  color: AppColors.success, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }

  // --- 0. Bienvenida -------------------------------------------------------
  Widget _welcome(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    Widget feature(IconData i, String t, String d) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(14)),
                child: Icon(i, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(d,
                        style: tt.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant, height: 1.35)),
                  ],
                ),
              ),
            ],
          ),
        );

    return _stepLayout(
      art: const ShieldArt(size: 128),
      title: 'Adiós a las llamadas de cobranza',
      body: 'Filtra las llamadas molestas antes de que suenen.',
      extra: [
        const SizedBox(height: 8),
        feature(Icons.phone_disabled_rounded, 'Bloquea cobranza y spam',
            'Cuelga solo los desconocidos, los números ocultos y los de tu lista.'),
        feature(Icons.contacts_rounded, 'Tus contactos siempre entran',
            'Nunca se bloquea a alguien que tienes guardado.'),
        feature(Icons.phone_android_rounded, 'Tu app de Teléfono no cambia',
            'Sigues marcando y contestando como siempre.'),
      ],
      actions: [
        FilledButton(onPressed: () => _go(1), child: const Text('Comenzar')),
        const SizedBox(height: 8),
        const MadeByBrainCode(),
      ],
    );
  }

  // --- 1. Rol de filtro -----------------------------------------------------
  Widget _roleStep(BuildContext context) {
    return _stepLayout(
      art: ShieldArt(
          size: 112,
          icon: s.roleHeld ? Icons.check_rounded : Icons.filter_alt_rounded,
          ok: s.roleHeld),
      title: 'Activa el filtro de llamadas',
      body: 'Android te mostrará un aviso para elegir la app de '
          '“identificación de llamadas y spam”. Elige Bloqueador Cobranza.',
      extra: [
        const InfoBox(
          icon: Icons.phone_android_rounded,
          text: 'Esto NO reemplaza tu app de Teléfono. Solo nos permite decidir '
              'si una llamada entra o no.',
        ),
        const SizedBox(height: 16),
        if (s.roleHeld) _doneChip('Filtro activado'),
        if (!s.roleAvailable)
          const InfoBox(
            warning: true,
            icon: Icons.error_outline_rounded,
            text: 'Tu teléfono no ofrece el filtro de llamadas. Se necesita '
                'Android 10 o superior.',
          ),
      ],
      actions: [
        if (s.roleHeld)
          FilledButton(onPressed: () => _go(2), child: const Text('Continuar'))
        else ...[
          FilledButton(
            onPressed: s.roleAvailable ? NativeBridge.requestRole : null,
            child: const Text('Activar filtro'),
          ),
        ],
      ],
    );
  }

  // --- 2. Contactos (aviso destacado de uso de datos) -----------------------
  Widget _contactsStep(BuildContext context) {
    final denied = !s.contactsGranted && _contactAttempts >= 2;
    return _stepLayout(
      art: ShieldArt(
          size: 112,
          icon: s.contactsGranted ? Icons.check_rounded : Icons.contacts_rounded,
          ok: s.contactsGranted),
      title: 'Tus contactos, siempre bienvenidos',
      body: 'Para no bloquear nunca a alguien que conoces, la app compara cada '
          'llamada con tus contactos.',
      extra: [
        const InfoBox(
          icon: Icons.lock_outline_rounded,
          text: 'Tus contactos no salen de tu teléfono. La app no tiene acceso a '
              'internet y no guarda copias.',
        ),
        const SizedBox(height: 16),
        if (s.contactsGranted) _doneChip('Permiso concedido'),
        if (denied)
          const InfoBox(
            warning: true,
            icon: Icons.info_outline_rounded,
            text: 'Android ya no muestra el aviso. Ábrelo desde Ajustes → '
                'Permisos → Contactos → Permitir.',
          ),
      ],
      actions: [
        if (s.contactsGranted)
          FilledButton(onPressed: () => _go(3), child: const Text('Continuar'))
        else ...[
          FilledButton(
            onPressed: () {
              setState(() => _contactAttempts++);
              denied
                  ? NativeBridge.openAppSettings()
                  : NativeBridge.requestContacts();
            },
            child: Text(denied ? 'Abrir ajustes' : 'Permitir acceso a contactos'),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () => _go(3), child: const Text('Ahora no')),
        ],
      ],
    );
  }

  // --- 3. Nivel -------------------------------------------------------------
  Widget _levelStep(BuildContext context) {
    final needsContacts = levelPresets[_level]!['blockUnknown']! &&
        !s.contactsGranted;
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        Text('Elige tu nivel de protección',
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text('Puedes cambiarlo cuando quieras.',
            style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        LevelSelector(
            selected: _level, onChanged: (l) => setState(() => _level = l)),
        if (needsContacts) ...[
          const SizedBox(height: 4),
          const InfoBox(
            warning: true,
            icon: Icons.contacts_rounded,
            text: 'Sin permiso de contactos, los números desconocidos no se '
                'bloquearán (para no bloquear a alguien que conoces).',
          ),
        ],
        const SizedBox(height: 20),
        FilledButton(onPressed: () => _go(4), child: const Text('Continuar')),
      ],
    );
  }

  // --- 4. Listo ---------------------------------------------------------------
  Widget _doneStep(BuildContext context) {
    final ready = s.roleHeld;
    return _stepLayout(
      art: ShieldArt(
          size: 128,
          icon: ready ? Icons.check_rounded : Icons.priority_high_rounded,
          ok: ready),
      title: ready ? '¡Listo! Ya estás protegido' : 'Casi listo',
      body: ready
          ? 'Las llamadas bloqueadas no sonarán y las verás en el Historial. '
              'Puedes cambiar todo en cualquier momento.'
          : 'Falta activar el filtro de llamadas. Puedes hacerlo desde la '
              'pantalla principal.',
      extra: const [
        InfoBox(
          icon: Icons.lightbulb_outline_rounded,
          text: 'Consejo: si un despacho te llama desde números parecidos, '
              'agrégalos en Listas terminando con * (ej. 5588*).',
        ),
      ],
      actions: [
        FilledButton(
          onPressed: _busy ? null : _finish,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5))
              : const Text('Ir a la app'),
        ),
      ],
    );
  }
}
