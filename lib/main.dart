import 'package:flutter/material.dart';

import 'bridge.dart';
import 'home.dart';
import 'onboarding.dart';
import 'theme.dart';

void main() => runApp(const BloqueadorApp());

class BloqueadorApp extends StatelessWidget {
  /// Solo para capturas/pruebas: abre directamente una pantalla.
  final Widget Function(BlockerState s, Future<void> Function() refresh)?
      debugScreen;

  const BloqueadorApp({super.key, this.debugScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bloqueador Cobranza',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      home: AppRoot(debugScreen: debugScreen),
    );
  }
}

/// Carga el estado nativo, lo recarga al volver a la app y decide si mostrar
/// la guía de configuración o la pantalla principal.
class AppRoot extends StatefulWidget {
  final Widget Function(BlockerState s, Future<void> Function() refresh)?
      debugScreen;
  const AppRoot({super.key, this.debugScreen});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> with WidgetsBindingObserver {
  BlockerState? _s;
  bool _replayGuide = false;

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

  // Al volver de los diálogos de Android (rol, permisos) recargamos el estado.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final s = await NativeBridge.getState();
    if (mounted) setState(() => _s = s);
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    if (s == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (widget.debugScreen != null) return widget.debugScreen!(s, _refresh);

    final Widget child;
    if (!s.onboardingDone || _replayGuide) {
      child = OnboardingFlow(
        key: const ValueKey('onboarding'),
        state: s,
        onRefresh: _refresh,
        onFinished: () => setState(() => _replayGuide = false),
      );
    } else {
      child = HomePage(
        key: const ValueKey('home'),
        state: s,
        onRefresh: _refresh,
        onReplayGuide: () => setState(() => _replayGuide = true),
      );
    }
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 300), child: child);
  }
}
