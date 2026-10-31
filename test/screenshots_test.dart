// Genera las capturas para la ficha de Play Store:
//   flutter test --update-goldens test/screenshots_test.dart
import 'dart:io';

import 'package:bloqueador_cobranza/braincode.dart';
import 'package:bloqueador_cobranza/bridge.dart';
import 'package:bloqueador_cobranza/home.dart';
import 'package:bloqueador_cobranza/main.dart';
import 'package:bloqueador_cobranza/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> fakeState() {
  final now = DateTime.now();
  int ago(int minutes) =>
      now.subtract(Duration(minutes: minutes)).millisecondsSinceEpoch;
  Map<String, dynamic> e(String n, int m, bool b, String r) => {
        'number': n,
        'digits': n.replaceAll(RegExp(r'[^0-9]'), ''),
        'time': ago(m),
        'blocked': b,
        'reason': r,
        'code': ''
      };
  return {
    'roleHeld': true,
    'roleAvailable': true,
    'contactsGranted': true,
    'onboardingDone': true,
    'promoHiddenUntil': 0,
    'appVersion': '1.1.0',
    'settings': {
      'enabled': true,
      'blockUnknown': true,
      'allowRepeat': true,
      'blockHidden': true,
      'blockSpoofed': true,
    },
    'blocklist': ['5588*', '+52 55 4120 3391', '8134567788'],
    'whitelist': ['5550001234'],
    'log': [
      e('+525541203391', 12, true, 'En tu lista de bloqueo'),
      e('+528134567788', 48, true, 'En tu lista de bloqueo'),
      e('+525588120045', 95, true, 'En tu lista de bloqueo'),
      e('+523312457800', 140, false, 'Contacto guardado'),
      e('Número oculto', 210, true, 'Número oculto o privado'),
      e('+525567781200', 60 * 24 + 30, true, 'Número desconocido'),
      e('+525567781200', 60 * 24 + 28, false,
          'Insistió 2 veces en 3 min (posible urgencia)'),
      e('+525512309876', 60 * 24 + 300, true, 'Número desconocido'),
      e('+528112349900', 60 * 26, true, 'Número desconocido'),
    ],
  };
}

Future<void> loadFonts() async {
  Future<void> fam(String family, List<String> files) async {
    final l = FontLoader(family);
    for (final f in files) {
      l.addFont(rootBundle.load(f));
    }
    await l.load();
  }

  await fam('Inter', [
    'assets/fonts/Inter-Regular.otf',
    'assets/fonts/Inter-Medium.otf',
    'assets/fonts/Inter-SemiBold.otf',
    'assets/fonts/Inter-Bold.otf',
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final f = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      final l = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())));
      await l.load();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await loadFonts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(NativeBridge.channel, (call) async {
      if (call.method == 'getState') return fakeState();
      return null;
    });
  });

  Future<void> shoot(WidgetTester tester, String name,
      Widget Function(BlockerState s, Future<void> Function() r) screen,
      {Brightness b = Brightness.light, String? scrollToText}) async {
    debugDisableShadows = false; // sombras reales en las capturas
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2.625;
    tester.platformDispatcher.platformBrightnessTestValue = b;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await tester.pumpWidget(BloqueadorApp(debugScreen: screen));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final ctx = tester.element(find.byType(Scaffold).first);
      await precacheImage(
          const AssetImage('assets/images/braincode_isotipo.png'), ctx);
    });
    await tester.pumpAndSettle();
    if (scrollToText != null) {
      await tester.scrollUntilVisible(find.text(scrollToText), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
    }
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('../store/screenshots/$name.png'));
    debugDisableShadows = true;
  }

  testWidgets('01 bienvenida', (t) async {
    await shoot(t, '01_bienvenida', (s, r) {
      final f = fakeState()..['roleHeld'] = false;
      return OnboardingFlow(
          state: BlockerState.fromMap(f), onRefresh: r, onFinished: () {});
    });
  });

  testWidgets('02 nivel', (t) async {
    await shoot(
        t,
        '02_nivel',
        (s, r) => OnboardingFlow(
            state: s, onRefresh: r, onFinished: () {}, initialPage: 3));
  });

  testWidgets('03 proteccion', (t) async {
    await shoot(t, '03_proteccion',
        (s, r) => HomePage(state: s, onRefresh: r, onReplayGuide: () {}));
  });

  testWidgets('04 historial', (t) async {
    await shoot(
        t,
        '04_historial',
        (s, r) => HomePage(
            state: s, onRefresh: r, onReplayGuide: () {}, initialTab: 2));
  });

  testWidgets('05 listas', (t) async {
    await shoot(
        t,
        '05_listas',
        (s, r) => HomePage(
            state: s, onRefresh: r, onReplayGuide: () {}, initialTab: 1));
  });

  testWidgets('06 acerca de', (t) async {
    await shoot(t, '06_acerca_de', (s, r) => const AboutPage(version: '1.1.0'));
  });

  testWidgets('07 proteccion oscuro', (t) async {
    await shoot(t, '07_proteccion_oscuro',
        (s, r) => HomePage(state: s, onRefresh: r, onReplayGuide: () {}),
        b: Brightness.dark);
  });

  testWidgets('08 tarjeta braincode', (t) async {
    await shoot(t, '08_tarjeta_braincode',
        (s, r) => HomePage(state: s, onRefresh: r, onReplayGuide: () {}),
        scrollToText: 'Conocer BrainCode');
  });
}
