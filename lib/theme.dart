import 'package:flutter/material.dart';

class AppColors {
  static const seed = Color(0xFF23468A);
  static const brandDeep = Color(0xFF16294D);
  static const brand = Color(0xFF2A4D8F);
  static const danger = Color(0xFFE5484D);
  static const success = Color(0xFF1F9D61);
}

ThemeData buildTheme(Brightness b) {
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.seed, brightness: b);
  final light = b == Brightness.light;
  final base =
      ThemeData(colorScheme: scheme, useMaterial3: true, fontFamily: 'Inter');
  final radius = BorderRadius.circular(20);

  return base.copyWith(
    scaffoldBackgroundColor:
        light ? const Color(0xFFF6F8FC) : const Color(0xFF0F1420),
    appBarTheme: AppBarTheme(
      backgroundColor: light ? const Color(0xFFF6F8FC) : const Color(0xFF0F1420),
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700, color: scheme.onSurface, fontSize: 20),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: light ? Colors.white : scheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant.withAlpha(110)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        textStyle: const TextStyle(
            fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: light ? Colors.white : scheme.surfaceContainer,
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(
          fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w600)),
    ),
    switchTheme: SwitchThemeData(
      thumbIcon: WidgetStateProperty.resolveWith((s) => s
              .contains(WidgetState.selected)
          ? const Icon(Icons.check, size: 16)
          : null),
    ),
    dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withAlpha(110), space: 1, thickness: 1),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Contenedor informativo de color suave con ícono.
class InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool warning;

  const InfoBox(
      {super.key, required this.icon, required this.text, this.warning = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = warning ? cs.errorContainer : cs.secondaryContainer;
    final fg = warning ? cs.onErrorContainer : cs.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(text,
                  style: TextStyle(color: fg, height: 1.35, fontSize: 14))),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: .2)),
      );
}
